// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import SwiftUI
import DeviceDiscoveryUI

struct AddTunnelButton: View {
    @Environment(ConnectionManager.self) private var connectionManager

    var body: some View {
        DevicePicker(.applicationService(name: "WireGuardAddTunnel")) { endpoint in
            connectionManager.connectTo(endpoint: endpoint)
        } label: {
            addTunnelLabel
        } fallback: {
            addTunnelLabel.disabled(true)
        } parameters: {
            .applicationService
        }
    }

    var addTunnelLabel: some View {
        Label("Tilføj en ny tunnel", systemImage: "plus")
    }
}

#Preview {
    AddTunnelButton()
}
