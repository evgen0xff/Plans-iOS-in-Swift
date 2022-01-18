//
//  PlansCameraVC.swift
//  Plans
//
//  Created by Plans Collective LLC on 12/02/19.
//  Copyright © 2019 PlansCollective. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

/// Enumeration for Camera Selection

public enum CameraSelection {

    /// Camera on the back of the device
    case rear

    /// Camera on the front of the device
    case front
}


@objc protocol PlansCameraVCDelegate {
    @objc optional func didFinishProcessingPhoto (photo : UIImage?)
    @objc optional func didFinishRecording (outputFileURL: URL?, previewImage: UIImage?)
}

class PlansCameraVC: BaseViewController {
    
    enum Mode {
        case none
        case takePhoto
        case recordVideo
        case playVideo
        case comment
    }
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var previewImgView: UIImageView!
    @IBOutlet weak var flipView: UIView!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var cameraSwitchBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var backBtnContainerView: UIView!
    @IBOutlet weak var btnRecord: TimerRingButton!
    @IBOutlet weak var cameraControlView: UIView!
    @IBOutlet weak var flashOffImg: UIImageView!
    @IBOutlet weak var flashView: UIView!
    @IBOutlet weak var cameraSwitchView: UIView!
    @IBOutlet weak var videoPlayerView: AGVideoPlayerView!
    @IBOutlet weak var chooseBtnView: UIView!
    @IBOutlet weak var topCloseBtn: NSLayoutConstraint!
    
    
    // MARK: - Properties
    
    var delegate : PlansCameraVCDelegate?
    var mode = Mode.none
    var videoUrl:URL?
    var previewImg: UIImage?
    var isWatch = false
    var maxVideoDuration = APP_CONFIG.DURATION_VIDEO_EVENT
    var mediaType = MediaPicker.MediaType.allMedia
    
    fileprivate var captureSession: AVCaptureSession!
    fileprivate var input: AVCaptureDevice!
    var activeCamera: AVCaptureDevice?

    fileprivate var output = AVCapturePhotoOutput()
    fileprivate var movieOutput = AVCaptureMovieFileOutput()
    
    private var blurEffectView: UIVisualEffectView!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var imgvFocusRing = UIImageView(image: UIImage(named: "ic_ring_white"))

    /// Returns the CameraSelection corresponding to the currently utilized camera
    private(set) public var currentCamera        = CameraSelection.rear

    /// Sets wether the taken photo or video should be oriented according to the device orientation
    public var shouldUseDeviceOrientation      = true

    /// Last changed orientation
    fileprivate var deviceOrientation            : UIDeviceOrientation?
    
    private var initialScale: CGFloat = 0
    var zoomScaleRange: ClosedRange<CGFloat> = 1...10
    
    /// the current flash mode
    private var flashMode: AVCaptureDevice.FlashMode = .off
    
