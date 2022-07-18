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
        NSWorkspace.shared.open(URL(string: "https://github.com/godbout/WooshyWindowToTheForeground#permissions")!)
        
        return true
    }
    
    private static func bringWindowToForeground() -> Bool {
        guard let appPID = Int(ProcessInfo.processInfo.environment["appPID"] ?? "") else { return false }
        let windowTitle = ProcessInfo.processInfo.environment["windowTitle"] ?? ""
        let windowBounds = NSRectFromString(ProcessInfo.processInfo.environment["windowBounds"] ?? "")
        
        let axApplication = AXUIElementCreateApplication(pid_t(appPID))
              
        var axWindows: AnyObject?
        guard AXUIElementCopyAttributeValue(axApplication, kAXWindowsAttribute as CFString, &axWindows) == .success else { return false }
        
        for axWindow in (axWindows as! [AXUIElement]) {
            var values: CFArray?
            guard AXUIElementCopyMultipleAttributeValues(axWindow, [kAXTitleAttribute, kAXPositionAttribute, kAXSizeAttribute] as CFArray, AXCopyMultipleAttributeOptions(rawValue: 0), &values) == .success else { continue }
            guard let windowValues = values as NSArray? else { continue }
                       
            let title = windowValues[0] as? String
            var position = CGPoint()
            AXValueGetValue(windowValues[1] as! AXValue, .cgPoint, &position)
            var size = CGSize()
            AXValueGetValue(windowValues[2] as! AXValue, .cgSize, &size)
            let bounds = NSRect(x: position.x, y: position.y, width: size.width, height: size.height)
            
            if windowTitle.isNotEmpty, windowTitle == title, windowBounds == bounds {
                return bringToForeground(window: axWindow, of: pid_t(appPID))
            } else if windowBounds == bounds {
                return bringToForeground(window: axWindow, of: pid_t(appPID))
            }
        }
                
        return false
    }
    
    private static func bringToForeground(window: AXUIElement, of pid: pid_t) -> Bool {
        let app = NSRunningApplication(processIdentifier: pid)
        app?.activate(options:.activateIgnoringOtherApps)
        
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        
        return true
    }

}
