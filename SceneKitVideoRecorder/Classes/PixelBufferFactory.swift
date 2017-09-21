//
//  PixelBufferFactory.swift
//
//  Created by Omer Karisman on 2017/08/29.
//

import UIKit

struct PixelBufferFactory {
  
  static let context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
  
  static func make(with image: UIImage, usingBuffer pool: CVPixelBufferPool) -> CVPixelBuffer? {
    
    var pixelBuffer: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
    
    if let pixelBuffer = pixelBuffer {
      CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.init(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
      
      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
      
      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)
      
      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      
      CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.init(rawValue: 0))
      return pixelBuffer
    }
    return nil
  }
  
  static func imageFromCVPixelBuffer(buffer: CVPixelBuffer) -> UIImage {
    
    let ciimage = CIImage(cvPixelBuffer: buffer)
    let cgimgage = context.createCGImage(ciimage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer)))
    
    let uiimage = UIImage(cgImage: cgimgage!)
    
    return uiimage
  }
  
}

