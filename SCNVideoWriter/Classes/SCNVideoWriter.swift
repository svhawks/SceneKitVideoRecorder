//
//  SCNVideoWriter.swift
//  Pods-SCNVideoWriter_Example
//
//  Created by Tomoya Hirano on 2017/07/31.
//

import UIKit
import SceneKit
import AVFoundation

public class SCNVideoWriter {
  private let writer: AVAssetWriter
  private let input: AVAssetWriterInput
  private let pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor
  private let renderer: SCNRenderer
  private let options: Options
  
  private let frameQueue = DispatchQueue(label: "com.noppelabs.SCNVideoWriter.frameQueue")
  private let renderQueue = DispatchQueue(label: "com.noppelabs.SCNVideoWriter.RenderQueue")
  private let renderSemaphore = DispatchSemaphore(value: 3)
  private var displayLink: CADisplayLink? = nil
  private var currentTime: CFTimeInterval = 0.0
  
  private var finishedCompletionHandler: ((_ url: URL) -> Void)? = nil
  
  public init?(scene: SCNScene, options: Options = .default) throws {
    self.options = options
    self.renderer = SCNRenderer(device: nil, options: nil)
    renderer.scene = scene
    
    self.writer = try AVAssetWriter(outputURL: options.outputUrl,
                                    fileType: options.fileType)
    self.input = AVAssetWriterInput(mediaType: AVMediaTypeVideo,
                                    outputSettings: options.assetWriterInputSettings)
    
    self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
                                                                   sourcePixelBufferAttributes: options.sourcePixelBufferAttributes)
    prepare(with: options)
  }
  
  private func prepare(with options: Options) {
    if options.deleteFileIfExists {
      FileController.delete(file: options.outputUrl)
    }
    renderer.autoenablesDefaultLighting = true
    writer.add(input)
  }
  
  public func startWriting() {
    renderQueue.async { [weak self] in
      self?.renderSemaphore.wait()
      self?.startDisplayLink()
      self?.startInputPipeline()
    }
  }
  
  public func finisheWriting(completionHandler: (@escaping (_ url: URL) -> Void)) {
    let outputUrl = options.outputUrl
    input.markAsFinished()
    writer.finishWriting(completionHandler: { [weak self] in
      completionHandler(outputUrl)
      self?.stopDisplayLink()
      self?.renderSemaphore.signal()
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
      guard let size = self?.options.videoSize else { return }
      self?.renderSnapshot(with: pool, video: size)
    }
  }
  
  private func startInputPipeline() {
    writer.startWriting()
    writer.startSession(atSourceTime: kCMTimeZero)
    input.requestMediaDataWhenReady(on: frameQueue, using: {})
  }
  
  private func renderSnapshot(with pool: CVPixelBufferPool, video size: CGSize) {
    guard let link = displayLink else { return }
    currentTime += link.targetTimestamp - link.timestamp
    autoreleasepool {
      let image = renderer.snapshot(atTime: currentTime, with: size, antialiasingMode: .multisampling4X)
      guard let pixelBuffer = PixelBufferFactory.make(with: size, from: image, usingBuffer: pool) else { return }
      let value: Int64 = Int64(currentTime * CFTimeInterval(options.timeScale))
      let presentationTime = CMTimeMake(value, options.timeScale)
      pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
  }
  
  private func stopDisplayLink() {
    displayLink?.invalidate()
    displayLink = nil
  }
}

extension SCNVideoWriter {
  public struct Options {
    public var timeScale: Int32
    public var videoSize: CGSize
    public var fps: Int
    public var outputUrl: URL
    public var fileType: String
    public var codec: String
    public var deleteFileIfExists: Bool
    
    public static var `default`: Options {
      return Options(timeScale: 600,
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
