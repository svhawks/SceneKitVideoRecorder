//
//  FileController.swift
//
//  Created by Omer Karisman on 2017/08/29.
//

import UIKit

struct FileController {
  static func delete(file url: URL) {
    let fm = FileManager.default
    if fm.fileExists(atPath: url.path) {
      try! fm.removeItem(at: url)
    }
  }

  static func move(from urlFrom: URL, to urlTo: URL) {
    let fm = FileManager.default
    guard fm.fileExists(atPath: urlFrom.path) else { return }
    if fm.fileExists(atPath: urlTo.path) {
      try! fm.removeItem(at: urlTo)
    }
    try! fm.moveItem(at: urlFrom, to: urlTo)
  }

  static func clearTemporaryDirectory(){
    var removed: Int = 0
    do {
      let tmpDirURL = URL(string: NSTemporaryDirectory())!
      var tmpFiles = try FileManager.default.contentsOfDirectory(at: tmpDirURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
      tmpFiles = tmpFiles.filter() { $0.absoluteString.contains(".mp4") }
      print("\(tmpFiles.count) temporary files found")
      for url in tmpFiles {
        removed += 1
        try FileManager.default.removeItem(at: url)
      }
      print("\(removed) temporary files removed")
    } catch {
      print(error)
      print("\(removed) temporary files removed")
    }
  }
}
