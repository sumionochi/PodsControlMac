//CursorLogic
import Foundation
import CoreGraphics
import AppKit

/// Handles head-controlled cursor movement with click gestures
final class CursorLogic {
    
    // Cursor movement sensitivity and smoothing
    private var movementSpeed: CGFloat {
        CGFloat(HeadFlowSettings.cursorSpeed)
    }

    private var deadZone: Double {
        HeadFlowSettings.cursorDeadZone
    }

    private var smoothingFactor: CGFloat {
        CGFloat(HeadFlowSettings.cursorSmoothing)
    }

    
    
    // Smoothed velocity for weighted movement
    private var smoothedDeltaX: CGFloat = 0.0
    private var smoothedDeltaY: CGFloat = 0.0
    
    // Click detection thresholds (using YAW - head turning left/right)
    private var singleClickYawThreshold: Double {
        HeadFlowSettings.cursorSingleClickYawDegrees
    }

    private var doubleClickYawThreshold: Double {
        max(
            HeadFlowSettings.cursorDoubleClickYawDegrees,
            HeadFlowSettings.cursorSingleClickYawDegrees + 1.0 // keep > single
        )
    }

    private var clickCooldown: TimeInterval {
        HeadFlowSettings.cursorClickCooldown
    }
    
    // State tracking
    private var lastClickTime: CFAbsoluteTime = 0
    private var isDragging = false
    private var wasClickComboActive = false
    private var wasDragComboActive  = false
    
    // Click gesture state
    private enum ClickGestureState {
        case idle
        case tiltDetected(side: TiltSide, magnitude: Double, startTime: CFAbsoluteTime)
        case clickExecuted
    }
    
    private enum TiltSide {
        case left
        case right
    }
    
    private var clickState: ClickGestureState = .idle
    
    func update(yaw: Double, pitch: Double, roll: Double) {
        // 1) Current modifier flags (only the 4 we care about)
        let rawFlags = NSEvent.modifierFlags
        let flags = rawFlags.intersection([.command, .option, .control, .shift])

        // 2) User-configured combos
        let clickCombo = HeadFlowSettings.cursorClickModifiers          // e.g. ⌘ or ⌘+⌥
        let dragExtra  = HeadFlowSettings.cursorDragExtraModifiers      // e.g. ^

        // Full drag combo = click combo + extra drag modifiers
        let dragCombo = clickCombo.union(dragExtra)                      // e.g. ⌘+^

        // 3) Are those combos currently held?
        // `contains` for OptionSet behaves like "isSuperset(of:)"
        let isClickComboActive = !clickCombo.isEmpty && flags.contains(clickCombo)
        let isDragComboActive  = !dragCombo.isEmpty && flags.contains(dragCombo)

        // === PRESS / RELEASE HANDLING ===

        // Click combo pressed
        if isClickComboActive && !wasClickComboActive {
            // combo just pressed - freeze cursor for stable clicking
            smoothedDeltaX = 0.0
            smoothedDeltaY = 0.0
            clickState = .idle
            print("CursorLogic: click combo pressed - cursor frozen")
        }
        // Click combo released
        else if !isClickComboActive && wasClickComboActive {
            if isDragging {
                CursorEngine.endDrag()
                isDragging = false
                print("CursorLogic: Ended drag (click combo released)")
            }
            clickState = .idle
        }

        // Drag combo pressed (must include the click combo as well)
        if isDragComboActive && !wasDragComboActive && isClickComboActive {
            print("CursorLogic: drag combo pressed - drag mode ready")
        }
        // Drag combo released
        else if !isDragComboActive && wasDragComboActive {
            if isDragging {
                CursorEngine.endDrag()
                isDragging = false
                clickState = .idle
                print("CursorLogic: Ended drag (drag combo released)")
            }
        }

        wasClickComboActive = isClickComboActive
        wasDragComboActive  = isDragComboActive
        
        // --- CURSOR MOVEMENT ---
        // Move cursor when Command is NOT held, OR when dragging (Command + Control)
        let shouldMoveCursor = !isClickComboActive || (isDragComboActive && isDragging)

        if shouldMoveCursor {
            // Apply dead zone to filter out tiny movements
            let effectiveYaw = abs(yaw) > deadZone ? yaw : 0.0
            let effectivePitch = abs(pitch) > deadZone ? pitch : 0.0
            
            // Calculate target deltas
            // Invert yaw so left head movement = left cursor movement
            let targetDeltaX = CGFloat(-effectiveYaw) * movementSpeed
            let targetDeltaY = CGFloat(-effectivePitch) * movementSpeed
            
            // Apply smoothing for weighted, controlled movement
            smoothedDeltaX = smoothedDeltaX * (1.0 - smoothingFactor) + targetDeltaX * smoothingFactor
            smoothedDeltaY = smoothedDeltaY * (1.0 - smoothingFactor) + targetDeltaY * smoothingFactor
            
            // Only move if smoothed values are above minimum threshold
            if abs(smoothedDeltaX) > 0.1 || abs(smoothedDeltaY) > 0.1 {
                if isDragging {
                    CursorEngine.continueDrag(deltaX: smoothedDeltaX, deltaY: smoothedDeltaY)
                } else {
                    CursorEngine.moveCursor(deltaX: smoothedDeltaX, deltaY: smoothedDeltaY)
                }
            }
        } else if isClickComboActive && !isDragComboActive {
            // Command held without Control - cursor is frozen
            // Gradually decay smoothed values to zero
            smoothedDeltaX *= 0.8
            smoothedDeltaY *= 0.8
        }
        
        // --- CLICK/DRAG DETECTION ---
        // Only when Command is held
        if isClickComboActive {
            if isDragComboActive {
                // Click combo + drag extra modifiers = Drag Mode
                handleDragMode(yaw: yaw)
            } else {
                // Only click combo = Click Mode
                handleClickMode(yaw: yaw)
            }
        } else {
            // No click combo - reset state
            clickState = .idle
        }
    }
    
