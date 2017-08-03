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
final class ViewController: UIViewController {
  @IBOutlet private weak var sceneView: ARSCNView!
  private var writer: SCNVideoWriter? = nil
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
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
      writer = try SCNVideoWriter(scene: sceneView.scene)
      writer?.startWriting()
    } catch let e {
      print(e)
    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    writer?.finisheWriting(completionHandler: { [weak self] (url) in
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
