// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var showSettings: Bool = false
    @State private var showAddTunnel: Bool = false

    @State private var tunnels = ["Tunnel 1", "Tunnel 2", "Tunnel 3", "Tunnel 4", "Tunnel 5"]

    @StateObject private var server = ServerModel()

    var body: some View {
        TabView {
            Tab("Forbindelse", systemImage: "network") {
                NavigationStack {
                    List {
                        AddTunnelButton()

                        Divider()

                        TunnelListView()
                    }

                    Text("Du er forbundet til **Tunnel 1**")
                }
            }

            Tab("Indstillinger", systemImage: "gear") {
                SettingsView()
            }
        }
        /*.sheet(isPresented: $showAddTunnel) {
            NavigationStack {
                Text("Scan nedenstående QR-kode for at tilføje en ny tunnel")

                if let ip = getPrimaryIPAddress() {
                    let text = "http://\(ip):10000"
                    generateQRCode(text: text)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 400)
                        .navigationTitle("Tilføj ny tunnel")

                    Text("Eller skriv **\(text)** ind i din browser.")
                }
            }
            .onAppear {
                server.start()
            }
            .frame(width: 800, height: 700)
        }*/
    }

    func getPrimaryIPAddress() -> String? {
        var address: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }

        defer { freeifaddrs(ifaddr) }

        var ptr = firstAddr
        while ptr.pointee.ifa_next != nil {
            let interface = ptr.pointee
            let name = String(cString: interface.ifa_name)
            let addrFamily = interface.ifa_addr.pointee.sa_family

            // Only IPv4
            if addrFamily == UInt8(AF_INET) {
                // Usually en0 = Wi-Fi, en1 = wired
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                                socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname,
                                socklen_t(hostname.count),
                                nil,
                                socklen_t(0),
                                NI_NUMERICHOST)

                    address = String(cString: hostname)
                    break
                }
            }

            ptr = interface.ifa_next
        }

        return address
    }

    func generateQRCode(text: String) -> Image {
        let ciContext = CIContext()

        guard let data = text.data(using: .ascii, allowLossyConversion: false) else {
            return Image(systemName: "exclamationmark.octagon")

        }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data

        if let ciImage = filter.outputImage {
            if let cgImage = ciContext.createCGImage(
                ciImage,
                from: ciImage.extent) {

                return Image(uiImage: UIImage(cgImage: cgImage))
            }
        }
        return Image(systemName: "exclamationmark.octagon")
    }
}

#Preview {
    ContentView()
}
