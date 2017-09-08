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

```
@IBAction func startRecording (sender: UIButton) {
  //Initialize recorder just before recording. This way we can make sure everything sized properly.
  if recorder == nil {
    recorder = try! SceneKitVideoRecorder(withARSCNView: sceneView)
  }
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

## Author
okaris, ok@okaris.com

## Inspired from
noppefoxwolf, noppelabs@gmail.com

## License

SceneKitVideoRecorder is available under the MIT license. See the LICENSE file for more info.
