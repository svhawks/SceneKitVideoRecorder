//
//  SCNVideoWriter.swift
//  Pods-SCNVideoWriter_Example
//
//  Created by Tomoya Hirano on 2017/07/31.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation

public class SCNVideoWriter {
  private let writer: AVAssetWriter
  private let input: AVAssetWriterInput
  private let pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor
  private let renderer: SCNRenderer
  private let options: Options
  
  private let frameQueue = DispatchQueue(label: "com.noppelabs.SCNVideoWriter.frameQueue")
  private static let renderQueue = DispatchQueue(label: "com.noppelabs.SCNVideoWriter.renderQueue")
  private static let renderSemaphore = DispatchSemaphore(value: 3)
  private var displayLink: CADisplayLink? = nil
  private var currentTime: CFTimeInterval = 0.0
  
  public var updateFrameHandler: ((_ image: UIImage, _ time: CMTime) -> Void)? = nil
  private var finishedCompletionHandler: ((_ url: URL) -> Void)? = nil
  
  @available(iOS 11.0, *)
  public convenience init?(withARSCNView view: ARSCNView, options: Options = .default) throws {
    var options = options
    options.renderSize = CGSize(width: view.bounds.width * view.contentScaleFactor, height: view.bounds.height * view.contentScaleFactor)
    try self.init(scene: view.scene, options: options)
  }
  
  public init?(scene: SCNScene, options: Options = .default) throws {
    self.options = options
    self.renderer = SCNRenderer(device: nil, options: nil)
    renderer.scene = scene
    
    self.writer = try AVAssetWriter(outputURL: options.outputUrl,
                                    fileType: options.fileType)
    self.input = AVAssetWriterInput(mediaType: AVMediaTypeVideo,
                                    outputSettings: options.assetWriterInputSettings)
    //input.expectsMediaDataInRealTime = true
    self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
                                                                   sourcePixelBufferAttributes: options.sourcePixelBufferAttributes)
    prepare(with: options)
  }
  
  private func prepare(with options: Options) {
    if options.deleteFileIfExists {
      FileController.delete(file: options.outputUrl)
    }
    writer.add(input)
  }
  
  public func startWriting() {
    SCNVideoWriter.renderQueue.async { [weak self] in
      SCNVideoWriter.renderSemaphore.wait()
      self?.startDisplayLink()
      self?.startInputPipeline()
    }
  }
  
  public func finishWriting(completionHandler: (@escaping (_ url: URL) -> Void)) {
    let outputUrl = options.outputUrl
    input.markAsFinished()
    writer.finishWriting(completionHandler: { [weak self] in
      completionHandler(outputUrl)
      self?.stopDisplayLink()
      SCNVideoWriter.renderSemaphore.signal()
    })
  }
  
  private func startDisplayLink() {
    currentTime = 0.0
    displayLink = CADisplayLink(target: self, selector: #selector(updateDisplayLink))
    displayLink?.preferredFramesPerSecond = options.fps
    displayLink?.add(to: .main, forMode: .commonModes)
  }
  
  @objc private func updateDisplayLink() {
    frameQueue.async { [weak self] in
      guard let input = self?.input, input.isReadyForMoreMediaData else { return }
      guard let pool = self?.pixelBufferAdaptor.pixelBufferPool else { return }
      guard let renderSize = self?.options.renderSize else { return }
      guard let videoSize = self?.options.videoSize else { return }
      self?.renderSnapshot(with: pool, renderSize: renderSize, videoSize: videoSize)
    }
  }
  
  private func startInputPipeline() {
    writer.startWriting()
    writer.startSession(atSourceTime: kCMTimeZero)
    input.requestMediaDataWhenReady(on: frameQueue, using: {})
  }
  
  private func renderSnapshot(with pool: CVPixelBufferPool, renderSize: CGSize, videoSize: CGSize) {
    guard let link = displayLink else { return }
    currentTime += link.targetTimestamp - link.timestamp
    autoreleasepool {
      let image = renderer.snapshot(atTime: currentTime, with: renderSize, antialiasingMode: .multisampling4X)
      let croppedImage = image.crop(at: videoSize)
      guard let pixelBuffer = PixelBufferFactory.make(with: videoSize, from: croppedImage, usingBuffer: pool) else { return }
      let value: Int64 = Int64(currentTime * CFTimeInterval(options.timeScale))
      let presentationTime = CMTimeMake(value, options.timeScale)
      pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    updateFrameHandler?(croppedImage, presentationTime)
  }
  
  private func stopDisplayLink() {
    displayLink?.invalidate()
    displayLink = nil
  }
}

extension SCNVideoWriter {
  public struct Options {
    public var timeScale: Int32
    public var renderSize: CGSize
    public var videoSize: CGSize
    public var fps: Int
    public var outputUrl: URL
    public var fileType: String
    public var codec: String
    public var deleteFileIfExists: Bool
    
    public static var `default`: Options {
      return Options(timeScale: 600,
                     renderSize: CGSize(width: 640, height: 640),
                     videoSize: CGSize(width: 640, height: 640),
                     fps: 60,
                     outputUrl: URL(fileURLWithPath: NSTemporaryDirectory() + "output.mp4"),
                     fileType: AVFileTypeAppleM4V,
                     codec: AVVideoCodecH264,
                     deleteFileIfExists: true)
    }
    
    var assetWriterInputSettings: [String : Any] {
      return [
        AVVideoCodecKey: codec,
        AVVideoWidthKey: videoSize.width,
        AVVideoHeightKey: videoSize.height
      ]
    }
    var sourcePixelBufferAttributes: [String : Any] {
      return [
        kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
        kCVPixelBufferWidthKey as String: videoSize.width,
        kCVPixelBufferHeightKey as String: videoSize.height
      ]
    }
  }
}
