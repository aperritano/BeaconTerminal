//
//  DraggableSpeciesImageView.swift
//  BeaconTerminal
//
//  Created by Anthony Perritano on 7/11/16.
//  Copyright © 2016 aperritano@gmail.com. All rights reserved.
//

import Foundation
import UIKit

class DraggableSpeciesImageView : UIImageView {
    
    var species: Species?
    var jiggling = false
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

    func smoothJiggle() {
    
        jiggling = true
        let degrees: CGFloat = 5.0
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.duration = 0.6
        animation.cumulative = true
        animation.repeatCount = Float.infinity
        animation.values = [0.0, degreesToRadians(-degrees) * 0.25,
                            0.0,
                            degreesToRadians(degrees) * 0.5,
                            0.0,
                            degreesToRadians(-degrees),
                            0.0,
                            degreesToRadians(degrees),
                            0.0,
                            degreesToRadians(-degrees) * 0.5,
                            0.0,
                            degreesToRadians(degrees) * 0.25,
                            0.0]
        animation.fillMode = kCAFillModeForwards;
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.removedOnCompletion = true
        
        layer.addAnimation(animation, forKey: "wobble")
    }
    
    func stopJiggling() {
        jiggling = false
        self.layer.removeAllAnimations()
        self.transform = CGAffineTransformIdentity
        self.layer.anchorPoint = CGPointMake(0.5, 0.5)
    }
    
    func radiansToDegrees(radians: Double)->Double {
        return radians * 180 / M_PI
    }
    
    func degreesToRadians(value:CGFloat) -> CGFloat {
        return value * CGFloat(M_PI / 180.0)
    }
    
    func clone() -> DraggableSpeciesImageView {        
        var clone = DraggableSpeciesImageView(frame: self.frame)
        clone.image = self.image
        clone.userInteractionEnabled = true
        clone.species = self.species
        return clone
        
    }

}