//
//  TimerRingButton.swift
//  Plans
//
//  Created by Star on 1/27/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit

@objc protocol TimerRingButtonDelegate {
    @objc optional func didTapped () -> Void
    @objc optional func didTimerStarted() -> Void
    @objc optional func didTimerEnded() -> Void
}

class TimerRingButton: UIView {

    enum TimerMode {
        case none
        case start
        case stop
    }
   
    
    public var delegate : TimerRingButtonDelegate?
    public var timeInterval : TimeInterval = 30
    public var enableLongPressGesture = true
    public var enableTapGesture = true
    
    public var timerMode : TimerMode = .none {
        didSet {
            switch timerMode {
            case .start:
                self.startTimer()
                break
            case .stop:
                self.stopTimer()
                break
            default:
                self.endAngle = 0.0
                break
            }
            setNeedsDisplay()
        }
    }
    
    private var timer : Timer?
    private var endAngle : CGFloat = 0.0

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        let tapGesture :UITapGestureRecognizer = {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureMethod(_:)))
            gesture.numberOfTapsRequired = 1
            return gesture
        }()
        
        let longPressGesture :UILongPressGestureRecognizer = {
            let longG = UILongPressGestureRecognizer(target: self, action: #selector(longGestureMethod(_:)))
            longG.minimumPressDuration = 0.2
            return longG
        }()
        self.addGestureRecognizer(tapGesture)
        self.addGestureRecognizer(longPressGesture)
    }
    
    @objc func tapGestureMethod(_ sender: UITapGestureRecognizer) {
        guard enableTapGesture else { return }
        delegate?.didTapped?()
    }

    @objc private func longGestureMethod(_ sender: UILongPressGestureRecognizer) {
        
        guard enableLongPressGesture else { return }
        
        switch sender.state {
        case .began:
            timerMode = .start
            delegate?.didTimerStarted?()
            break
            
        case .ended:
            timerMode = .stop
            delegate?.didTimerEnded?()
            break
            
        default:
            break
        }
    }

    func startTimer () {
        timer?.invalidate()
        timer = nil
        self.endAngle = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval / 360.0, repeats: true, block: { (timer) in
            self.endAngle += 1
            if self.endAngle > 360 {
                self.timerMode = .stop
                self.delegate?.didTimerEnded?()
            }else {
                self.setNeedsDisplay()
            }
        })
    }
    
    func stopTimer () {
        timer?.invalidate()
        timer = nil
        timerMode = .none
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        layer.sublayers?.removeAll()
        
        switch timerMode {
        case .start, .stop:
            drawCircleFilled(radiusPercent: 50, color: .white)
            drawRing(radiusPercent: 100, color: .white, widthRing: 4)
            drawRingShapeWithGradient(startAngle: 0,
                                      endAngle: endAngle,
                                      radiusPercent: 100,
                                      colorLeft: AppColor.teal_main,
                                      colorRight: AppColor.teal_main,
                                      widthRing: 4)
            break
        default :
            drawCircleFilled(radiusPercent: 50, color: .white)
            drawRing(radiusPercent: 60, color: .white, widthRing: 3)
            break

        }

    }

}
