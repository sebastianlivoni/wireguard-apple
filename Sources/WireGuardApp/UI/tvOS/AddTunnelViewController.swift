// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class AddTunnelViewController: UIViewController {

    private let waitingLabel: UILabel = {
        let label = UILabel()
        label.text = "Brug nu din enhed til at uploade din konfiguration."
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(waitingLabel)

        NSLayoutConstraint.activate([
            waitingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            waitingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            waitingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            waitingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60)
        ])
    }
}
