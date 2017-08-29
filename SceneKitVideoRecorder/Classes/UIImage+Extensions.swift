//
//  UIImage+Extensions.swift
//
//  Created by Omer Karisman on 2017/08/29.
//

import UIKit

extension UIImage {
  func fill(at targetSize: CGSize) -> UIImage? {
    let imageSize = self.size
    let width = imageSize.width
    let height = imageSize.height
    let targetWidth = targetSize.width
    let targetHeight = targetSize.height
    var scaleFactor: CGFloat = 0.0
    var scaledWidth = targetWidth
    var scaledHeight = targetHeight
    var thumbnailPoint = CGPoint(x: 0, y: 0)
    
    if imageSize != targetSize {
      let widthFactor = targetWidth / width
      let heightFactor = targetHeight / height
      
      if widthFactor > heightFactor {
        scaleFactor = widthFactor
      } else {
        scaleFactor = heightFactor
      }
      
      scaledWidth  = width * scaleFactor
      scaledHeight = height * scaleFactor
      
      if widthFactor > heightFactor {
        thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
      } else {
        if widthFactor < heightFactor {
          thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
        }
      }
    }
    
    UIGraphicsBeginImageContext(targetSize)
    
    var thumbnailRect = CGRect.zero
    thumbnailRect.origin = thumbnailPoint
    thumbnailRect.size.width  = scaledWidth
    thumbnailRect.size.height = scaledHeight
    
    draw(in: thumbnailRect)
    
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
    
    return newImage
  }
}
