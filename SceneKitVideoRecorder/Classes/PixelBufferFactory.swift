//
//  PixelBufferFactory.swift
//
//  Created by Omer Karisman on 2017/08/29.
//
#if arch(i386) || arch(x86_64)
  import UIKit
  struct PixelBufferFactory {
  }
  //Metal does not work in simulator :(
#else
import UIKit

struct PixelBufferFactory {

  static let context = CIContext(options: nil)

  static func make(with metalLayer: CAMetalLayer, usingBuffer pool: CVPixelBufferPool) -> (CVPixelBuffer?, UIImage) {

    let currentDrawable = metalLayer.nextDrawable()
    let destinationTexture = currentDrawable?.texture

    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
    if let pixelBuffer = pixelBuffer {
      CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.init(rawValue: 0))
      let region = MTLRegionMake2D(0, 0, Int((currentDrawable?.layer.drawableSize.width)!), Int((currentDrawable?.layer.drawableSize.height)!))

      let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

      let tempBuffer = CVPixelBufferGetBaseAddress(pixelBuffer)
      destinationTexture?.getBytes(tempBuffer!, bytesPerRow: Int(bytesPerRow), from: region, mipmapLevel: 0)

      let image = imageFromCVPixelBuffer(buffer: pixelBuffer)
      CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.init(rawValue: 0))
      return (pixelBuffer, image)
    }
    return (nil, UIImage())
  }

  static func imageFromCVPixelBuffer(buffer: CVPixelBuffer) -> UIImage {

    let ciimage = CIImage(cvPixelBuffer: buffer)
    let cgimgage = context.createCGImage(ciimage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer)))

    let uiimage = UIImage(cgImage: cgimgage!)

    return uiimage
  }

}
#endif
