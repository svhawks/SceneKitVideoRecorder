//
//  PixelBufferFactory.swift
//  Pods-SCNVideoWriter_Example
//
//  Created by Tomoya Hirano on 2017/08/02.
//

import UIKit

struct PixelBufferFactory {
  static func make(withSize size: CGSize, fromImage image: UIImage, usingBufferPool pool: CVPixelBufferPool) -> CVPixelBuffer {
    
    var pixelBufferOut: CVPixelBuffer?
    
    let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBufferOut)
    
    if status != kCVReturnSuccess {
      fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
    }
    
    let pixelBuffer = pixelBufferOut!
    
    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
    
    let data = CVPixelBufferGetBaseAddress(pixelBuffer)
    
    let context = CGContext(
      data: data,
      width: Int(size.width),
      height: Int(size.height),
      bitsPerComponent: Int(8),
      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
    )
    
    if context == nil {
      assert(false, "Could not create context from pixel buffer")
    }
    
    context?.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))
    
    context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
    
    return pixelBuffer
  }
}

