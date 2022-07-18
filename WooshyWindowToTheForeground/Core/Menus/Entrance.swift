import AlfredWorkflowScriptFilter
import AppKit


class Entrance {
    static let shared = Entrance()

    private init() {}

    
    static func scriptFilter() -> String {
        results()
    }

    static func results() -> String {
        guard let visibleWindows = visibleWindows() else {
            ScriptFilter.add(
                Item(title: "Oops. Can't grab windows. macOS requires you to grant permissions manually.")
                    .subtitle("Press ↵ to head to the README and learn how to grant those permissions")
                    .arg("do")
                    .variable(Variable(name: "action", value: "headToREADME"))
            )
                        
            return ScriptFilter.output()
        }
        
        if visibleWindows.isEmpty {
            ScriptFilter.add(
                Item(title: "Desktop is all clean! No window found.")
                    .arg("do")
                    .valid(false)
            )
        } else {
            for visibleWindow in visibleWindows {
                ScriptFilter.add(
                    Item(title: visibleWindow.title)
                        .uid(visibleWindow.appName + visibleWindow.title)
                        .subtitle(visibleWindow.appName)
                        .match("\(visibleWindow.appName) \(visibleWindow.title)")
                        .icon(Icon(path: visibleWindow.appIcon, type: .fileicon))
                        .arg("do")
                        .variable(Variable(name: "action", value: "bringWindowToForeground"))
                        .variable(Variable(name: "appPID", value: String(visibleWindow.appPID)))
                        .variable(Variable(name: "windowTitle", value: visibleWindow.title))
                        .variable(Variable(name: "windowBounds", value: NSStringFromRect(visibleWindow.bounds)))
                )
            }
        }
       
        return ScriptFilter.output()
    }
        
    private static func visibleWindows() -> [Window]? {
        guard let tooManyWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as NSArray? else { return nil }
        guard let visibleWindows = tooManyWindows.filtered(using: NSPredicate(format: "kCGWindowLayer == 0 && kCGWindowAlpha != 0")) as NSArray? else { return nil }
        
        var windows: [Window] = []
               
        for visibleWindow in visibleWindows {
            guard let visibleWindow = visibleWindow as? NSDictionary else { continue }
            guard let visibleWindowOwnerPID = visibleWindow.value(forKey: "kCGWindowOwnerPID") as? pid_t else { continue }
            guard let visibleWindowOwnerName = visibleWindow.value(forKey: "kCGWindowOwnerName") as? String else { continue }
            guard let visibleWindowName = visibleWindow.value(forKey: "kCGWindowName") as? String else { return nil }
            guard let bounds = visibleWindow.value(forKey: "kCGWindowBounds") as? NSDictionary else { return nil }
            guard let height = bounds.value(forKey: "Height") as? CGFloat else { return nil }
            guard let width = bounds.value(forKey: "Width") as? CGFloat else { return nil }
            guard let x = bounds.value(forKey: "X") as? CGFloat else { return nil }
            guard let y = bounds.value(forKey: "Y") as? CGFloat else { return nil }

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
                appPID: visibleWindowOwnerPID,
                appName: visibleWindowOwnerName,
                appIcon: icon,
                title: visibleWindowName,
                bounds: NSRect(x: x, y: y, width: width, height: height)
            )
            
            windows.append(window)
        }
        
        return windows
    }

}
