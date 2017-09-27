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

public class SceneKitVideoRecorder: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
  private var writer: AVAssetWriter!
  private var videoInput: AVAssetWriterInput!
  private var audioInput: AVAssetWriterInput!
  private var captureSession: AVCaptureSession!

  private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
  private var options: Options

  private let frameQueue = DispatchQueue(label: "com.svtek.SceneKitVideoRecorder.frameQueue")
  private static let renderQueue = DispatchQueue(label: "com.svtek.SceneKitVideoRecorder.renderQueue", attributes: .concurrent)
  private let bufferQueue = DispatchQueue(label: "com.svtek.SceneKitVideoRecorder.bufferQueue", attributes: .concurrent)
  private let audioQueue = DispatchQueue(label: "com.svtek.SceneKitVideoRecorder.audioQueue")

  private static let renderSemaphore = DispatchSemaphore(value: 3)
  private static let bufferAppendSemaphore = DispatchSemaphore(value: 1)

  private var displayLink: CADisplayLink? = nil
  private var initialTime: CFTimeInterval = 0.0
  private var currentTime: CFTimeInterval = 0.0

  private var sceneView: SCNView

  private var audioSettings: [String : Any]?

  private var isPrepared: Bool = false
  private var isRecording: Bool = false
  private var isAudioSetUp: Bool = false
  private var useAudio: Bool {
    return self.options.useMicrophone && AVAudioSession.sharedInstance().recordPermission() == .granted && isAudioSetUp
  }
  private var videoFramesWritten: Bool = false
  private var waitingForPermissions: Bool = false

  private var renderer: SCNRenderer!

  private var initialRenderTime: CFTimeInterval!

  public var updateFrameHandler: ((_ image: UIImage) -> Void)? = nil
  private var finishedCompletionHandler: ((_ url: URL) -> Void)? = nil

  @available(iOS 11.0, *)
  public convenience init(withARSCNView view: ARSCNView, options: Options = .default) throws {
    try self.init(scene: view, options: options)
  }

  public init(scene: SCNView, options: Options = .default) throws {

    self.sceneView = scene

    self.renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice()!, options: nil)
    renderer.scene = scene.scene

    self.initialRenderTime = CACurrentMediaTime()

    self.options = options

    self.isRecording = false
    self.videoFramesWritten = false

    super.init()

    self.prepare()
  }

  public func setupMicrophone() {

    self.waitingForPermissions = true
    AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
      if granted {
        self.setupAudio()
        self.options.useMicrophone = true
      } else{
        self.options.useMicrophone = false
      }
      self.waitingForPermissions = false
      self.isAudioSetUp = true
    })

  }

  private func prepare() {

    self.prepare(with: self.options)
    isPrepared = true

  }

  private func setupAudio () {

    let device: AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
    guard device.isConnected else {
      self.options.useMicrophone = false
      return
    }

    let audioCaptureInput = try! AVCaptureDeviceInput.init(device: device)

    let audioCaptureOutput = AVCaptureAudioDataOutput.init()

    audioCaptureOutput.setSampleBufferDelegate(self, queue: audioQueue)

    captureSession = AVCaptureSession.init()

    captureSession.sessionPreset = AVCaptureSessionPresetMedium

    captureSession.addInput(audioCaptureInput)
    captureSession.addOutput(audioCaptureOutput)

    self.audioSettings = audioCaptureOutput.recommendedAudioSettingsForAssetWriter(withOutputFileType: AVFileTypeAppleM4V) as? [String : Any]

    self.audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioSettings )

    self.audioInput.expectsMediaDataInRealTime = true

    audioQueue.async { [weak self] in
      self?.captureSession.startRunning()
    }
    writer.add(audioInput)

  }

  func setupVideo() {

    self.videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo,
                                         outputSettings: self.options.assetWriterVideoInputSettings)

    self.videoInput.mediaTimeScale = self.options.timeScale

    self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput,sourcePixelBufferAttributes: self.options.sourcePixelBufferAttributes)

    writer.add(videoInput)

  }

  private func prepare(with options: Options) {

    self.options.videoSize = options.videoSize

    writer = try! AVAssetWriter(outputURL: self.options.outputUrl,
                                fileType: self.options.fileType)
    setupVideo()

  }

  public func cleanUp() {

    if options.deleteFileIfExists {
      FileController.delete(file: options.outputUrl)
    }

  }

  public func startWriting() {

    cleanUp()

    SceneKitVideoRecorder.renderQueue.async { [weak self] in

      SceneKitVideoRecorder.renderSemaphore.wait()

      guard self?.startInputPipeline() == true else {
        print("AVAssetWriter Failed:", "Unknown error")
        SceneKitVideoRecorder.renderSemaphore.signal()
        self?.cleanUp()
        return
      }

      self?.startDisplayLink()

      self?.isRecording = true

    }

  }

  public func finishWriting(completionHandler: (@escaping (_ url: URL) -> Void)) {

    if !isRecording { return }

    let outputUrl = options.outputUrl
    videoInput.markAsFinished()
    if useAudio {
      audioInput.markAsFinished()
    }
    self.stopDisplayLink()

    self.isRecording = false
    self.isPrepared = false
    self.videoFramesWritten = false

    writer.finishWriting(completionHandler: { [weak self] in
      completionHandler(outputUrl)
      self?.prepare()
      SceneKitVideoRecorder.renderSemaphore.signal()
    })

  }

  private func startDisplayLink() {

    currentTime = 0.0
    initialTime = CFAbsoluteTimeGetCurrent()
    displayLink = CADisplayLink(target: self, selector: #selector(updateDisplayLink))
    displayLink?.preferredFramesPerSecond = options.fps
    displayLink?.add(to: .main, forMode: .commonModes)

  }

  @objc private func updateDisplayLink() {

    frameQueue.async { [weak self] in
      guard let input = self?.videoInput, input.isReadyForMoreMediaData else { return }
      self?.renderSnapshot()
    }

  }

  private func startInputPipeline() -> Bool {

    guard writer.startWriting() else { return false }
    
    if useAudio {
      while audioCaptureStartedAt == nil && firstAudioTimestamp == nil {}
      let millisElapsed = NSDate().timeIntervalSince(audioCaptureStartedAt! as Date) * Double(options.timeScale)
      writer.startSession(atSourceTime: CMTimeAdd(firstAudioTimestamp!, CMTimeMake(Int64(millisElapsed), Int32(options.timeScale))))
    }else{
      writer.startSession(atSourceTime: kCMTimeZero)
    }
    videoInput.requestMediaDataWhenReady(on: frameQueue, using: {})

    return true
  }

  private func renderSnapshot() {

    if writer.status == .unknown { return }
    if writer.status == .failed {
      self.prepare()
    }

    if !videoInput.isReadyForMoreMediaData { return }

    autoreleasepool {

      let image = renderer.snapshot(atTime: CACurrentMediaTime(), with: self.options.videoSize, antialiasingMode: .none)

      guard let pool = self.pixelBufferAdaptor.pixelBufferPool else { return }

      let pixelBufferTemp = PixelBufferFactory.make(with: image, usingBuffer: pool)

      guard let pixelBuffer = pixelBufferTemp else { return }

      var presentationTime: CMTime

      if(useAudio){
        let millisElapsed = NSDate().timeIntervalSince(audioCaptureStartedAt! as Date) * Double(options.timeScale)
        presentationTime = CMTimeAdd(firstAudioTimestamp!, CMTimeMake(Int64(millisElapsed), Int32(options.timeScale)))
      }else{
        currentTime = CFAbsoluteTimeGetCurrent() - initialTime
        let value: Int64 = Int64(currentTime * CFTimeInterval(options.timeScale))
        presentationTime = CMTimeMake(value, options.timeScale)
      }

      SceneKitVideoRecorder.bufferAppendSemaphore.wait()

      bufferQueue.async { [weak self] in
        if self?.videoFramesWritten == false { self?.videoFramesWritten = true }
        if !(self?.videoInput.isReadyForMoreMediaData)! { return }
        self?.pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
        SceneKitVideoRecorder.bufferAppendSemaphore.signal()
      }
    }

  }

  private var audioCaptureStartedAt: NSDate?
  private var firstAudioTimestamp: CMTime?

  public func captureOutput(_ output: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {

    if(audioCaptureStartedAt == nil) {
      audioCaptureStartedAt = NSDate()
      firstAudioTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    }
    if(audioInput.isReadyForMoreMediaData && isRecording && videoFramesWritten){
      audioInput.append(sampleBuffer)
    }

  }


  private func stopDisplayLink() {

    displayLink?.invalidate()
    displayLink = nil

  }

}
