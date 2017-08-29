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
}
