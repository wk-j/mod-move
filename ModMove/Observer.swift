import AppKit
import Foundation

enum FlagState {
    case resize
    case drag
    case ignore
}

final class Observer {
    fileprivate var monitor: AnyObject?

    func startObserving(_ state: @escaping (FlagState) -> Void) {
        self.monitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            state(self.stateForFlags(event.modifierFlags))
        } as AnyObject?
    }

    fileprivate func stateForFlags(_ flags: NSEventModifierFlags) -> FlagState {
        // let hasMain = flags.contains(.control) && flags.contains(.AlternateKeyMask)
        let hasMain = flags.contains(.control) // && flags.contains(.)

        let hasShift = flags.contains(.shift)

        if hasMain && hasShift {
            return .resize
        } else if hasMain {
            return .drag
        } else {
            return .ignore
        }
    }

    deinit {
        if let monitor = self.monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
