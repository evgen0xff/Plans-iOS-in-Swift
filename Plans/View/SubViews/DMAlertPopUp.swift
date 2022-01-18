//
//  DMAlertPopUp.swift
//  DataMaster
//
//  Created by Star on 5/28/19.
//  Copyright © 2019 wagnermeters. All rights reserved.
//

import UIKit
import PopupDialog


class DMAlertPopUp: UIViewController {

    // MARK:- IBOutlets

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var btnNo: UIButton!
    @IBOutlet weak var btnYes: UIButton!
    @IBOutlet weak var btnOK: UIButton!
    @IBOutlet weak var viewImage: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var heightContentView: NSLayoutConstraint!
    
    // MARK:- Properties

    var titleMsg : String?
    var fontTitle: UIFont?
    var fontMsg: UIFont?
    var image: UIImage?
    var urlImage: String?
    var message : String?
    var attributedMsg: String?
    var titleBtnOk : String?
    var titleBtnNo : String?
    var titleBtnYes : String?
    var actionOk: (() -> Void)?
    var actionNo: (() -> Void)?
    var actionYes: (() -> Void)?
    var actionComplete: (() -> Void)?
    var colorYesBtn: UIColor?

    // MARK:- ViewController Life Cycles

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.clipsToBounds = true
        
        setupUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK:- User Actions
    
    @IBAction func actionOK(_ sender: Any) {
        if let parent = parent as? PopupDialog {
            parent.dismiss(actionOk)
        }else {
            parent?.dismiss(animated: true, completion: actionOk)
        }
        actionComplete?()
    }
    @IBAction func actionNo(_ sender: Any) {
        if let parent = parent as? PopupDialog {
            parent.dismiss(actionNo)
        }else {
            parent?.dismiss(animated: true, completion: actionNo)
        }
        actionComplete?()
    }
    @IBAction func actionYes(_ sender: Any) {
        if let parent = parent as? PopupDialog {
            parent.dismiss(actionYes)
        }else {
            parent?.dismiss(animated: true, completion: actionYes)
        }
        actionComplete?()
    }
    
    // MARK: - Private Methods

    func setupUI() {
        // Title
        lblTitle.text = titleMsg ?? ""
        if let font = fontTitle {
            lblTitle.font = font
        }
        if lblTitle.text == "" {
            lblTitle.isHidden = true
        }else {
            lblTitle.isHidden = false
        }
        
        // Image
        if image != nil  {
            viewImage.isHidden = false
            imageView.image = image
        }else if urlImage != nil{
            viewImage.isHidden = false
            imageView?.setUserImage(urlImage)
        }else {
            viewImage.isHidden = true
        }
        
        // Message
        lblMessage.text = message ?? ""
        if let font = fontMsg {
            lblMessage.font = font
        }
        if attributedMsg != nil {
            lblMessage.attributedText = attributedMsg?.set(style: AppLabelStyleGroup.alert)
        }

        // Buttons
        if let title = titleBtnOk {
            btnOK.setTitle(title, for: .normal)
        }
        if let title = titleBtnNo {
            btnNo.setTitle(title, for: .normal)
        }
        if let title = titleBtnYes {
            btnYes.setTitle(title, for: .normal)
        }

        btnOK.isHidden = true
        btnNo.isHidden = true
        btnYes.isHidden = true
        btnYes.backgroundColor = colorYesBtn ?? AppColor.teal_main
        
        // Actions
        if let _ = actionOk {
            btnOK.isHidden = false
            btnNo.isHidden = true
            btnYes.isHidden = true
        }
        if let _ = actionYes {
            btnOK.isHidden = true
            btnNo.isHidden = false
            btnYes.isHidden = false
        }
        if let _ = actionNo {
            btnOK.isHidden = true
            btnNo.isHidden = false
            btnYes.isHidden = false
        }
        
        if btnNo.isHidden == true, btnYes.isHidden == true {
            btnOK.isHidden = false
        }
        
        updateContentHeight()
    }
    
    func updateContentHeight() {
        // Title Height
        var height = lblTitle.isHidden == false ? ( lblTitle?.text?.height(withConstrainedWidth: 240, font: AppFont.regular.size(13.0)) ?? 0) : 0

        // Image Height
        height += viewImage.isHidden == false ? 40 : 0

        // Message Height
        height += lblMessage.isHidden == false ? (lblMessage?.text?.height(withConstrainedWidth: 240, font: AppFont.regular.size(13.0)) ?? 0) : 0
        
        // Ok/Yes/No Button and Padding Length
        height += 10 + 45 + 70
        
        heightContentView.constant = height
        view.bounds.size.height = heightContentView.constant
        view.sizeToFit()
    }
    
}
