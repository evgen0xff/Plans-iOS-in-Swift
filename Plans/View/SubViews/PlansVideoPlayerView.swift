//
//  PlansVideoPlayerView.swift
//  Plans
//
//  Created by Top Star on 12/24/21.
//

import UIKit
import MediaPlayer
import BMPlayer

// MARK: - PlansPlayerControlView

class PlansPlayerControlView : BMPlayerControlView {
    override func autoFadeOutControlViewWithAnimation() {
    }
    override func controlViewAnimation(isShow: Bool) {
    }
}

// MARK: - PlansVideoPlayerView

class PlansVideoPlayerView: BMPlayer {
    
    enum UIType {
        case standard
        case plansEvent
        case watchLiveMoment
        case postComment
    }
    
    var playConrolView: BMPlayerControlView?
    var asset: BMPlayerResource?
    var urlCoverImage: String?
    var urlVideo: String?
    
    var currentItemTotalDuration: TimeInterval? {
        get {
            let seconds = avPlayer?.currentItem?.duration.seconds
            return (seconds == nil || seconds!.isNaN == true) ? nil : seconds
        }
    }
    
    let imvCoverImage = UIImageView()
    let imvCenterPlay = UIImageView(image: UIImage(named:"ic_play_circle_black_opacity"))

    var ishiddenPlayConrolView = true {
        didSet {
            playConrolView?.isHidden = ishiddenPlayConrolView
        }
    }
    
    var typeUI = UIType.standard {
        didSet {
            setupUI()
        }
    }
    
    var shouldAutoRepeat = true
    var shouldAutoPlay = true
    var totalDuration: TimeInterval? = nil    

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }

    override init(customControlView: BMPlayerControlView?) {
        let controlView = customControlView ?? PlansPlayerControlView()
        super.init(customControlView: customControlView ?? controlView)
        
        playConrolView = controlView
        initialize()
    }
    

    override func storyBoardCustomControl() -> BMPlayerControlView? {
        if playConrolView == nil {
            playConrolView = PlansPlayerControlView()
        }
        return playConrolView
    }
    
    private func initialize() {
        initUI()
        setupUI()
    }
    
    private func initUI() {
        backgroundColor = .clear
        // Set up Player Control View
        playConrolView?.isHidden = ishiddenPlayConrolView
        
        // Add Cover Image View
        imvCoverImage.backgroundColor = .clear
        imvCoverImage.contentMode = .scaleAspectFill
        imvCoverImage.clipsToBounds = true
        insertSubview(imvCoverImage, at: 0)
        imvCoverImage.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }

        // Add Center Play Icon Image View
        imvCenterPlay.backgroundColor = .clear
        imvCenterPlay.contentMode = .scaleAspectFit
        imvCenterPlay.clipsToBounds = true
        addSubview(imvCenterPlay)
        imvCenterPlay.snp.makeConstraints { (make) in
            make.width.height.equalTo(36)
            make.center.equalTo(self)
        }

    }
    
    func setupUI() {
        switch typeUI {
        case .standard:
            break
        case .plansEvent, .postComment:
            avPlayer?.isMuted = true
            shouldAutoPlay = true
            shouldAutoRepeat = true
            imvCenterPlay.isHidden = false
            imvCoverImage.setEventImage(urlCoverImage)
            DispatchQueue.main.async {
                self.videoGravity = .resizeAspectFill
            }
            break
        case .watchLiveMoment:
            avPlayer?.isMuted = false
            shouldAutoPlay = true
            shouldAutoRepeat = false
            imvCenterPlay.isHidden = true
            imvCoverImage.setEventImage(urlCoverImage, placeholder: "")
            DispatchQueue.main.async {
                self.videoGravity = .resizeAspectFill
            }
            break
        }
    }
    
    func setVideo(_ videoUrl: String?, _ coverImagUrl: String? = nil, _ delegate: BMPlayerDelegate? = nil) {
        urlCoverImage = coverImagUrl
        urlVideo = videoUrl
        self.delegate = delegate ?? self.delegate ?? self

        setupUI()

        guard let strUrl = urlVideo, !strUrl.isEmpty, let url = URL(string: strUrl) else { return }

        if isPlaying == true {
            pause(allowAutoPlay: false)
        }
        
        asset = BMPlayerResource(url: url)
        setVideo(resource: asset!)
        
        if shouldAutoPlay == true {
            play()
        }else {
            pause(allowAutoPlay: false)
        }
        
        DispatchQueue.main.async {
            self.playerLayer?.videoGravity = self.videoGravity
        }
    }
    
    func resetVideo() {
        guard let asset = asset else { return }

        if isPlaying == true {
            pause(allowAutoPlay: false)
        }

        setVideo(resource: asset)

        if shouldAutoPlay == true {
            play()
        }else {
            pause(allowAutoPlay: false)
        }

        DispatchQueue.main.async {
            self.playerLayer?.videoGravity = self.videoGravity
        }
    }
    
}


// MARK: - BMPlayerDelegate
extension PlansVideoPlayerView: BMPlayerDelegate {
    func bmPlayer(player: BMPlayer, playerOrientChanged isFullscreen: Bool) {
    }
    func bmPlayer(player: BMPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
    }
    func bmPlayer(player: BMPlayer, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
    }
    
    func bmPlayer(player: BMPlayer, playerStateDidChange state: BMPlayerState) {
        print("playerStateDidChange state: ", state)
        switch state {
        case .notSetURL:
            imvCenterPlay.isHidden = false
            break
        case .readyToPlay:
            break
        case .buffering:
            imvCenterPlay.isHidden = false
            break
        case .bufferFinished:
            imvCenterPlay.isHidden = true
            break
        case .playedToTheEnd:
            if shouldAutoRepeat {
                resetVideo()
            }
            break
        case .error:
            resetVideo()
            break
        }
    }
    
    func bmPlayer(player: BMPlayer, playerIsPlaying playing: Bool) {
        print("playerIsPlaying playing: ", playing)
        imvCenterPlay.isHidden = playing
    }
    
}






