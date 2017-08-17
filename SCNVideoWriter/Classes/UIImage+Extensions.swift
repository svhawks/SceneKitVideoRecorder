//
//  UIImage+Extensions.swift
//  Pods-SCNVideoWriter_Example
//
//  Created by Tomoya Hirano on 2017/08/10.
//

import UIKit

extension UIImage {
  func crop(at size: CGSize) -> UIImage {
    let imageSize = self.size
    let cropSize = size
    let x = (imageSize.width - cropSize.width) / 2.0
    let y = (imageSize.height - cropSize.height) / 2.0
    let cropRect = CGRect(x: x, y: y, width: size.width, height: size.height)
    return crop(to: cropRect)
  }
  
  func crop(to rect: CGRect) -> UIImage {
    guard let croppedImageRef = cgImage?.cropping(to: rect) else { return UIImage() }
    return UIImage(cgImage: croppedImageRef, scale: scale, orientation: .up)
  }
}
