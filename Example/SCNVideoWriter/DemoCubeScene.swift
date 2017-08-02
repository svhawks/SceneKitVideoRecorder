//
//  DemoCubeScene.swift
//  SCNVideoWriter_Example
//
//  Created by Tomoya Hirano on 2017/08/02.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import SceneKit
import ARKit

class DemoCubeScene: SCNScene {
  var isDone: Bool {
    return self.rotationsSoFar >= self.rotations
  }
  
  private(set) var rotations: Int = 1
  private var rotationsSoFar: Int = 0
  private var rotationDuration: TimeInterval = 3.0
  
  var duration: TimeInterval {
    return self.rotationDuration * TimeInterval(self.rotations)
  }
  
  convenience init(rotations: Int) {
    self.init()
    
    precondition(rotations >= 1)
    
    self.rotations = rotations
    
    self.background.contents = UIColor.black
    
    let redMaterial = SCNMaterial()
    redMaterial.diffuse.contents = UIColor.red
    let cube = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
    cube.materials = [redMaterial]
    let cubeGeometryNode = SCNNode(geometry: cube)
    cubeGeometryNode.position = SCNVector3Make(0.0, 0.0, 0)
    self.rootNode.addChildNode(cubeGeometryNode)
    
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3Make(5, 5, 5)
    
    let cameraBoxNode = SCNNode()
    cameraBoxNode.addChildNode(cameraNode)
    self.rootNode.addChildNode(cameraBoxNode)
    
    let constraint = SCNLookAtConstraint(target: cubeGeometryNode)
    constraint.isGimbalLockEnabled = true
    cameraNode.constraints = [constraint]
    
    cubeGeometryNode.runAction(
      SCNAction.repeatForever(
        SCNAction.sequence(
          [
            SCNAction.rotateBy(x: 0.0, y: 2 * CGFloat.pi, z: 2 * CGFloat.pi, duration: self.rotationDuration),
            SCNAction.run({ (node) in
              self.rotationsSoFar += 1
            })
          ]
        )
      )
    )
  }
}
