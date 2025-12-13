// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation
import Network

struct Message: Codable {
    let type: MessageType
    let payload: Data?
}

enum MessageType: String, Codable {
    case requestAddConfiguration
    case addConfiguration

    case requestEditConfiguration
    case editConfiguration

    case exportLogs
    case error
}

struct AddConfigurationPayload: Codable {
    var configs: [Configuration]

    struct Configuration: Codable {
        var name: String
        var wgQuickConfig: String
    }
}

struct EditConfigurationPayload: Codable {
    var config: AddConfigurationPayload.Configuration
}

struct ExportLogsPayload: Codable {}

struct ErrorPayload: Codable {
    var message: String
}

protocol ConnectionManagerDelegate: AnyObject {
    func receive(message: Message)
}

struct MessageConfiguration: Codable {
    var configs: [Configuration]

    struct Configuration: Codable {
        var name: String
        var wgQuickConfig: String
    }
}

class ConnectionManager {
    public var delegate: ConnectionManagerDelegate?

    private var listener: NWListener?
    private var endpoint: NWEndpoint?
    private var connection: NWConnection?

    func createListener() throws {
        listener = try NWListener(using: .applicationService)
        listener?.service = .init(applicationService: "WireGuardAddTunnel")

        listener?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .failed(let error):
                print("Fejl: \(error)")
                disconnect()
            default:
                break
            }
        }

        listener?.newConnectionHandler = { connection in
            self.setUpConnection(connection)
        }

        listener?.start(queue: .main)
    }

    func send<T: Codable>(_ payload: T, type: MessageType) {
        guard
            let payloadData = try? JSONEncoder().encode(payload),
            let messageData = try? JSONEncoder().encode(
                Message(type: type, payload: payloadData)
            )
        else { return }

        connection?.send(content: messageData, completion: .contentProcessed { error in
            if let error {
                print("Fejl: \(error)")
            }
        })
    }

    func send(type: MessageType) {
        guard
            let messageData = try? JSONEncoder().encode(
                Message(type: type, payload: nil)
            )
        else { return }

        connection?.send(content: messageData, completion: .contentProcessed { error in
            if let error {
                print("Fejl: \(error)")
            }
        })
    }

    var isConnected: Bool {
        guard let connection else { return false }
        return connection.state == .ready
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
    }

    func connect(to endpoint: NWEndpoint) {
        self.endpoint = endpoint
        let connection = NWConnection(to: endpoint, using: .applicationService)
        setUpConnection(connection)
    }

    private func setUpConnection(_ connection: NWConnection) {
        self.connection = connection

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .failed(let error):
                print("Fejl: \(error)")
                disconnect()
            default:
                break
            }
        }

        receive()
        connection.start(queue: .main)
    }

    private func receive() {
        guard let connection else { return }

        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: 1024 * 1024
        ) { [weak self] content, _, _, error in
            guard let self else { return }

            if let error {
                print("Fejl ved modtaget data: \(error)")
            }

            if let content,
               let message = try? JSONDecoder().decode(Message.self, from: content) {
                delegate?.receive(message: message)
            }

            receive()
        }
    }
}
