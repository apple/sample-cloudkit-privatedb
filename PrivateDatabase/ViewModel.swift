//
//  ViewModel.swift
//  (cloudkit-samples) private-database
//

import os.log
import CloudKit

/// Our class primarily sets properties for the UI, so the entire model is in the MainActor context
@MainActor class ViewModel: ObservableObject {

    // MARK: - Properties

    /// The CloudKit container to use. Update with your own container identifier.
    private let container = CKContainer(identifier: Config.containerIdentifier)

    /// This sample uses the private database, which requires a logged in iCloud account.
    private lazy var database = container.privateCloudDatabase

    /// This sample uses a singleton record ID, referred to by this property.
    /// CloudKit uses `CKRecord.ID` objects to represent record IDs.
    private let lastPersonRecordID: CKRecord.ID

    /// Publish the fetched last person to our view.
    @Published var lastPerson = String()

    // MARK: - Init

    nonisolated init(isTesting: Bool = false) {
        // Use a different unique record ID if testing.
        lastPersonRecordID = CKRecord.ID(recordName: isTesting ? "lastPersonTest" : "lastPerson")
        Task {
            try? await self.refreshLastPerson()
        }
    }

    // MARK: - API

    /// Saves the given name as the last person in the database.
    /// - Parameters:
    ///   - name: Name to attach to the record as the last person.
    func saveRecord(name: String) async throws {
        let lastPersonRecord = CKRecord(recordType: "Person", recordID: lastPersonRecordID)
        lastPersonRecord["name"] = name

        let recordResult: Result<CKRecord, Error>
        // With the CloudKit async API, we can customize savePolicy. (For this sample, we'd like
        // to overwrite the server version of the record in all cases, regardless of what's
        // on the server.
        do {
            let (saveResults, _) = try await database.modifyRecords(saving: [lastPersonRecord],
                                                                    deleting: [],
                                                                    savePolicy: .allKeys)
            // In this sample, we will only ever be saving a single record,
            // so we only expect one returned result.  We know that if the
            // function did not throw, we'll have a result for every record
            // we attempted to save
            recordResult = saveResults[lastPersonRecordID]!
        } catch let functionError { // Handle per-function error
            self.reportError(functionError)
            // Give callers a chance to handle this error as they like
            throw functionError
        }
        
        switch recordResult {
        case .success(let savedRecord):
            os_log("Record with ID \(savedRecord.recordID.recordName) was saved.")
            try await self.refreshLastPerson()
            
        case .failure(let recordError): // Handle per-record error
            self.reportError(recordError)
            // Give callers a chance to handle this error as they like
            throw recordError
        }
    }

    /// Deletes the last person record.
    func deleteLastPerson() async throws {
        do {
            let recordID = try await database.deleteRecord(withID: lastPersonRecordID)
            os_log("Record with ID \(recordID.recordName) was deleted.")
        } catch {
            self.reportError(error)
            throw error
        }
    }

    /// Fetches the last person record and updates the published `lastPerson` property in the VM.
    func refreshLastPerson() async throws {
        // Here, we will use the convenience async method on CKDatabase
        // to fetch a single CKRecord
        do {
            let record = try await database.record(for: lastPersonRecordID)
            os_log("Record with ID \(record.recordID.recordName) was fetched.")
            if let name = record["name"] as? String {
                self.lastPerson = name
            }
        } catch {
            self.reportError(error)
            // Give callers a chance to handle this error as they like
            throw error
        }
    }

    // MARK: - Helpers

    private func reportError(_ error: Error) {
        guard let ckerror = error as? CKError else {
            os_log("Not a CKError: \(error.localizedDescription)")
            return
        }

        switch ckerror.code {
        case .partialFailure:
            // Iterate through error(s) in partial failure and report each one.
            let dict = ckerror.userInfo[CKPartialErrorsByItemIDKey] as? [NSObject: CKError]
            if let errorDictionary = dict {
                for (_, error) in errorDictionary {
                    reportError(error)
                }
            }

        // This switch could explicitly handle as many specific errors as needed, for example:
        case .unknownItem:
            os_log("CKError: Record not found.")

        case .notAuthenticated:
            os_log("CKError: An iCloud account must be signed in on device or Simulator to write to a PrivateDB.")

        case .permissionFailure:
            os_log("CKError: An iCloud account permission failure occured.")

        case .networkUnavailable:
            os_log("CKError: The network is unavailable.")

        default:
            os_log("CKError: \(error.localizedDescription)")
        }
    }

}
