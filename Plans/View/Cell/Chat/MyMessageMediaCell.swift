//
//  MyMessageMediaCell.swift
//  Plans
//
//  Created by Star on 3/3/21.
//

import UIKit

class MyMessageMediaCell: MessageBaseCell {
    
    @IBOutlet weak var imgvMedia: UIImageView!
    @IBOutlet weak var viewVideo: PlansVideoPlayerView!
    @IBOutlet weak var viewLoading: PlansIndicatorView!
    @IBOutlet weak var viewTime: UIView!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var viewSendMark: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        viewVideo.typeUI = .postComment
        viewLoading.isHidden = true
        viewLoading.stopAnimating()
    }
    
    override func setupUI(message: MessageModel?, chat: ChatModel? = nil) {
        super.setupUI(message: message, chat: chat)

        if message?._id != nil {
            viewLoading.isHidden = true
            viewLoading.stopAnimating()
            viewSendMark.isHidden = true
            viewTime.isHidden = false
        }else {
            viewLoading.isHidden = false
            viewLoading.startAnimating()
            viewSendMark.isHidden = false
            viewTime.isHidden = true
        }
        
        if let videoUrl = message?.videoFile, !videoUrl.isEmpty {
            viewVideo.isHidden = false
            viewVideo.setVideo(videoUrl, message?.imageUrl)
        }else {
            viewVideo.isHidden = true
            if let image = message?.image {
                imgvMedia.image = image
            }else {
                imgvMedia.setEventImage(message?.imageUrl)
            }
        }
        
        if let createdAt = message?.createdAt {
            lblTime.text = Date(timeIntervalSince1970: createdAt).dateStringWith(strFormat: "h:mm a")
        }
        
    }

    
    @IBAction func actionTapMedia(_ sender: Any) {
        guard let model = message else { return }
        if model.type == .video {
            APP_MANAGER.playVideo(model.videoFile)
        }else if model.type == .image {
            APP_MANAGER.openImageVC(imgStr: model.imageUrl)
        }
    }

}
