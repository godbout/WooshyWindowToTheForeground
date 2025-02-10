import AlfredWorkflowScriptFilter


struct Window {
    
    let number: CGWindowID
    let title: String
    let appPID: pid_t
    let appName: String?
    let appIcon: String?
    
}


class Entrance {
    static let shared = Entrance()
    
    // TODO: WTF IS THIS
    static var screenRecordingGranted = false
    
    private init() {}
    
    
    static func scriptFilter() -> String {
        results()
    }
        
    static func results() -> String {
        guard let onscreenWindows = onscreenWindows() else {
            ScriptFilter.add(
                Item(title: "🚨️ Oops 🚨️ Something is failing badly. The smart thing to do is to report!")
                    .subtitle("Press ↵ to fly to the GitHub Issues page")
                    .arg("do")
                    .variable(Variable(name: "action", value: "headToGitHubIssues"))
            )
                    
            return ScriptFilter.output()
        }
        
        if onscreenWindows.isEmpty {
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
            let onscreenWindowsToShowInAlfredResults = filterOutFocusedWindow ? removeCurrentlyFocusedWindow(from: onscreenWindows) : onscreenWindows
            
            if onscreenWindowsToShowInAlfredResults.isEmpty {
                ScriptFilter.add(
                    Item(title: "The only visible window is the one you're already on!")
                        .subtitle("Press ↵ to go back to it")
                        .arg("do")
                        .variable(Variable(name: "action", value: "nothing"))
                )
            } else {
                for window in onscreenWindowsToShowInAlfredResults {
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
                            .mod(
                                Cmd()
                                    .subtitle("Exclude this Window from Alfred's Results")
                                    .arg("do")
                                    .variable(Variable(name: "windowTitle", value: window.title))
                                    .variable(Variable(name: "appName", value: window.appName))
                                    .variable(Variable(name: "action", value: "excludeWindowFromAlfredResults"))
                            )
                    )
                }
            }
        }
        
        return ScriptFilter.output()
    }
    
}


extension Entrance {
    
    private static func onscreenWindows() -> [Window]? {
        guard let tooManyWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as NSArray? else { return nil }
        
        // filter out:
        // 1. Menu Bar Icons
        // 2. Transparent Windows
        // 3. a bunch of Window Server Windows (Cursor, StatusIndicator, Menubar, etc.)
        // 4. Notification Center when it shows up (like receiving a Notification)
        // 5. a Screenshot Window that doesn't go away after you used Screenshot
        // 6. a bunch of Stage Manager Windows
        // 7. Alfred itself
        var windowsFilter = """
kCGWindowLayer != 25
&& kCGWindowAlpha > 0
&& kCGWindowOwnerName != "Window Server"
&& kCGWindowOwnerName != "Notification Center"
&& kCGWindowOwnerName != "Screenshot"
&& kCGWindowOwnerName != "WindowManager"
&& kCGWindowOwnerName != "Alfred"
"""

        excludedWindows()?.windows.forEach { excludedWindow in
            windowsFilter.append("""
&& !(kCGWindowOwnerName = "\(excludedWindow.appName)" && kCGWindowName = "\(excludedWindow.windowTitle)")
"""
            )
        }
               
        let onscreenWindows = tooManyWindows.filtered(using: NSPredicate(format: windowsFilter))
        
        var windows: [Window] = []
               
        for onscreenWindow in onscreenWindows {
            guard
                let onscreenWindow = onscreenWindow as? NSDictionary,
                let onscreenWindowNumber = onscreenWindow.value(forKey: "kCGWindowNumber") as? CGWindowID,
                let onscreenWindowOwnerPID = onscreenWindow.value(forKey: "kCGWindowOwnerPID") as? pid_t,
                let onscreenWindowOwnerName = onscreenWindow.value(forKey: "kCGWindowOwnerName") as? String
            else {
                continue
            }
            
            let onscreenWindowName = onscreenWindow.value(forKey: "kCGWindowName") as? String
            if onscreenWindowName == nil {
                continue
            } else {
                Self.screenRecordingGranted = true
            }
            
            var icon: String
            if
                let application = NSRunningApplication(processIdentifier: onscreenWindowOwnerPID),
                let bundleIdentifier = application.bundleIdentifier,
                let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
            {
                icon = url.path
            } else {
                icon = Bundle.main.bundlePath
            }
            
            let window = Window(
                number: onscreenWindowNumber,
                title: onscreenWindowName!,
                appPID: onscreenWindowOwnerPID,
                appName: onscreenWindowOwnerName,
                appIcon: icon
            )
            
            windows.append(window)
        }
        
        return windows
    }
    
    private static func excludedWindows() -> ExcludedWindows? {
        guard FileManager.default.fileExists(atPath: Workflow.excludedWindowsPlistFile) else { return nil }
        
        let excludedWindowsPlistFileURL = URL(fileURLWithPath: Workflow.excludedWindowsPlistFile)
        guard let data = try? Data(contentsOf: excludedWindowsPlistFileURL) else { return nil }
            
        let decoder = PropertyListDecoder()
        guard let excludedWindows = try? decoder.decode(ExcludedWindows.self, from: data) else { return nil }
        
        return excludedWindows
    }
        
    private static func removeCurrentlyFocusedWindow(from onscreenWindows: [Window]) -> [Window] {
        guard 
            let frontmostWindow = onscreenWindows.first,
            frontmostWindow.appPID == NSWorkspace.shared.frontmostApplication?.processIdentifier
        else {
            return onscreenWindows
        }
        
        return Array(onscreenWindows.dropFirst())
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
