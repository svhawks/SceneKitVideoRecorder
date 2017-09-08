//
//  Error.swift
//
//  Created by Omer Karisman on 2017/08/29.
//

import UIKit

extension SceneKitVideoRecorder {
  public struct VideoSizeError: Error {}
  public struct PreparationError: Error {
    let title = "Recorder wasn't ready!"
    let description = "You need to call prepare() before startWriting(). Preferably in viewDidAppear() way before startWriting()"
  }
  public struct RenderingApiError: Error {
    let title = "Only Metal is supported!"
    let description = "SceneKitVideoRecorder only supports scenes with Metal as rendering api for now."
  }
}

