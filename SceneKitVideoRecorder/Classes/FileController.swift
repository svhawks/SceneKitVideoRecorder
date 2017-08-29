//
//  FileController.swift
//
//  Created by Tomoya Hirano on 2017/08/02.
//

import UIKit

struct FileController {
  static func delete(file url: URL) {
    let fm = FileManager.default
    if fm.fileExists(atPath: url.path) {
      try! fm.removeItem(at: url)
    }
  }
}
