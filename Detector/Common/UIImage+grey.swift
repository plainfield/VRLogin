//
//  UIImage+grey.swift
//  Detector
//
//  Created by EkinYang on 2017/8/2.
//  Copyright © 2017年 Gregg Mojica. All rights reserved.
//
import Foundation
import UIKit

extension UIImage {
    
    func grayImage() -> UIImage {
        
        let imageRef:CGImage = self.cgImage!
        
        let width:Int = imageRef.width
        let height:Int = imageRef.height
        
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let context:CGContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        let rect:CGRect = CGRect.init(x: 0, y: 0, width: width, height: height)
        context.draw(imageRef, in: rect)
        let outPutImage:CGImage = context.makeImage()!
        
        let newImage:UIImage = UIImage.init(cgImage: outPutImage, scale: self.scale, orientation: self.imageOrientation)
        return newImage
    }
    
    func clipImage(rect: CGRect?) -> UIImage? {
        guard rect != nil else{
            return nil
        }
//        let _: CGImage = self.cgImage!
//        let newCGImage = CGImageCreateWithImageInRect(sourceImageRef, CGRect(x: 0, y: 0, width: size.width, height: size.height))!
        let imageRef = self.cgImage!.cropping(to: rect!)
        let newImage = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
//        let newImage = UIImage(cgImage: newCGImage)
        return newImage
    }
    
    func faceBounds() -> [CGRect]? {
        guard let personciImage = CIImage(image: self) else {
            return nil
        }
        
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: personciImage)
        
        // Convert Core Image Coordinate to UIView Coordinate
        let ciImageSize = personciImage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        
        var faceRects = [CGRect]()
        for face in faces as! [CIFaceFeature] {
            
            print("Found bounds are \(face.bounds)")
            
            // Apply the transform to convert the coordinates
            var faceViewBounds = face.bounds.applying(transform)
            
            // Calculate the actual position and size of the rectangle in the image view
            let viewSize = self.size
            let scale = min(viewSize.width / ciImageSize.width,
                            viewSize.height / ciImageSize.height)
            let offsetX = (viewSize.width - ciImageSize.width * scale) / 2
            let offsetY = (viewSize.height - ciImageSize.height * scale) / 2
            
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            faceRects.append(faceViewBounds)
            
//            let faceBox = UIView(frame: faceViewBounds)
//
//            faceBox.layer.borderWidth = 3
//            faceBox.layer.borderColor = UIColor.red.cgColor
//            faceBox.backgroundColor = UIColor.clear
//            personPic.addSubview(faceBox)
            
            if face.hasLeftEyePosition {
                print("Left eye bounds are \(face.leftEyePosition)")
            }
            
            if face.hasRightEyePosition {
                print("Right eye bounds are \(face.rightEyePosition)")
            }
        }
        if faceRects.count == 0 {
        print("face detecting failed!")
        }
        return faceRects
    }
    
    func saveToFiles(name: String) {
        if let data = UIImagePNGRepresentation(self) {
            let ducumentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
            let filename = ducumentPath.appendingPathComponent(name).path
            do {
                try data.write(to: URL(fileURLWithPath: filename), options: [])
            }
            catch let error as NSError {
                print("get file path error: \(error)")
            }
        }
    }
}
