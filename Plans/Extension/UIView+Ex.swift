//
//  UIView+Additions.swift
//  Plans
//
//  Created by Star on 1/27/20.
//  Copyright © 2020 PlansCollective. All rights reserved.
//

import UIKit

extension UIView {
    
    class func fromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
    
    /** This is the function to get subViews of a view of a particular type
*/
    func subViews<T : UIView>(type : T.Type) -> [T]{
        var all = [T]()
        for view in self.subviews {
            if let aView = view as? T{
                all.append(aView)
            }
        }
        return all
    }


/** This is a function to get subViews of a particular type from view recursively. It would look recursively in all subviews and return back the subviews of the type T */
    func allSubViewsOf<T : UIView>(type : T.Type) -> [T]{
        var all = [T]()
        func getSubview(view: UIView) {
            if let aView = view as? T{
            all.append(aView)
            }
            guard view.subviews.count>0 else { return }
            view.subviews.forEach{ getSubview(view: $0) }
        }
        getSubview(view: self)
        return all
    }

    func drawRingShape(startAngle: CGFloat,
                      endAngle: CGFloat,
                      radiusPercent: CGFloat,
                      color : UIColor,
                      widthRing: CGFloat)
    {
        let halfSize:CGFloat = min( bounds.size.width/2.0, bounds.size.height/2.0)
        let centerPoint = CGPoint(x: halfSize, y: halfSize)
        let startValue = (startAngle * 2 * CGFloat(Float.pi)) / 360.0 - CGFloat(Float.pi / 2)
        let endValue = (endAngle * 2 * CGFloat(Float.pi)) / 360.0 - CGFloat(Float.pi / 2)
        var percent = radiusPercent
        if radiusPercent > 100 {
            percent = 100
        }else if radiusPercent < 0 {
            percent = 0
        }

        let radius = halfSize * percent / 100.0 - widthRing / 2.0
        
        let path = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: startValue, endAngle: endValue, clockwise: true)
        
        let fanLayer = CAShapeLayer()
        fanLayer.path = path.cgPath
        fanLayer.fillColor = UIColor.clear.cgColor
        fanLayer.strokeColor = color.cgColor
        fanLayer.lineWidth = widthRing
        
