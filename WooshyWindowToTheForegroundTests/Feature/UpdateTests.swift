import XCTest


class UpdateTests: WooshyWindowToTheForegroundCoreTests {
    
    func test_that_if_there_is_an_updateAvailable_file_in_the_Workflow_cache_folder_then_we_show_the_update_in_Alfred_Results() throws {
        try? Self.mockAlreadyCreatedReleaseInfoFile()
        
        XCTAssertTrue(
            Workflow.menu().contains("Press ↵ to update, or ⌘↵ to take a trip to the release page")
        )        
    }
    
}
