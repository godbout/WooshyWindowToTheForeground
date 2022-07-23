import Foundation


struct UpdateInfo: Codable {
    
    let version: String
    let file: String
    let page: String
    
}


struct Updater {
    
    static func updateAvailable() -> UpdateInfo? {
        guard let alfredWorkflowCache = ProcessInfo.processInfo.environment["alfred_workflow_cache"] else { return nil }
        
        let updateFile = URL(fileURLWithPath: "\(alfredWorkflowCache)/update_available.plist")
        guard let updateData = try? Data(contentsOf: updateFile) else { return nil }
        
        let decoder = PropertyListDecoder()
        guard let updateInfo = try? decoder.decode(UpdateInfo.self, from: updateData) else { return nil } 
        
        return updateInfo
    }
    
}
