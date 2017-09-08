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
    private var writer: AVAssetWriter!
    private var input: AVAssetWriterInput!
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    private var options: Options
    private var currentDrawable: CAMetalDrawable?
    
    private let frameQueue = DispatchQueue(label: "com.svtek.SceneKitVideoRecorder.frameQueue")
    private static let renderQueue = DispatchQueue(label: "com.svtek.SceneKitVideoRecorder.renderQueue", attributes: .concurrent)
    private let bufferQueue = DispatchQueue(label: "com.svtek.SceneKitVideoRecorder.bufferQueue", attributes: .concurrent)
    
    private static let renderSemaphore = DispatchSemaphore(value: 3)
    
    private static let frameRenderSemaphore = DispatchSemaphore(value: 1)
    private static let bufferAppendSemaphore = DispatchSemaphore(value: 1)
    
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
      options.videoSize = CGSize(width: view.bounds.width * view.contentScaleFactor, height: view.bounds.height * view.contentScaleFactor)
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
      
      prepare(with: self.options)
    }
    
    private func prepare(with options: Options) {
      self.writer = try! AVAssetWriter(outputURL: self.options.outputUrl,
                                       fileType: self.options.fileType)
      self.input = AVAssetWriterInput(mediaType: AVMediaTypeVideo,
                                      outputSettings: self.options.assetWriterInputSettings)
      
      self.input.mediaTimeScale = self.options.timeScale
      
      self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,sourcePixelBufferAttributes: self.options.sourcePixelBufferAttributes)
      
      writer.add(input)
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
        self?.startDisplayLink()
        self?.startInputPipeline()
      }
    }
    
    public func finishWriting(completionHandler: (@escaping (_ url: URL) -> Void)) {
      let outputUrl = options.outputUrl
      input.markAsFinished()
      self.stopDisplayLink()
      writer.finishWriting(completionHandler: { _ in
        completionHandler(outputUrl)
        self.prepare(with: self.options)
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
      if !input.isReadyForMoreMediaData { return }
      
      autoreleasepool {
        
        while (currentDrawable == nil) {
          currentDrawable = metalLayer.nextDrawable()
        }
        
        
        SceneKitVideoRecorder.frameRenderSemaphore.wait()
        
        
        guard let pool = self.pixelBufferAdaptor.pixelBufferPool else { return }
        
        let (pixelBufferTemp, image) = PixelBufferFactory.make(with: currentDrawable!, usingBuffer: pool)
        currentDrawable = nil
        guard let pixelBuffer = pixelBufferTemp else { return }
        currentTime = CFAbsoluteTimeGetCurrent() - initialTime
        
        let value: Int64 = Int64(currentTime * CFTimeInterval(options.timeScale))
        let presentationTime = CMTimeMake(value, options.timeScale)
        SceneKitVideoRecorder.bufferAppendSemaphore.wait()
        bufferQueue.async { [weak self] in
          self?.pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
          SceneKitVideoRecorder.bufferAppendSemaphore.signal()
        }
        updateFrameHandler?(image, presentationTime)
      }
      SceneKitVideoRecorder.frameRenderSemaphore.signal()
    }
    
    
    
    
    private func stopDisplayLink() {
      displayLink?.invalidate()
      displayLink = nil
    }
  }
  
#endif


