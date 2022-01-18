//
//  EventDetailViewController.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/14/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import GrowingTextView

class EventDetailsVC: EventBaseVC {
    
    enum SectionType {
        case cover
        case hostInfo
        case dateLocation
        case optionAction
        case liveMoment
        case people
        case post
    }
    
    // MARK: - IBOutlets
    @IBOutlet weak var viewTopNaviBar: UIView!
    @IBOutlet weak var lblEventName: UILabel!
    @IBOutlet weak var viewNonLoaded: UIView!
    @IBOutlet weak var heigthLoadingEventCoverImage: NSLayoutConstraint!
    @IBOutlet weak var tblvEventDetails: UITableView!
    @IBOutlet weak var viewPosting: UIView!
    @IBOutlet weak var viewPostingMedia: UIView!
    @IBOutlet weak var viewPostingMessage: UIView!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var imgviewUserProfile: UIImageView!
    @IBOutlet weak var txtvMessage: GrowingTextView!
    @IBOutlet weak var imgviewMedia: UIImageView!
    @IBOutlet weak var imgviewPlay: UIImageView!
    @IBOutlet weak var bottomMarginContent: NSLayoutConstraint!
    
    @IBOutlet weak var viewGuideAddEventPosts: UIView!
    // MARK: - Properties
    var sections = [SectionType]()
    var eventPost = [PostModel]()
    var pageNumber = 1
    var cellHeights = [IndexPath: CGFloat]()
    var imageMedia: UIImage?
    var urlVideo: URL?
    override var screenName: String? { "Event_Screen" }

