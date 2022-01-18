//
//  PostCommentBaseVC.swift
//  Plans
//
//  Created by Star on 2/14/21.
//

import UIKit

// ViewController related to Post and Comment
// PostCommentBaseVC -> EventBaseVC -> PlansContentBaseVC -> PlansBaseVC -> BaseViewController -> UIViewController
// Event actions

class PostCommentBaseVC: EventBaseVC {

    var postID: String?
    var postDetail: PostModel?

    override func initializeData() {
        super.initializeData()
        postID = postID ?? postDetail?._id
        getEventDetails(eventID)
    }

}

// MARK: - Post, Comments
extension PostCommentBaseVC {
    // Add new comment
    func addComment(comment: String?) {
        guard let text = comment?.trimmingCharacters(in: .whitespaces) else { return }
        guard let postId = postID, let eventId = eventID else { return }

        let dict = ["postId": postId,
                    "eventId": eventId,
                    "commentText": text] as [String : Any]
        showLoader()
        POSTS_SERVICE.hitCreateComment(dict as! [String : String]).done { (response) -> Void in
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    func shareContent(content: PostModel?) {
        guard let content = content else { return }
        APP_MANAGER.sharePost(post: content, event: activeEvent, postParent: postDetail, sender: self)
    }
    
    func download(content: PostModel?) {
        guard let type = content?.type, let url = content?.urlMedia else { return }
        FILE_CENTER.downloadMediaToPhotosAlbum(url: url, type: type)
    }
    
    func reportPost(content: PostModel?) {
        guard let content = content else { return }
        let message = content.isComment == true ? ConstantTexts.reportComment.localizedString : ConstantTexts.reportPost.localizedString
        let _ = showPlansAlertYesNo(message: message,
                            actionYes: {
                                guard let id = content._id, let type = content.isComment == true ? "comment" : "post" else { return }
                                self.reportEntity(id: id, type: type)
        }, blurEnabled: true)
    }
    
    func deleteContent(content: PostModel?) {
        guard let content = content else { return }
        let message = content.isComment == true ? ConstantTexts.deleteComment.localizedString : ConstantTexts.deletePost.localizedString
        let _ = showPlansAlertYesNo(message: message,
                            actionYes: {
                                if content.isComment == true{
                                    self.deleteComment(comment: content)
                                }else {
                                    self.deletePost(post: content)
                                }
        }, blurEnabled: true)
    }
    
    // Delete Comment
    func deleteComment(comment: PostModel?) {
        guard let commentId = comment?._id,
              let eventId = activeEvent?._id,
              let postId = postID else { return }

        let dict = ["commentId": commentId,
                    "eventId": eventId,
                    "postId": postId] as [String : Any]

        showLoader()
        POSTS_SERVICE.deleteComment(dict).done { (response) -> Void in
            self.hideLoader()
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    // Delete Post
    func deletePost(post: PostModel?) {
        guard let eventId = activeEvent?._id,
              let postId = post?._id else { return }

        let dict = ["postId": postId,
                    "eventId": eventId]

        showLoader()
        POSTS_SERVICE.deletePost(dict).done { (response) -> Void in
            self.hideLoader()
            if let msg = response.message,
                msg != "" {
                self.navigationController?.popViewController(animated: true)
            }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    // Like Comment
    func likeComment(comment: PostModel?, isLike: Bool) {

        guard let id = comment?._id,
              let postId = postID,
              let eventId = eventID else { return }
        
        let dict = ["commentId": id,
                    "postId": postId,
                    "eventId": eventId,
                    "isLike": "\(isLike)"] as [String : Any]

        showLoader()
        POSTS_SERVICE.hitLikeComment(dict).done { (response) -> Void in
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }



}

// MARK: - Options Menu
extension PostCommentBaseVC {
    func processPostMenuAction(titleAction: String?, post: PostModel?) -> Bool {
        var result = false
        guard let post = post else { return result }
        
        result = true

        switch titleAction {
        case "Share":
            shareContent(content: post)
            break
        case "Download":
            download(content: post)
            break
        case "Report":
            reportPost(content: post)
            break
        case "Delete":
            deleteContent(content: post)
            break
            
        default:
            result = false
            break
        }

        return result
    }

}

