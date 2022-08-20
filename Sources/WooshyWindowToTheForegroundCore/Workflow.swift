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
        case "headToREADME":
            return headToREADME()
        case "bringWindowToForeground":
            return bringWindowToForeground()
        case "promptPermissionDialogs":
            return promptPermissionDialogs()
        default:
            return false
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
        guard let appPID = Int(ProcessInfo.processInfo.environment["appPID"] ?? "") else { return false }
        let windowTitle = ProcessInfo.processInfo.environment["windowTitle"] ?? ""
        let windowBounds = NSRectFromString(ProcessInfo.processInfo.environment["windowBounds"] ?? "")
        
        let axApplication = AXUIElementCreateApplication(pid_t(appPID))
              
        var axWindows: AnyObject?
        guard AXUIElementCopyAttributeValue(axApplication, kAXWindowsAttribute as CFString, &axWindows) == .success else { return false }
        
        // first pass with trying to match titles
        for axWindow in (axWindows as! [AXUIElement]) {
            guard let title = axTitle(of: axWindow) else { continue }
            guard let bounds = axBounds(of: axWindow) else { continue }
            
           if windowTitle == title, windowBounds == bounds {
                return bringToForeground(window: axWindow, of: pid_t(appPID))
            }
        }
        
        // if no match has been found, it may be because the CG and AX are returning different
        // titles for the same window. happens with Dash, Chrome, Brave etc.
        // so we try again only with the bounds now
        for axWindow in (axWindows as! [AXUIElement]) {
            guard let bounds = axBounds(of: axWindow) else { continue }
            
            if windowBounds == bounds {
                return bringToForeground(window: axWindow, of: pid_t(appPID))
            }
        }
                
        return false
    }
        
    private static func axTitle(of axWindow: AXUIElement) -> String? {
        var axTitle: AnyObject?
        guard AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &axTitle) == .success else { return nil }
                
        return axTitle as? String
    }
    
    private static func axBounds(of axWindow: AXUIElement) -> NSRect? {
        var values: CFArray?
        guard AXUIElementCopyMultipleAttributeValues(axWindow, [kAXPositionAttribute, kAXSizeAttribute] as CFArray, AXCopyMultipleAttributeOptions(rawValue: 0), &values) == .success else { return nil }
        guard let windowValues = values as NSArray? else { return nil }
        
        var position = CGPoint()
        AXValueGetValue(windowValues[0] as! AXValue, .cgPoint, &position)
        var size = CGSize()
        AXValueGetValue(windowValues[1] as! AXValue, .cgSize, &size)
        
        return NSRect(x: position.x, y: position.y, width: size.width, height: size.height)
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

}
