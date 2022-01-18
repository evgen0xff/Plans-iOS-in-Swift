//
//  WatchLiveMomentsVC.swift
//  Plans
//
//  Created by Star on 2/15/21.
//

import UIKit
import AVFoundation
import AVKit
import CoreMedia
import GrowingTextView
import BMPlayer

class WatchLiveMomentsVC: EventBaseVC {
    
    enum Status {
        case none
        case photoPlaying
        case photoPause
        case videoPlaying
        case videoPause
    }
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var videoPlayerView: PlansVideoPlayerView!
    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var photoImg: UIImageView!
    @IBOutlet weak var photoContainerView: UIView!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var closeView: UIView!
    @IBOutlet weak var chatView: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var lblCaption: ExpandableLabel!
    @IBOutlet weak var heightScrollCaption: NSLayoutConstraint!
    @IBOutlet weak var captionContainerView: UIView!
    @IBOutlet weak var guestureView: UIView!
    
    // MARK: - Properties

    var SPB: SegmentedProgressBar?

    var userId: String?
    var user: UserModel?
    
    var liveMomentId: String?
    var liveMoment: LiveMomentModel?

    var listUserMoments = [UserLiveMomentsModel]()
    var curUserMoments: UserLiveMomentsModel?

    var listLiveMoments = [LiveMomentModel]()
    var curLiveMoment : LiveMomentModel?
    var completeCurVideoDuration:((_ duration: TimeInterval?) -> Void)? = nil
    
