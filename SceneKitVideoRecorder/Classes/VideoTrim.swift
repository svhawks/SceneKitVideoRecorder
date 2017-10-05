import AVFoundation
import Foundation
import UIKit

typealias TrimCompletion = (Error?) -> ()
typealias TrimPoints = [(CMTime, CMTime)]

struct VideoTrim {

  static func verifyPresetForAsset(preset: String, asset: AVAsset) -> Bool {
    let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
    let filteredPresets = compatiblePresets.filter { $0 == preset }
    return filteredPresets.count > 0 || preset == AVAssetExportPresetPassthrough
  }

  static func removeFileAtURLIfExists(url: URL) {

    let fileManager = FileManager.default

    guard fileManager.fileExists(atPath: url.path) else { return }

    do {
      try fileManager.removeItem(at: url)
    }
    catch let error {
      print("TrimVideo - Couldn't remove existing destination file: \(String(describing: error))")
    }
  }

  static func trimVideo(sourceURL: URL, destinationURL: URL, trimPoints: TrimPoints, completion: TrimCompletion?) {

    guard sourceURL.isFileURL else { return }
    guard destinationURL.isFileURL else { return }

    let options = [
      AVURLAssetPreferPreciseDurationAndTimingKey: true
    ]

    let asset = AVURLAsset(url: sourceURL as URL, options: options)
    let preferredPreset = AVAssetExportPresetPassthrough

    if  verifyPresetForAsset(preset: preferredPreset, asset: asset) {

      let composition = AVMutableComposition()

      guard let assetVideoTrack: AVAssetTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first else { return }
      let assetAudioTrack: AVAssetTrack? = asset.tracks(withMediaType: AVMediaTypeAudio).first


      let videoCompTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
      var audioCompTrack: AVMutableCompositionTrack?
      if assetAudioTrack != nil {
       audioCompTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
      }
      var accumulatedTime = kCMTimeZero
      for (startTimeForCurrentSlice, endTimeForCurrentSlice) in trimPoints {
        let durationOfCurrentSlice = CMTimeSubtract(endTimeForCurrentSlice, startTimeForCurrentSlice)
        let timeRangeForCurrentSlice = CMTimeRangeMake(startTimeForCurrentSlice, durationOfCurrentSlice)

        do {
          try videoCompTrack.insertTimeRange(timeRangeForCurrentSlice, of: assetVideoTrack, at: accumulatedTime)
          if assetAudioTrack != nil {
            try audioCompTrack?.insertTimeRange(timeRangeForCurrentSlice, of: assetAudioTrack!, at: accumulatedTime)
          }
          accumulatedTime = CMTimeAdd(accumulatedTime, durationOfCurrentSlice)
        }
        catch let compError {
          print("TrimVideo: error during composition: \(compError)")
          completion?(compError)
        }
      }

      guard let exportSession = AVAssetExportSession(asset: composition, presetName: preferredPreset) else { return }

      exportSession.outputURL = destinationURL
      exportSession.outputFileType = AVFileTypeAppleM4V
      exportSession.shouldOptimizeForNetworkUse = true

      removeFileAtURLIfExists(url: destinationURL as URL)

      exportSession.exportAsynchronously {
        completion?(exportSession.error)
      }
    }
    else {
      print("TrimVideo - Could not find a suitable export preset for the input video")
      let error = NSError(domain: "com.svtek.SceneKitVideoRecorder", code: -1, userInfo: nil)
      completion?(error)
    }
  }
}
