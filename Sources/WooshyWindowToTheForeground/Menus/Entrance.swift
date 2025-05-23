import AlfredWorkflowScriptFilter


struct Window {
    
    let number: CGWindowID
    let title: String
    let appPID: pid_t
    let appName: String
    let appIcon: String
    
}


class Entrance {
    
    static let shared = Entrance()
    
    private init() {}
    
    
    static func scriptFilter() -> String {
        if argument == "excluded" {
            return resultsForExcludedWindows()
        } else {
            return resultsForOnscreenWindowsExcludingExcludedWindowsLOL()
        }
    }
        
}


extension Entrance {
    
    private static var argument: String? {
        guard CommandLine.arguments.count >= 2 else { return nil }
        
        return CommandLine.arguments[1]
    }

    private static func resultsForExcludedWindows() -> String {
        guard let excludedWindows = excludedWindows()?.windows else {
            ScriptFilter.add(
                Item(title: "🚨️ Oops 🚨️ Something is failing badly. The smart thing to do is to report!")
                    .subtitle("Press ↵ to fly to the GitHub Issues page")
                    .arg("do")
                    .variable(Variable(name: "action", value: "headToGitHubIssues"))
            )
            
            return ScriptFilter.output()
        }
        
        if excludedWindows.isEmpty {
            ScriptFilter.add(
                Item(title: "You haven't excluded any Window yet!")
                    .valid(false)
            )
        } else {
            for window in excludedWindows {
                ScriptFilter.add(
                    Item(title: window.title)
                        .subtitle(window.appName)
                        .match("\(window.appName) \(window.title)")
                        .icon(Icon(path: window.appIcon, type: .fileicon))
                        .arg("do")
                        .variable(Variable(name: "windowTitle", value: window.title))
                        .variable(Variable(name: "appName", value: window.appName))
                        .variable(Variable(name: "action", value: "includeBackWindow"))
                        .mod(
                            Cmd()
                                .subtitle("Unban this Window")
                                .arg("do")
                                .variable(Variable(name: "windowTitle", value: window.title))
                                .variable(Variable(name: "appName", value: window.appName))
                                .variable(Variable(name: "action", value: "includeBackWindow"))
                        )
                )
            }
            
        }
        
        return ScriptFilter.output()
    }
    
    private static func resultsForOnscreenWindowsExcludingExcludedWindowsLOL() -> String {
        guard let windowsToShowInAlfredResults = onscreenWindowsExcludingExcludedWindowsLOL() else {
            ScriptFilter.add(
                Item(title: "🚨️ Oops 🚨️ Something is failing badly. The smart thing to do is to report!")
                    .subtitle("Press ↵ to fly to the GitHub Issues page")
                    .arg("do")
                    .variable(Variable(name: "action", value: "headToGitHubIssues"))
            )
            
            return ScriptFilter.output()
        }
            
        if windowsToShowInAlfredResults.isEmpty {
            if CGPreflightScreenCaptureAccess() == true {
                ScriptFilter.add(
                    Item(title: "Desktop is all clean! No Window found.")
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
            let windowsToShowInAlfredResults = filterOutFocusedWindow ? removeCurrentlyFocusedWindow(from: windowsToShowInAlfredResults) : windowsToShowInAlfredResults
            
            if windowsToShowInAlfredResults.isEmpty {
                ScriptFilter.add(
                    Item(title: "The only visible Window is the one you're already on!")
                        .subtitle("Press ↵ to go back to it")
                        .arg("do")
                        .variable(Variable(name: "action", value: "nothing"))
                )
            } else {
                for window in windowsToShowInAlfredResults {
                    ScriptFilter.add(
                        Item(title: window.title)
                            .subtitle(window.appName)
                            .match("\(window.appName) \(window.title)")
                            .icon(Icon(path: window.appIcon, type: .fileicon))
                            .arg("do")
                            .variable(Variable(name: "windowNumber", value: String(window.number)))
                            .variable(Variable(name: "windowTitle", value: window.title))
                            .variable(Variable(name: "appPID", value: String(window.appPID)))
                            .variable(Variable(name: "action", value: "bringWindowToForeground"))
                            .mod(
                                Cmd()
                                    .subtitle("Ban this Window from Alfred's Results")
                                    .arg("do")
                                    .variable(Variable(name: "windowTitle", value: window.title))
                                    .variable(Variable(name: "appName", value: window.appName))
                                    .variable(Variable(name: "appIcon", value: window.appIcon))
                                    .variable(Variable(name: "action", value: "excludeWindowFromAlfredResults"))
                            )
                    )
                }
            }
        }
                
        return ScriptFilter.output()
    }
    
    private static func onscreenWindowsExcludingExcludedWindowsLOL() -> [Window]? {
        guard let tooManyWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as NSArray? else { return nil }
        
        // keep Windows that are:
        // 1. not Menu Bar Icons (back to using kCGWindowLayer 25 as Apple finally fixed its kCGStatusWindowLevel vs kCGModalPanelWindowLevel fuckery)
        // 2. not Transparent Windows
        // 3. not a bunch of Window Server Windows (Cursor, StatusIndicator, Menubar, etc.)
        // 4. not Notification Center Windows that show up when receiving Notifications
        // 5. not a Screenshot Window that doesn't go away after you used Screenshot
        // 6. not a bunch of Stage Manager Windows
        // 7. not Alfred itself (Alfred Preferences is something else altogether and is embraced)
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
            // necessary because of Korean: https://developer.apple.com/documentation/foundation/nscharacterset/decomposables#Discussion LOL
            let precomposedAppName = String(data: excludedWindow.appName.precomposedStringWithCanonicalMapping.data(using: .utf8) ?? Data(), encoding: .utf8) ?? ""
            let precomposedWindowTitle = String(data: excludedWindow.title.precomposedStringWithCanonicalMapping.data(using: .utf8) ?? Data(), encoding: .utf8) ?? ""
            
            windowsFilter.append("""
&& !(kCGWindowOwnerName = "\(precomposedAppName)" && kCGWindowName = "\(precomposedWindowTitle)")
"""
            )
        }
               
        let windows: [Window] = tooManyWindows.filtered(using: NSPredicate(format: windowsFilter)).compactMap { window in
            guard
                let window = window as? NSDictionary,
                let windowNumber = window.value(forKey: "kCGWindowNumber") as? CGWindowID,
                let windowOwnerPID = window.value(forKey: "kCGWindowOwnerPID") as? pid_t,
                let windowOwnerName = window.value(forKey: "kCGWindowOwnerName") as? String,
                let windowName = window.value(forKey: "kCGWindowName") as? String
            else {
                return nil
            }
            
            return Window(
                number: windowNumber,
                title: windowName,
                appPID: windowOwnerPID,
                appName: windowOwnerName,
                appIcon: NSRunningApplication(processIdentifier: windowOwnerPID)?.bundleURL?.path ?? Bundle.main.bundlePath
            )
        }
        
        return windows
    }
    
    private static func excludedWindows() -> ExcludedWindows? {
        guard
            let excludedWindowsPlistFile = Workflow.excludedWindowsPlistFile,
            FileManager.default.fileExists(atPath: excludedWindowsPlistFile)
        else {
            return nil
        }
        
        let excludedWindowsPlistFileURL = URL(fileURLWithPath: excludedWindowsPlistFile)
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
