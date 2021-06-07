//
//  ViewModel.swift
//  (cloudkit-samples) private-database
//

import os.log
import CloudKit

class ViewModel: ObservableObject {

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

    init(isTesting: Bool = false) {
        // Use a different unique record ID if testing.
        lastPersonRecordID = CKRecord.ID(recordName: isTesting ? "lastPersonTest" : "lastPerson")
        getLastPerson()
    }

    // MARK: - API

    /// Saves the given name as the last person in the database.
    /// - Parameters:
    ///   - name: Name to attach to the record as the last person.
    ///   - completionHandler: An optional handler to process completion `success` or `failure`.
    func saveRecord(name: String, completionHandler: ((Result<Void, Error>) -> Void)? = nil) {
        let lastPersonRecord = CKRecord(recordType: "Person", recordID: lastPersonRecordID)
        lastPersonRecord["name"] = name

        // We'll use a CKModifyRecordsOperation instead of the convenience "save" method
        // on CKDatabase so that we can customize savePolicy. (For this sample, we'd like
        // to overwrite the server version of the record in all cases, regardless of what's
        // on the server.
        let saveOperation = CKModifyRecordsOperation(recordsToSave: [lastPersonRecord])
        saveOperation.savePolicy = .allKeys

        // This completion block will execute once for every record saved. In this sample,
        // we will only ever be saving a single record, so we only expect this to get called
        // once.
        saveOperation.perRecordCompletionBlock = { record, error in
            os_log("Record with ID \(record.recordID.recordName) was saved.")

            if let error = error {
                self.reportError(error)
            }

            self.getLastPerson()
        }

        // This completion block will execute once when the entire CKModifyRecordsOperation
        // is complete. We'll use it in this sample to see errors, if any. Note that we could
        // have used this single modifyRecordsCompletionBlock instead of the perRecordCompletionBlock
        // in this sample and simply parsed the array of records passed in, of which there would
        // only have been one in this particular sample. In this sample, we are using both for
        // illustrative purposes.
        saveOperation.modifyRecordsCompletionBlock = { _, _, error in
            if let error = error {
                self.reportError(error)

                // If a completion was supplied, pass along the error here.
                completionHandler?(.failure(error))
            } else {
                // If a completion was supplied, like during tests, call it back now.
                completionHandler?(.success(()))
            }
        }

        database.add(saveOperation)
    }

    /// Deletes the last person record.
    /// - Parameter completionHandler: An optional handler to process completion `success` or `failure`.
    func deleteLastPerson(completionHandler: ((Result<Void, Error>) -> Void)? = nil) {
        database.delete(withRecordID: lastPersonRecordID) { recordID, error in
            if let recordID = recordID {
                os_log("Record with ID \(recordID.recordName) was deleted.")
            }

            if let error = error {
                self.reportError(error)

                // If a completion was supplied, pass along the error here.
                completionHandler?(.failure(error))
            } else {
                // If a completion was supplied, like during tests, call it back now.
                completionHandler?(.success(()))
            }
        }
    }

    /// Fetches the last person record and updates the published `lastPerson` property in the VM.
    /// - Parameter completionHandler: An optional handler to process completion `success` or `failure`.
    func getLastPerson(completionHandler: ((Result<Void, Error>) -> Void)? = nil) {
        // Here, we will use the convenience "fetch" method on CKDatabase, instead of
        // CKFetchRecordsOperation, which is more flexible but also more complex.
        database.fetch(withRecordID: lastPersonRecordID) { record, error in
            if let record = record {
                os_log("Record with ID \(record.recordID.recordName) was fetched.")
                if let name = record["name"] as? String {
                    DispatchQueue.main.async {
                        self.lastPerson = name
                    }
                }
            }

            if let error = error {
                self.reportError(error)

                // If a completion was supplied, pass along the error here.
                completionHandler?(.failure(error))
            } else {
                // If a completion was supplied, like during tests, call it back now.
                completionHandler?(.success(()))
            }
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
