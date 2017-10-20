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

    if fm.fileExists(atPath: urlFrom.path) {
      try! fm.removeItem(at: urlFrom)
    }
  }

  static func clearTemporaryDirectory(){
    var removed: Int = 0
    do {
      let tmpDirURL = URL(string: NSTemporaryDirectory())!
      var tmpFiles = try FileManager.default.contentsOfDirectory(at: tmpDirURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
      tmpFiles = tmpFiles.filter() { $0.absoluteString.contains(".mp4") }
      for url in tmpFiles {
        removed += 1
        try FileManager.default.removeItem(at: url)
      }
    } catch {
      print(error)
    }
  }
}
