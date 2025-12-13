// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import SwiftUI

struct TunnelDetailView: View {

    public var tunnel: TunnelContainer

    @Environment(\.dismiss) private var dismiss
    @Environment(TunnelsManager.self) private var tunnelsManager

    var body: some View {
        List {
            Button("Gå tilbage", systemImage: "arrow.left") {
                dismiss()
            }

            Divider()

            Section("Status") {
                Toggle("On-Demand Disabled", isOn: .constant(true))
            }

            Section("Interface") {
                LabeledContent("Name", value: tunnel.name)
                LabeledContent("Public key", value: tunnel.tunnelConfiguration?.interface.privateKey.publicKey.base64Key ?? "Unknown")
                    .lineLimit(1)
                LabeledContent("Addresses") {
                    Text((tunnel.tunnelConfiguration?.interface.addresses ?? [])
                        .map { $0.stringRepresentation }
                        .joined(separator: ", "))
                }
                LabeledContent("DNS servers") {
                    Text((tunnel.tunnelConfiguration?.interface.dns ?? [])
                        .map { $0.stringRepresentation }
                        .joined(separator: ", "))
                }
            }

            ForEach(tunnel.tunnelConfiguration?.peers ?? [], id: \.hashValue) { peer in
                Section("Peer") {
                    LabeledContent("Public key", value: peer.publicKey.base64Key)
                        .lineLimit(1)

                    if let preSharedKey = peer.preSharedKey {
                        LabeledContent("Preshared key", value: preSharedKey.base64Key)
                            .lineLimit(1)
                    }

                    LabeledContent("Endpoint", value: peer.endpoint?.stringRepresentation ?? "Unknown")
                        .lineLimit(1)

                    LabeledContent("Allowed IPs") {
                        Text(peer.allowedIPs
                            .map { $0.stringRepresentation }
                            .joined(separator: ", "))
                    }

                    if let presistentKeepalive = peer.persistentKeepAlive {
                        LabeledContent("Persistent keepalive", value: "every \(presistentKeepalive) seconds")
                    }
                }
            }

            Section("On-demand activation") {

            }

            Button("Delete tunnel", role: .destructive) {
                tunnelsManager.remove(tunnel: tunnel) { error in
                    if let error {
                        print("Fejl at slette tunnel: \(error)")
                    }
                }
            }
        }
    }
}

/*#Preview {
    TunnelDetailView()
}*/
