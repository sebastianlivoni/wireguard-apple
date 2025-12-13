// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import NIO
import NIOHTTP1
import SwiftUI

final class SimpleHTTPHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)

        switch reqPart {
        case .head(let header):
            print("Received request:", header.uri)

        case .body:
            break

        case .end:
            // Prepare a simple "Hello" response
            var headers = HTTPHeaders()
            headers.add(name: "Content-Type", value: "text/plain")
            headers.add(name: "Content-Length", value: "5")

            let head = HTTPResponseHead(version: .http1_1, status: .ok, headers: headers)

            context.write(self.wrapOutboundOut(.head(head)), promise: nil)
            context.write(self.wrapOutboundOut(.body(.byteBuffer(context.channel.allocator.buffer(string: "Hello")))), promise: nil)
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        }
    }
}
final class ServerModel: ObservableObject {
    private var group: MultiThreadedEventLoopGroup?
    private var channel: Channel?

    func start(port: Int = 10000) {
        guard group == nil else { return }

        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let bootstrap = ServerBootstrap(group: group!)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(SimpleHTTPHandler())
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

        do {
            self.channel = try bootstrap.bind(host: "0.0.0.0", port: port).wait()
            print("Server running on:", channel?.localAddress ?? "unknown")
        } catch {
            print("Error starting server:", error.localizedDescription)
        }
    }

    func stop() {
        do {
            try channel?.close().wait()
            try group?.syncShutdownGracefully()
        } catch {
            print("Error shutting down server:", error.localizedDescription)
        }
    }
}
