//
//  MediaPicker.swift
//  Plans
//
//  Created by Star on 7/8/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import Photos
import MobileCoreServices


let MEDIA_PICKER = MediaPicker.shared

protocol MediaPickerDelegate {
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenImage image: UIImage?)
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenVideo outputFileURL: URL?, previewImage: UIImage?)
}

extension MediaPickerDelegate {
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenImage image: UIImage?) {}
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenVideo outputFileURL: URL?, previewImage: UIImage?){}
}

class MediaPicker: NSObject {

    static let shared = MediaPicker()
    
    enum CameraType {
        case plans
        case system
    }
    
    enum MediaType {
        case imageOnly
        case videoOnly
        case allMedia
    }
    
    enum ActionType {
        case eventCover
        case userProfile
        case postMedia
        case takeScreen
    }

    var delegate : MediaPickerDelegate?
    var parentVC : UIViewController?

    var camerType = CameraType.plans
    var mediaType = MediaType.allMedia
    var isShouldCropImage : Bool = false
    var maxVideoDuration = APP_CONFIG.DURATION_VIDEO_EVENT

    var typeAction = ActionType.postMedia {

        didSet {
            camerType = .plans
            mediaType = .allMedia
            isShouldCropImage = false
            maxVideoDuration = APP_CONFIG.DURATION_VIDEO_EVENT

            switch typeAction {
            case .eventCover:
                isShouldCropImage = true
                break
            case .userProfile:
                mediaType = .imageOnly
                isShouldCropImage = true
                break
            case .postMedia:
                break
            case .takeScreen:
                mediaType = .imageOnly
                break
            }
        }
    }

    var rectCropedImage : CGRect {
        var size = CGSize(width: MAIN_SCREEN_WIDTH, height: MAIN_SCREEN_WIDTH)
        switch typeAction {
        case .eventCover:
            size = CGSize(width: MAIN_SCREEN_WIDTH, height: (180 * MAIN_SCREEN_HEIGHT)/568.0)
            break
        default:
            break
        }
        
        let origin = CGPoint(x: 0, y: (MAIN_SCREEN_HEIGHT - size.height) / 2.0)
        return CGRect(origin: origin, size: size)
    }
    
    // MARK: - Private Method
    private func convertWithKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
    
