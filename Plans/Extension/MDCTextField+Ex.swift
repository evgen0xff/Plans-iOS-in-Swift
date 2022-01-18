//
//  MDCTextField+Ex.swift
//  Plans
//
//  Created by Star on 1/30/21.
//

import Foundation
import MaterialComponents

extension MDCTextInput {
    func addCheckMark(imgCheck: String,
                      mode: UITextField.ViewMode = .never,
                      tintColor: UIColor = .white) {
        let checkMark = UIImageView(image: UIImage(named: imgCheck))
        trailingView = checkMark
        trailingViewMode = mode
        clearButton.tintColor = tintColor
    }
    
    func addClearBtn(image: String,
                      mode: UITextField.ViewMode? = nil,
                      tintColor: UIColor? = .clear) {
        clearButton.setBackgroundImage(UIImage(named: image), for: .normal)
        clearButtonMode = mode ?? clearButtonMode
        clearButton.tintColor = tintColor
    }
    
    func addTrailingView(imgCheck: String? = nil,
                         titleAction: String? = nil,
                         colorActionTitle: UIColor? = nil,
                         taget: Any? = nil,
                         action: Selector? = nil) {
        
        var imgView: UIImageView?
        var actionBtn: UIButton?
        let stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: 45, height: 35))
        stackView.axis = .horizontal
        stackView.spacing = 15.0
        
        if let name = imgCheck, let image = UIImage(named: name)  {
            imgView = UIImageView(image: image)
            imgView?.contentMode = .scaleAspectFit
            stackView.addArrangedSubview(imgView!)
        }
        
        if let titleAction = titleAction {
            actionBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 35))
            actionBtn?.setTitle(titleAction, for: .normal)
            actionBtn?.setTitleColor(colorActionTitle ?? self.cursorColor, for: .normal)
            actionBtn?.titleLabel?.font = AppFont.regular.size(17.0)
            if let taget = taget, let action = action {
                actionBtn?.addTarget(taget, action:action, for: .touchUpInside)
            }
            stackView.addArrangedSubview(actionBtn!)
        }
        
        if stackView.arrangedSubviews.count > 0 {
            trailingView = stackView
            trailingViewMode = .always
            clearButtonMode = .never
        }
        
        return
    }
    

}

extension MDCTextField {
    func addShowHideForSecureText (_ taget: Any? = nil, action: Selector? = nil) {
        let showBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 45, height: 35))
        if isSecureTextEntry == true {
            showBtn.setTitle("Show", for: .normal)
        }else {
            showBtn.setTitle("Hide", for: .normal)
        }
        showBtn.setTitleColor(.white, for: .normal)
        showBtn.titleLabel?.font = AppFont.regular.size(17.0)
        showBtn.addTarget(taget ?? self, action:action ?? #selector(actionShowHide), for: .touchUpInside)
        trailingView = showBtn
        trailingViewMode = .always
        clearButtonMode = .never
    }
    
    @objc func actionShowHide(_ sender: UIButton) {
        if isSecureTextEntry == true {
            isSecureTextEntry = false
            sender.setTitle("Hide", for: .normal)
        }else {
            isSecureTextEntry = true
            sender.setTitle("Show", for: .normal)
        }
        layoutSubviews()
    }
    
}