    var curStatus = Status.none
    var curIndex : Int = 0
    var isMine = false
    var isEventHost = false
    let widthCaption = MAIN_SCREEN_WIDTH - 30

    
    // MARK: - ViewController Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getLiveMomments()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playPause(isPause: true)
    }
    
    override func initializeData() {
        super.initializeData()
        
        userId = userId ?? user?._id ?? user?.userId
        liveMomentId = liveMomentId ?? liveMoment?._id
        
        listLiveMoments.removeAll()
        listUserMoments.forEach { (model) in
            if let medias = model.liveMoments {
                listLiveMoments.append(contentsOf: medias)
            }
        }
    }
    
    // MARK: - Private Methods
    func initializeUI() {
        setupCaptionText()

        // Segmented progress bar
        setUpProgressBar(count: listLiveMoments.count)

        // Video Player View
        videoPlayerView.typeUI = .watchLiveMoment
        videoPlayerView.delegate = self

        // Play story
        playMedia(index: curIndex, isPause: USER_MANAGER.isFirstWatchMoment)
    }
    
    func playMedia (index : Int, isPause : Bool = false){
        
        guard index >= 0, index < listLiveMoments.count else { return }
        
        curIndex = index
        curLiveMoment = listLiveMoments[curIndex]
        curUserMoments = listUserMoments.filter({ (model) -> Bool in
            if model.liveMoments?.contains(where: { (media) -> Bool in
                if media == curLiveMoment {
                    return true
                }else {
                    return false
                }
            }) == true {
                return true
            }else {
                return false
            }
            }).first
        
        setupUI(curUserMoments, isPause: isPause)
        updateUI(mode: curStatus)
        
        if let id = curLiveMoment?._id, id != "" {
            let _ = LIVE_MOMENT_SERVICE.viewedLiveMomentApi([id])
        }
    }
    

    private func setupUI (_ model : UserLiveMomentsModel?, isPause : Bool = false) {
        
        curUserMoments = model
        isMine = false
        isEventHost = false
        if let userId = USER_MANAGER.userId {
            if userId == curUserMoments?.user?.userId {
                isMine = true
            }
            if userId == activeEvent?.userId {
                isEventHost = true
            }
        }
        
        // Segmented Progress Bar
        SPB?.isPaused = isPause
        
        // Profile Image
        profileImg.setUserImage(model?.user?.profileImage)

        // User Name
        if let fullName = model?.user?.fullName {
            usernameLbl.text = fullName
        }
        
        // Time label
        if let createdAt = curLiveMoment?.createdAt {
            timeLbl.text = Date(timeIntervalSince1970: createdAt).timeAgoSince()
        }
        
        // Caption
        updateCaptionText(curLiveMoment?.media, heightLimit: 66.0, isCollapsed: true)

        // Media
        if curLiveMoment?.mediaType == "video", let videoUrl = curLiveMoment?.imageOrVideo {
            videoPlayerView.setVideo(videoUrl, curLiveMoment?.liveThumbnail)
            if isPause == true {
                curStatus = .videoPause
                videoPlayerView.pause()
            }else {
                curStatus = .videoPlaying
                videoPlayerView.play()
            }
        }else {
            if let imageUrl = curLiveMoment?.imageOrVideo,
                let url = URL(string: imageUrl) {
                if isPause == true {
                    curStatus = .photoPause
                }else {
                    curStatus = .photoPlaying
                }

                if tutorialView.isHidden == true {
                    showLoader()
                    SPB?.isPaused = true
                }
 
                photoImg.sd_setImage(with: url) { (image, err, cash, url) in
                    self.hideLoader()
                    if self.curStatus == .photoPlaying, self.SPB?.isPaused == true, self.tutorialView.isHidden == true {
                        self.SPB?.isPaused = false
                    }
                }
                SPB?.duration = APP_CONFIG.DURATION_PLAY_PHOTO
            }
        }
        
    }
    
    private func updateData(list: [UserLiveMomentsModel]?) {
        guard let list = list else { return }

        if list.count > 0 {
            listUserMoments.removeAll()
            listUserMoments.append(contentsOf: list)
            curStatus = .none
            curIndex = 0
            initializeData()
            initializeUI()
        }else {
            actionCloseBtn(self)
        }
    }
    
    private func updateUI(mode : Status = .none) {
        
        if USER_MANAGER.isFirstWatchMoment == false {
            tutorialView.isHidden = true
        }else {
            tutorialView.isHidden = false
        }

        photoContainerView.isHidden = true
        videoContainerView.isHidden = true
        captionContainerView.isHidden = true
        chatView.isHidden = isMine
        menuView.isHidden = false
        closeView.isHidden = false
        profileImg.isHidden = false

        switch mode {
            case .none:
                chatView.isHidden = true
                menuView.isHidden = true
                closeView.isHidden = true
                profileImg.isHidden = true
                break
            case .photoPlaying:
                photoContainerView.isHidden = false
                captionContainerView.isHidden = false
                break
            case .photoPause:
                photoContainerView.isHidden = false
                captionContainerView.isHidden = false
                break
            case .videoPlaying:
                videoContainerView.isHidden = false
                captionContainerView.isHidden = false
                break
            case .videoPause:
                videoContainerView.isHidden = false
                captionContainerView.isHidden = false
                break
        }
        

        captionContainerView.isHidden = (curLiveMoment?.media ?? "") == ""
        
        self.curStatus = mode
    }
    
    private func setupCaptionText() {
        lblCaption.delegateExpandable = self

        lblCaption.collapsedAttributedLink = "See more".colored(color: AppColor.grey_text, font: AppFont.bold.size(17.0))
        lblCaption.expandedAttributedLink = "See less".colored(color: AppColor.grey_text, font: AppFont.bold.size(17.0))
        lblCaption.ellipsis = " ...".colored(color: UIColor.white, font: AppFont.regular.size(17.0))
//        view.layoutIfNeeded()
        
        lblCaption.shouldExpand = true
        lblCaption.shouldCollapse = true
        lblCaption.textReplacementType = .word
        lblCaption.numberOfLines = 3
        lblCaption.collapsed = true

        setupActiveLabel(label: lblCaption, color: .white)
    }
    
    private func updateCaptionText(_ text: String?,
                                   heightLimit: CGFloat,
                                   isCollapsed: Bool? = nil ) {
        
        let caption = text ?? ""

        if isCollapsed != nil {
            lblCaption.collapsed = isCollapsed!
        }

        if let caption = text {
            lblCaption.text = caption
        }

        var height = caption.height(withConstrainedWidth: widthCaption, font: AppFont.regular.size(17.0))
        if height > heightLimit {
            height = heightLimit
        }
        heightScrollCaption.constant = height
//        view.layoutIfNeeded()
    }
    
    private func playPause (isPause : Bool = false) {
        
        switch curStatus {
        case .photoPause, .photoPlaying:
            curStatus = isPause ? .photoPause : .photoPlaying
            SPB?.isPaused = isPause
            break
        case .videoPause, .videoPlaying:
            curStatus = isPause ? .videoPause : .videoPlaying
            if isPause == true {
                videoPlayerView.pause()
            }else {
                videoPlayerView.play()
            }
            break
        default :
            SPB?.isPaused = isPause
            break
        }
        
        updateUI(mode: curStatus)
    }
    
    
    // Progress Bar
    private func setUpProgressBar(count: Int) {
        if SPB != nil {
            SPB?.isPaused = true
            SPB?.removeFromSuperview()
            SPB = nil
        }
        
        SPB = SegmentedProgressBar(numberOfSegments: count, duration: APP_CONFIG.DURATION_PLAY_PHOTO)
        SPB?.frame = progressView.bounds
        
        SPB?.delegate = self
        SPB?.topColor = UIColor.white
        SPB?.bottomColor = UIColor.white.withAlphaComponent(0.25)
        SPB?.padding = 2
        SPB?.currentAnimationIndex = 0

        progressView.addSubview(SPB!)
        
        SPB?.startAnimation()
    }
    
    func presentFeedOptions() {
        var list = [String]()
        if isMine == false {
            list.append("Report")
        }
        if isEventHost == true || isMine == true {
            list.append("Delete")
        }

        OPTIONS_MANAGER.showMenu(list:list, delegate: self, sender: self)
    }
    
    func reportLiveMoment() {
        playPause(isPause: true)
        let _ = showPlansAlertYesNo(message: ConstantTexts.reportLiveMoment.localizedString,
                                    actionYes: {
                                        self.reportEntity(id: self.curLiveMoment?._id, type: "liveMoment")
                                    },
                                    blurEnabled: true)
    }

    
    // MARK: - User anction handler
    
    @IBAction func actionMenuBtn(_ sender: Any) {
        playPause(isPause: true)
        presentFeedOptions()
    }
    
    @IBAction func actionCloseBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionDeleteBtn(_ sender: Any) {
        playPause(isPause : true)
        let _ = showPlansAlertYesNo(message: ConstantTexts.deleteLiveMoment.rawValue,
                                    actionYes: {
                                            self.deleteLiveMomentApi()
                                    },
                                    blurEnabled: true)
    }
    
    @IBAction func actionChatBtn(_ sender: Any) {
        guard let user = curUserMoments?.user else { return }

        APP_MANAGER.pushChatMessageVC(otherUser: user,
                                      sender: self)
    }

    @IBAction func actionTappedTutorial(_ sender: Any) {
        USER_MANAGER.isFirstWatchMoment = false
        playPause(isPause: false)
    }
    @IBAction func actionSwipeRight(_ sender: Any) {
        SPB?.rewind()
    }
    
    @IBAction func actionSwipeLeft(_ sender: Any) {
        if (curIndex + 1) < listLiveMoments.count {
            SPB?.skip()
        }else if (curIndex + 1) == listLiveMoments.count {
            navigationController?.popViewController(direction: .fromRight)
        }
    }
    
    @IBAction func actionSwipeDown(_ sender: Any) {
        navigationController?.popViewController(direction: .fromBottom)
    }
    
    @IBAction func actionTappedOverlay(_ sender: UITapGestureRecognizer) {
        
        let tapPoint = sender.location(in: guestureView)
        let partWidth = guestureView.bounds.size.width / 3.0
        if tapPoint.x < partWidth {
            SPB?.rewind()
        }else if tapPoint.x > partWidth * 2 {
            if (curIndex + 1) < listLiveMoments.count {
                SPB?.skip()
            }else if (curIndex + 1) == listLiveMoments.count {
                self.actionCloseBtn(sender)
            }
        }else {
            if SPB?.isPaused == true {
                playPause(isPause: false)
            }
        }
    }
    
    @IBAction func actionLongPressed(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
        case .began:
            playPause(isPause: true)
            break
        case .ended:
            playPause(isPause: false)
            break
        default:
            break
        }
    }
    
    @IBAction func actionUserProfileBtn(_ sender: Any) {
        APP_MANAGER.pushUserProfileVC(userId: curUserMoments?.user?.userId, sender: self)
    }
}


