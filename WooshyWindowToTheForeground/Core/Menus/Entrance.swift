import AlfredWorkflowScriptFilter
import Foundation


class Entrance {
    static let shared = Entrance()

    private init() {}

    static func scriptFilter() -> String {
        results()
    }

    static func results() -> String {
        ScriptFilter.add(
            Item(title: "hehe")
        )
        
        return ScriptFilter.output()
    }

}