    // MARK: - Drag Mode (Command + Control)
    
    private func handleDragMode(yaw: Double) {
        // Start drag on any significant yaw turn (left or right)
        let absYaw = abs(yaw)
        
        if absYaw >= singleClickYawThreshold {
            if !isDragging {
                CursorEngine.startDrag()
                isDragging = true
                print("CursorLogic: Started drag (yaw: \(yaw)°, threshold: \(singleClickYawThreshold)°)")
            }
        }
        // Drag continues as long as Command + Control are held
        // Released via key release detection above
    }
    
    // MARK: - Click Mode (Command only)
    
    private func handleClickMode(yaw: Double) {
        let now = CFAbsoluteTimeGetCurrent()
        let absYaw = abs(yaw)
        
        // Determine which side we're turning to
        let currentSide: TiltSide? = {
            if yaw < -singleClickYawThreshold {
                return .left
            } else if yaw > singleClickYawThreshold {
                return .right
            }
            return nil
        }()
        
        switch clickState {
        case .idle:
            // Waiting for a turn gesture
            if let side = currentSide {
                // Check cooldown before starting new gesture
                guard now - lastClickTime > clickCooldown else {
                    print("CursorLogic: Still in cooldown period")
                    return
                }
                
                // Immediately check if this is a double click gesture (≥20°)
                if absYaw >= doubleClickYawThreshold {
                    executeDoubleClick(side: side, magnitude: absYaw)
                    clickState = .clickExecuted
                    lastClickTime = now
                } else {
                    // Single click range (10°-19°) - track it
                    clickState = .tiltDetected(side: side, magnitude: absYaw, startTime: now)
                    print("CursorLogic: Turn detected - \(side) at \(absYaw)°")
                }
            }
            
        case .tiltDetected(let side, let initialMagnitude, _):
            // Currently tracking a turn
            
            if let newSide = currentSide {
                // Still turning
                if newSide == side {
                    // Same side - check if magnitude increased to double click threshold
                    if absYaw >= doubleClickYawThreshold && initialMagnitude < doubleClickYawThreshold {
                        executeDoubleClick(side: side, magnitude: absYaw)
                        clickState = .clickExecuted
                        lastClickTime = now
                    }
                    // Otherwise, keep tracking (waiting for release)
                } else {
                    // Changed sides - reset
                    clickState = .idle
                    print("CursorLogic: Turn direction changed - reset")
                }
            } else {
                // Returned to neutral - execute single click
                executeSingleClick(side: side, magnitude: initialMagnitude)
                clickState = .clickExecuted
                lastClickTime = now
            }
            
        case .clickExecuted:
            // Waiting for cooldown to expire and head to return to neutral
            if currentSide == nil && now - lastClickTime > clickCooldown {
                clickState = .idle
                print("CursorLogic: Ready for next gesture")
            }
        }
    }
    
    // MARK: - Click Execution
    
    private func executeSingleClick(side: TiltSide, magnitude: Double) {
        switch side {
        case .left:
            CursorEngine.leftClick()
            print("CursorLogic: ✓ LEFT CLICK (turn: \(magnitude)°)")
        case .right:
            CursorEngine.rightClick()
            print("CursorLogic: ✓ RIGHT CLICK (turn: \(magnitude)°)")
        }
    }
    
    private func executeDoubleClick(side: TiltSide, magnitude: Double) {
        // Double click uses the same button as the turn direction
        switch side {
        case .left:
            CursorEngine.doubleClick()
            print("CursorLogic: ✓ LEFT DOUBLE CLICK (turn left: \(magnitude)°)")
        case .right:
            // For right side, we still use standard double click (left button)
            // but you could add a rightDoubleClick() method if needed
            CursorEngine.doubleClick()
            print("CursorLogic: ✓ RIGHT DOUBLE CLICK (turn right: \(magnitude)°)")
        }
    }
    
    // MARK: - Calibration Helper
    
    /// Reset smoothed velocities (called on calibration)
    func resetSmoothing() {
        smoothedDeltaX = 0.0
        smoothedDeltaY = 0.0
        clickState = .idle
        if isDragging {
            CursorEngine.endDrag()
            isDragging = false
        }
        print("CursorLogic: Reset smoothing and state")
    }
}
