// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import SwiftUI

struct TunnelListView: View {
    @Environment(TunnelsManager.self) private var tunnelsManager

    var body: some View {
        ForEach(tunnelsManager.tunnels, id: \.name) { tunnel in
            NavigationLink(tunnel.name) {
                TunnelDetailView(tunnel: tunnel)
            }
        }
    }
}

#Preview {
    TunnelListView()
}
