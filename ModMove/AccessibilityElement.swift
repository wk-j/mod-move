import AppKit
import Foundation

final class AccessibilityElement {
    static let systemWideElement = AccessibilityElement.createSystemWideElement()

    var position: CGPoint? {
        get { return self.getPosition() }
        set {
            if let position = newValue {
                self.setPosition(position)
            }
        }
    }

    var size: CGSize? {
        get { return self.getSize() }
        set {
            if let size = newValue {
                self.setSize(size)
            }
        }
    }

    fileprivate let elementRef: AXUIElement

    init(elementRef: AXUIElement) {
        self.elementRef = elementRef
    }

    func elementAtPoint(_ point: CGPoint) -> Self? {
        var ref: AXUIElement?
        AXUIElementCopyElementAtPosition(self.elementRef, Float(point.x), Float(point.y), &ref)
        return ref.map(type(of: self).init)
    }

    func window() -> Self? {
        var element = self
        while element.role() != kAXWindowRole {
            if let nextElement = element.parent() {
                element = nextElement
            } else {
                return nil
            }
        }

        return element
    }

    func parent() -> Self? {
        return self.valueForAttribute(kAXParentAttribute)
    }

    func role() -> String? {
        return self.valueForAttribute(kAXRoleAttribute)
    }

    func pid() -> pid_t? {
        let pointer = UnsafeMutablePointer<pid_t>.allocate(capacity: 1)
        let error = AXUIElementGetPid(self.elementRef, pointer)
        return error == .success ? pointer.pointee : nil
    }

    func bringToFront() {
        if let isMainWindow = self.rawValueForAttribute(NSAccessibilityMainAttribute) as? Bool
            , isMainWindow
        {
            return
        }

        AXUIElementSetAttributeValue(self.elementRef, NSAccessibilityMainAttribute as CFString, true as CFTypeRef)
    }

    // MARK: - Private functions

    static fileprivate func createSystemWideElement() -> Self {
        return self.init(elementRef: AXUIElementCreateSystemWide())
        // return self.init(elementRef: AXUIElementCreateSystemWide().takeUnretainedValue())
    }

    fileprivate func getPosition() -> CGPoint? {
        return self.valueForAttribute(kAXPositionAttribute)
    }

    fileprivate func setPosition(_ position: CGPoint) {
        if let value = AXValue.fromValue(position, type: .cgPoint) {
            AXUIElementSetAttributeValue(self.elementRef, kAXPositionAttribute as CFString, value)
        }
    }

    fileprivate func getSize() -> CGSize? {
        return self.valueForAttribute(kAXSizeAttribute)
    }

    fileprivate func setSize(_ size: CGSize) {
        if let value = AXValue.fromValue(size, type: .cgSize) {
            AXUIElementSetAttributeValue(self.elementRef, kAXSizeAttribute as CFString, value)
        }
    }

    fileprivate func rawValueForAttribute(_ attribute: String) -> AnyObject? {
        var rawValue: AnyObject?
        let error = AXUIElementCopyAttributeValue(self.elementRef, attribute as CFString, &rawValue)
        return error == .success ? rawValue : nil
    }

    fileprivate func valueForAttribute(_ attribute: String) -> Self? {
        if let rawValue = self.rawValueForAttribute(attribute)
            , CFGetTypeID(rawValue) == AXUIElementGetTypeID()
        {
            return type(of: self).init(elementRef: rawValue as! AXUIElement)
        }

        return nil
    }

    fileprivate func valueForAttribute(_ attribute: String) -> String? {
        return self.rawValueForAttribute(attribute) as? String
    }

    fileprivate func valueForAttribute<T>(_ attribute: String) -> T? {
        if let rawValue = self.rawValueForAttribute(attribute)
            , CFGetTypeID(rawValue) == AXValueGetTypeID()
        {
            return (rawValue as! AXValue).toValue()
        }

        return nil
    }
}
