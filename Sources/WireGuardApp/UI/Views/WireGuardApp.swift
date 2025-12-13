// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import SwiftUI

@main
struct WireGuardApp: App {
    @State private var connectionManager = ConnectionManager()

    @State private var tunnelsManager: TunnelsManager = .init(tunnelProviders: [])

    @State var data: Data?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(tunnelsManager)
                .environment(connectionManager)
                .onAppear {
                    connectionManager.receiveData = receiveData
                }
                .sheet(isPresented: Binding(
                    get: { data != nil },
                    set: { if !$0 { data = nil } }
                )) {
                    if let data = data, let str = String(data: data, encoding: .utf8) {
                        Text("I received data: \(str)")
                            .padding()
                    }
                }
                .task {
                    setup()
                }
        }
    }

    func addTunnel(config: String) {
        do {
            try tunnelsManager.add(tunnelConfiguration: .init(fromWgQuickConfig: config, called: "test")) { result in
                switch result {
                case .success(let success):
                    print("Tilføjede en tunnel: \(success)")
                case .failure(let failure):
                    print("Kunne ikke tilføje tunnel: \(failure)")
                }
            }
        } catch {
            print("Kunne ikke tilføje tunnel: \(error)")
        }
    }

    func receiveData(data: Data) {
        print("Received data: \(data)")
        self.data = data

        if let str = String(data: data, encoding: .utf8) {
           addTunnel(config: str)
        }
    }

    func setup() {
        TunnelsManager.create { result in
            switch result {
            case .failure(let error):
                print("Der skete en fejl: \(error)")
                break
                //ErrorPresenter.showErrorAlert(error: error, from: self)
            case .success(let tunnelsManager):
                self.tunnelsManager = tunnelsManager
            }
        }
    }
}
