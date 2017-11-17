//
//  SceneKitVideoRecorder.swift
//
//  Created by Omer Karisman on 2017/08/29.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation
import CoreImage

public class SceneKitVideoRecorder: NSObject, AVAudioRecorderDelegate {
  private var writer: AVAssetWriter!
  private var videoInput: AVAssetWriterInput!

  var recordingSession: AVAudioSession!
  var audioRecorder: AVAudioRecorder!

  private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
  private var options: Options

  private let frameQueue = DispatchQueue(label: "com.svtek.SceneKitVideoRecorder.frameQueue")
  private let bufferQueue = DispatchQueue(label: "com.svtek.SceneKitVideoRecorder.bufferQueue", attributes: .concurrent)
  private let audioQueue = DispatchQueue(label: "com.svtek.SceneKitVideoRecorder.audioQueue")

  private var displayLink: CADisplayLink? = nil

  private var initialTime: CMTime = kCMTimeInvalid
  private var currentTime: CMTime = kCMTimeInvalid

  private var sceneView: SCNView

  private var audioSettings: [String : Any]?

  public var isAudioSetup: Bool = false

  private var isPrepared: Bool = false
  private var isRecording: Bool = false

  private var useAudio: Bool {
    return options.useMicrophone && AVAudioSession.sharedInstance().recordPermission() == .granted && isAudioSetup
  }
  private var videoFramesWritten: Bool = false
  private var waitingForPermissions: Bool = false

  private var renderer: SCNRenderer!

  public var updateFrameHandler: ((_ image: UIImage) -> Void)? = nil
  private var finishedCompletionHandler: ((_ url: URL) -> Void)? = nil

  @available(iOS 11.0, *)
  public convenience init(withARSCNView view: ARSCNView, options: Options = .`default`) throws {
    try self.init(scene: view, options: options)
  }

  public init(scene: SCNView, options: Options = .`default`, setupAudio: Bool = true) throws {

    self.sceneView = scene

    self.options = options

    self.isRecording = false
    self.videoFramesWritten = false

    super.init()

    FileController.clearTemporaryDirectory()

    self.prepare()

    if setupAudio {
      self.setupAudio()
    }
  }

  private func prepare() {

    self.prepare(with: self.options)
    isPrepared = true

  }

  private func prepare(with options: Options) {
    guard let device = MTLCreateSystemDefaultDevice() else { return }
    self.renderer = SCNRenderer(device: device, options: nil)
    renderer.scene = self.sceneView.scene

    initialTime = kCMTimeInvalid

    self.options.videoSize = options.videoSize

    writer = try! AVAssetWriter(outputURL: self.options.videoOnlyUrl, fileType: self.options.fileType)

    self.setupVideo()
  }

  @discardableResult public func cleanUp() -> URL {

    var output = options.outputUrl

    if options.deleteFileIfExists {
      let nameOnly = (options.outputUrl.lastPathComponent as NSString).deletingPathExtension
      let fileExt  = (options.outputUrl.lastPathComponent as NSString).pathExtension
      let tempFileName = NSTemporaryDirectory() + nameOnly + "TMP." + fileExt
      output = URL(fileURLWithPath: tempFileName)

      FileController.move(from: options.outputUrl, to: output)

      FileController.delete(file: self.options.audioOnlyUrl)
      FileController.delete(file: self.options.videoOnlyUrl)
    }

    return output
  }