    // MARK: - ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SOCKET_MANAGER.getChatList()
    }
    
    override func setupUI() {
        heigthLoadingEventCoverImage.constant = (MAIN_SCREEN_WIDTH * 2.0 / 3.0) + (UIDevice.current.hasTopNotch ? UIDevice.current.heightTopNotch : 0)
        viewNonLoaded.isHidden = false
        viewTopNaviBar.isHidden = true
        setupTableView()
        setupPostingUI()
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        hiteventDetailMethod(showLoader: isShowLoader, pageNumber: 1, numberOfRows: pageNumber * 10)
    }
    
    override func hideLoader() {
        super.hideLoader()
        tblvEventDetails.switchRefreshHeader(to: .normal(.success, 0.0))
        tblvEventDetails.switchRefreshFooter(to: .normal)
    }
    
    override func willShowKeyboard(frame: CGRect) {
        bottomMarginContent.constant = frame.height - UIDevice.current.heightBottomNotch
        view.updateConstraintsIfNeeded()
    }
    
    override func willHideKeyboard() {
        bottomMarginContent.constant = 0
        view.updateConstraintsIfNeeded()
    }
    
    // MARK: - User Actions
    @IBAction func actionBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionMenu(_ sender: Any) {
        OPTIONS_MANAGER.showMenu(data: activeEvent, menuType: .eventDetails, delegate: self, sender: self)
    }
    
    @IBAction func actionMediaBtn(_ sender: Any) {
        if urlVideo != nil {
            playVideo(urlVideo?.absoluteString)
        }else {
            APP_MANAGER.openImageVC(image: imageMedia, activeEvent: activeEvent, sender: self)
        }
    }
    
    @IBAction func actionCloseMedia(_ sender: Any) {
        imageMedia = nil
        urlVideo = nil
        updateUI()
    }
    
    @IBAction func actionAttachBtn(_ sender: Any) {
        updateGuideView(isSeen: true)
        MEDIA_PICKER.showCameraGalleryActionSheet(sender: self,
                                                  delegate: self,
                                                  action: .postMedia)
    }
    
    @IBAction func actionSendBtn(_ sender: Any) {
        let text = txtvMessage.text.trimmingCharacters(in: .whitespaces)

        guard text.count > 0 || imageMedia != nil else { return }

        view.endEditing(true)

        let post = EventModel()
        post.eventID = activeEvent?._id
        post.postText = text
        
        if imageMedia == nil {
            createPostWithText(eventModel: post)
        }else if urlVideo != nil {
            post.mediaType = "video"
            createPostWithMedia(eventModel: post, uploadImage: nil, videoUrl: urlVideo)
        }else if imageMedia != nil {
            post.mediaType = "image"
            createPostWithMedia(eventModel: post, uploadImage: imageMedia, videoUrl: nil)
        }
        
        txtvMessage.text = ""
        imageMedia = nil
        urlVideo = nil
        updateUI()
    }
    
    @IBAction func actionGuideAddEventPosts(_ sender: Any) {
        updateGuideView(isSeen: true)
    }
    
    // MARK: - Private Methods
    private func setupTableView() {
        if #available(iOS 15.0, *) {
            tblvEventDetails.sectionHeaderTopPadding = 0.0
        }
        tblvEventDetails.registerMultiple(nibs: [HomeFeedImageCell.className,
                                                 HomeFeedCell.className,
                                                 DateLocationCell.className,
                                                 PostCommentCell.className,
                                                 SectionHeaderCell.className,
                                                 EventOptionsCell.className,
                                                 LiveMomentsCell.className,
                                                 PeopleTableCell.className])
        tblvEventDetails.dataSource = self
        tblvEventDetails.delegate = self
        refreshHeader.isUnderStatusBar = true
        
        tblvEventDetails.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            self?.refreshAll()
        }
        
        tblvEventDetails.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.eventPost.count % 10 == 0, this.eventPost.count != 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }
    }
    
    func setupPostingUI() {
        viewPosting.layer.shadowColor = UIColor.black.cgColor
        viewPosting.layer.shadowOpacity = 0.5
        viewPosting.layer.shadowOffset = CGSize.zero
        viewPosting.layer.shadowRadius = 5
        txtvMessage.delegate = self
    }
    
    func getNextPage(isShowLoader: Bool = false) {
        pageNumber = eventPost.count / 10 + ((eventPost.count % 10) > 0 ? 1 : 0) + 1
        hiteventDetailMethod(showLoader: isShowLoader, pageNumber: pageNumber)
    }
    
    func updateData(event: EventFeedModel?, pageNumber: Int = 1, numberOfRows: Int = 10) {
        guard let event = event else { return }
        guard event.isEnableToShow(userId: USER_MANAGER.userId) else {
            actionBack(self)
            return
        }

        activeEvent = event
        if pageNumber == 1 { eventPost.removeAll() }
        eventPost.replace(arrPage: event.post, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)
        APP_CONFIG.defautMainQ.async {
            if event.isActive == true {
                self.updateSections()
                self.updateUI()
            }else {
                self.actionBack(self)
            }
        }
    }
    
    func updateSections() {
        sections.removeAll()
        sections.append(contentsOf: [.cover, .hostInfo, .dateLocation, .optionAction])
        if activeEvent?.isEnableAddLiveMoment() == true || (activeEvent?.liveMommentsCount != nil && activeEvent!.liveMommentsCount! > 0) {
            sections.append(.liveMoment)
        }
        if let count = activeEvent?.invitationDetails?.count, count > 0 {
            sections.append(.people)
        }
        if eventPost.count > 0 {
            sections.append(.post)
        }
    }
    
    func updateUI() {
        lblEventName.text = activeEvent?.eventName
        viewNonLoaded.isHidden = activeEvent != nil

        updatePostingUI()
        tblvEventDetails.reloadData()
        checkFirstTimeViewing(event: activeEvent)
    }
    
    func updatePostingUI (isHidden : Bool = false) {
        viewPostingMedia.isHidden = imageMedia == nil
        imgviewMedia.image = imageMedia
        imgviewPlay.isHidden = urlVideo == nil
        imgviewUserProfile.setUserImage(USER_MANAGER.profileUrl)
        
        let msg = txtvMessage.text?.trimmingCharacters(in: .whitespaces)
        btnSend.isSelected = !viewPostingMedia.isHidden || msg?.count != 0
        
        if activeEvent?.isPostingForMe() == true {
            viewPosting.isHidden = isHidden
        } else {
            viewPosting.isHidden = true
        }

        if viewPosting.isHidden == true {
            view.endEditing(true)
        }
        
        updateGuideView()
    }
    
    func updateGuideView(isSeen: Bool? = nil) {
 
        if let isSeen = isSeen {
            USER_MANAGER.isSeenGuideAddEventPosts = isSeen
        }
        
        if viewPosting.isHidden == false, USER_MANAGER.isSeenGuideAddEventPosts == false {
            viewGuideAddEventPosts.isHidden = false
        }else {
            viewGuideAddEventPosts.isHidden = true
        }
    }

    
    func checkFirstTimeViewing(event: EventFeedModel?) {
        guard let isViewed = event?.isViewed, isViewed == false, USER_MANAGER.userId == event?.userId else { return }
        APP_MANAGER.presentInviteByLinkVC(event: event, sender: self)
    }
        
}


