//
//  Error.swift
//
//  Created by Omer Karisman on 2017/08/29.
//

import UIKit

extension SceneKitVideoRecorder {
  public enum ErrorCode: Int {
    case notReady = 0
    case zeroFrames = 1
    case assetExport = 2
    case recorderBusy = 3
    case unknown = 4
  }
}

