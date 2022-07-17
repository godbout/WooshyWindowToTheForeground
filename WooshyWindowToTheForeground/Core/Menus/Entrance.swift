import AlfredWorkflowScriptFilter
// TODO: still needed?
import CoreGraphics
// TODO: still needed?
import Foundation
import AppKit


struct Window {
    
    let icon: String
    let app: String
    let title: String
    
}


class Entrance {
    static let shared = Entrance()

    private init() {}

    
    static func scriptFilter() -> String {
        results()
    }

    static func results() -> String {
        let visibleWindows = visibleWindows()
        
        for visibleWindow in visibleWindows {
            ScriptFilter.add(
                Item(title: "\(visibleWindow.app) — \(visibleWindow.title)")
                    .icon(Icon(path: visibleWindow.icon, type: .fileicon))
            )
        }
        
        return ScriptFilter.output()
    }
        
    private static func visibleWindows() -> [Window] {
        var windows: [Window] = []
        
        guard let tooManyWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as NSArray? else { return [] }
        guard let visibleWindows = tooManyWindows.filtered(using: NSPredicate(format: "kCGWindowLayer == 0 && kCGWindowAlpha != 0")) as NSArray? else { return [] }
        
        for visibleWindow in visibleWindows {
            guard let visibleWindow = visibleWindow as? NSDictionary else { continue }
            guard let visibleWindowOwnerPID = visibleWindow.value(forKey: "kCGWindowOwnerPID") as? pid_t else { continue }
            guard let visibleWindowOwnerName = visibleWindow.value(forKey: "kCGWindowOwnerName") as? String else { continue }
            guard let visibleWindowID = visibleWindow.value(forKey: "kCGWindowNumber") as? Int else { continue }
            
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
                icon: icon,
                app: visibleWindowOwnerName,
                title: String(visibleWindowID)
            )
            
            windows.append(window)
        }
        
        return windows
    }

}
