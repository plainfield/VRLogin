//
//  ViewController.swift
//  Detector
//
//  Created by Gregg Mojica on 8/21/16.
//  Copyright © 2016 Gregg Mojica. All rights reserved.
//

import UIKit
import CoreImage
import MobileCoreServices

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    @IBOutlet weak var personPic: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        personPic.image = UIImage(named: "face-1")

        detect()
    }
    
    @IBAction func btnAlbum(sender: AnyObject) {
        //判断是否支持要使用的图片库
//        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
//
//            //初始化图片控制器
//            let picker = UIImagePickerController()
//
//            //设置代理
//            picker.delegate = self
//
//            //设置媒体类型
//            picker.mediaTypes = [kUTTypeImage as String,kUTTypeVideo as String]
//
//            //设置允许编辑
//            picker.allowsEditing = true
//
//            //指定图片控制器类型
//            picker.sourceType = .photoLibrary
//
//            //弹出控制器,显示界面
//            self.present(picker, animated: true, completion: nil)
//        }else{
//            print("读取相册错误!")
//            //let alert = UIAlertView.init(title: "读取相册错误!", message: nil, delegate: nil, cancelButtonTitle: "确定")
//            //alert.show()
//        }
    }
    
    //实现图片控制器代理方法
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        //查看info对象
        print(info)
        
        //获取选择的原图
        let originImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        //赋值，图片视图显示图片
        personPic.image = originImage
        
        detect();
        
        //图片控制器退出
        picker.dismiss(animated: true, completion: nil)
    }
    
    //取消图片控制器代理
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        //图片控制器退出
        picker.dismiss(animated: true, completion: nil)
    }
    
    func detect() {
        
        guard let personciImage = CIImage(image: personPic.image!) else {
            return
        }
        
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: personciImage)
        
        // Convert Core Image Coordinate to UIView Coordinate
        let ciImageSize = personciImage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        
        for face in faces as! [CIFaceFeature] {
            
            print("Found bounds are \(face.bounds)")
            
            // Apply the transform to convert the coordinates
            var faceViewBounds = face.bounds.applying(transform)
            
            // Calculate the actual position and size of the rectangle in the image view
            let viewSize = personPic.bounds.size
            let scale = min(viewSize.width / ciImageSize.width,
                            viewSize.height / ciImageSize.height)
            let offsetX = (viewSize.width - ciImageSize.width * scale) / 2
            let offsetY = (viewSize.height - ciImageSize.height * scale) / 2
            
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            
            let faceBox = UIView(frame: faceViewBounds)
            
            faceBox.layer.borderWidth = 3
            faceBox.layer.borderColor = UIColor.red.cgColor
            faceBox.backgroundColor = UIColor.clear
            personPic.addSubview(faceBox)
            
            if face.hasLeftEyePosition {
                print("Left eye bounds are \(face.leftEyePosition)")
            }
            
            if face.hasRightEyePosition {
                print("Right eye bounds are \(face.rightEyePosition)")
            }
        }
    }
    
}
