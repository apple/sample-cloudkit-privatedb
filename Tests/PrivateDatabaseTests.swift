//
//  PrivateDatabaseTests.swift
//  (cloudkit-samples) private-database-tests
//

import XCTest
import CloudKit
@testable import PrivateDatabase

class Tests: XCTestCase {
    let viewModel = ViewModel(isTesting: true)

    override func setUpWithError() throws {
        self.executionTimeAllowance = 10
    }

    override func tearDownWithError() throws {}

    func test_CloudKitReadiness() async throws {
        // Fetch zones from the Private Database of the CKContainer for the current user to test for valid/ready state
        let container = CKContainer(identifier: Config.containerIdentifier)
        let database = container.privateCloudDatabase

        do {
            try await database.allRecordZones()
        } catch let error as CKError {
            switch error.code {
            case .badContainer, .badDatabase:
                XCTFail("Create or select a CloudKit container in this app target's Signing & Capabilities in Xcode")

            case .permissionFailure, .notAuthenticated:
                XCTFail("Simulator or device running this app needs a signed-in iCloud account")

            default:
                break
            }
        }
    }

    func testWriteToAndReadFromCloudKit() async throws {
        // Write a Person record to CloudKit with a random name, and read it back
        let randomName = UUID().uuidString

        try await viewModel.saveRecord(name: randomName)
        try await viewModel.refreshLastPerson()
        
        let lastPerson = await viewModel.lastPerson

        XCTAssertEqual(randomName, lastPerson,
                       "Attempted write value to CloudKit doesn't match attempted read value from CloudKit")
        
        try await viewModel.deleteLastPerson()
    }
}
