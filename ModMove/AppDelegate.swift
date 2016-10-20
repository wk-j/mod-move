import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AccessibilityHelper.askForAccessibilityIfNeeded()

        if !LoginController.opensAtLogin() {
            LoginAlert.showAlertIfNeeded()
        }

        let mover = Mover()
        Observer().startObserving { state in
            mover.state = state
        }
    }
}
