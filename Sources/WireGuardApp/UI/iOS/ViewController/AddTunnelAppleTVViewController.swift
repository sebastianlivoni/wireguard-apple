// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.
import UIKit
import Network
import MobileCoreServices

class AddTunnelAppleTVViewController: UIViewController {

    private let connectionManager: ConnectionManager
    private var tunnelsManager: TunnelsManager

    init(connectionManager: ConnectionManager, tunnelsManager: TunnelsManager) {
        self.connectionManager = connectionManager
        self.tunnelsManager = tunnelsManager
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        navigationItem.title = "Tilføj en ny WireGuard-tunnel til Apple TV"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissSheet))

        setupUI()
    }

    private func setupUI() {
        let label = UILabel()
        label.text = "New connection received!"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40)
        ])

        // Buttons
        let importFileButton = makeButton(title: "Import File", action: #selector(importFileTapped))
        let scanQRCodeButton = makeButton(title: "Scan QR Code", action: #selector(scanQRCodeTapped))
        let createFromScratchButton = makeButton(title: "Create From Scratch", action: #selector(createFromScratchTapped))
        let closeButton = makeButton(title: "Close", action: #selector(dismissSheet))

        let stack = UIStackView(arrangedSubviews: [importFileButton, scanQRCodeButton, createFromScratchButton, closeButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 40)
        ])
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.addTarget(self, action: action, for: .primaryActionTriggered)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 300).isActive = true
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return button
    }

    // MARK: - Actions

    @objc private func importFileTapped() {
        presentFileImport()
    }

    @objc private func scanQRCodeTapped() {
        presentQRCodeScan()
    }

    @objc private func dismissSheet() {
        connectionManager.send(type: .error)
        self.dismiss(animated: true)
    }

    // MARK: - Modal Presentations

    @objc private func createFromScratchTapped() {
        #if os(tvOS)
        fatalError("Not supportd")
        #else
        let editVC = TunnelEditTableViewController(tunnelsManager: tunnelsManager)
        editVC.delegateAppleTV = self
        let editNC = UINavigationController(rootViewController: editVC)
        editNC.modalPresentationStyle = .fullScreen
        present(editNC, animated: true)
        #endif
    }

    func presentFileImport() {
        #if !os(tvOS)
        let documentTypes = ["com.wireguard.config.quick", String(kUTTypeText), String(kUTTypeZipArchive)]
        let filePicker = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
        filePicker.delegate = self
        self.present(filePicker, animated: true)
        #endif
    }

    func presentQRCodeScan() {
        #if !os(tvOS)
        let scanVC = QRScanViewController()
        scanVC.delegate = self
        let scanNC = UINavigationController(rootViewController: scanVC)
        scanNC.modalPresentationStyle = .fullScreen
        self.present(scanNC, animated: true)
        #endif
    }

    func send(configs: [AddConfigurationPayload.Configuration]) {
        connectionManager.send(AddConfigurationPayload(configs: configs), type: .addConfiguration)
        dismissSheet()
    }
}

extension AddTunnelAppleTVViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        TunnelImporter.importFrom(urls: urls) { configurations in
            let configs = configurations.map { configuration in
                return AddConfigurationPayload.Configuration(name: configuration.name ?? "", wgQuickConfig: configuration.asWgQuickConfig())
            }

            self.send(configs: configs)
        }
    }
}

extension AddTunnelAppleTVViewController: QRScanViewControllerDelegate {
    func addScannedQRCode(tunnelConfiguration: TunnelConfiguration, qrScanViewController: QRScanViewController, completionHandler: (() -> Void)?) {
        guard let name = tunnelConfiguration.name else {
            print("No name")
            return
        }
        send(configs: [.init(name: name, wgQuickConfig: tunnelConfiguration.asWgQuickConfig())])
    }
}

extension AddTunnelAppleTVViewController: TunnelEditTableViewControllerDelegateAppleTV {
    func tunnelSaved(tunnelConfiguration: TunnelConfiguration) {
        guard let name = tunnelConfiguration.name else {
            print("No name")
            return
        }
        send(configs: [.init(name: name, wgQuickConfig: tunnelConfiguration.asWgQuickConfig())])
    }
}
