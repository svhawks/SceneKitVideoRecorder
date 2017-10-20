//
//  Options.swift
//
//  Created by Omer Karisman on 2017/08/29.
//

import UIKit
import SceneKit
import AVFoundation

extension SceneKitVideoRecorder {
  public struct Options {
    public var timeScale: Int32
    public var videoSize: CGSize
    public var fps: Int
    public var outputUrl: URL
    public var audioOnlyUrl: URL
    public var videoOnlyUrl: URL
    public var fileType: String
    public var codec: String
    public var deleteFileIfExists: Bool
    public var useMicrophone: Bool
    public var antialiasingMode: SCNAntialiasingMode

    public static var `default`: Options {
      return Options(timeScale: 1000,
                     videoSize: CGSize(width: 720, height: 1280),
                     fps: 60,
                     outputUrl: URL(fileURLWithPath: NSTemporaryDirectory() + "output.mp4"),
                     audioOnlyUrl: URL(fileURLWithPath: NSTemporaryDirectory() + "audio.m4a"),
                     videoOnlyUrl: URL(fileURLWithPath: NSTemporaryDirectory() + "video.mp4"),
                     fileType: AVFileType.m4v.rawValue,
                     codec: AVVideoCodecH264,
                     deleteFileIfExists: true,
                     useMicrophone: true,
                     antialiasingMode: .multisampling4X)
    }
    
    var assetWriterVideoInputSettings: [String : Any] {
      return [
        AVVideoCodecKey: codec,
        AVVideoWidthKey: videoSize.width,
        AVVideoHeightKey: videoSize.height
      ]
    }
    
    var assetWriterAudioInputSettings: [String : Any] {
      return [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
      ]
    }
    
    var sourcePixelBufferAttributes: [String : Any] {
      return [
        kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
        kCVPixelBufferWidthKey as String: videoSize.width,
        kCVPixelBufferHeightKey as String: videoSize.height,
      ]
    }
  }
}