    private func convertToDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }

    private func alertPromptToAllowCameraAccessViaSettings() {
        POPUP_MANAGER.showAlertWithAction(title: APP_CONFIG.APP_NAME, message: "Please grant permission to use the Camera/Gallery", style: .alert, actionTitles: ["Open Settings", "Cancel"], action: { (alert) in
            if let title = alert.title {
                switch title {
                case "Open Settings":
                    if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
                        if #available(iOS 10.0, *) {
                            APPLICATION.open(appSettingsURL, options: APP_DELEGATE.convertToDictionary([:]), completionHandler: { (isOpen) in
                            })
                        }
                    }
                default:
                    break
                }
            }
        })
    }
    
    private func openSystemCamera(picker: UIImagePickerController) {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            picker.sourceType = UIImagePickerController.SourceType.camera
            picker.videoQuality = .typeHigh
            picker.modalPresentationStyle = .fullScreen
            parentVC?.present(picker, animated: true)
        } else {
            finishPickingMedia(false)
            POPUP_MANAGER.makeToast("Camera Not Available!")
        }
    }
    
    private func openSystemGallery(picker: UIImagePickerController){
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary)) {
            picker.sourceType = UIImagePickerController.SourceType.photoLibrary
            picker.modalPresentationStyle = .fullScreen
            parentVC?.present(picker, animated: true)
        } else {
            finishPickingMedia(false)
            POPUP_MANAGER.makeToast("Photo Library Not Available!")
        }
    }

    private func finishPickingMedia(image: UIImage? = nil, videoUrl: URL? = nil, _ success: Bool) {
        guard success == true else { return }
        
        if let videoUrl = videoUrl {
            if FILE_MANAGER.fileExists(atPath: videoUrl.path){
                let durationTime = CMTimeGetSeconds(AVAsset(url: videoUrl).duration)
                if durationTime > maxVideoDuration {
                    if UIVideoEditorController.canEditVideo(atPath: videoUrl.path) {
                        let videoEditing = UIVideoEditorController()
                        videoEditing.videoPath = videoUrl.path
                        videoEditing.videoMaximumDuration = maxVideoDuration
                        videoEditing.delegate = self
                        videoEditing.modalPresentationStyle = .fullScreen
                        parentVC?.present(videoEditing, animated: true, completion: nil)
                    }else {
                        POPUP_MANAGER.makeToast("The file size is too large")
                    }
                }else {
                    delegate?.mediaPicker(self, didTakenVideo: videoUrl, previewImage: FILE_CENTER.getThumbnailFrom(path: videoUrl))
                }
            }else {
                POPUP_MANAGER.makeToast("The file doesn't exist")
            }
        }else if let image = image {
            if isShouldCropImage == true {
                let cropVC = RSKImageCropViewController(image: image, cropMode: .custom)
                cropVC.delegate = self
                cropVC.dataSource = self
                cropVC.modalPresentationStyle = .fullScreen
                parentVC?.present(cropVC, animated: true, completion: nil)
            }else {
                delegate?.mediaPicker(self, didTakenImage: image)
            }
        }
    }

    // MARK: - Public Methods
    func showCameraGalleryActionSheet(sender: UIViewController? = nil,
                                      delegate: MediaPickerDelegate? = nil,
                                      action: ActionType = .postMedia) {
        self.typeAction = action
        showCameraGalleryActionSheet(sender: sender,
                                     delegate: delegate,
                                     camerType: self.camerType,
                                     mediaType: self.mediaType,
                                     isShouldCropImage: self.isShouldCropImage,
                                     maxVideoDuration: self.maxVideoDuration)
    }
    
    func openCamera(sender: UIViewController? = nil,
                    delegate: MediaPickerDelegate? = nil,
                    action: ActionType = .postMedia ) {
        
        self.typeAction = action
        openCamera(sender: sender,
                   delegate: delegate,
                   camerType: self.camerType,
                   mediaType: self.mediaType,
                   isShouldCropImage: self.isShouldCropImage,
                   maxVideoDuration: self.maxVideoDuration )
    }

    func openGallery(sender: UIViewController? = nil,
                    delegate: MediaPickerDelegate? = nil,
                    action: ActionType = .postMedia ) {
        
        self.typeAction = action
        openGallery(sender: sender,
                    delegate: delegate,
                    mediaType: self.mediaType,
                    isShouldCropImage: self.isShouldCropImage,
                    maxVideoDuration: self.maxVideoDuration )
    }



    // Camera/Gallery Methods
    func showCameraGalleryActionSheet(sender: UIViewController? = nil,
                                      delegate: MediaPickerDelegate? = nil,
                                      titleCameraBtn: String? = nil,
                                      titleGalleryBtn: String? = nil,
                                      titleCancelBtn: String? = nil,
                                      camerType: CameraType = .plans,
                                      mediaType: MediaType = .allMedia,
                                      isShouldCropImage: Bool = false,
                                      maxVideoDuration: TimeInterval = APP_CONFIG.DURATION_VIDEO_EVENT) {
        
        self.parentVC = sender ?? APP_MANAGER.topVC
        self.delegate = delegate
        self.camerType = camerType
        self.mediaType = mediaType
        self.isShouldCropImage = isShouldCropImage
        self.maxVideoDuration = maxVideoDuration

        //Create the AlertController and add Its action like button in Actionsheet
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Cancel Button
        let cancelActionButton: UIAlertAction = UIAlertAction(title: titleCancelBtn ?? "Cancel", style: .cancel) { action -> Void in
        }
        cancelActionButton.setValue(AppColor.teal_main, forKey: "titleTextColor")

        actionSheetController.addAction(cancelActionButton)
        
        // Camera Button
        let cameraActionButton: UIAlertAction = UIAlertAction(title: titleCameraBtn ?? "Camera" , style: .default) { action -> Void in
            self.openCamera(sender: self.parentVC,
                            delegate: self.delegate,
                            camerType: self.camerType,
                            mediaType: self.mediaType,
                            isShouldCropImage: self.isShouldCropImage,
                            maxVideoDuration: self.maxVideoDuration)
        }
        cameraActionButton.setValue(AppColor.teal_main, forKey: "titleTextColor")
        actionSheetController.addAction(cameraActionButton)
        
        // Gallery Button
        let galleryActionButton: UIAlertAction = UIAlertAction(title: titleGalleryBtn ?? "Gallery", style: .default) { action -> Void in
            self.openGallery(sender: self.parentVC,
                             delegate: self.delegate,
                             mediaType: self.mediaType,
                             isShouldCropImage: self.isShouldCropImage,
                             maxVideoDuration: self.maxVideoDuration )
        }
        galleryActionButton.setValue(AppColor.teal_main, forKey: "titleTextColor")
        actionSheetController.addAction(galleryActionButton)

        parentVC?.present(actionSheetController , animated: true, completion: nil)
    }
    
    func openCamera(sender: UIViewController? = nil,
                    delegate: MediaPickerDelegate? = nil,
                    camerType: CameraType = .plans,
                    mediaType: MediaType = .allMedia,
                    isShouldCropImage: Bool = false,
                    maxVideoDuration: TimeInterval = APP_CONFIG.DURATION_VIDEO_EVENT ) {

        self.parentVC = sender ?? APP_MANAGER.topVC
        self.delegate = delegate
        self.camerType = camerType
        self.mediaType = mediaType
        self.isShouldCropImage = isShouldCropImage
        self.maxVideoDuration = maxVideoDuration
        
        if camerType == .plans {
            APP_MANAGER.presentPlansCamera(delegate: self, maxVideoDuration: maxVideoDuration, sender: parentVC, mediaType: mediaType)
        }else {
            openSystemMeidaPicker(sender: self.parentVC,
                                  delegate: self.delegate,
                                  isSourceCamera: true,
                                  mediaType: self.mediaType,
                                  isShouldCropImage: self.isShouldCropImage,
                                  maxVideoDuration: self.maxVideoDuration )
        }
    }
    
    func openGallery(sender: UIViewController? = nil,
                     delegate: MediaPickerDelegate? = nil,
                     mediaType: MediaType = .allMedia,
                     isShouldCropImage: Bool = false,
                     maxVideoDuration: TimeInterval = APP_CONFIG.DURATION_VIDEO_EVENT ) {
        
        self.parentVC = sender ?? APP_MANAGER.topVC
        self.delegate = delegate
        self.mediaType = mediaType
        self.isShouldCropImage = isShouldCropImage
        self.maxVideoDuration = maxVideoDuration

        PHPhotoLibrary.requestAuthorization { (status) in
            APP_CONFIG.defautMainQ.async {
                switch status {
                case .authorized, .notDetermined:
                    self.openSystemMeidaPicker(sender: self.parentVC,
                                               delegate: self.delegate,
                                               isSourceCamera: false,
                                               mediaType: mediaType,
                                               isShouldCropImage: self.isShouldCropImage,
                                               maxVideoDuration: self.maxVideoDuration )
                default:
                    self.alertPromptToAllowCameraAccessViaSettings()
                }
            }
        }
    }
    
    func openSystemMeidaPicker(sender: UIViewController? = nil,
                               delegate: MediaPickerDelegate? = nil,
                               isSourceCamera: Bool = false,
                               mediaType: MediaType = .allMedia,
                               isShouldCropImage: Bool = false,
                               maxVideoDuration: TimeInterval = APP_CONFIG.DURATION_VIDEO_EVENT) {
        
        self.parentVC = sender ?? APP_MANAGER.topVC
        self.delegate = delegate
        self.mediaType = mediaType
        self.isShouldCropImage = isShouldCropImage
        self.maxVideoDuration = maxVideoDuration

        let imgPicker = UIImagePickerController()
        imgPicker.delegate = self
        imgPicker.allowsEditing = false

        switch mediaType  {
        case .imageOnly:
            imgPicker.mediaTypes = [(kUTTypeImage) as String]
        case .videoOnly:
            imgPicker.mediaTypes = [(kUTTypeMovie) as String, (kUTTypeVideo) as String]
        case .allMedia:
            imgPicker.mediaTypes = [(kUTTypeMovie) as String, (kUTTypeVideo) as String, (kUTTypeImage) as String]
        }
        
        if isSourceCamera {
            openSystemCamera(picker: imgPicker)
        } else {
            openSystemGallery(picker: imgPicker)
        }
    }
    
}

