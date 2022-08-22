import AlfredWorkflowScriptFilter
import AppKit


struct Window {
    
    let number: CGWindowID
    let title: String
    let appPID: pid_t
    let appName: String?
    let appIcon: String?
    let title: String
    let bounds: NSRect
    
}


class Entrance {
    static let shared = Entrance()
    
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
            ScriptFilter.add(
                Item(title: "Desktop is all clean! No window found.")
                    .subtitle("Doesn't feel right? Maybe you haven't granted permissions. Press ↵ for the prompts, ⌘↵ for the README")
                    .arg("do")
                    .variable(Variable(name: "action", value: "promptPermissionDialogs"))
                    .mod(
                        Cmd()
                            .subtitle("README here I come!")
                            .arg("do")
                            .variable(Variable(name: "action", value: "headToREADME"))
                    )
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
    
    // kCGWindowLayer:
    // 0: normal windows
    // 8: don't remember
    // 20: Character View when not extended
    // 23: don't remember
    // 25: stuff from the status bar. was filtered out at first but some windows like the Apple ID 2FA shows up as 25.
    // so now we grab them, and filter out the ones that have a small height because those ones are probably icons for the status bar.
    // 28: Character View when extended
    private static func cgVisibleWindows() -> [Window]? {
        guard let tooManyWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as NSArray? else { return nil }
        guard let visibleWindows = tooManyWindows.filtered(using: NSPredicate(format: """
            (
                kCGWindowLayer == 0
                || kCGWindowLayer == 8
                || kCGWindowLayer == 20
                || kCGWindowLayer == 23
                || kCGWindowLayer == 25
                || kCGWindowLayer == 28
            )
            && kCGWindowAlpha > 0
            """)) as NSArray? else { return nil }
        
        var windows: [Window] = []
               
        for visibleWindow in visibleWindows {
            guard
                let visibleWindow = visibleWindow as? NSDictionary,
                let visibleWindowLayer = visibleWindow.value(forKey: "kCGWindowLayer") as? Int,
                let visibleWindowNumber = visibleWindow.value(forKey: "kCGWindowNumber") as? CGWindowID,
                let visibleWindowOwnerPID = visibleWindow.value(forKey: "kCGWindowOwnerPID") as? pid_t,
                let visibleWindowOwnerName = visibleWindow.value(forKey: "kCGWindowOwnerName") as? String,
                let visibleWindowName = visibleWindow.value(forKey: "kCGWindowName") as? String,
                let bounds = visibleWindow.value(forKey: "kCGWindowBounds") as? NSDictionary,
                let height = bounds.value(forKey: "Height") as? CGFloat
            else {
                continue
            }
            
            guard visibleWindowIsNotAMenuBarIcon(layer: visibleWindowLayer, height: height) else { continue }
                
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
                title: visibleWindowName,
                appPID: visibleWindowOwnerPID,
                appName: visibleWindowOwnerName,
                appIcon: icon
            )
            
            windows.append(window)
        }
        
        return windows
    }
        
    private static func visibleWindowIsNotAMenuBarIcon(layer: Int, height: Double) -> Bool {
        layer != 25 || height > 24
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
