//
//  ViewController.swift
//  SCNVideoWriter
//
//  Created by noppefoxwolf on 07/31/2017.
//  Copyright (c) 2017 noppefoxwolf. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import SCNVideoWriter
import Photos

@available(iOS 11.0, *)
final class ARViewController: UIViewController {
  static func make() -> ARViewController {
    return UIStoryboard(name: "AR", bundle: nil).instantiateInitialViewController() as! ARViewController
  }
  
  @IBOutlet private weak var sceneView: ARSCNView!
  private var writer: SCNVideoWriter? = nil
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    setupARScene()
  }
  
  private func setupARScene() {
    let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
    let node = SCNNode(geometry: box)
    sceneView.scene.rootNode.addChildNode(node)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    sceneView.session.run(ARWorldTrackingSessionConfiguration())
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    sceneView.session.pause()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    do {
      writer = try SCNVideoWriter(withARSCNView: sceneView)
      writer?.startWriting()
    } catch let e {
      print(e)
    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    writer?.finishWriting(completionHandler: { [weak self] (url) in
      print("done", url)
      self?.save(video: url)
    })
  }
  
  private func save(video url: URL) {
    PHPhotoLibrary.shared().performChanges({
      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
    }) { (done, error) in
      print(done, error)
    }
  }
}
