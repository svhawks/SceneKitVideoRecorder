//
//  SceneKitVideoRecorder.swift
//
//  Created by Omer Karisman on 2017/08/29.
//
#if arch(i386) || arch(x86_64)
  import UIKit
  import SceneKit
  public class SceneKitVideoRecorder {
    public init?(scene: SCNView, options: Options = .default) throws {}
    public func startWriting() {}
    public func finishWriting(completionHandler: (@escaping (_ url: URL) -> Void)) {}
  }
  //Metal does not work in simulator :(
#else
  
  import UIKit
  import SceneKit
  import ARKit
  import AVFoundation
  import Metal
  import CoreImage
  
  public class SceneKitVideoRecorder {
    private let writer: AVAssetWriter
    private let input: AVAssetWriterInput
    private let pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor
    private var options: Options
    
    private let frameQueue = DispatchQueue(label: "com.svtek.SceneKitVideoRecorder.frameQueue")
    private static let renderQueue = DispatchQueue(label: "com.svtek.SceneKitVideoRecorder.renderQueue")
    private static let renderSemaphore = DispatchSemaphore(value: 3)
    private var displayLink: CADisplayLink? = nil
    private var initialTime: CFTimeInterval = 0.0
    private var currentTime: CFTimeInterval = 0.0
    
    private var sceneView: SCNView
    private var metalLayer: CAMetalLayer
    
    public var updateFrameHandler: ((_ image: UIImage, _ time: CMTime) -> Void)? = nil
    private var finishedCompletionHandler: ((_ url: URL) -> Void)? = nil
    private let context:CIContext
    
    @available(iOS 11.0, *)
    public convenience init?(withARSCNView view: ARSCNView, options: Options = .default) throws {
      var options = options
      options.renderSize = CGSize(width: view.bounds.width * view.contentScaleFactor, height: view.bounds.height * view.contentScaleFactor)
      try self.init(scene: view, options: options)
    }
    
    public init?(scene: SCNView, options: Options = .default) throws {
      
      self.sceneView = scene
      
      self.context = CIContext.init(mtlDevice: MTLCreateSystemDefaultDevice()!)
      
      self.metalLayer = (sceneView.layer as? CAMetalLayer)!
      self.metalLayer.framebufferOnly = false
      
      self.options = options
      
      let currentDrawable = metalLayer.nextDrawable()
      
      self.options.videoSize = (currentDrawable?.layer.drawableSize)!
      
      self.writer = try AVAssetWriter(outputURL: self.options.outputUrl,
                                      fileType: self.options.fileType)
      self.input = AVAssetWriterInput(mediaType: AVMediaTypeVideo,
                                      outputSettings: self.options.assetWriterInputSettings)
      
      self.input.mediaTimeScale = self.options.timeScale
      
      
      self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,sourcePixelBufferAttributes: self.options.sourcePixelBufferAttributes)
      prepare(with: self.options)
    }
    
    private func prepare(with options: Options) {
      if options.deleteFileIfExists {
        FileController.delete(file: options.outputUrl)
      }
      writer.add(input)
    }
    
    public func startWriting() {
      SceneKitVideoRecorder.renderQueue.async { [weak self] in
        SceneKitVideoRecorder.renderSemaphore.wait()
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
        guard let input = self?.input, input.isReadyForMoreMediaData else { return }
        self?.renderSnapshot()
      }
    }
    
    private func startInputPipeline() {
      writer.startWriting()
      writer.startSession(atSourceTime: kCMTimeZero)
      input.requestMediaDataWhenReady(on: frameQueue, using: {})
    }
    
    private func renderSnapshot() {
      autoreleasepool {
        
        guard let pool = self.pixelBufferAdaptor.pixelBufferPool else { return }
        
        let (pixelBufferTemp, image) = PixelBufferFactory.make(with: metalLayer, usingBuffer: pool)
        guard let pixelBuffer = pixelBufferTemp else { return }
        currentTime = CFAbsoluteTimeGetCurrent() - initialTime
        
        let actualFramesPerSecond = 1 / ((displayLink?.targetTimestamp)! - (displayLink?.timestamp)!)
        
        let value: Int64 = Int64(currentTime * CFTimeInterval(options.timeScale))
        let presentationTime = CMTimeMake(value, options.timeScale)
        
        pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
        updateFrameHandler?(image, presentationTime)
        
      }
    }
    
    
    
    
    private func stopDisplayLink() {
      displayLink?.invalidate()
      displayLink = nil
    }
  }
  
#endif