        layer.addSublayer(fanLayer)
    }

    func drawRingShapeWithGradient(startAngle: CGFloat,
                      endAngle: CGFloat,
                      radiusPercent: CGFloat,
                      colorLeft : UIColor,
                      colorRight : UIColor,
                      widthRing: CGFloat)
    {
        let halfSize:CGFloat = min( bounds.size.width/2.0, bounds.size.height/2.0)
        let centerPoint = CGPoint(x: halfSize, y: halfSize)
        let startValue = (startAngle * 2 * CGFloat(Float.pi)) / 360.0 - CGFloat(Float.pi / 2)
        let endValue = (endAngle * 2 * CGFloat(Float.pi)) / 360.0 - CGFloat(Float.pi / 2)
        var percent = radiusPercent
        if radiusPercent > 100 {
            percent = 100
        }else if radiusPercent < 0 {
            percent = 0
        }

        let radius = halfSize * percent / 100.0 - widthRing / 2.0
        
        let path = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: startValue, endAngle: endValue, clockwise: true)
        
        let fanLayer = CAShapeLayer()
        fanLayer.path = path.cgPath
        fanLayer.fillColor = UIColor.clear.cgColor
        fanLayer.strokeColor = UIColor.white.cgColor
        fanLayer.lineWidth = widthRing
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.mask = fanLayer
        gradientLayer.frame = bounds
        gradientLayer.colors = [colorLeft.cgColor, colorRight.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.locations = [0.0, 0.85]

        layer.addSublayer(gradientLayer)
    }

    
    func drawCircleFilled (radiusPercent : CGFloat, color : UIColor) {
        let halfSize:CGFloat = min( bounds.size.width/2, bounds.size.height/2)
        
        var percent = radiusPercent
        if radiusPercent > 100 {
            percent = 100
        }else if radiusPercent < 0 {
            percent = 0
        }

        let radius = halfSize * percent / 100.0

        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x:halfSize,y:halfSize),
            radius: radius,
            startAngle: CGFloat(0),
            endAngle:CGFloat(Float.pi * 2),
            clockwise: true)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = color.cgColor
        shapeLayer.backgroundColor = nil

        layer.addSublayer(shapeLayer)
    }
    
    func drawRing (radiusPercent : CGFloat, color : UIColor, widthRing: CGFloat) {

        drawRingShape(startAngle: 0, endAngle: 360, radiusPercent: radiusPercent, color: color, widthRing: widthRing)
    }

    public func addShadow(_ shadowRadius: CGFloat = 2.0,
                          shadowOpacity: Float = 0.2,
                          shadowOffset: CGSize = CGSize(width: 0, height: 2.0)) {
        self.layer.masksToBounds = false
        self.layer.shadowOffset = shadowOffset
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowColor = UIColor.black.cgColor
    }

    func roundCorners(corners:UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
    
    func fadeIn(_ duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 1.0
        }, completion: completion)  }
    
    func fadeOut(_ duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
        }, completion: completion)
    }

    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius
        
        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    func addHorizontalGradient(colorStart: UIColor, colorEnd: UIColor, width: CGFloat? = nil, height: CGFloat? = nil){
        let gl = CAGradientLayer()
        gl.colors = [colorStart.cgColor, colorEnd.cgColor] as [AnyObject]
        gl.frame = CGRect(x: 0, y: 0, width: width ?? bounds.width, height: height ?? bounds.height)
        gl.startPoint = CGPoint(x: 0, y: 0.5)
        gl.endPoint = CGPoint(x: 1.0, y: 0.5)
        layer.addSublayer(gl)
    }
    
    func addPinkGradient(width: CGFloat? = nil, height: CGFloat? = nil) {
        addHorizontalGradient(colorStart: AppColor.pink_gradient_start,
                              colorEnd: AppColor.pink_gradient_end,
                              width: width, height: height)
    }
    
    func fixInView(_ container: UIView!) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
    
    func maskRoundCorners(cornerRadius: CGFloat?, cornersNonRound: [MessageViewModel.CornerType]?) {
        
        let radius = cornerRadius ?? 0
        let path = UIBezierPath()
        
        // Start Point
        path.move(to: CGPoint(x: bounds.origin.x, y: bounds.origin.y + radius))
        
        // Top-Left
        var startAngle = CGFloat(Float.pi)
        var endAngle = startAngle + CGFloat(Float.pi) / 2.0
        if cornersNonRound?.contains(.topLeft) == true {
            path.addLine(to: bounds.origin)
        }else {
            path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius,
                        startAngle: startAngle, endAngle: endAngle, clockwise: true)
        }
        path.addLine(to: CGPoint(x: bounds.width - radius, y: bounds.origin.y))

        // Top-Right
        startAngle += CGFloat(Float.pi) / 2.0
        endAngle += CGFloat(Float.pi) / 2.0
        if cornersNonRound?.contains(.topRight) == true {
            path.addLine(to: CGPoint(x: bounds.width, y: bounds.origin.y))
        }else {
            path.addArc(withCenter: CGPoint(x: bounds.width - radius, y: bounds.origin.y + radius),
                        radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        }
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.height - radius))

        // Bottom-Right
        startAngle += CGFloat(Float.pi) / 2.0
        endAngle += CGFloat(Float.pi) / 2.0
        if cornersNonRound?.contains(.bottomRight) == true {
            path.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
        }else {
            path.addArc(withCenter: CGPoint(x: bounds.width - radius, y: bounds.height - radius),
                        radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        }
        path.addLine(to: CGPoint(x: radius, y: bounds.height))

        // Bottom-Left
        startAngle += CGFloat(Float.pi) / 2.0
        endAngle += CGFloat(Float.pi) / 2.0
        if cornersNonRound?.contains(.bottomLeft) == true {
            path.addLine(to: CGPoint(x: bounds.origin.x, y: bounds.height))
        }else {
            path.addArc(withCenter: CGPoint(x: radius, y: bounds.height - radius),
                        radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        }
        path.addLine(to: CGPoint(x: bounds.origin.x, y: bounds.origin.y + radius))
        
        // Close Path
        path.close()

        let layerMask = CAShapeLayer()
        layerMask.path = path.cgPath
        layer.mask = layerMask
    }



}


