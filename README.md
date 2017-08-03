# SCNVideoWriter

[![Version](https://img.shields.io/cocoapods/v/SCNVideoWriter.svg?style=flat)](http://cocoapods.org/pods/SCNVideoWriter)
[![License](https://img.shields.io/cocoapods/l/SCNVideoWriter.svg?style=flat)](http://cocoapods.org/pods/SCNVideoWriter)
[![Platform](https://img.shields.io/cocoapods/p/SCNVideoWriter.svg?style=flat)](http://cocoapods.org/pods/SCNVideoWriter)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

SCNVideoWriter is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SCNVideoWriter"
```

## Usage

```
let writer = try! SCNVideoWriter(scene: sceneView.scene)
writer.startWriting()
writer.finisheWriting(completionHandler: { [weak self] (url) in
  print("done", url)
})
```

## Author

noppefoxwolf, noppelabs@gmail.com

## License

SCNVideoWriter is available under the MIT license. See the LICENSE file for more info.
