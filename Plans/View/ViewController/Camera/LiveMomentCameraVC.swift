//
//  LiveMomentCameraVC.swift
//  Plans
//
//  Created by Star on 2/12/21.
//

import UIKit
import AVFoundation
import AVKit

class LiveMomentCameraVC: EventBaseVC {
    
    enum Mode {
        case none
        case takePhoto
        case recordVideo
        case playVideo
        case comment
    }
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var liveBg: UIImageView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var previewImg: UIImageView!
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var flipView: UIView!
    @IBOutlet weak var commentTF: UITextView!
    @IBOutlet weak var bottomCommentView: NSLayoutConstraint!
    @IBOutlet weak var eventTitleLbl: UILabel!
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
    @IBOutlet weak var topEventTitleLbl: NSLayoutConstraint!
    
    // MARK: - Properties
    
    private var videoUrl:URL?
    private var blurEffectView: UIVisualEffectView!
    private var mode = Mode.none
    private var imgvFocusRing = UIImageView(image: UIImage(named: "ic_ring_white"))

    
    fileprivate var captureSession: AVCaptureSession!
    fileprivate var input: AVCaptureDevice!
    var activeCamera: AVCaptureDevice?

    fileprivate var movieOutput = AVCaptureMovieFileOutput()
    fileprivate var output = AVCapturePhotoOutput()
    
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!

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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyborard(_:)))
        self.view.addGestureRecognizer(tap)
        
        // Do any additional setup after loading the view.
        USER_MANAGER.isShownPostTutorial = true
        setUpView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
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

    // MARK: - Notification Handlers

    @objc func hideKeyborard(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    

    // MARK: - Private Methods
    private func setUpView() {
        eventTitleLbl.text = activeEvent?.eventName
        eventID = activeEvent?._id

        bottomCommentView.constant = 20 + UIDevice.current.heightBottomNotch
        topEventTitleLbl.constant = 20 + (UIDevice.current.hasTopNotch == false ? UIDevice.current.heightTopNotch : 0)

        
        let options : UIView.AnimationOptions = .repeat
        UIView.animate(withDuration: 0.8, delay:0.0, options:options, animations: {
            self.liveBg.alpha = 0.2
        }, completion: nil)
        
        btnRecord.delegate = self
        flashOffImg.isHighlighted = false
        
        setUpInputSession()
        setUpOutputSession()
        setUpPreview()
        addKeyboardObserver()
        updateUI()
    }
    
    
    // Capture Input Session
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
    
    // Capture Output Session
    private func setUpOutputSession() {
        output = AVCapturePhotoOutput()
        if #available(iOS 11.0, *) {
            output.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        } else {
            // Fallback on earlier versions
        }
        if captureSession.canAddOutput(output) { captureSession.addOutput(output) }
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
    
    // Capture PreviewLayer
    private func setUpPreview() {
        guard let captureSession = self.captureSession else {
            return
        }
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.connection?.videoOrientation = getPreviewLayerOrientation()
        videoPreviewLayer.frame = CGRect(x: 0, y: 0, width: MAIN_SCREEN_WIDTH, height: (MAIN_SCREEN_WIDTH * 1280.0) / 720.0)
        cameraView.layer.addSublayer(self.videoPreviewLayer)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapped(_:)))
        cameraView.addGestureRecognizer(recognizer)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinched(_:)))
        cameraView.addGestureRecognizer(pinch)

    }

    // Video Player
    private func prepareVideoPlayer (url : URL?) {
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

    // Update All UIs
    private func updateUI (_ mode : Mode = .none) {

        cameraView.isHidden = true
        previewImg.isHidden = true
        videoPlayerView.isHidden = true
        cameraControlView.isHidden = true
        commentView.isHidden = true
        flashView.isHidden = false
        cameraSwitchView.isHidden = false
        eventTitleLbl.isHidden = false
        backBtnContainerView.isHidden = false

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
            eventTitleLbl.isHidden = true
            break
        case .playVideo:
            videoPlayerView.isHidden = false
            break
        case .comment:
            if self.mode == .recordVideo || self.mode == .playVideo {
                videoPlayerView.isHidden = false
            }else {
                previewImg.isHidden = false
            }
            commentView.isHidden = false
            break
        }

        self.mode = mode
    }

    // Click Photo
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
    
    // Go to video mode
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
    
    // Stop video recording
    private func stopVideoRecording() {
        turnOnOffTorch(isOn: false)
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
    }
    
    // Path of the video
    private func startRecordingVideo() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("output.mov")
        try? FileManager.default.removeItem(at: fileUrl)
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
    
    private func addKeyboardObserver() {
        NOTIFICATION_CENTER.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main) { (noti) in
            let userInfo:NSDictionary = noti.userInfo! as NSDictionary
            let keyboardFrame:NSValue = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue
            self.bottomCommentView.constant = keyboardFrame.cgRectValue.height - UIDevice.current.heightBottomNotch
            self.view.updateConstraintsIfNeeded()
        }
        
        NOTIFICATION_CENTER.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main) { (noti) in
            self.bottomCommentView.constant = 20 + UIDevice.current.heightBottomNotch
            self.view.updateConstraintsIfNeeded()
        }
    }
    
    func getCamera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        guard let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] else {
            return nil
        }
        return devices.filter {
            $0.position == position
            }.first
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

    // MARK: - User Actions
    
    @IBAction func backBtn(_ sender: UIButton) {
        view.endEditing(true)
        if mode == .comment || mode == .playVideo {
            if mode == .playVideo {
                videoPlayerView.pause()
            }
            previewImg.image = nil
            videoUrl = nil
            commentTF.text = ""
            updateUI(.none)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func sendBtnAction(_ sender: UIButton) {
        self.view.endEditing(true)

        if previewImg.image != nil && videoUrl == nil {
            createLiveMoment(previewImg.image!)
        } else {
            createLiveMoment(videoUrl: videoUrl)
            /*
            POPUP_MANAGER.showLoadingToast(.posting)
            FILE_CENTER.compressVideo(inputURL: videoUrl, quality: AVAssetExportPresetHighestQuality) { (exportSession) in
                guard let session = exportSession else {
                    POPUP_MANAGER.hideLoadingToast(.posting)
                    POPUP_MANAGER.makeToast("Failed to compress.")
                    return
                }

                switch session.status {
                case .waiting:
                    break
                case .exporting:
                    break
                case .completed:
                    self.createLiveMoment(videoUrl: session.outputURL, isShowLoading: false)
                    break
                default:
                    POPUP_MANAGER.hideLoadingToast(.posting)
                    POPUP_MANAGER.makeToast("Failed to compress.")
                    break
                }
            }
             */
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
        self.view.endEditing(true)
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

    
    
    // MARK: - Backend APIs

    // Create event dictionary
    func prepareDic() -> [String: Any] {
        let dict = ["liveText": commentTF.text ?? "",
                    "eventId": self.eventID ?? "",
                    "mediaType": videoUrl == nil ? "image" : "video",
                    "createdAt": String(floor(Date().timeIntervalSince1970))] as [String : Any]
        return dict
    }
    
    // Create moment api method
    func createLiveMoment(_ image: UIImage? = nil, videoUrl: URL? = nil, isShowLoading: Bool = true) {
        if isShowLoading == true {
            POPUP_MANAGER.showLoadingToast(.posting)
        }
        LIVE_MOMENT_SERVICE.createLiveMoments(self.prepareDic(), media: image, videoUrl: videoUrl).done { (response) -> Void in
            POPUP_MANAGER.hideLoadingToast(.posting)
            POPUP_MANAGER.makeToast(ConstantTexts.postedliveMoment.localizedString)
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            ANALYTICS_MANAGER.logEvent(.story_add)
        }.catch { (error) in
            POPUP_MANAGER.hideLoadingToast(.posting)
            POPUP_MANAGER.handleError(error)
        }
        
        navigationController?.popViewController(animated: true)
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

extension LiveMomentCameraVC : AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if error != nil {} else if let buffer = photoSampleBuffer, let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: nil) {
            previewImg.image = processPhoto(data)
            updateUI(.comment)
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        updateUI(.recordVideo)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

        if FileManager.default.fileExists(atPath: outputFileURL.path){
            if let image = FILE_CENTER.getThumbnailFrom(path: outputFileURL) {
                self.previewImg.image = image
            }
            prepareVideoPlayer(url : outputFileURL)
        }
        updateUI(.comment)
    }

}


// MARK: - TimerRingButtonDelegate

extension LiveMomentCameraVC : TimerRingButtonDelegate {
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

extension LiveMomentCameraVC : AGVideoPlayerViewDelegate {
    
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

// MARK: - UITextFieldDelegate

extension LiveMomentCameraVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.view.endEditing(true)
    }
}

