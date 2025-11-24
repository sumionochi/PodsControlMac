//  CursorEngine.swift

import Foundation
import CoreGraphics
import AppKit

/// Low-level engine to synthesize mouse events (movement, clicks, drags).
struct CursorEngine {

    /// Moves the cursor by a relative amount (dx, dy).
    static func moveCursor(deltaX: CGFloat, deltaY: CGFloat) {
        guard let currentEvent = CGEvent(source: nil) else { return }
        let currentLoc = currentEvent.location
        
        let newLoc = CGPoint(
            x: currentLoc.x + deltaX,
            y: currentLoc.y + deltaY
        )
        
        // Use CGWarpMouseCursorPosition for smooth movement without generating events
        CGWarpMouseCursorPosition(newLoc)
    }
    
    /// Centers the cursor on the main screen
    static func centerCursor() {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        let centerPoint = CGPoint(
            x: screenRect.origin.x + screenRect.width / 2,
            y: screenRect.origin.y + screenRect.height / 2
        )
        CGWarpMouseCursorPosition(centerPoint)
        print("CursorEngine: Centered cursor at \(centerPoint)")
    }
    
    /// Generates a specific mouse event at a location.
    private static func postMouseEvent(type: CGEventType, at location: CGPoint, button: CGMouseButton = .left) {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let event = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: location, mouseButton: button)
        else { return }
        
        event.post(tap: .cghidEventTap)
    }
    
    static func leftClick() {
        guard let loc = CGEvent(source: nil)?.location else { return }
        postMouseEvent(type: .leftMouseDown, at: loc, button: .left)
        usleep(10000) // 10ms delay for click registration
        postMouseEvent(type: .leftMouseUp, at: loc, button: .left)
        print("CursorEngine: Left click at \(loc)")
    }
    
    static func rightClick() {
        guard let loc = CGEvent(source: nil)?.location else { return }
        postMouseEvent(type: .rightMouseDown, at: loc, button: .right)
        usleep(10000) // 10ms delay
        postMouseEvent(type: .rightMouseUp, at: loc, button: .right)
        print("CursorEngine: Right click at \(loc)")
    }
    
    static func doubleClick() {
        guard let loc = CGEvent(source: nil)?.location else { return }
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        
        // First click
        let down1 = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: loc, mouseButton: .left)
        down1?.setIntegerValueField(.mouseEventClickState, value: 1)
        down1?.post(tap: .cghidEventTap)
        
        let up1 = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: loc, mouseButton: .left)
        up1?.setIntegerValueField(.mouseEventClickState, value: 1)
        up1?.post(tap: .cghidEventTap)
        
        usleep(50000) // 50ms between clicks
        
        // Second click
        let down2 = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: loc, mouseButton: .left)
        down2?.setIntegerValueField(.mouseEventClickState, value: 2)
        down2?.post(tap: .cghidEventTap)
        
        let up2 = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: loc, mouseButton: .left)
        up2?.setIntegerValueField(.mouseEventClickState, value: 2)
        up2?.post(tap: .cghidEventTap)
        
        print("CursorEngine: Double click at \(loc)")
    }
    
    /// Starts a drag operation (Mouse Down)
    static func startDrag() {
        guard let loc = CGEvent(source: nil)?.location else { return }
        postMouseEvent(type: .leftMouseDown, at: loc, button: .left)
        print("CursorEngine: Drag started at \(loc)")
    }
    
    /// Ends a drag operation (Mouse Up)
    static func endDrag() {
        guard let loc = CGEvent(source: nil)?.location else { return }
        postMouseEvent(type: .leftMouseUp, at: loc, button: .left)
        print("CursorEngine: Drag ended at \(loc)")
    }
    
    /// Updates drag position (Mouse Dragged)
    static func continueDrag(deltaX: CGFloat, deltaY: CGFloat) {
        guard let currentEvent = CGEvent(source: nil) else { return }
        let currentLoc = currentEvent.location
        let newLoc = CGPoint(x: currentLoc.x + deltaX, y: currentLoc.y + deltaY)
        
        // During drag, we need to post .leftMouseDragged events
        guard let source = CGEventSource(stateID: .hidSystemState),
              let event = CGEvent(mouseEventSource: source, mouseType: .leftMouseDragged, mouseCursorPosition: newLoc, mouseButton: .left)
        else { return }
        
        event.post(tap: .cghidEventTap)
    }
}