// MARK: PlansCameraVCDelegate
extension MediaPicker : PlansCameraVCDelegate {
    func didFinishProcessingPhoto(photo: UIImage?) {
        guard let image = photo else { return }
        if isShouldCropImage == true {
            let imageCropViewController = RSKImageCropViewController(image: image, cropMode: .custom)
            imageCropViewController.delegate = self
            imageCropViewController.dataSource = self
            imageCropViewController.modalPresentationStyle = .fullScreen
            parentVC?.present(imageCropViewController, animated: true, completion: nil)
        }else {
            delegate?.mediaPicker(self, didTakenImage: image)
        }
    }
    
    func didFinishRecording(outputFileURL: URL?, previewImage: UIImage?) {
        delegate?.mediaPicker(self, didTakenVideo: outputFileURL, previewImage: previewImage)
    }
}

// MARK: - UIVideoEditorControllerDelegate, UINavigationControllerDelegate

extension MediaPicker : UIVideoEditorControllerDelegate, UINavigationControllerDelegate {
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        editor.dismiss(animated: true, completion: nil)

        if FILE_MANAGER.fileExists(atPath: editedVideoPath){
            let videoURl = URL(fileURLWithPath: editedVideoPath)
            delegate?.mediaPicker(self, didTakenVideo: videoURl, previewImage: FILE_CENTER.getThumbnailFrom(path: videoURl))
        }
    }
}


