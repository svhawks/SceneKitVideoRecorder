//
//  PixelBufferFactory.swift
//  Pods-SCNVideoWriter_Example
//
//  Created by Tomoya Hirano on 2017/08/02.
//

import UIKit

struct PixelBufferFactory {
  static func make(with size: CGSize, from image: UIImage, usingBuffer pool: CVPixelBufferPool) -> CVPixelBuffer? {
    var pixelBufferOut: CVPixelBuffer?
    let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBufferOut)
    guard status == kCVReturnSuccess else { return nil }
    guard let pixelBuffer = pixelBufferOut else { return nil }
    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
    let data = CVPixelBufferGetBaseAddress(pixelBuffer)
    
    guard let context = CGContext(
      data: data,
      width: Int(size.width),
      height: Int(size.height),
      bitsPerComponent: Int(8),
      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
    ) else { return nil }
    guard let cgImage = image.cgImage else { return nil }
    let drawRect = CGRect(origin: .zero, size: size)
    context.clear(drawRect)
    context.draw(cgImage, in: drawRect)
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
    return pixelBuffer
  }
}