  public func setupAudio() {
    guard self.options.useMicrophone, !self.isAudioSetup else { return }

    recordingSession = AVAudioSession.sharedInstance()

    do {
      try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.defaultToSpeaker])
      try recordingSession.setActive(true)
      recordingSession.requestRecordPermission() { allowed in
        DispatchQueue.main.async {
          if allowed {
            self.isAudioSetup = true
          } else {
            self.isAudioSetup = false
          }
        }
      }
    } catch {
      self.isAudioSetup = false
    }
  }

  private func startRecordingAudio() {
    let audioUrl = self.options.audioOnlyUrl

    let settings = self.options.assetWriterAudioInputSettings

    do {
      audioRecorder = try AVAudioRecorder(url: audioUrl, settings: settings)
      audioRecorder.delegate = self
      audioRecorder.record()

    } catch {
      finishRecordingAudio(success: false)
    }
  }

  private func finishRecordingAudio(success: Bool) {
    audioRecorder.stop()
    audioRecorder = nil
  }

  private func setupVideo() {

    self.videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo,
                                         outputSettings: self.options.assetWriterVideoInputSettings)

    self.videoInput.mediaTimeScale = self.options.timeScale

    self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput,sourcePixelBufferAttributes: self.options.sourcePixelBufferAttributes)

    writer.add(videoInput)
  }

  public func startWriting(completionHandler: (@escaping (_ success: Bool) -> Void) = {_ in }) {

    if isRecording { return }
    isRecording = true

    startDisplayLink()

    guard startInputPipeline() == true else {
      print("AVAssetWriter Failed:", "Unknown error")
      stopDisplayLink()
      cleanUp()
      completionHandler(false)
      return
    }

    completionHandler(true)

  }

  public func finishWriting(completionHandler: (@escaping (_ url: URL) -> Void)) {

    if !isRecording { return }

    if writer.status != .writing { return }

    videoInput.markAsFinished()

    if audioRecorder != nil {
      finishRecordingAudio(success: true)
    }

    isRecording = false
    isPrepared = false
    videoFramesWritten = false

    currentTime = kCMTimeInvalid

    writer.finishWriting(completionHandler: { [weak self] in

      guard let this = self else { return }

      this.stopDisplayLink()

      if this.useAudio {
        this.mergeVideoAndAudio(videoUrl: this.options.videoOnlyUrl, audioUrl: this.options.audioOnlyUrl) {
          let outputUrl = this.cleanUp()
          completionHandler(outputUrl)
        }
      }else{
        FileController.move(from: this.options.videoOnlyUrl, to: this.options.outputUrl)
        let outputUrl = this.cleanUp()
        completionHandler(outputUrl)
      }

      this.prepare()
    })

  }

  private func getCurrentCMTime() -> CMTime {
    return CMTimeMakeWithSeconds(CACurrentMediaTime(), 1000);
  }

  private func getAppendTime() -> CMTime {
    currentTime = getCurrentCMTime() - initialTime
    return currentTime
  }

  private func startDisplayLink() {

    displayLink = CADisplayLink(target: self, selector: #selector(updateDisplayLink))
    displayLink?.preferredFramesPerSecond = options.fps
    displayLink?.add(to: .main, forMode: .commonModes)

  }

  @objc private func updateDisplayLink() {

    frameQueue.async { [weak self] in

      if self?.writer.status == .unknown { return }
      if self?.writer.status == .failed { return }
      guard let input = self?.videoInput, input.isReadyForMoreMediaData else { return }

      self?.renderSnapshot()
    }

  }

  private func startInputPipeline() -> Bool {

    if writer.status != .unknown { return false }

    guard writer.startWriting() else { return false }

    writer.startSession(atSourceTime: kCMTimeZero)

    videoInput.requestMediaDataWhenReady(on: frameQueue, using: {})

    return true
  }

  private func renderSnapshot() {

    autoreleasepool {

      let time = CACurrentMediaTime()
      let image = renderer.snapshot(atTime: time, with: self.options.videoSize, antialiasingMode: self.options.antialiasingMode)

      updateFrameHandler?(image)

      guard let pool = self.pixelBufferAdaptor.pixelBufferPool else { print("No pool"); return }

      let pixelBufferTemp = PixelBufferFactory.make(with: image, usingBuffer: pool)

      guard let pixelBuffer = pixelBufferTemp else { print("No buffer"); return }

      guard videoInput.isReadyForMoreMediaData else { print("No ready for media data"); return }

      if videoFramesWritten == false {
        videoFramesWritten = true
        startRecordingAudio()
        initialTime = getCurrentCMTime()
      }

      let currentTime = getCurrentCMTime()

      guard CMTIME_IS_VALID(currentTime) else { print("No current time"); return }

      let appendTime = getAppendTime()

      guard CMTIME_IS_VALID(appendTime) else { print("No append time"); return }

      bufferQueue.async { [weak self] in

        self?.pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: appendTime)

      }
    }

  }

  private func stopDisplayLink() {

    displayLink?.invalidate()
    displayLink = nil

  }

  private func mergeVideoAndAudio(videoUrl:URL, audioUrl:URL, completion: @escaping () -> Void)
  {
    let mixComposition : AVMutableComposition = AVMutableComposition()
    var mutableCompositionVideoTrack : [AVMutableCompositionTrack] = []
    var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
    let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()

    let aVideoAsset : AVAsset = AVAsset(url: videoUrl)
    let aAudioAsset : AVAsset = AVAsset(url: audioUrl)

    mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid))
    mutableCompositionAudioTrack.append( mixComposition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid))

    let aVideoAssetTrack : AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaTypeVideo)[0]
    let aAudioAssetTrack : AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaTypeAudio)[0]

    do{
      try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: kCMTimeZero)

      try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aVideoAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: kCMTimeZero)

    }catch{

    }

    totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,aVideoAssetTrack.timeRange.duration )

    let mutableVideoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
    mutableVideoComposition.frameDuration = CMTimeMake(1, Int32(self.options.fps))

    mutableVideoComposition.renderSize = self.options.videoSize

    let savePathUrl : URL = self.options.outputUrl

    let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
    assetExport.outputFileType = AVFileTypeMPEG4
    assetExport.outputURL = savePathUrl
    assetExport.shouldOptimizeForNetworkUse = true

    assetExport.exportAsynchronously { () -> Void in
      switch assetExport.status {

      case AVAssetExportSessionStatus.completed:
        completion()
      case  AVAssetExportSessionStatus.failed:
        print("failed \(String(describing: assetExport.error))")
      case AVAssetExportSessionStatus.cancelled:
        print("cancelled \(String(describing: assetExport.error))")
      default:
        completion()
      }
    }
  }

}
