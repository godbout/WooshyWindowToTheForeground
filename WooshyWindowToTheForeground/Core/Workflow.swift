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
        case "headToREADME":
            return headToREADME()
        case "bringWindowToForeground":
            return bringWindowToForeground()
        default:
            return false
        }
    }
    
    private static func headToREADME() -> Bool {
        // TODO: add header
        NSWorkspace.shared.open(URL(string: "https://github.com/godbout/WooshyWindowToTheForeground")!)
        
        return true
    }
       
    private static func bringWindowToForeground() -> Bool {
        guard let appPID = Int(ProcessInfo.processInfo.environment["appPID"] ?? "") else { return false }
        let windowTitle = ProcessInfo.processInfo.environment["windowTitle"]
        
        let axApplication = AXUIElementCreateApplication(pid_t(appPID))
              
        var axWindows: AnyObject?
        guard AXUIElementCopyAttributeValue(axApplication, kAXWindowsAttribute as CFString, &axWindows) == .success else { return false }
        
        for axWindow in (axWindows as! [AXUIElement]) {
            var axTitle: AnyObject?
            guard AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &axTitle) == .success else { continue }
               
            if windowTitle == axTitle as? String {
                let app = NSRunningApplication(processIdentifier: pid_t(appPID))
                app?.activate(options: .activateIgnoringOtherApps)
                
                AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
                
                return true
            }
        }
                
        return false
    }

}
