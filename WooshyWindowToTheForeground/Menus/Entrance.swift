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
                    
            if let release = Updater.updateAvailable() {
                ScriptFilter.add(updateItem(for: release))
            }
            
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
                            .variable(Variable(name: "windowNumber", value: String(window.number)))
                            .variable(Variable(name: "windowTitle", value: window.title))
                            .variable(Variable(name: "appPID", value: String(window.appPID)))
                            .variable(Variable(name: "action", value: "bringWindowToForeground"))
                    )
                }
            }
        }
        
        if let release = Updater.updateAvailable() {
            ScriptFilter.add(updateItem(for: release))
        }
        
        return ScriptFilter.output()
    }
    
}


extension Entrance {
    
    private static func updateItem(for release: ReleaseInfo) -> Item {
        Item(title: "Update available! (\(release.version))")
            .subtitle("Press ↵ to update, or ⌘↵ to take a trip to the release page")
            .arg("do")
            .variable(Variable(name: "AlfredWorkflowUpdater_action", value: "update"))
            .mod(
                Cmd()
                    .subtitle("Say hello to the release page")
                    .arg("do")
                    .variable(Variable(name: "AlfredWorkflowUpdater_action", value: "open"))
            )
    }
        
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
        
    private static func visibleWindowIsNotAMenuBarIcon(layer: Int, height: Double) -> Bool {
        layer != 25 || height > 37
    }
    
    // the previous version of this function was "safer" in the sense that it captured the exact Focused Window
    // while now the func removes the most top window that **should** be the Focused Window.
    // the change was made because the call to AXUIElementCopyAttributeValue was taking 40ms, which was almost doubling
    // the time it takes for the Workflow to grab the windows and render the Alfred Results. and that would make the
    // Workflow feel slow (to my taste). so yeah, priorities.
    private static func removeCurrentlyFocusedWindow(from visibleWindows: [Window]) -> [Window] {
        var visibleWindowsExcludingTheFocusedWindow = visibleWindows
        
        if visibleWindowsExcludingTheFocusedWindow.isEmpty == false {
            visibleWindowsExcludingTheFocusedWindow.removeFirst()
        }

        return visibleWindowsExcludingTheFocusedWindow
    }

}
