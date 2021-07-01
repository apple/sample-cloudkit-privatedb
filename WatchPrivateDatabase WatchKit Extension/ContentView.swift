//
//  ContentView.swift
//  (cloudkit-samples) private-database
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: ViewModel

    @State var nameInput: String = ""

    var body: some View {
        ScrollView {
            VStack {
                Text("Hello there.")
                Text("The last person was ") +
                    Text(vm.lastPerson.isEmpty ? "Nobody" : vm.lastPerson)
                    .fontWeight(.bold)
                    .foregroundColor(Color.purple) +
                    Text("!")
                TextField("Enter your name", text: $nameInput, onCommit: { vm.saveRecord(name: nameInput) })
                    .textContentType(.givenName)
                    .font(.headline)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1))
                    .padding()
                Spacer()
            }
            .padding()
            .navigationTitle("Last Person")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { vm.getLastPerson() }, label: {
                        Image(systemName: "arrow.clockwise")
                    })
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ViewModel())
    }
}
