/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `CanvasView` tracks `UITouch`es and represents them as a series of `Line`s.
*/

import UIKit

class CanvasView: DropTargetView {
    // MARK: Properties
    
    let isPredictionEnabled = UIDevice.current().userInterfaceIdiom == .pad
    let isTouchUpdatingEnabled = true
    
    var usePreciseLocations = false {
        didSet {
            needsFullRedraw = true
            setNeedsDisplay()
        }
    }
    var isDebuggingEnabled = false {
        didSet {
            needsFullRedraw = true
            setNeedsDisplay()
        }
    }
    var needsFullRedraw = true
    
    /// Array containing all line objects that need to be drawn in `drawRect(_:)`.
    var lines = [Line]()

    /// Array containing all line objects that have been completely drawn into the frozenContext.
    var finishedLines = [Line]()

    
    /** 
        Holds a map of `UITouch` objects to `Line` objects whose touch has not ended yet.
    
        Use `NSMapTable` to handle association as `UITouch` doesn't conform to `NSCopying`. There is no value
        in accessing the properties of the touch used as a key in the map table. `UITouch` properties should
        be accessed in `NSResponder` callbacks and methods called from them.
    */
    let activeLines = MapTable.strongToStrongObjects() as MapTable<UITouch,Line>
    
    /**
        Holds a map of `UITouch` objects to `Line` objects whose touch has ended but still has points awaiting
        updates.
        
        Use `NSMapTable` to handle association as `UITouch` doesn't conform to `NSCopying`. There is no value
        in accessing the properties of the touch used as a key in the map table. `UITouch` properties should
        be accessed in `NSResponder` callbacks and methods called from them.
    */
    let pendingLines = MapTable.strongToStrongObjects() as MapTable<UITouch,Line>
    
    /// A `CGContext` for drawing the last representation of lines no longer receiving updates into.
    lazy var frozenContext: CGContext = {
        let scale = self.window!.screen.scale
        var size = self.bounds.size
        
        size.width *= scale
        size.height *= scale
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

        context!.setLineCap(.round)
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        context!.concatCTM(transform)
        
        return context!
    }()
    
    /// An optional `CGImage` containing the last representation of lines no longer receiving updates.
    var frozenImage: CGImage?
    
    // MARK: Drawing
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        
        context.setLineCap(.round)

        if (needsFullRedraw) {
            setFrozenImageNeedsUpdate()
            frozenContext.clear(bounds)
            for array in [finishedLines,lines] {
                for line in array {
                    line.drawCommitedPointsInContext(frozenContext, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocations)
                }
            }
            needsFullRedraw = false
        }

        frozenImage = frozenImage ?? frozenContext.makeImage()
        
        if let frozenImage = frozenImage {
            context.draw(in: bounds, image: frozenImage)
        }
        