    // MARK: - ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kLoadingToastOff), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kLoadingToastOn), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldUseDeviceOrientation {
            subscribeToDeviceOrientationChangeNotifications()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Unsubscribe from device rotation notifications
        if shouldUseDeviceOrientation {
            unsubscribeFromDeviceOrientationChangeNotifications()
        }
        NOTIFICATION_CENTER.removeObserver(self)
    }
    
    // MARK: - Private Methods
    override func setupUI() {
        super.setupUI()
        
        btnRecord.delegate = self
        btnRecord.timeInterval = maxVideoDuration
        btnRecord.enableLongPressGesture = mediaType != .imageOnly
        btnRecord.enableTapGesture = mediaType != .videoOnly
        
        topCloseBtn.constant = 5 + (UIDevice.current.hasTopNotch == false ? UIDevice.current.heightTopNotch : 0)
        flashOffImg.isHighlighted = false
        
        setUpInputSession()
        setUpOutputSession()
        setUpPreview()
        updateUI(mode)
        prepareVideoPlayer(url: videoUrl)
    }
    
    // MARK: - Capture Input Session
    
    private func setUpInputSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1280x720
        captureSession.beginConfiguration()
        
        // setup Camera
        input = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        if input == nil { return }
        guard let deviceInput = try? AVCaptureDeviceInput(device: input),
            captureSession.canAddInput(deviceInput) else { return }
        captureSession.addInput(deviceInput)
        activeCamera = input
        
        // setup Microphone
        guard let microphone = AVCaptureDevice.default(for: .audio) else { return }
        guard let micInput = try? AVCaptureDeviceInput(device: microphone), captureSession.canAddInput(micInput) else { return }
        captureSession.addInput(micInput)
    }
    
    // MARK: - Capture Output Session
    
    private func setUpOutputSession() {
        output = AVCapturePhotoOutput()
        if #available(iOS 11.0, *) {
            output.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        } else {
            // Fallback on earlier versions
        }
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }

        captureSession.commitConfiguration()
        captureSession.startRunning()
    }

    // MARK: - Capture PreviewLayer
    
    private func setUpPreview() {
        guard let captureSession = self.captureSession else {
            return
        }
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.connection?.videoOrientation = getPreviewLayerOrientation()
        videoPreviewLayer.frame = CGRect(x: 0, y: 0, width: MAIN_SCREEN_WIDTH, height: (MAIN_SCREEN_WIDTH * 1280.0) / 720)
        cameraView.layer.addSublayer(self.videoPreviewLayer)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapped(_:)))
        cameraView.addGestureRecognizer(recognizer)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinched(_:)))
        cameraView.addGestureRecognizer(pinch)
    }

    func prepareVideoPlayer (url : URL?) {
        self.videoUrl = url
        videoPlayerView.videoUrl = videoUrl
        videoPlayerView.isMuted = false
        videoPlayerView.shouldAutoplay = false
        videoPlayerView.shouldAutoRepeat = true
        videoPlayerView.showsCustomControls = true
        videoPlayerView.shouldSwitchToFullscreen = false
        videoPlayerView.videoGravity = .resizeAspect
        videoPlayerView.delegate = self
    }

    private func updateUI (_ mode : Mode = .none) {
        
        previewImgView.image = previewImg
        
        cameraView.isHidden = true
        previewImgView.isHidden = true
        videoPlayerView.isHidden = true
        cameraControlView.isHidden = true
        flashView.isHidden = false
        cameraSwitchView.isHidden = false
        backBtnContainerView.isHidden = false
        chooseBtnView.isHidden = true

        switch mode {
        case .none:
            cameraView.isHidden = false
            cameraControlView.isHidden = false
            break
        case .takePhoto:
            break
        case .recordVideo:
            cameraView.isHidden = false
            cameraControlView.isHidden = false
            flashView.isHidden = true
            cameraSwitchView.isHidden = true
            backBtnContainerView.isHidden = true
            break
        case .playVideo:
            videoPlayerView.isHidden = false
            break
        case .comment:
            if self.mode == .recordVideo || self.mode == .playVideo {
                videoPlayerView.isHidden = false
            }else {
                previewImgView.isHidden = false
            }
            chooseBtnView.isHidden = isWatch
            break
        }

        self.mode = mode
    }
    
    func addFocusRing(point: CGPoint? = nil) {
        guard let point = point else { return }
        
        removeFocusRing()
        let size = imgvFocusRing.bounds.size
        imgvFocusRing.frame = CGRect(origin: CGPoint(x: point.x - (size.width / 2.0), y: point.y - (size.height / 2.0)), size: size)
        cameraView.addSubview(imgvFocusRing)
        cameraView.bringSubviewToFront(imgvFocusRing)
        imgvFocusRing.isHidden = false
        
        APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 5.0) {
            self.removeFocusRing()
        }
    }
    
    private func turnOnOffTorch(isOn: Bool = true) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        
        if (device.hasTorch) {
            do {
                try device.lockForConfiguration()
                device.torchMode = isOn ? .on : .off
                if isOn {
                    try device.setTorchModeOn(level: 1.0)
                }
                device.unlockForConfiguration()
            } catch {}
        }
    }
    
    func removeFocusRing() {
        imgvFocusRing.removeFromSuperview()
        imgvFocusRing.isHidden = true
    }
    
    private func configCamera(_ camera: AVCaptureDevice?, _ config: @escaping (AVCaptureDevice) -> ()) {
        guard let device = camera else { return }
        APP_CONFIG.defautMainQ.async { [device] in
            do {
                try device.lockForConfiguration()
            } catch {
                return
            }
            config(device)
            device.unlockForConfiguration()
        }
    }

    // MARK: - Click Photo
    
    private func clickPhoto() {
        if mode == .takePhoto {
            guard let captureSession = captureSession, captureSession.isRunning else { return }
            let photoSetting = AVCapturePhotoSettings()
            photoSetting.flashMode = currentCamera == .rear ? flashMode : .off
            output.capturePhoto(with: photoSetting, delegate: self)
        }
    }
        
    private func blurView() {
        let blurEffect = UIBlurEffect(style: .dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = cameraView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cameraView.addSubview(blurEffectView)
    }
    
    // MARK: - Go to video mode
    
    private func goToVideoMode() {
        captureSession.removeOutput(movieOutput)
        if movieOutput.isRecording {} else {
            do {
                try input.lockForConfiguration()
                if captureSession.canAddOutput(movieOutput) {
                    captureSession.addOutput(movieOutput)
                }
                startRecordingVideo()
                input.unlockForConfiguration()
            }catch {}
            turnOnOffTorch(isOn: currentCamera == .rear ? flashMode == .on : false)
        }
    }
    
    // MARK: - Stop video recording
    
    private func stopVideoRecording() {
        turnOnOffTorch(isOn: false)
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
    }
    
    // MARK: - Path of the video
    
    private func startRecordingVideo() {
        let paths = FILE_MANAGER.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("output.mov")
        try? FILE_MANAGER.removeItem(at: fileUrl)
        APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.25) {
            self.blurEffectView.removeFromSuperview()
            if self.btnRecord.timerMode == .start {
                
                // Update the orientation on the movie file output video connection before starting recording.
                let movieFileOutputConnection = self.movieOutput.connection(with: AVMediaType.video)

                //flip video output if front facing camera is selected
                if self.currentCamera == .front {
                    movieFileOutputConnection?.isVideoMirrored = true
                }

                movieFileOutputConnection?.videoOrientation = self.getVideoOrientation()
                self.movieOutput.startRecording(to: fileUrl, recordingDelegate: self)
            }
        }
    }
    
    func getCamera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        return devices.filter {$0.position == position}.first
    }

    
    // MARK: - User Actions
    
    @IBAction func backBtn(_ sender: UIButton) {
        if mode == .comment || mode == .playVideo {
            if mode == .playVideo {
                videoPlayerView.pause()
            }
            previewImg = nil
            videoUrl = nil

            if isWatch == true {
                self.dismiss(animated: true, completion: nil)
            }else {
                updateUI(.none)
            }
        }else {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func actionChooseBtn(_ sender: Any) {
        if self.previewImg != nil, self.videoUrl != nil {
            self.dismiss(animated: true){
                self.delegate?.didFinishRecording?(outputFileURL: self.videoUrl, previewImage: self.previewImg)
            }
            /*
            showLoader("Compressing video...")
            FILE_CENTER.compressVideo(inputURL: videoUrl!) { (exportSession) in
                guard let session = exportSession else {
                    self.hideLoader()
                    POPUP_MANAGER.makeToast("Failed to compress.")
                    return
                }

                switch session.status {
                case .waiting:
                    break
                case .exporting:
                    break
                case .completed:
                    self.hideLoader()
                    self.dismiss(animated: true){
                        self.delegate?.didFinishRecording?(outputFileURL: session.outputURL, previewImage: self.previewImg)
                    }
                    break
                default:
                    self.hideLoader()
                    POPUP_MANAGER.makeToast("Failed to compress.")
                    break
                }
            }
            */
        }else if self.previewImg != nil {
            self.dismiss(animated: true){
                self.delegate?.didFinishProcessingPhoto?(photo: self.previewImg)
            }
        }

    }
    
    @IBAction func actionFlashCamera(_ sender: UIButton) {
        if flashMode == .off {
            flashMode = .on
            flashOffImg.isHighlighted = true
        }else {
            flashMode = .off
            flashOffImg.isHighlighted = false
        }
    }
    
    @IBAction func switchCameraTapped(sender: Any) {
        //Change camera source
        if let session = captureSession {
            //Indicate that some changes will be made to the session
            session.beginConfiguration()
            
            //Remove existing input
            var currentCameraDevice : AVCaptureDeviceInput?
            if let inputs = session.inputs as? [AVCaptureDeviceInput] {
                inputs.forEach { (input) in
                    if input.device.deviceType != .builtInMicrophone {
                        currentCameraDevice = input
                        session.removeInput(input)
                    }
                }
            }
            
            if currentCameraDevice?.device.position == .back {
                flashView.isHidden = true
            }else {
                flashView.isHidden = false
            }
            
            guard let newCameraDevice = currentCameraDevice?.device.position == .back ? getCamera(with: .front) : getCamera(with: .back) else { return  }
            let newVideoInput = try? AVCaptureDeviceInput(device: newCameraDevice)
            session.addInput(newVideoInput!)
            session.commitConfiguration()
            activeCamera = newCameraDevice

            switch currentCamera {
            case .front:
                currentCamera = .rear
            case .rear:
                currentCamera = .front
            }
            
        }
    }
    
    
    @objc func hideKeyborard(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }

    @objc func handleTapped(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)

        if let device = activeCamera {
            let focusPoint = sender.location(in:cameraView)
            addFocusRing(point: focusPoint)
            let focusScaledPointX = focusPoint.x / cameraView.frame.size.width
            let focusScaledPointY = focusPoint.y / cameraView.frame.size.height
            if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported {
                configCamera(device) { device in
                    device.focusMode = .autoFocus
                    device.focusPointOfInterest = CGPoint(x:focusScaledPointX, y:focusScaledPointY)
                }
            }
        }
    }
    
    @objc func handlePinched(_ pinch: UIPinchGestureRecognizer) {
        guard let device = activeCamera else { return }

        switch pinch.state {
        case .began:
            initialScale = device.videoZoomFactor
        case .changed:
            let minAvailableZoomScale = device.minAvailableVideoZoomFactor
            let maxAvailableZoomScale = device.maxAvailableVideoZoomFactor
            let availableZoomScaleRange = minAvailableZoomScale...maxAvailableZoomScale
            let resolvedZoomScaleRange = zoomScaleRange.clamped(to: availableZoomScaleRange)

            let resolvedScale = max(resolvedZoomScaleRange.lowerBound, min(pinch.scale * initialScale, resolvedZoomScaleRange.upperBound))

            configCamera(device) { device in
                device.videoZoomFactor = resolvedScale
            }
        default:
            return
        }
    }

    
    // MARK: - Orientation management

    func subscribeToDeviceOrientationChangeNotifications() {
        self.deviceOrientation = UIDevice.current.orientation
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(deviceDidRotate), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    func unsubscribeFromDeviceOrientationChangeNotifications() {
        NOTIFICATION_CENTER.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        self.deviceOrientation = nil
    }

    @objc func deviceDidRotate() {
        if !UIDevice.current.orientation.isFlat {
            self.deviceOrientation = UIDevice.current.orientation
        }
    }

    func getImageOrientation(forCamera: CameraSelection) -> UIImage.Orientation {
        guard shouldUseDeviceOrientation, let deviceOrientation = self.deviceOrientation else { return forCamera == .rear ? .right : .leftMirrored }

        switch deviceOrientation {
        case .landscapeLeft:
            return forCamera == .rear ? .up : .downMirrored
        case .landscapeRight:
            return forCamera == .rear ? .down : .upMirrored
        case .portraitUpsideDown:
            return forCamera == .rear ? .left : .rightMirrored
        default:
            return forCamera == .rear ? .right : .leftMirrored
        }
    }
    
    func processPhoto(_ imageData: Data) -> UIImage {
        let dataProvider = CGDataProvider(data: imageData as CFData)
        let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)

        // Set proper orientation for photo
        // If camera is currently set to front camera, flip image

        let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: self.getImageOrientation(forCamera: self.currentCamera))

        return image
    }
    
    func getVideoOrientation() -> AVCaptureVideoOrientation {
        guard shouldUseDeviceOrientation, let deviceOrientation = self.deviceOrientation else { return videoPreviewLayer.connection!.videoOrientation }

        switch deviceOrientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    func getPreviewLayerOrientation() -> AVCaptureVideoOrientation {
        // Depends on layout orientation, not device orientation
        switch APPLICATION.statusBarOrientation {
        case .portrait, .unknown:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        }
    }


}


