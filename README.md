# SceneKitVideoRecorder

[![Version](https://img.shields.io/cocoapods/v/SceneKitVideoRecorder.svg?style=flat)](http://cocoapods.org/pods/SceneKitVideoRecorder)
[![License](https://img.shields.io/cocoapods/l/SceneKitVideoRecorder.svg?style=flat)](http://cocoapods.org/pods/SceneKitVideoRecorder)
[![Platform](https://img.shields.io/cocoapods/p/SceneKitVideoRecorder.svg?style=flat)](http://cocoapods.org/pods/SceneKitVideoRecorder)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

SceneKitVideoRecorder is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SceneKitVideoRecorder"
```

## Usage

Add `NSMicrophoneUsageDescription` to `info.plist`


Add below code to your view controller

```
var recorder: SceneKitVideoRecorder?

override func viewDidLoad() {
  super.viewDidLoad()
  ...
  recorder = try! SceneKitVideoRecorder(withARSCNView: sceneView)
}

@IBAction func startRecording (sender: UIButton) {
  sender.backgroundColor = .red
  self.recorder?.startWriting()
}

@IBAction func stopRecording (sender: UIButton) {
  sender.backgroundColor = .white
  self.recorder?.finishWriting(completionHandler: { [weak self] (url) in
    print("Recording Finished", url)
    self?.checkAuthorizationAndPresentActivityController(toShare: url, using: self!)
  })
}
```

## Performance tips

Here is a piece of Apple sample code

```
 if let camera = sceneView.pointOfView?.camera {
  camera.wantsHDR = true
  camera.wantsExposureAdaptation = true
  camera.exposureOffset = -1
  camera.minimumExposure = -1
}
```
The line ```camera.wantsHDR = true``` causes a huge drop in video recording performance. You should remove or disable it out for video recording.

## Author
okaris, ok@okaris.com

## Inspired from
noppefoxwolf, noppelabs@gmail.com

## License

SceneKitVideoRecorder is available under the MIT license. See the LICENSE file for more info.