// MARK: - BackEnd Method
extension EventDetailsVC {
    func hiteventDetailMethod(showLoader: Bool,
                                    pageNumber: Int = 1,
                                    numberOfRows: Int = 10) {
        if showLoader {
            self.showLoader()
        }
        
        EVENT_SERVICE.getEventDetail(eventID ?? "", pageNumber: pageNumber, numberOfRows: numberOfRows).done { (response) -> Void in
            self.hideLoader()
            self.updateData(event: response, pageNumber: pageNumber, numberOfRows: numberOfRows)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
}

// MARK: UIScrollViewDelegate
extension EventDetailsVC : UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView){
        if scrollView.contentOffset.y < 170 {
            viewTopNaviBar.isHidden = true
        } else {
            viewTopNaviBar.isHidden = false
        }
        
        if(scrollView.panGestureRecognizer.translation(in: scrollView.superview).y < 0) {
            updatePostingUI(isHidden: true)
        } else {
            updatePostingUI(isHidden: false)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updatePostingUI(isHidden: false)
    }
}


// MARK: - UITableViewDataSource

extension EventDetailsVC: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sections[section] == .post {
            return eventPost.count
        }else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch sections[indexPath.section] {
            case .cover:        return getEventCoverCell(indexPath, tableView: tableView)
            case .hostInfo:     return getEventHostCell(indexPath, tableView: tableView)
            case .dateLocation: return getDateLocationCell(indexPath, tableView: tableView)
            case .optionAction: return getEventOptionsCell(indexPath, tableView: tableView)
            case .liveMoment:   return getLiveMomentsCell(indexPath, tableView: tableView)
            case .people:       return getPeopleCell(indexPath, tableView: tableView)
            case .post:         return getPostCommentCell(indexPath, tableView: tableView)
        }
    }
    
    private func getEventCoverCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedImageCell.className, for: indexPath) as? HomeFeedImageCell else {
            return UITableViewCell()
        }
        cell.configureHomeCell(eventModel: activeEvent, cellType: .overTop)
        return cell
    }
    
    private func getEventHostCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeFeedCell.className, for: indexPath) as? HomeFeedCell else {
            return UITableViewCell()
        }
        cell.setupUI(eventModel: activeEvent, delegate: self, cellType: .eventDetails)
        return cell
    }

    private func getDateLocationCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DateLocationCell.className, for: indexPath) as? DateLocationCell else {
            return UITableViewCell()
        }
        cell.setupUI(eventModel: activeEvent, cellType: .eventDetails)
        return cell
    }

    private func getEventOptionsCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EventOptionsCell.className, for: indexPath) as? EventOptionsCell else {
            return UITableViewCell()
        }
        cell.setupUI(event: activeEvent, delegate: self)
        return cell
    }

    private func getLiveMomentsCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LiveMomentsCell.className, for: indexPath) as? LiveMomentsCell
            else {
                return UITableViewCell()
        }
        let isLast = sections.last == .liveMoment
        cell.setupUI(event: activeEvent, isHiddenSeparator: isLast)
        return cell
    }

    private func getPeopleCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PeopleTableCell.className, for: indexPath) as? PeopleTableCell
            else {
                return UITableViewCell()
        }
        let isLast = sections.last == .people
        cell.setupUI(model: activeEvent, delegate: nil,
                     cellType: .eventDetails,
                     isHiddenSeparator: isLast)
        return cell
    }
    
    private func getPostCommentCell(_ indexPath: IndexPath, tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCommentCell.className, for: indexPath) as? PostCommentCell
            else {
            return UITableViewCell()
        }
        let isLast = indexPath.row == (eventPost.count - 1)
        cell.setupUI(post: eventPost[indexPath.row],
                     event: activeEvent,
                     isHiddenSeparator: isLast)
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension EventDetailsVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[indexPath.section] == .post {
            APP_MANAGER.pushPostCommentVC(eventId: eventID, postId: eventPost[indexPath.row]._id, sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var header: UIView? = nil
        if sections[section] == .post {
            if let cell = tableView.dequeueReusableCell(withIdentifier: SectionHeaderCell.className) as? SectionHeaderCell {
                cell.setupUI(title: "Posts", cellType: .eventDetails)
                header = cell
            }
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sections[section] == .post ? 26.0 : 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }
}

// MARK: - EventOptionsCellDelegate
extension EventDetailsVC: EventOptionsCellDelegate {
    
    func eventOptions(didEdit event: EventFeedModel?) {
        APP_MANAGER.pushEditEventVC(event: event, isDuplicate: false, sender: self)

    }
    
    func eventOptions(didInvite event: EventFeedModel?) {
        APP_MANAGER.pushEditInvitationVC(editMode: .edit, selectedUsers: activeEvent?.getInvitedPeople(), sender: self)
    }
    
    func eventOptions(didDetails event: EventFeedModel?) {
        APP_MANAGER.pushDetailsOfEventVC(event: event, sender: self)
    }
    
    func eventOptions(didChat event: EventFeedModel?) {
        APP_MANAGER.pushChatMessageVC(event: event, sender: self )
    }
    
    func eventOptions(didGuestAction actionName: String?, event: EventFeedModel?) {
        switch actionName {
        case "Join" :
            joinEvent(model: activeEvent)
            break
        case "Joined" :
            OPTIONS_MANAGER.showMenu(data: activeEvent, menuType: .eventJoin, delegate: self, sender: self)
            break
        case "You're Here", "Not Here":
            OPTIONS_MANAGER.showMenu(data: activeEvent, menuType: .eventLeave, delegate: self, sender: self)
            break
        case "Going", "Maybe", "Next Time", "Pending Invite" :
            OPTIONS_MANAGER.showMenu(data: activeEvent, menuType: .eventPending, delegate: self, sender: self)
            break
        default:
            break
        }
    }

    
}


// MARK: - OptionsMenuManagerDelegate

extension EventDetailsVC: OptionsMenuManagerDelegate {
    func didSelectedMenuItem(titleItem: String?, data: Any?) {
        guard let event = (data as? EventFeedModel), let titleAction = titleItem else { return }
        if processEventMenuAction(titleAction: titleAction, event: event) == false {
            print("Not handled Menu Action : ", titleAction)
        }
    }
}

//MARK: - HomeFeedCellDelegate
extension EventDetailsVC : HomeFeedCellDelegate {
    func didTappedProfile(eventModel: EventFeedModel?) {
        APP_MANAGER.pushUserProfileVC(userId: eventModel?.eventCreatedBy?.userId, sender: self)
    }
}


// MARK: - MediaPickerDelegate
extension EventDetailsVC : MediaPickerDelegate {
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenImage image: UIImage?) {
        urlVideo = nil
        imageMedia = image
        updateUI()
    }
    
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenVideo outputFileURL: URL?, previewImage: UIImage?) {
        imageMedia = previewImage
        urlVideo = outputFileURL
        updateUI()
    }
}

extension EventDetailsVC: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateGuideView(isSeen: true)
        updateUI()
    }
}







