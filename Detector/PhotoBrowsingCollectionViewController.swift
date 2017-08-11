//
//  PhotoBrowsingCollectionViewController.swift
//  Detector
//
//  Created by EkinYang on 2017/8/2.
//  Copyright © 2017年 Gregg Mojica. All rights reserved.
//

import UIKit
import Photos

//https://stackoverflow.com/questions/39970273/no-such-module-in-xcode
import Zip

private let reuseIdentifier = "PhotoBrowsingCell"

class PhotoBrowsingCollectionViewController: UICollectionViewController {
    
    ///取得的资源结果，用了存放的PHAsset
    var assetsFetchResults:PHFetchResult<PHAsset>!
    
    ///缩略图大小
    var thumbnailSize:CGSize!
    
    var assetArray = [PHAsset]()
    var imageArray = [(UIImage, String)]()
    
    let photosCount = 0
    
    /// 带缓存的图片管理对象
    var imageManager:PHCachingImageManager!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //根据单元格的尺寸计算我们需要的缩略图大小
        let scale = UIScreen.main.scale
        let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        thumbnailSize = CGSize(width:cellSize.width*scale ,
                                        height:cellSize.height*scale)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //则获取所有资源
        let allPhotosOptions = PHFetchOptions()
        //按照创建时间倒序排列
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",
                                                             ascending: false)]
        //只获取图片
        allPhotosOptions.predicate = NSPredicate(format: "mediaType = %d",
                                                 PHAssetMediaType.image.rawValue)
        assetsFetchResults = PHAsset.fetchAssets(with: PHAssetMediaType.image,
                                                 options: allPhotosOptions)
        
        self.imageManager = PHCachingImageManager()
        self.resetCachedAssets()
    }
    
    //reset Cache
    func resetCachedAssets(){
        self.imageManager.stopCachingImagesForAllAssets()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if imageArray.count > 0 {
            return self.imageArray.count
        }
        return self.assetsFetchResults.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PhotoBrowsingCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoBrowsingCell
        
        if imageArray.count > 0 {
            cell.imageView?.image = imageArray[indexPath.row].0
        }
        else {
            // Configure the cell
            let asset = self.assetsFetchResults[indexPath.row]
            //获取缩略图
            self.imageManager.requestImage(for: asset, targetSize: thumbnailSize,
                                           contentMode: PHImageContentMode.aspectFill,
                                           options: nil) { (image, nfo) in
                                            cell.imageView?.image = image
                                            
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        let asset = self.assetsFetchResults[indexPath.row]
        let selectedCell: PhotoBrowsingCell = collectionView.cellForItem(at: indexPath) as! PhotoBrowsingCell
        
        selectedCell.selectButton?.isSelected = !(selectedCell.selectButton?.isSelected)!
        if (selectedCell.selectButton?.isSelected)! {
            assetArray.append(asset)
        }
        else {
            if assetArray.contains(asset) {
             assetArray.remove(at: assetArray.index(of: asset)!)
            }
        }
    }
    
    @IBAction func back() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func finish() {
        if assetArray.count >= photosCount {
            requestImages(by: assetArray, completion: {
                
                photos in
                self.imageArray = photos
                self.collectionView?.reloadData()
//                self.navigationController?.dismiss(animated: true, completion: nil)
                // save images to DocumentsDirectory
                self.imageArray.forEach {
                    $0.0.saveToFiles(name: $0.1)
                }
                self.zipImages()
            })
        }
    }
    
    @IBAction func selectButtonAction(sender: UIButton) {
        sender.isSelected = !(sender.isSelected)
        
        let selectedCell: UICollectionViewCell = sender.superview?.superview as! UICollectionViewCell
        let indexPath = self.collectionView?.indexPath(for: selectedCell)
        let asset = self.assetsFetchResults[(indexPath?.row)!]
        
        if sender.isSelected {
            assetArray.append(asset)
        }
        else {
            if assetArray.contains(asset) {
                assetArray.remove(at: assetArray.index(of: asset)!)
            }
        }
    }
    
    func requestImages(by assets:[PHAsset], completion:@escaping ([(UIImage, String)]) -> Void) {
        
        var photos = [(UIImage, String)]()
        
        let dispatchGroup = DispatchGroup()
        assetArray.forEach {
            
            let asset = $0
            dispatchGroup.enter()
            
            let options = PHImageRequestOptions()
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            options.isSynchronous = true
            options.isNetworkAccessAllowed = true
            
//            options.progressHandler = {  (progress, error, stop, info) in
//                print("progress: \(progress)")
//            }
            PHImageManager.default().requestImage(for: $0, targetSize:thumbnailSize, contentMode: PHImageContentMode.aspectFill, options: options, resultHandler: {
                (image, info) in

                let faceRect = image?.faceBounds()
                let faceImage = image?.clipImage(rect: faceRect?.first)
                let greyImage = faceImage?.grayImage()
                if let image = greyImage {
                    let dateString = asset.creationDate?.description
                    let dateStringNoSpace = dateString?.replacingOccurrences(of: " ", with: "")
                    photos.append((image, dateStringNoSpace!))
                }
                dispatchGroup.leave()
            })
        }
        dispatchGroup.notify(queue: DispatchQueue.main) {
            completion(photos)
        }
    }
    
    func getAllImagePaths(_ dirPath: String) -> [URL]? {
        var filePaths = [URL]()
        do {
            let array = try FileManager.default.contentsOfDirectory(atPath: dirPath)
            for fileName in array { var isDir: ObjCBool = true
                let fullPath = "\(dirPath)/\(fileName)"
                if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir) {
                    if !isDir.boolValue {
                        filePaths.append(URL(fileURLWithPath: fullPath))
                    }
                }
            }
        }
        catch let error as NSError {
            print("get file path error: \(error)")
        }
        return filePaths;
    }

    func zipImages() {
        
        let ducumentPath = NSHomeDirectory() + "/Documents"
        let urlPaths = getAllImagePaths(ducumentPath)
        
        do {
            let _ = try Zip.quickZipFiles(urlPaths!, fileName: "Images")
            let zipFilePath = ducumentPath + "/Images.zip"
            let data = NSData(contentsOfFile: zipFilePath)
            print("zip data is \(String(describing: data))")
            
        } catch {
            print("ERROR")
        }
        deleteFiles()
    }

    func deleteFiles() {
        let ducumentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        //        let filename = documentsDirectory.appendingPathComponent("tempImages")
        try? FileManager.default.removeItem(at: ducumentUrl)
    }
}
