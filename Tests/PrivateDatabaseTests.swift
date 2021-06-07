//
//  PrivateDatabaseTests.swift
//  (cloudkit-samples) private-database-tests
//

import XCTest
import CloudKit
@testable import PrivateDatabase

class Tests: XCTestCase {
    let viewModel = ViewModel(isTesting: true)

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {
        let deleteExpectation = expectation(description: "Expect CloudKit delete to complete")
        viewModel.deleteLastPerson() { result in
            if case let .failure(error) = result {
                XCTFail("Error deleting last person: \(error)")
            }
            deleteExpectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
     }

    func test_CloudKitReadiness() throws {
        // Fetch zones from the Private Database of the CKContainer for the current user to test for valid/ready state
        let container = CKContainer(identifier: Config.containerIdentifier)
        let database = container.privateCloudDatabase

        let fetchExpectation = expectation(description: "Expect CloudKit fetch to complete")
        database.fetchAllRecordZones { _, error in
            if let error = error as? CKError {
                switch error.code {
                case .badContainer, .badDatabase:
                    XCTFail("Create or select a CloudKit container in this app target's Signing & Capabilities in Xcode")

                case .permissionFailure, .notAuthenticated:
                    XCTFail("Simulator or device running this app needs a signed-in iCloud account")

                default:
                    return
                }
            }
            fetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testWriteToAndReadFromCloudKit() throws {
        // Write a Person record to CloudKit with a random name, and read it back
        let randomName = UUID().uuidString

        let saveExpectation = expectation(description: "Expect CloudKit save to complete")
        viewModel.saveRecord(name: randomName) { result in
            if case let .failure(error) = result {
                XCTFail("Error saving record: \(error)")
            }
            saveExpectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        let fetchExpectation = expectation(description: "Expect CloudKit fetch to complete")
        viewModel.getLastPerson() { result in
            if case let .failure(error) = result {
                XCTFail("Error fetching last person: \(error)")
            }

            fetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(randomName, viewModel.lastPerson,
                       "Attempted write value to CloudKit doesn't match attempted read value from CloudKit")
    }
}
