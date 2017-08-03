//
//  ViewController.swift
//  SCNVideoWriter_Example
//
//  Created by Tomoya Hirano on 2017/08/04.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

final class ViewController: UITableViewController {
  enum SceneKitKind: Int {
    case scn
    case ar
    
    static var all: [SceneKitKind] {
      return [scn, ar]
    }
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return SceneKitKind.all.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
    switch SceneKitKind(rawValue: indexPath.row) {
    case .some(.scn): cell.textLabel?.text = "SceneKit"
    case .some(.ar): cell.textLabel?.text = "ARKit (iOS11 or later)"
    default: break
    }
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch SceneKitKind(rawValue: indexPath.row) {
    case .some(.scn):
      navigationController?.pushViewController(SCNViewController.make(), animated: true)
    case .some(.ar):
      if #available(iOS 11.0, *) {
        navigationController?.pushViewController(ARViewController.make(), animated: true)
      }
    default: break
    }
  }
}
