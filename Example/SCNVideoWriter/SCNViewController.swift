//
//  SCNViewController.swift
//  SCNVideoWriter_Example
//
//  Created by Tomoya Hirano on 2017/08/04.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit
import SceneKit
import SCNVideoWriter
import Photos

final class SCNViewController: UIViewController {
  static func make() -> SCNViewController {
    return UIStoryboard(name: "SCN", bundle: nil).instantiateInitialViewController() as! SCNViewController
  } 
  @IBOutlet private weak var sceneView: SCNView!
  private var writer: SCNVideoWriter? = nil
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupSceneView()
  }
  
  private func setupSceneView() {
    let scene = SCNScene()
    
    let box = SCNBox(width: 10.0, height: 10.0, length: 10.0, chamferRadius: 0.0)
    let boxNode = SCNNode(geometry: box)
    scene.rootNode.addChildNode(boxNode)
    boxNode.rotation = SCNVector4Make(0, 1, 0, Float.pi / 5.0)
    
    let cameraNode = SCNNode()
    let camera = SCNCamera()
    cameraNode.camera = camera
    cameraNode.position = SCNVector3Make(0, 10, 20)
    cameraNode.rotation = SCNVector4Make(1, 0, 0, -atan2(10.0, 20.0))
    scene.rootNode.addChildNode(cameraNode)
    
    let light = SCNLight()
    light.type = SCNLight.LightType.directional
    light.color = UIColor.blue
    let lightNode = SCNNode()
    lightNode.light = light
    cameraNode.addChildNode(lightNode)
    
    sceneView.scene = scene
    boxNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    do {
      writer = try SCNVideoWriter(scene: sceneView.scene!)
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
