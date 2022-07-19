import AlfredWorkflowScriptFilter
import AppKit


class Entrance {
    static let shared = Entrance()
    
    private init() {}
    
    
    static func scriptFilter() -> String {
        results()
    }
    
    static func results() -> String {
        guard let visibleWindows = visibleWindows() else {
            ScriptFilter.add(
                Item(title: "Oops. Can't grab windows. macOS requires you to grant permissions manually.")
                    .subtitle("Press ↵ to head to the README and learn how to grant those permissions")
                    .arg("do")
                    .variable(Variable(name: "action", value: "headToREADME"))
            )
            
            return ScriptFilter.output()
        }
        
        if visibleWindows.isEmpty {
            ScriptFilter.add(
                Item(title: "Desktop is all clean! No window found.")
                    .valid(false)
            )
        } else {
            let visibleWindowsExcludingTheFocusedWindow = removeCurrentlyFocusedWindow(from: visibleWindows)
            
            if visibleWindowsExcludingTheFocusedWindow.isEmpty {
                ScriptFilter.add(
                    Item(title: "The only visible window is the one you're already on!")
                        .subtitle("Press ↵ to go back to it")
                        .arg("do")
                        .variable(Variable(name: "action", value: "nothing"))
                )
            } else {
                for window in visibleWindowsExcludingTheFocusedWindow {
                    ScriptFilter.add(
                        Item(title: window.title)
                            .subtitle(window.appName ?? "")
                            .match("\(window.appName ?? "") \(window.title)")
                            .icon(Icon(path: window.appIcon ?? "", type: .fileicon))
                            .arg("do")
                            .variable(Variable(name: "action", value: "bringWindowToForeground"))
                            .variable(Variable(name: "appPID", value: String(window.appPID)))
                            .variable(Variable(name: "windowTitle", value: window.title))
                            .variable(Variable(name: "windowBounds", value: NSStringFromRect(window.bounds)))
                    )
                }
            }
        }
        
        return ScriptFilter.output()
    }
    
}


extension Entrance {
        
    private static func visibleWindows() -> [Window]? {
        guard let cgVisibleWindows = cgVisibleWindows() else { return nil }
           
        return cgVisibleWindows
    }
    
    private static func cgVisibleWindows() -> [Window]? {
        guard let tooManyWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as NSArray? else { return nil }
        guard let visibleWindows = tooManyWindows.filtered(using: NSPredicate(format: """
            (
                kCGWindowLayer == 0
                || kCGWindowLayer == 8
                || kCGWindowLayer == 23
            )
            && kCGWindowAlpha > 0
            """)) as NSArray? else { return nil }
        
        var windows: [Window] = []
               
        for visibleWindow in visibleWindows {
            guard let visibleWindow = visibleWindow as? NSDictionary else { continue }
            guard let visibleWindowOwnerPID = visibleWindow.value(forKey: "kCGWindowOwnerPID") as? pid_t else { continue }
            guard let visibleWindowOwnerName = visibleWindow.value(forKey: "kCGWindowOwnerName") as? String else { continue }
            guard let visibleWindowName = visibleWindow.value(forKey: "kCGWindowName") as? String else { return nil }
            guard let bounds = visibleWindow.value(forKey: "kCGWindowBounds") as? NSDictionary else { return nil }
            guard let height = bounds.value(forKey: "Height") as? CGFloat else { return nil }
            guard let width = bounds.value(forKey: "Width") as? CGFloat else { return nil }
            guard let x = bounds.value(forKey: "X") as? CGFloat else { return nil }
            guard let y = bounds.value(forKey: "Y") as? CGFloat else { return nil }

            var icon: String
            if
                let application = NSRunningApplication(processIdentifier: visibleWindowOwnerPID),
                let bundleIdentifier = application.bundleIdentifier,
                let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
            {
                icon = url.path
            } else {
                icon = Bundle.main.bundlePath
            }
            
            let window = Window(
                appPID: visibleWindowOwnerPID,
                appName: visibleWindowOwnerName,
                appIcon: icon,
                title: visibleWindowName,
                bounds: NSRect(x: x, y: y, width: width, height: height)
            )
            
            windows.append(window)
        }
        
        return windows
    }
    
    private static func removeCurrentlyFocusedWindow(from visibleWindows: [Window]) -> [Window] {
        var visibleWindowsExcludingTheFocusedWindow = visibleWindows
        
        if let axFocusedWindow = axFocusedWindow() {
            // first pass
            visibleWindowsExcludingTheFocusedWindow.removeAll { cgWindow in
                cgWindow.appPID == axFocusedWindow.appPID
                && cgWindow.title == axFocusedWindow.title
                && cgWindow.bounds == axFocusedWindow.bounds
            }
            
            // second pass for same windows that return different titles with CG and AX
            // in that case, if no window has been found at first pass, we match only with app and bounds, not title
            if visibleWindows.count == visibleWindowsExcludingTheFocusedWindow.count {
                visibleWindowsExcludingTheFocusedWindow.removeAll { cgWindow in
                    cgWindow.appPID == axFocusedWindow.appPID
                    && cgWindow.bounds == axFocusedWindow.bounds
                }
            }
        }
               
        return visibleWindowsExcludingTheFocusedWindow
    }

    private static func axFocusedWindow() -> Window? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return nil }
        let axApplication = AXUIElementCreateApplication(pid)
        
        var axWindow: AnyObject?
        guard AXUIElementCopyAttributeValue(axApplication, kAXFocusedWindowAttribute as CFString, &axWindow) == .success else { return nil }
               
        var values: CFArray?
        guard AXUIElementCopyMultipleAttributeValues(axWindow as! AXUIElement, [kAXTitleAttribute, kAXPositionAttribute, kAXSizeAttribute] as CFArray, AXCopyMultipleAttributeOptions(rawValue: 0), &values) == .success else { return nil }
        guard let windowValues = values as NSArray? else { return nil }
                   
        let title = windowValues[0] as? String ?? ""
        var position = CGPoint()
        AXValueGetValue(windowValues[1] as! AXValue, .cgPoint, &position)
        var size = CGSize()
        AXValueGetValue(windowValues[2] as! AXValue, .cgSize, &size)
        let bounds = NSRect(x: position.x, y: position.y, width: size.width, height: size.height)
        
        return Window(
            appPID: pid,
            appName: "",
            appIcon: "",
            title: title,
            bounds: bounds
        )
    }
    
}
