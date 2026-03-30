// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import SwiftUI
import Network
import UniformTypeIdentifiers

struct SendTunnelView: View {
    public var connection: NWConnection

    @State private var showFileImporter = false

    @Environment(\.dismiss) var dismiss

    var body: some View {
        Text("Choose a file to send to the Apple TV!")

        Button {
           showFileImporter = true
       } label: {
           Label("Choose WireGuard configuration to send", systemImage: "doc.circle")
       }
       .fileImporter(
           isPresented: $showFileImporter,
           allowedContentTypes: [
            UTType(filenameExtension: "conf")!
           ],
       ) { result in
           switch result {
           case .success(let file):
               let gotAccess = file.startAccessingSecurityScopedResource()
               if !gotAccess { return }

               guard let data = try? Data(contentsOf: file) else { return }

               connection.send(content: data, isComplete: true, completion: .contentProcessed({ _ in }))

               file.stopAccessingSecurityScopedResource()

               dismiss()
           case .failure(let error):
               // handle error
               print(error)
           }
       }
    }
}

#Preview {
    SendTunnelView(connection: .init(message: .default)!)
}
