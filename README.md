![SceneKitVideoRecorder](https://i.imgur.com/1f7aXFY.png "SceneKitVideoRecorder")

# SceneKitVideoRecorder

[![Version](https://img.shields.io/cocoapods/v/SceneKitVideoRecorder.svg?style=flat)](http://cocoapods.org/pods/SceneKitVideoRecorder)
[![Downloads](https://img.shields.io/cocoapods/dt/SceneKitVideoRecorder.svg?style=flat)](http://cocoapods.org/pods/SceneKitVideoRecorder)
[![License](https://img.shields.io/cocoapods/l/SceneKitVideoRecorder.svg?style=flat)](http://cocoapods.org/pods/SceneKitVideoRecorder)
[![Platform](https://img.shields.io/cocoapods/p/SceneKitVideoRecorder.svg?style=flat)](http://cocoapods.org/pods/SceneKitVideoRecorder)
[![Build Status](https://travis-ci.org/svtek/SceneKitVideoRecorder.svg?branch=master)](https://travis-ci.org/svtek/SceneKitVideoRecorder)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Apps using SceneKitVideoRecorder

[Surreal AR](https://itunes.apple.com/us/app/surreal-ar-augmented-reality/id1286981298?mt=8)
[Arrow](https://itunes.apple.com/app/arrow-ar-texts-emojis/id1296755150?ref=producthunt)

*Send a PR to add your app here*

## Installation

SceneKitVideoRecorder is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SceneKitVideoRecorder'
```


To install Swift 4 branch add the following line to your Podfile:
```ruby
pod 'SceneKitVideoRecorder', :git => 'https://github.com/svtek/SceneKitVideoRecorder.git', :branch => 'swift4'

```

## Usage

Add `NSMicrophoneUsageDescription` to `info.plist`


Add below code to your view controller

``` swift
var recorder: SceneKitVideoRecorder?
override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if recorder == nil {
        var options = SceneKitVideoRecorder.Options.default

        let scale = UIScreen.main.nativeScale
        let sceneSize = sceneView.bounds.size
        options.videoSize = CGSize(width: sceneSize.width * scale, height: sceneSize.height * scale)
        recorder = try! SceneKitVideoRecorder(withARSCNView: sceneView, options: options)
    }
}

@IBAction func startRecording (sender: UIButton) {
  self.recorder?.startWriting().onSuccess {
    print("Recording Started")
  }
}

@IBAction func stopRecording (sender: UIButton) {
  self.recorder?.finishWriting().onSuccess { [weak self] url in
    print("Recording Finished", url)
  }
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
The line ```camera.wantsHDR = true``` and ```camera.wantsExposureAdaptation = true``` causes a huge drop in video recording performance. You should remove or disable it for video recording.

## Author
| [<img src="https://avatars1.githubusercontent.com/u/1448702?v=4" width="100px;"/>](http://okaris.com)   | [Omer Karisman](http://okaris.com)<br/><br/><sub>Product Manager @ [MojiLaLa](http://mojilala.com)</sub><br/> [![Twitter][1.1]][1] [![Dribble][2.1]][2] [![Github][3.1]][3]| [<img src="https://pbs.twimg.com/profile_images/508440350495485952/U1VH52UZ_200x200.jpeg" width="100px;"/>](https://twitter.com/sahinboydas)   | [Sahin Boydas](https://twitter.com/sahinboydas)<br/><br/><sub>Co-Founder @ [MojiLaLa](http://mojilala.com)</sub><br/> [![LinkedIn][4.1]][4]|
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
