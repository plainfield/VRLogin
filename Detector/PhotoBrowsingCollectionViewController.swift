//
//  PhotoBrowsingCollectionViewController.swift
//  Detector
//
//  Created by EkinYang on 2017/8/2.
//  Copyright © 2017年 Gregg Mojica. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "PhotoBrowsingCell"

class PhotoBrowsingCollectionViewController: UICollectionViewController {
    
    ///取得的资源结果，用了存放的PHAsset
    var assetsFetchResults:PHFetchResult<PHAsset>!
    
    ///缩略图大小
    var thumbnailSize:CGSize!
    
    var assetArray = [PHAsset]()
    var imageArray = [UIImage]()
    
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
            cell.imageView?.image = imageArray[indexPath.row]
        }
        else {
            // Configure the cell
            let asset = self.assetsFetchResults[indexPath.row]
            //获取缩略图
            self.imageManager.requestImage(for: asset, targetSize: thumbnailSize,
                                           contentMode: PHImageContentMode.aspectFill,
                                           options: nil) { (image, nfo) in
                                            //                                        (cell.contentView.viewWithTag(1) as! UIImageView).image = image
                                            //                                        print(image)
                                            cell.imageView?.image = image
                                            
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        let asset = self.assetsFetchResults[indexPath.row]
        let selectedCell: PhotoBrowsingCell = collectionView.cellForItem(at: indexPath) as! PhotoBrowsingCell
        
        selectedCell.isAdded = !selectedCell.isAdded
        if (selectedCell.isAdded) {
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
            })
        }
    }
    
    func requestImages(by assets:[PHAsset], completion:@escaping ([UIImage]) -> Void) {
        
        var photos = [UIImage]()
        
        let dispatchGroup = DispatchGroup()
        assetArray.forEach {
            
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
                    photos.append(image)
                    dispatchGroup.leave()
                }
            })
        }
        dispatchGroup.notify(queue: DispatchQueue.main) {
            completion(photos)
        }
    }
}
