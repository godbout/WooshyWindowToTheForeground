import Foundation
import AlfredWorkflowScriptFilter
import AppKit


public struct Workflow {
    
    public static func next() -> String {
        ProcessInfo.processInfo.environment["next"] ?? "oops"
    }
    
    public static func menu() -> String {
        Entrance.scriptFilter()
    }
    
    public static func `do`() -> Bool {
        switch ProcessInfo.processInfo.environment["action"] {
        case "headToGitHubIssues":
            return headToGitHubIssues()
        case "bringWindowToForeground":
            return bringWindowToForeground()
        default:
            return false
        }
    }
    
    private static func headToGitHubIssues() -> Bool {
        NSWorkspace.shared.open(URL(string: "https://github.com/godbout/WooshyWindowToTheForeground/issues")!)
        
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

}
