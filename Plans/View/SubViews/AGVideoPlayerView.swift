//
//  MediaCell.swift
//  Settlyt
//
//  Created by Plans Collective LLC on 11/09/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import SDWebImage
import BMPlayer


extension Notification.Name {
    static let playerDidChangeFullscreenMode = Notification.Name("playerDidEnterFullscreenMode")
}

@objc protocol AGVideoPlayerViewDelegate {
    @objc optional func didPlay (playerView : AGVideoPlayerView?) -> Void
    @objc optional func didPause (playerView : AGVideoPlayerView?) -> Void
    @objc optional func didTapped (playerView : AGVideoPlayerView?) -> Void
}


class AGVideoPlayerView: UIView {
    
    //MARK: Public variables
    var delegate : AGVideoPlayerViewDelegate?
    
    var videoUrl: URL? {
        didSet {
            prepareVideoPlayer()
        }
    }
    
    var previewImageUrl: String? {
        didSet {
            previewImageView?.setEventImage(previewImageUrl)
        }
    }
    
    //Automatically play the video when its view is visible on the screen.
    var shouldAutoplay: Bool = false {
        didSet {
            if shouldAutoplay {
                runTimer()
            } else {
                removeTimer()
            }
        }
    }
    
    //Automatically replay video after playback is complete.
    var shouldAutoRepeat: Bool = false {
        didSet {
            if oldValue == shouldAutoRepeat { return }
            if shouldAutoRepeat {
                NOTIFICATION_CENTER.addObserver(self, selector: #selector(itemDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
            } else {
                NOTIFICATION_CENTER.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
            }
        }
    }
    
    //Automatically switch to full-screen mode when device orientation did change to landscape.
    var shouldSwitchToFullscreen: Bool = false {
        didSet {
            if oldValue == shouldSwitchToFullscreen { return }
            if shouldSwitchToFullscreen {
                NOTIFICATION_CENTER.addObserver(self, selector: #selector(deviceOrientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
            } else {
                NOTIFICATION_CENTER.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
            }
        }
    }
    
    //Use AVPlayer's controls or custom. Now custom control view has only "Play" button. Add additional controls if needed.
    var showsCustomControls: Bool = false {
        didSet {
            playerController.showsPlaybackControls = !showsCustomControls
            customControlsContentView.isHidden = !showsCustomControls
        }
    }
    
    var hidePlayBackControls : Bool = false {
        didSet {
            playerController.showsPlaybackControls = !hidePlayBackControls
            customControlsContentView.isHidden = hidePlayBackControls
        }
    }
    
    var enablePlayBackControls : Bool = true {
        didSet {
            customControlsContentView.isUserInteractionEnabled = enablePlayBackControls
            playIcon.isUserInteractionEnabled = enablePlayBackControls
        }
    }
    
    var videoGravity : AVLayerVideoGravity = .resizeAspectFill {
        didSet {
            playerController.videoGravity = videoGravity
        }
    }
    
    //Value from 0.0 to 1.0, which sets the minimum percentage of the video player's view visibility on the screen to start playback.
    var minimumVisibilityValueForStartAutoPlay: CGFloat = 0.9
    
    //Mute the video.
    var isMuted: Bool = false {
        didSet {
            playerController.player?.isMuted = isMuted
        }
    }

    public let playerController = AVPlayerViewController()
    public var customControlsContentView: UIView!

    //MARK: Private variables
    fileprivate var isPlaying: Bool = false
    fileprivate var videoAsset: AVURLAsset?
    fileprivate var displayLink: CADisplayLink?
    
    fileprivate var previewImageView: UIImageView!
    fileprivate var playIcon: UIImageView!
    fileprivate var isFullscreen = false
    fileprivate var observer:Any?
    
    //MARK: Life cycle
    deinit {
        NOTIFICATION_CENTER.removeObserver(self)
        removePlayerObservers()
        displayLink?.invalidate()
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpView()
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            pause()
            removeTimer()
        } else {
            if shouldAutoplay {
                runTimer()
            }
        }
    }
    
}

//MARK: View configuration
extension AGVideoPlayerView {
    fileprivate func setUpView() {
        configurateControls()
        addVideoPlayerView()
    }
    
    private func addVideoPlayerView() {
        playerController.view.frame = self.bounds
        playerController.videoGravity = self.videoGravity
        playerController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerController.showsPlaybackControls = false
        playerController.view.backgroundColor = UIColor.clear
        //playerController.show
        self.insertSubview(playerController.view, at: 0)
    }
    
