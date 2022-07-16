import Foundation
import AlfredWorkflowScriptFilter


public struct Workflow {
    
    public static func next() -> String {
        ProcessInfo.processInfo.environment["next"] ?? "oops"
    }

    public static func menu() -> String {
        Entrance.scriptFilter()
    }

    public static func `do`() -> Bool {
        false
    }

    public static func notify(resultFrom _: Bool = false) -> String {
        "huh wtf?"
    }

}
