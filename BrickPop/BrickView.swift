//
//  BrickView.swift
//  BrickPop
//
//  Created by Lee Foster on 2017-06-18.
//  Copyright © 2017 Lee Foster. All rights reserved.
//

import Foundation
import UIKit

enum BrickType: UInt32 {
    case yellow,red,green,blue,purple,gray,removed
    var rectColor: UIColor {
        switch self {
        case .yellow:
            return UIColor(red:0.98, green:0.81, blue:0.58, alpha:1.00)
        case .red:
            return UIColor(red:0.98, green:0.66, blue:0.66, alpha:1.00)
        case .blue:
            return UIColor(red:0.65, green:0.76, blue:0.91, alpha:1.00)
        case .purple:
            return UIColor(red:0.86, green:0.74, blue:0.91, alpha:1.00)
        case .green:
            return UIColor(red:0.55, green:0.81, blue:0.75, alpha:1.00)
        case .gray:
            return UIColor(red:0.77, green:0.73, blue:0.68, alpha:1.00)
        default:
            return UIColor.clear
        }
        
    }
    
    var circleColor: UIColor {
        switch self {
        case .yellow:
            return UIColor(red:0.99, green:0.69, blue:0.27, alpha:1.00)
        case .red:
            return UIColor(red:0.99, green:0.43, blue:0.46, alpha:1.00)
        case .blue:
            return UIColor(red:0.33, green:0.60, blue:0.94, alpha:1.00)
        case .purple:
            return UIColor(red:0.70, green:0.45, blue:0.92, alpha:1.00)
        case .green:
            return UIColor(red:0.13, green:0.69, blue:0.61, alpha:1.00)
        case .gray:
            return UIColor(red:0.59, green:0.53, blue:0.46, alpha:1.00)
        default:
            return UIColor.clear
        }
    }
    
    private static func random(upperBound: UInt32) -> BrickType {
        var checkedMax = max(0,upperBound)
        checkedMax = min(upperBound,gray.rawValue+1)
        let rand = arc4random_uniform(checkedMax)
        return BrickType(rawValue: rand)!
    }
    
    static func randomLevel1() -> BrickType {
        return random(upperBound: green.rawValue+1)
    }
    
    static func randomLevel2() -> BrickType {
        return random(upperBound: blue.rawValue+1)
    }
    
    static func randomLevel3() -> BrickType {
        return random(upperBound: purple.rawValue+1)
    }
    
    static func randomLevel4() -> BrickType {
        return random(upperBound: gray.rawValue+1)
    }
}

@objc protocol BrickViewTappedDelegate {
    @objc optional func tappedBrickView(tappedView: BrickView)
}

class BrickView : UIControl {
    var brickType: BrickType
    weak var tappedDelegate: BrickViewTappedDelegate?
    
    init(frame: CGRect, brickType: BrickType) {
        self.brickType = brickType
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        
        // make the shadow layer
        let shadowOffset = self.bounds.width * 0.05
        let shadowColor = UIColor(red:0.85, green:0.83, blue:0.79, alpha:1.00)
        let shadowRect = CGRect(x: shadowOffset,
                                y: shadowOffset,
                                width: self.bounds.width,
                                height: self.bounds.height)
        let roundedShadowPath = UIBezierPath(roundedRect: shadowRect, cornerRadius: 8.0)
        let shadowLayer = CAShapeLayer()
        shadowLayer.fillColor = shadowColor.cgColor
        shadowLayer.path = roundedShadowPath.cgPath
        self.layer.addSublayer(shadowLayer)
        
        // draw rect
        let roundRectPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 8.0)
        let rectLayer = CAShapeLayer()
        rectLayer.fillColor = brickType.rectColor.cgColor
        rectLayer.path = roundRectPath.cgPath
        self.layer.addSublayer(rectLayer)
        
        // draw cirlce
        let insetAmount = self.bounds.width * 0.2
        let circleFrame = CGRect(x:insetAmount/2,
                                 y:insetAmount/2,
                                 width: self.bounds.width-insetAmount,
                                 height: self.bounds.height-insetAmount)
        let circlePath = UIBezierPath(ovalIn: circleFrame)
        let circleLayer = CAShapeLayer()
        circleLayer.fillColor = brickType.circleColor.cgColor
        circleLayer.path = circlePath.cgPath
        self.layer.addSublayer(circleLayer)
        
        self.addTarget(self,
                       action: #selector(tapped(_:)),
                       for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tapped(_ sender: BrickView) {
        self.tappedDelegate?.tappedBrickView?(tappedView: self)
    }
    
    override public var description: String {
        if self.isHidden {
            return "hidden"
        }
        return "(\(self.brickType), x:\(self.frame.origin.x), y:\(self.frame.origin.y))"
    }
}
