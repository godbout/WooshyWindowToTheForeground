struct ExcludedWindows: Codable {
    
    var windows: [ExcludedWindow]
    
}

struct ExcludedWindow: Codable {
    
    let title: String
    let appName: String
    let appIcon: String
    
}


public struct Workflow {
    
    static let excludedWindowsPlistFile = "\(ProcessInfo.processInfo.environment["alfred_workflow_data"] ?? "")/excluded_windows.plist"
    
    public static func next() -> String {
        ProcessInfo.processInfo.environment["next"] ?? "oops"
    }
    
    public static func menu() -> String {
        createExcludedWindowsPlistFileIfNecessary()
        
        return Entrance.scriptFilter()
    }
    
    public static func `do`() -> Bool {
        switch ProcessInfo.processInfo.environment["action"] {
        case "headToGitHubIssues":
            return headToGitHubIssues()
        case "headToREADME":
            return headToREADME()
        case "bringWindowToForeground":
            return bringWindowToForeground()
        case "promptPermissionDialogs":
            return promptPermissionDialogs()
        case "excludeWindowFromAlfredResults":
            return excludeWindowFromAlfredResults()
        case "includeBackWindow":
            return includeBackWindow()
        default:
            return false
        }
    }
    
}


extension Workflow {

    private static func createExcludedWindowsPlistFileIfNecessary() {
        if FileManager.default.fileExists(atPath: excludedWindowsPlistFile) == false {
            let encoder = PropertyListEncoder()
            guard let encoded = try? encoder.encode(ExcludedWindows(windows: [])) else { return }
            
            FileManager.default.createFile(atPath: excludedWindowsPlistFile, contents: encoded)
        }
    }
    
    private static func headToGitHubIssues() -> Bool {
        NSWorkspace.shared.open(URL(string: "https://github.com/godbout/WooshyWindowToTheForeground/issues")!)
        
        return true
    }
    
    private static func headToREADME() -> Bool {
        NSWorkspace.shared.open(URL(string: "https://github.com/godbout/WooshyWindowToTheForeground#permissions")!)
        
        return true
    }
    
    private static func bringWindowToForeground() -> Bool {
        guard let windowNumber = Int(ProcessInfo.processInfo.environment["windowNumber"] ?? "") else { return false }
        guard let appPID = Int(ProcessInfo.processInfo.environment["appPID"] ?? "") else { return false }
        
        let axApplication = AXUIElementCreateApplication(pid_t(appPID))
              
        var axWindows: AnyObject?
        guard AXUIElementCopyAttributeValue(axApplication, kAXWindowsAttribute as CFString, &axWindows) == .success else { return false }
        
        for axWindow in (axWindows as! [AXUIElement]) {
            guard let number = axWindowNumber(of: axWindow) else { continue }
                       
            if number == windowNumber {
                return bringToForeground(window: axWindow, of: pid_t(appPID))
            }
        }
                
        return false
    }
        
    private static func axWindowNumber(of axWindow: AXUIElement) -> CGWindowID? {
        var axWindowNumber: CGWindowID = 0
        guard _AXUIElementGetWindow(axWindow, &axWindowNumber) == .success else { return nil }
                
        return axWindowNumber
    }
        
    private static func bringToForeground(window: AXUIElement, of pid: pid_t) -> Bool {
        let app = NSRunningApplication(processIdentifier: pid)
        app?.activate(options:.activateIgnoringOtherApps)
        
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        
        return true
    }
    
    private static func promptPermissionDialogs() -> Bool {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true] as CFDictionary)
        CGRequestScreenCaptureAccess()
        
        return true
    }
    
    private static func excludeWindowFromAlfredResults() -> Bool {
        guard
            let windowTitle = ProcessInfo.processInfo.environment["windowTitle"],
            let appName = ProcessInfo.processInfo.environment["appName"],
            let appIcon = ProcessInfo.processInfo.environment["appIcon"]
        else { return false }

        if FileManager.default.fileExists(atPath: excludedWindowsPlistFile) {
            let excludedWindowsPlistFileURL = URL(fileURLWithPath: excludedWindowsPlistFile)
            guard let data = try? Data(contentsOf: excludedWindowsPlistFileURL) else { return false }
            
            let decoder = PropertyListDecoder()
            guard var excludedWindows = try? decoder.decode(ExcludedWindows.self, from: data) else { return false }
            
            excludedWindows.windows.append(ExcludedWindow(title: windowTitle, appName: appName, appIcon: appIcon))
            
            let encoder = PropertyListEncoder()
            guard let encoded = try? encoder.encode(excludedWindows) else { return false }
            
            try? encoded.write(to: excludedWindowsPlistFileURL)
        }
        
        return true
    }
    
    private static func includeBackWindow() -> Bool {
        guard
            let windowTitle = ProcessInfo.processInfo.environment["windowTitle"],
            let appName = ProcessInfo.processInfo.environment["appName"]
        else { return false }

        if FileManager.default.fileExists(atPath: excludedWindowsPlistFile) {
            let excludedWindowsPlistFileURL = URL(fileURLWithPath: excludedWindowsPlistFile)
            guard let data = try? Data(contentsOf: excludedWindowsPlistFileURL) else { return false }
            
            let decoder = PropertyListDecoder()
            guard var excludedWindows = try? decoder.decode(ExcludedWindows.self, from: data) else { return false }
            
            excludedWindows.windows.removeAll { window in
                window.title == windowTitle && window.appName == appName
            }
            
            let encoder = PropertyListEncoder()
            guard let encoded = try? encoder.encode(excludedWindows) else { return false }
            
            try? encoded.write(to: excludedWindowsPlistFileURL)
        }
        
        return true
    }

}
