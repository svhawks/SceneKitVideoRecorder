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
| [<img src="https://avatars1.githubusercontent.com/u/1448702?v=4" width="100px;"/>](http://okaris.com)   | [Omer Karisman](http://okaris.com)<br/><br/><sub>Lead UI/UX @ [MojiLaLa](http://mojilala.com)</sub><br/> [![Twitter][1.1]][1] [![Dribble][2.1]][2] [![Github][3.1]][3]| [<img src="https://pbs.twimg.com/profile_images/508440350495485952/U1VH52UZ_200x200.jpeg" width="100px;"/>](https://twitter.com/sahinboydas)   | [Sahin Boydas](https://twitter.com/sahinboydas)<br/><br/><sub>Co-Founder @ [MojiLaLa](http://mojilala.com)</sub><br/> [![LinkedIn][4.1]][4]|
| - | :- | - | :- |

[1.1]: http://i.imgur.com/wWzX9uB.png (twitter icon without padding)
[2.1]: http://i.imgur.com/Vvy3Kru.png (dribbble icon without padding)
[3.1]: http://i.imgur.com/9I6NRUm.png (github icon without padding)
[4.1]: https://www.kingsfund.org.uk/themes/custom/kingsfund/dist/img/svg/sprite-icon-linkedin.svg (linkedin icon)

[1]: http://www.twitter.com/okarisman
[2]: http://dribbble.com/okaris
[3]: http://www.github.com/okaris
[4]: https://www.linkedin.com/in/sahinboydas

## Inspired from
noppefoxwolf, noppelabs@gmail.com

## License

SceneKitVideoRecorder is available under the MIT license. See the LICENSE file for more info.