// MARK: - UIImagePickerControllerDelegate

extension MediaPicker: UIImagePickerControllerDelegate {
 
    //Cancel button  of imagePicker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        finishPickingMedia(false)
    }
    
    //Picking Action of ImagePicker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)

        let info = convertToDictionary(info)
        var image: UIImage?
        var urlVideo: URL?

        if let videoUrl = info[convertWithKey(UIImagePickerController.InfoKey.mediaURL)] as? URL {
            urlVideo = videoUrl
        }else if let editedImage = info[convertWithKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage {
            image = editedImage
        }else if let originalImage = info[convertWithKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            image = originalImage
        }
        
        finishPickingMedia(image: image, videoUrl: urlVideo,  true)
    }

}


// MARK: - RSKImageCropViewControllerDataSource, RSKImageCropViewControllerDelegate
extension MediaPicker: RSKImageCropViewControllerDataSource, RSKImageCropViewControllerDelegate
{
    func imageCropViewControllerCustomMaskRect(_ controller: RSKImageCropViewController) -> CGRect {
        return rectCropedImage
    }
    
    func imageCropViewControllerCustomMaskPath(_ controller: RSKImageCropViewController) -> UIBezierPath {
        return UIBezierPath(rect: controller.maskRect)
    }
    
    func imageCropViewControllerCustomMovementRect(_ controller: RSKImageCropViewController) -> CGRect {
        return rectCropedImage
    }
    
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        parentVC?.dismiss(animated: true, completion: nil)
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        parentVC?.dismiss(animated: true, completion: nil)
        delegate?.mediaPicker(self, didTakenImage: croppedImage)
    }
}
