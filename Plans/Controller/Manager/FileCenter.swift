//
//  FileCenter.swift
//  Plans
//
//  Created by Star on 7/24/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit
import Alamofire
import Photos

// File Manager
let FILE_CENTER = FileCenter.shared
let FILE_MANAGER = FileManager.default

class FileCenter: NSObject {
    
    static let shared = FileCenter()
    let byte1024 = Double(1024.0)
    let videoUrlCompressed = NSURL.fileURL(withPath: NSTemporaryDirectory() + "videoCompressedd.mp4")
}

// MARK: - Process Media File
extension FileCenter {
    
    func getThumbnailFrom(path: URL) -> UIImage? {
        do {
            let asset = AVAsset(url: path)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 10), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch {
          print("Unexpected error: \(error).")
          return nil
        }
    }
    
    func getFileSize(url: URL) -> Double {
        do {
            let attribute = try FILE_MANAGER.attributesOfItem(atPath: url.path)
            if let size = attribute[FileAttributeKey.size] as? NSNumber {
                return size.doubleValue / (byte1024 * byte1024)
            }
        } catch {}
        return 0.0
    }
    
    func compressVideo(inputURL: URL?,
                       outputURL: URL? = nil,
                       quality: String = AVAssetExportPresetMediumQuality,
                       outputFileType: AVFileType = .mp4,
                       handler:@escaping (_ exportSession: AVAssetExportSession?) -> Void) {

        guard let inputURL = inputURL else {
            handler(nil)
            return
        }
        
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset,
                                                       presetName: quality) else {
            handler(nil)
            return
        }
        
        let url = outputURL ?? videoUrlCompressed
        do {
            if FILE_MANAGER.fileExists(atPath: url.path) {
                try FILE_MANAGER.removeItem(atPath: url.path)
            }
            exportSession.outputURL = url
        }catch {
            print("Unexpected error: \(error).")
            handler(nil)
            return
        }
        
        exportSession.outputFileType = outputFileType
        exportSession.exportAsynchronously {
            APP_CONFIG.defautMainQ.async {
                handler(exportSession)
            }
        }
    }
    
    
    
    


}

// MARK: - Save Media File
extension FileCenter {
    func saveImageToPhotosAlbum(image: UIImage?){
        guard let selectedImage = image else { return }
        UIImageWriteToSavedPhotosAlbum(selectedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func saveVideoToPhotosAlbum(localFile: URL?) {
        guard let url = localFile else { return }
        UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            POPUP_MANAGER.makeToast("Save error\n\(error.localizedDescription)")
        } else {
            POPUP_MANAGER.makeToast("Saved successfully")
        }
    }
    
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        if let error = error {
            // we got back an error!
            POPUP_MANAGER.makeToast("Save error\n\(error.localizedDescription)")
        } else {
            POPUP_MANAGER.makeToast("Saved successfully")
        }
    }
}

// MARK: - Download Media File
extension FileCenter {

    func destionationForDownloadMedia (_ type: String? = nil) -> DownloadRequest.Destination {
        let type = type ?? "image"
        return { _, _ in
            let documentsURL = FILE_MANAGER.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(type).\(type == "image" ? "png" : "mp4")")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
    }

    func downloadMediaToLocal(url: String?, type: String?, complete: ((_ localFile: URL?, _ error: Error?) -> Void)? = nil) {
        guard let url = url, let type = type else {
            complete?(nil, NSError(domain: "HUserService",code:1000,userInfo: ["errorMessage":ConstantTexts.invalidParams.localizedString]))
            return
        }
        APP_DELEGATE.registerBackgroundTask()
        AF.download(url, to: destionationForDownloadMedia(type)).response { response in
            complete?(response.fileURL, response.error)
            APP_DELEGATE.endBackgroundTask()
        }
    }

    func downloadMediaToPhotosAlbum(url: String?, type: String?, complete: ((_ localFile: URL?, _ error: Error?) -> Void)? = nil) {
        guard let url = url, let type = type else {
            complete?(nil, NSError(domain: "HUserService",code:1000,userInfo: ["errorMessage":ConstantTexts.invalidParams.localizedString]))
            return
        }

        // Download the media file from the server.
        POPUP_MANAGER.showLoadingToast(.downloading)
        APP_DELEGATE.registerBackgroundTask()
        AF.download(url, to: destionationForDownloadMedia(type)).response { response in
            POPUP_MANAGER.hideLoadingToast(.downloading)
            if response.error == nil, let fileUrl = response.fileURL {
                if type == "image" {
                    self.saveImageToPhotosAlbum(image: UIImage(contentsOfFile: fileUrl.path))
                }else if type == "video"{
                    self.saveVideoToPhotosAlbum(localFile: fileUrl)
                }
            }
            complete?(response.fileURL, response.error)
            APP_DELEGATE.endBackgroundTask()
        }
    }

}
