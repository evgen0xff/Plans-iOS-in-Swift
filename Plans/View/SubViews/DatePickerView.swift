//
//  DatePickerView.swift
//
//  Created by Star on 1/25/21.
//  Copyright © 2021 Plans Collective. All rights reserved.
//

import UIKit

protocol DatePickerViewDelegate {
    func datePickerView(_ pickerView: UIView, didSelected selectedDate: Date)
    func datePickerView(_ pickerView: UIView, didDone selectedDate: Date)
    func datePickerView(_ pickerView: UIView, didCancel selectedDate: Date)
}

extension DatePickerViewDelegate {
    func datePickerView(_ pickerView: UIView, didSelected selectedDate: Date){}
    func datePickerView(_ pickerView: UIView, didDone selectedDate: Date){}
    func datePickerView(_ pickerView: UIView, didCancel selectedDate: Date){}
}

let DATE_PICKER = DatePickerView.share

class DatePickerView: UIView {

    // MARK: - Variables
    static let share: DatePickerView = DatePickerView(frame: CGRect(x: 0.0, y: MAIN_SCREEN_HEIGHT - 260 , width: MAIN_SCREEN_WIDTH, height: 260.0))

    // MARK: - Outlets
    @IBOutlet weak var datepicker: UIDatePicker!
    
    var delegate: DatePickerViewDelegate?

    var date: Date {
        get {
            return datepicker?.date ?? Date()
        }
        set {
            datepicker?.date = newValue
        }
    }
    
    var datePickerMode: UIDatePicker.Mode {
        get {
            return datepicker?.datePickerMode ?? .date
        }
        set {
            datepicker?.datePickerMode = newValue
        }
    }

    var minimumDate: Date? {
        get {
            return datepicker?.minimumDate
        }
        set {
            datepicker?.minimumDate = newValue
        }
    }

    var maximumDate: Date? {
        get {
            return datepicker?.maximumDate
        }
        set {
            datepicker?.maximumDate = newValue
        }
    }

    // MARK: - Life Cycle Methods
    override init(frame: CGRect){
        super.init(frame: frame)
        self.initializeFromNib()
    }
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        self.initializeFromNib()
    }
    
    // MARK: - Private Methods
    private func initializeFromNib(){
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "DatePickerView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(view)
        
        datepicker.calendar = Calendar.current
        datepicker.timeZone = Calendar.current.timeZone
        datepicker.locale = Calendar.current.locale
    }
    
    
    // MARK: - IBAction
    @IBAction func doneButtonAction(_ sender: Any) {
        if delegate != nil {
            delegate?.datePickerView(self, didDone: date)
        }else {
            removeFromSuperview()
        }
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        if delegate != nil {
            delegate?.datePickerView(self, didCancel: date)
        }else {
            removeFromSuperview()
        }
    }
    
    @IBAction func actionChangedDate(_ sender: UIDatePicker) {
        delegate?.datePickerView(self, didSelected: date)
    }
}