    private func configurateControls() {
        customControlsContentView = UIView(frame: self.bounds)
        customControlsContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        customControlsContentView.backgroundColor = .clear
        
        previewImageView = UIImageView(frame: self.bounds)
        previewImageView.backgroundColor = .clear
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        previewImageView.clipsToBounds = true
        
        playIcon = UIImageView(image: UIImage(named:"ic_play_circle_black_opacity"))
        playIcon.isUserInteractionEnabled = true
        playIcon.contentMode = .scaleAspectFit
        playIcon.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        playIcon.center = previewImageView!.center
        playIcon.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        
        addSubview(previewImageView!)
        customControlsContentView?.addSubview(playIcon)
        addSubview(customControlsContentView!)
        let playAction = UITapGestureRecognizer(target: self, action: #selector(didTapPlay))
        playIcon.addGestureRecognizer(playAction)
        let pauseAction = UITapGestureRecognizer(target: self, action: #selector(didTapPause))
        customControlsContentView.addGestureRecognizer(pauseAction)
    }
}

//MARK: Timer part
extension AGVideoPlayerView {
    fileprivate func runTimer() {
        if displayLink != nil {
            displayLink?.isPaused = false
            return
        }
        displayLink = CADisplayLink(target: self, selector: #selector(timerAction))
        if #available(iOS 10.0, *) {
            displayLink?.preferredFramesPerSecond = 5
        } else {
            displayLink?.frameInterval = 5
        }
        displayLink?.add(to: RunLoop.current, forMode: .common)
    }
    
    fileprivate func removeTimer() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func timerAction() {
        guard videoUrl != nil else {
            return
        }
        if isVisible() {
            play()
        } else {
            pause()
        }
    }
}

//MARK: Logic of the view's position search on the app screen.
extension AGVideoPlayerView {
    fileprivate func isVisible() -> Bool {
        if self.window == nil {
            return false
        }
        let displayBounds = UIScreen.main.bounds
        let selfFrame = self.convert(self.bounds, to: APPLICATION.keyWindow)
        let intersection = displayBounds.intersection(selfFrame)
        let visibility = (intersection.width * intersection.height) / (frame.width * frame.height)
        return visibility >= minimumVisibilityValueForStartAutoPlay
    }
}

//MARK: Video player part
extension AGVideoPlayerView {
    fileprivate func prepareVideoPlayer() {
        playerController.player?.removeObserver(self, forKeyPath: "rate")
        guard let url = videoUrl else {
            videoAsset = nil
            playerController.player = nil
            return
        }
        
        previewImageView.isHidden = false

        videoAsset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: videoAsset!)
        let player = AVPlayer(playerItem: item)
        
        player.volume = 1.0
        player.isMuted = isMuted
        playerController.player = player
        addPlayerObservers()
    }
    
    @objc func didTapPlay() {
        displayLink?.isPaused = false
        play()
        delegate?.didTapped?(playerView: self)
    }
    
    @objc func didTapPause() {
        displayLink?.isPaused = true
        pause()
        delegate?.didTapped?(playerView: self)
    }
    
    func play() {
        if isPlaying { return }
        isPlaying = true
        videoAsset?.loadValuesAsynchronously(forKeys: ["playable", "tracks", "duration"], completionHandler: { [weak self]  in
            APP_CONFIG.defautMainQ.async {
                if self?.isPlaying == true {
                    self?.playIcon.isHidden = true
                    self?.playerController.player?.play()
                    self?.delegate?.didPlay?(playerView: self)
                }
            }
        })
    }
    
    func pause() {
        if isPlaying {
            isPlaying = false
            playIcon.isHidden = false
            playerController.player?.pause()
            delegate?.didPause?(playerView: self)
        }
    }
    
    @objc fileprivate func itemDidFinishPlaying() {
        if isPlaying {
            playerController.player?.seek(to: CMTime.zero, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            playerController.player?.play()
        }
    }
}

//MARK: Player size observing part
extension AGVideoPlayerView {
    fileprivate func addPlayerObservers() {
        playerController.player?.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
        playerController.player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        playerController.contentOverlayView?.addObserver(self, forKeyPath: "bounds", options: .new, context: nil)
    }
    
    fileprivate func removePlayerObservers() {
        playerController.player?.removeObserver(self, forKeyPath: "rate")
        playerController.player?.removeObserver(self, forKeyPath: "timeControlStatus")
        if let content = playerController.contentOverlayView, content.observationInfo != nil {
            playerController.contentOverlayView?.removeObserver(self, forKeyPath: "bounds")
        }
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath! {
        case "rate":
            if let rate = playerController.player?.rate, Int(rate) > 0 {
                previewImageView.isHidden = true
            }
        case "bounds":
            let fullscreen = playerController.contentOverlayView?.bounds == UIScreen.main.bounds
            if isFullscreen != fullscreen {
                isFullscreen = fullscreen
                NOTIFICATION_CENTER.post(name: .playerDidChangeFullscreenMode, object: isFullscreen)
            }
        case "timeControlStatus":
            if let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
                let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
                let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
                if newStatus != oldStatus {
                    APP_CONFIG.defautMainQ.async {[weak self] in
                        var dict = [String: Any]()
                        dict["isBuffering"] = newStatus
                        NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: "videoBufferingNotification"), object: dict)
                    }
                }
            }
        default:
            break
        }
    }
    
}

//MARK: Device orientation observing
extension AGVideoPlayerView {
    @objc fileprivate func deviceOrientationDidChange(_ notification: Notification) {
        if isFullscreen || !isVisible() { return }
        if let orientation = (notification.object as? UIDevice)?.orientation, orientation == .landscapeLeft || orientation == .landscapeRight {
            playerController.forceFullScreenMode()
            updateDeviceOrientation(with: orientation)
        }
    }
    
    private func updateDeviceOrientation(with orientation: UIDeviceOrientation) {
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.3, execute: {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        })
    }
}

//MARK: AVPlayerViewController extension for force fullscreen mode
extension AVPlayerViewController {
    func forceFullScreenMode() {
        let selectorName : String = {
            if #available(iOS 11, *) {
                return "_transitionToFullScreenAnimated:completionHandler:"
            } else {
                return "_transitionToFullScreenViewControllerAnimated:completionHandler:"
            }
        }()
        let selectorToForceFullScreenMode = NSSelectorFromString(selectorName)
        if self.responds(to: selectorToForceFullScreenMode) {
            self.perform(selectorToForceFullScreenMode, with: true, with: nil)
        }
    }
}
