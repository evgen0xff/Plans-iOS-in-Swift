//
//  UIImageView+Addition.swift
//  Plans
//
//  Created by Star on 11/24/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import Foundation
import Accelerate
import UIKit

extension UIImageView {
    func changeColor(_ color: UIColor?) {
        image = image?.imageWithColor(color)
        //            let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
        //            image = templateImage
        //            tintColor = changeColor
    }

    func setImage_Plans(url: URL? = nil,
                        placeholder: String? = nil,
                        defaultImage: String? = nil,
                        complete:((_ image: UIImage?) -> ())? = nil){
        
        let placeholderImage = placeholder != nil ? UIImage(named: placeholder!) : (defaultImage != nil ? UIImage(named: placeholder!) : nil) 
        if let url = url {
            self.sd_setImage(with:url, placeholderImage: placeholderImage){image,_,_,_ in
                complete?(image)
            }
        }else {
            if let defaultImage = defaultImage {
                image = UIImage(named: defaultImage)
            }else {
                image = placeholderImage
            }
        }
    }

    func setImage_Plans(urlStr: String? = nil,
                        placeholder: String? = nil,
                        defaultImage: String? = nil,
                        complete:((_ image: UIImage?) -> ())? = nil){
        setImage_Plans(url: URL(string: urlStr),
                       placeholder: placeholder,
                       defaultImage: defaultImage,
                       complete: complete)
    }

    // User Profile Image
    func setUserImage(_ url: URL? = nil,
                      placeholder: String? = nil,
                      defaultImage: String? = nil,
                      complete:((_ image: UIImage?) -> ())? = nil){
        
        setImage_Plans(url: url,
                       placeholder: placeholder ?? "ic_user_placeholder",
                       defaultImage: defaultImage ?? "ic_user_default",
                       complete: complete)
    }

    func setUserImage(_ urlStr: String? = nil,
                      placeholder: String? = nil,
                      defaultImage: String? = nil,
                      complete:((_ image: UIImage?) -> ())? = nil){
        
        setUserImage(URL(string: urlStr),
                     placeholder: placeholder,
                     defaultImage: defaultImage,
                     complete: complete)
    }
    
    // Event Cover Image
    func setEventImage(_ url: URL? = nil,
                       placeholder: String? = nil,
                       defaultImage: String? = nil,
                       complete:((_ image: UIImage?) -> ())? = nil){
        
        setImage_Plans(url: url,
                       placeholder: placeholder ?? "im_placeholder_event_cover",
                       defaultImage: defaultImage,
                       complete: complete)
    }

    func setEventImage(_ urlStr: String? = nil,
                       placeholder: String? = nil,
                       defaultImage: String? = nil,
                       complete:((_ image: UIImage?) -> ())? = nil){
        
        setEventImage(URL(string: urlStr),
                      placeholder: placeholder,
                      defaultImage: defaultImage,
                      complete: complete)
    }



}


extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 30)) {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        color.set()
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.fill(CGRect(origin: .zero, size: size))
        guard
            let image = UIGraphicsGetImageFromCurrentImageContext(),
            let imagePNGData = image.pngData()
            else { return nil }
        UIGraphicsEndImageContext()

        self.init(data: imagePNGData)
       }
    
    func imageWithColor(_ color: UIColor?) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color?.setFill()

        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    func resizeImageUsingVImage(size:CGSize) -> UIImage? {
        
        let cgImage = self.cgImage!
        var format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: nil, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue), version: 0, decode: nil, renderingIntent: CGColorRenderingIntent.defaultIntent)
        var sourceBuffer = vImage_Buffer()
        defer {
             free(sourceBuffer.data)
        }
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }

        // create a destination buffer
        let destWidth = Int(size.width)
        let destHeight = Int(size.height)
        let bytesPerPixel = self.cgImage!.bitsPerPixel/8
        let destBytesPerRow = destWidth * bytesPerPixel
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
              destData.deallocate()
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)
 
        // scale the image
        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return nil }
       
        // create a CGImage from vImage_Buffer
        var destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
        
        guard error == kvImageNoError else { return nil }
        
        // create a UIImage
        let resizedImage = destCGImage.flatMap { UIImage(cgImage: $0, scale: 0.0, orientation: self.imageOrientation) }
        destCGImage = nil
        return resizedImage
    }
    
    func resizeImage(targetSize: CGSize) -> UIImage? {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

}