// MARK: - AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate

extension PlansCameraVC : AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if error != nil {} else if let buffer = photoSampleBuffer, let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: nil) {
            previewImg = processPhoto(data)
            updateUI(.comment)
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        updateUI(.recordVideo)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

        if FILE_MANAGER.fileExists(atPath: outputFileURL.path){
            if let image = FILE_CENTER.getThumbnailFrom(path: outputFileURL) {
                previewImg = image
            }
            prepareVideoPlayer(url: outputFileURL)
        }
        updateUI(.comment)
    }
    
}


// MARK: - TimerRingButtonDelegate

extension PlansCameraVC : TimerRingButtonDelegate {
    func didTapped() {
        mode = .takePhoto
        clickPhoto()
    }
    
    func didTimerStarted() {
        self.blurView()
        APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.25) {
            self.goToVideoMode()
        }
    }
    
    func didTimerEnded() {
        self.stopVideoRecording()
    }
    
}

// MARK: - AGVideoPlayerViewDelegate

extension PlansCameraVC : AGVideoPlayerViewDelegate {
    
    func didTapped(playerView: AGVideoPlayerView?) {
        self.view.endEditing(true)
    }
    
    func didPlay(playerView: AGVideoPlayerView?) {
        updateUI(.playVideo)
    }
    
    func didPause(playerView: AGVideoPlayerView?) {
        updateUI(.comment)
    }
}