        for line in lines {
            line.drawInContext(context, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocations)
        }
    }
    
    func setFrozenImageNeedsUpdate() {
        frozenImage = nil
    }
    
    // MARK: Actions
    
    func clear() {
        activeLines.removeAllObjects()
        pendingLines.removeAllObjects()
        lines.removeAll()
        finishedLines.removeAll()
        needsFullRedraw = true
        setNeedsDisplay()
    }
    
    // MARK: Convenience
    
    func drawTouches(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
        let updateRect = CGRect.null
        
        for touch in touches {
            // Retrieve a line from `activeLines`. If no line exists, create one.
            let line : Line = activeLines.object(forKey: touch) ?? addActiveLineForTouch(touch)
            
            /*
                Remove prior predicted points and update the `updateRect` based on the removals. The touches 
                used to create these points are predictions provided to offer additional data. They are stale 
                by the time of the next event for this touch.
            */
          //  updateRect.insetInPlace(line.removePointsWithType(.Predicted))
            
            /*
                Incorporate coalesced touch data. The data in the last touch in the returned array will match
                the data of the touch supplied to `coalescedTouchesForTouch(_:)`
            */
            let coalescedTouches = event?.coalescedTouches(for: touch) ?? []
            _ = addPointsOfType(.Coalesced, forTouches: coalescedTouches, toLine: line, currentUpdateRect: updateRect)
           // updateRect.insetInPlace(coalescedRect)
            
            /*
                Incorporate predicted touch data. This sample draws predicted touches differently; however, 
                you may want to use them as inputs to smoothing algorithms rather than directly drawing them. 
                Points derived from predicted touches should be removed from the line at the next event for 
                this touch.
            */
            if isPredictionEnabled {
                let predictedTouches = event?.predictedTouches(for: touch) ?? []
                _ = addPointsOfType(.Predicted, forTouches: predictedTouches, toLine: line, currentUpdateRect: updateRect)
          //      updateRect.insetInPlace(predictedRect)
            }
        }
        
        setNeedsDisplay(updateRect)
    }
    
    func addActiveLineForTouch(_ touch: UITouch) -> Line {
        let newLine = Line()
        
        activeLines.setObject(newLine, forKey: touch)
        
        lines.append(newLine)
        
        return newLine
    }
    
    func addPointsOfType(_ type: LinePoint.PointType, forTouches touches: [UITouch], toLine line: Line, currentUpdateRect updateRect: CGRect) -> CGRect {
        var type = type
        let accumulatedRect = CGRect.null
        
        for (idx, touch) in touches.enumerated() {
            let isStylus = touch.type == .stylus
            
            // The visualization displays non-`.Stylus` touches differently.
            if !isStylus {
                type.formUnion(.Finger)
            }
            
            // Touches with estimated properties require updates; add this information to the `PointType`.
            if isTouchUpdatingEnabled && !touch.estimatedProperties.isEmpty {
                type.formUnion(.NeedsUpdate)
            }
            
            // The last touch in a set of `.Coalesced` touches is the originating touch. Track it differently.
            if type.contains(.Coalesced) && idx == touches.count - 1 {
                type.subtract(.Coalesced)
                type.formUnion(.Standard)
            }
            
            _ = line.addPointOfType(type, forTouch: touch)
            // todo: fix swift 3
            //accumulatedRect.unionInPlace(touchRect)
            
            commitLine(line)
        }
        
        return updateRect.union(accumulatedRect)
    }
    
    func endTouches(_ touches: Set<UITouch>, cancel: Bool) {
        let updateRect = CGRect.null
        
        for touch in touches {
            // Skip over touches that do not correspond to an active line.
            guard let line : Line = activeLines.object(forKey: touch) else { continue }
            
            // If this is a touch cancellation, cancel the associated line.
          //  if cancel { updateRect.insetInPlace(line.cancel()) }
            
            // If the line is complete (no points needing updates) or updating isn't enabled, move the line to the `frozenImage`.
            if line.isComplete || !isTouchUpdatingEnabled {
                finishLine(line)
            }
            // Otherwise, add the line to our map of touches to lines pending update.
            else {
                pendingLines.setObject(line, forKey: touch)
            }
            
            // This touch is ending, remove the line corresponding to it from `activeLines`.
            activeLines.removeObject(forKey: touch)
        }
        
        setNeedsDisplay(updateRect)
    }
    
    func updateEstimatedPropertiesForTouches(_ touches: Set<NSObject>) {
        guard isTouchUpdatingEnabled, let touches = touches as? Set<UITouch> else { return }
        
        for touch in touches {
            var isPending = false
            
            // Look to retrieve a line from `activeLines`. If no line exists, look it up in `pendingLines`.
            let possibleLine: Line = activeLines.object(forKey: touch) ?? {
                let pendingLine : Line = pendingLines.object(forKey: touch)!
                isPending = true
                return pendingLine
            }()
            
            // If no line is related to the touch, return as there is no additional work to do.
            guard let line: Line = possibleLine else { return }
            
            switch line.updateWithTouch(touch) {
                case (true, let updateRect):
                    setNeedsDisplay(updateRect)
                default:
                    ()
            }
            
            // If this update updated the last point requiring an update, move the line to the `frozenImage`.
            if isPending && line.isComplete {
                finishLine(line)
                pendingLines.removeObject(forKey: touch)
            }
            // Otherwise, have the line add any points no longer requiring updates to the `frozenImage`.
            else {
                commitLine(line)
            }
            
        }
    }
    
    func commitLine(_ line: Line) {
        // Have the line draw any segments between points no longer being updated into the `frozenContext` and remove them from the line.
        line.drawFixedPointsInContext(frozenContext, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocations)
        setFrozenImageNeedsUpdate()
    }
    
    func finishLine(_ line: Line) {
        // Have the line draw any remaining segments into the `frozenContext`. All should be fixed now.
        line.drawFixedPointsInContext(frozenContext, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocations, commitAll: true)
        setFrozenImageNeedsUpdate()
        
        // Cease tracking this line now that it is finished.
        lines.remove(at: lines.index(of: line)!)

        // Store into finished lines to allow for a full redraw on option changes.
        finishedLines.append(line)
    }
}
