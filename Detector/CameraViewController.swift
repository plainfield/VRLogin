

//
//  CameraViewController.swift
//  Detector
//
//  Created by Gregg Mojica on 8/22/16.
//  Copyright © 2016 Gregg Mojica. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController, FrameExtractorDelegate {

    @IBOutlet var previewImageView: UIImageView?
    @IBOutlet var snapshotImageView: UIImageView?
    private let position = AVCaptureDevicePosition.front
    private let quality = AVCaptureSessionPresetMedium
    
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let captureSession = AVCaptureSession()
    private let context = CIContext()
    private var frameExtractor: FrameExtractor!
    
    var capturePhotoTimer: Timer?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        capturePhotoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: {
            timer in
                let captureImage = self.previewImageView?.image
                if let faceRects = captureImage?.faceBounds() {
                    let faceImages = faceRects.map {
                        return captureImage?.clipImage(rect: $0)
                    }
                    if faceImages.count > 0 {
                        print("detect the face!!! face count = \(faceImages.count)")
                        
                        self.snapshotImageView?.image = faceImages.first!
//                        self.capturePhotoTimer?.invalidate()
                    }
                }
            })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        capturePhotoTimer?.invalidate()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
    }
    
    // MARK: FrameExtractorDelegate
    func captured(image: UIImage) {
        self.previewImageView?.image = image
    }
}
