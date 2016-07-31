//
//  DropTargetView.swift
//  DraggableView
//
//  Created by Anthony Perritano on 5/28/16.
//  Copyright © 2016 Mark Angelo Noquera. All rights reserved.
//

import Foundation
import UIKit

class DropTargetView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.bounds.contains(point) {
            return true
        }
        return super.point(inside: point, with: event)
    }
}