//MARK: - SegmentedProgressBarDelegate
extension WatchLiveMomentsVC: SegmentedProgressBarDelegate {
    
    func segmentedProgressBarChangedIndex(index: Int) {
        playMedia(index: index)
    }
    
    func segmentedProgressBarFinished() {
        actionCloseBtn(self)
    }
    
    func durationForIndex(index: Int, complete: ((TimeInterval?) -> Void)?) {
        guard index < listLiveMoments.count else { return }

        if listLiveMoments[index].mediaType == "video", let videoUrl = listLiveMoments[index].imageOrVideo, !videoUrl.isEmpty {
            videoPlayerView?.totalDuration = nil
            completeCurVideoDuration = complete
        }else {
            complete?(APP_CONFIG.DURATION_PLAY_PHOTO)
        }
    }
    

}

//MARK: - Backend APIs

extension WatchLiveMomentsVC {
    // delete Live moment
    func deleteLiveMomentApi() {
        let dict = ["eventId" : curUserMoments?.eventID ?? "",
                    "liveMommentsId": curLiveMoment?._id ?? ""]
        self.showLoader()
        LIVE_MOMENT_SERVICE.deleteLiveMomentsApi(dict).done { (response) -> Void in
            self.hideLoader()
            self.getLiveMomments()
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    // get live moments
    func getLiveMomments() {
        var dict = ["pageNo": "1",
                    "count": "100" ] as [String : Any]
        
        if let eventId = eventID {
            dict["eventId"] = eventId
        }
        if let userId = userId {
            dict["userId"] = userId
        }
        if let liveMomentId = liveMomentId {
            dict["liveMomentId"] = liveMomentId
        }

        self.showLoader()
        LIVE_MOMENT_SERVICE.getLiveMomments(dict).done { (response) -> Void in
            self.hideLoader()
            self.updateData(list: response)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }


}

// MARK: - Options Menu
extension WatchLiveMomentsVC: OptionsMenuManagerDelegate {
    
    func didSelectedMenuItem(titleItem: String?, data: Any?) {
        switch titleItem {
        case "Report":
            reportLiveMoment()
            break
        case "Delete":
            actionDeleteBtn(self)
            break
        default :
            break
        }

    }
}

// MARK -
extension WatchLiveMomentsVC : ExpandableLabelDelegate {
    func willExpandLabel(_ label: ExpandableLabel) {
        updateCaptionText(curLiveMoment?.media, heightLimit: 220.0)
        playPause(isPause: true)
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        updateCaptionText(curLiveMoment?.media, heightLimit: 66.0)
    }
}



// MARK: - PlansPlayerView - BMPlayerDelegate

extension WatchLiveMomentsVC: BMPlayerDelegate {
    func bmPlayer(player: BMPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        videoPlayerView?.totalDuration = totalDuration
    }
    func bmPlayer(player: BMPlayer, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
    }
    func bmPlayer(player: BMPlayer, playerOrientChanged isFullscreen: Bool) {
    }

    func bmPlayer(player: BMPlayer, playerStateDidChange state: BMPlayerState) {
        if curStatus == .videoPause || curStatus == .videoPlaying {
            print("playerStateDidChange state: ", state)
            switch state {
            case .error:
                hideLoader()
                videoPlayerView.resetVideo()
                break
            case .notSetURL:
                hideLoader()
                break
            case .buffering:
                if tutorialView.isHidden == true {
                    showLoader()
                }
                break
            case .bufferFinished:
                hideLoader()
                completeCurVideoDuration?(videoPlayerView?.totalDuration)
                break
            case .readyToPlay:
                break
            case .playedToTheEnd:
                actionSwipeLeft(self)
                break
            }
        }

    }

    func bmPlayer(player: BMPlayer, playerIsPlaying playing: Bool) {
        if curStatus == .videoPause || curStatus == .videoPlaying {
            SPB?.isPaused = !playing
        }
    }
    
}
