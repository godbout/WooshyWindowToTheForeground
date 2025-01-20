import AlfredWorkflowScriptFilter
import AppKit


struct Window {
    
    let number: CGWindowID
    let title: String
    let appPID: pid_t
    let appName: String?
    let appIcon: String?
    
}


class Entrance {
    static let shared = Entrance()
    static var screenRecordingGranted = false
    
    private init() {}
    
    
    static func scriptFilter() -> String {
        results()
    }
        
    static func results() -> String {
        guard let visibleWindows = visibleWindows() else {
            ScriptFilter.add(
                Item(title: "🚨️ Oops 🚨️ Something is failing badly. The smart thing to do is to report!")
                    .subtitle("Press ↵ to fly to the GitHub Issues page")
                    .arg("do")
                    .variable(Variable(name: "action", value: "headToGitHubIssues"))
            )
                    
            return ScriptFilter.output()
        }
        
        if visibleWindows.isEmpty {
            if CGPreflightScreenCaptureAccess() == true {
                ScriptFilter.add(
                    Item(title: "Desktop is all clean! No window found.")
                        .valid(false)
                )
            } else {
                ScriptFilter.add(
                    Item(title: "🔐️🔐️🔐️ Screen Recording and/or Accessibility permissions needed 🔐️🔐️🔐️")
                        .subtitle("Press ↵ to grant permissions, ⌘↵ for the README")
                        .arg("do")
                        .variable(Variable(name: "action", value: "promptPermissionDialogs"))
                        .mod(
                            Cmd()
                                .subtitle("README here I come!")
                                .arg("do")
                                .variable(Variable(name: "action", value: "headToREADME"))
                        )
                )
            }
        } else {
            let filterOutFocusedWindow = (ProcessInfo.processInfo.environment["filter_out_focused_window"] == "1" ? true : false)
            let visibleWindowsToShowInAlfredResults = filterOutFocusedWindow ? removeCurrentlyFocusedWindow(from: visibleWindows) : visibleWindows
            
            if visibleWindowsToShowInAlfredResults.isEmpty {
                ScriptFilter.add(
                    Item(title: "The only visible window is the one you're already on!")
                        .subtitle("Press ↵ to go back to it")
                        .arg("do")
                        .variable(Variable(name: "action", value: "nothing"))
                )
            } else {
                for window in visibleWindowsToShowInAlfredResults {
                    ScriptFilter.add(
                        Item(title: window.title)
                            .subtitle(window.appName ?? "")
                            .match("\(window.appName ?? "") \(window.title)")
                            .icon(Icon(path: window.appIcon ?? "", type: .fileicon))
                            .arg("do")
                            .variable(Variable(name: "windowNumber", value: String(window.number)))
                            .variable(Variable(name: "windowTitle", value: window.title))
                            .variable(Variable(name: "appPID", value: String(window.appPID)))
                            .variable(Variable(name: "action", value: "bringWindowToForeground"))
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
            (kCGWindowBounds.Width > 37 && kCGWindowBounds.Height > 37)
            && kCGWindowOwnerName != "Alfred"
            && kCGWindowOwnerName != "Notification Center"
            && kCGWindowOwnerName != "Wallpaper"
            && kCGWindowOwnerName != "Screenshot"
            && (kCGWindowOwnerName != "HazeOver" || kCGWindowAlpha = 1)
            && (kCGWindowOwnerName != "Magnet" || kCGWindowLayer != 25)
            && kCGWindowAlpha > 0
            """)) as NSArray? else { return nil }
        
        var windows: [Window] = []
               
        for visibleWindow in visibleWindows {
            guard
                let visibleWindow = visibleWindow as? NSDictionary,
                let visibleWindowNumber = visibleWindow.value(forKey: "kCGWindowNumber") as? CGWindowID,
                let visibleWindowOwnerPID = visibleWindow.value(forKey: "kCGWindowOwnerPID") as? pid_t,
                let visibleWindowOwnerName = visibleWindow.value(forKey: "kCGWindowOwnerName") as? String
            else {
                continue
            }
            
            let visibleWindowName = visibleWindow.value(forKey: "kCGWindowName") as? String
            if visibleWindowName == nil {
                continue
            } else {
                Self.screenRecordingGranted = true
            }
            
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
                number: visibleWindowNumber,
                title: visibleWindowName!,
                appPID: visibleWindowOwnerPID,
                appName: visibleWindowOwnerName,
                appIcon: icon
            )
            
            windows.append(window)
        }
        
        return windows
    }
        
    private static func removeCurrentlyFocusedWindow(from visibleWindows: [Window]) -> [Window] {
        var visibleWindowsExcludingTheFocusedWindow = visibleWindows

        if let axFocusedWindowNumber = axFocusedWindowNumber() {
            visibleWindowsExcludingTheFocusedWindow.removeAll { cgWindow in
                cgWindow.number == axFocusedWindowNumber
            }
        }

        return visibleWindowsExcludingTheFocusedWindow
    }

    private static func axFocusedWindowNumber() -> CGWindowID? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return nil }
        let axApplication = AXUIElementCreateApplication(pid)

        var axWindow: AnyObject?
        guard AXUIElementCopyAttributeValue(axApplication, kAXFocusedWindowAttribute as CFString, &axWindow) == .success else { return nil }

        var axWindowNumber: CGWindowID = 0
        guard _AXUIElementGetWindow((axWindow as! AXUIElement), &axWindowNumber) == .success else { return nil }

        return axWindowNumber
    }

}
