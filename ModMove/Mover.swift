import AppKit
import Foundation

final class Mover {
    var state: FlagState = .ignore {
        didSet {
            if self.state != oldValue {
                self.changedState(self.state)
            }
        }
    }

    fileprivate var monitor: AnyObject?
    fileprivate var lastMousePosition: CGPoint?
    fileprivate var window: AccessibilityElement?

    fileprivate func mouseMoved(_ handler: (_ window: AccessibilityElement, _ mouseDelta: CGPoint) -> Void) {
        let point = Mouse.currentPosition()
        if self.window == nil {
            self.window = AccessibilityElement.systemWideElement.elementAtPoint(point)?.window()
        }

        guard let window = self.window else {
            return
        }

        let currentPid = NSRunningApplication.current().processIdentifier
        if let pid = window.pid() , pid != currentPid {
            NSRunningApplication(processIdentifier: pid)?.activate(options: .activateIgnoringOtherApps)
        }

        window.bringToFront()
        if let lastPosition = self.lastMousePosition {
            let mouseDelta = CGPoint(x: lastPosition.x - point.x, y: lastPosition.y - point.y)
            handler(window, mouseDelta)
        }

        self.lastMousePosition = point
    }

    fileprivate func resizeWindow(_ window: AccessibilityElement, mouseDelta: CGPoint) {
        if let size = window.size {
            let newSize = CGSize(width: size.width - mouseDelta.x, height: size.height - mouseDelta.y)
            window.size = newSize
        }
    }

    fileprivate func moveWindow(_ window: AccessibilityElement, mouseDelta: CGPoint) {
        if let position = window.position {
            let newPosition = CGPoint(x: position.x - mouseDelta.x, y: position.y - mouseDelta.y)
            window.position = newPosition
        }
    }

    fileprivate func changedState(_ state: FlagState) {
        self.removeMonitor()

        switch state {
        case .resize:
            self.monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { _ in
                self.mouseMoved(self.resizeWindow)
            } as AnyObject?
        case .drag:
            self.monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { _ in
                self.mouseMoved(self.moveWindow)
            } as AnyObject?
        case .ignore:
            self.lastMousePosition = nil
            self.window = nil
        }
    }

    fileprivate func removeMonitor() {
        if let monitor = self.monitor {
            NSEvent.removeMonitor(monitor)
        }
        self.monitor = nil
    }

    deinit {
        self.removeMonitor()
    }
}
