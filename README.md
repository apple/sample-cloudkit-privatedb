# CloudKit Samples: Private Database

## Goals

This buildable (and testable) Xcode project demonstrates a simple use of the CloudKit Private Database. It allows you easily try out reading from and writing to a Private Database for a user in your own container on CloudKit servers.

## Prerequisites

* An [Apple Developer Program membership](https://developer.apple.com/support/compare-memberships/) is needed to create a CloudKit container.

* A Mac with [Xcode 12](https://developer.apple.com/xcode/) (or later) installed is required to build and test this project.

## Setup Steps

1. Clone this sample code repository
1. Open `PrivateDatabase.xcodeproj` in Xcode
1. In the General tab of `PrivateDatabase` Target in Xcode, set your own Bundle Identifier
1. In the Accounts section of Xcode Preferences, sign into your developer account (in Xcode) if needed
1. In the Signing & Capabilities tab of `PrivateDatabase` Target in Xcode, choose your account's Team
1. In the Signing & Capabilities tab of `PrivateDatabaseTests` Target in Xcode, choose your account's Team
1. In the Signing & Capabilities tab of `PrivateDatabase` Target in Xcode, choose existing iCloud container (or press "+" to create a new container)
1. Update the `containerIdentifier` property in `Config.swift` with your iCloud container name
1. Launch a Simulator (for example, via the Xcode menu in the menu bar) and ensure the Simulator is logged into an iCloud account in Settings
1. Test the app in the Simulator (from the Product menu in Xcode)
1. Run the app in the Simulator (from the Product menu in Xcode)

## How It Works

* Upon launch, the app reads a single record from the CloudKit server.

* Specifically, this record resides in the Default Zone of the currently signed-in iCloud user's Private Database in the app's CloudKit Container.

* The record is of type "Person". The "Person" record type, as defined in the CloudKit Container's Schema by the app's developer, has a single custom string field called "name".

* The specific CloudKit record the app reads has a well-known record ID of "lastPerson". (This well-known ID is hardcoded in the app.)

* The app's UI displays the name of the last person to write their name into the "name" field of this record on the server.

* When the user of the app enters their own name into a text field in the UI, the app writes the user's name into the "name" field of this same CloudKit Record and saves it back to the CloudKit Server.

* Subsequent launches of this app from this device (or other devices) will show this user's name until another user's name is written into the "name" field of the same CloudKit Record.

## Things To Learn

* A working Xcode project that interacts with the CloudKit server

* Some basic data flows between CloudKit and a SwiftUI `View`

* Reading from and writing to a CloudKit Private Database

* Writing a CloudKit record using `CKModifyRecordsOperation`

* Overriding the default `savePolicy` when writing

* Fetching an explicit record by ID using the `fetch(withRecordID:)` convenience method on `CKDatabase`

* Some basic error trapping of `CKError` errors, including those embedded in `partialFailure`

* Some basic testing using `XCTest`

## Further Reading

* [Running Your App in the Simulator or on a Device](https://developer.apple.com/documentation/xcode/running_your_app_in_the_simulator_or_on_a_device)

* [CloudKit Private Database](https://developer.apple.com/documentation/cloudkit/ckcontainer/1399205-privateclouddatabase)
