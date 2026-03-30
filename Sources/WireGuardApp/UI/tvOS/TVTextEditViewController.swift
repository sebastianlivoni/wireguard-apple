// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

final class TVTextEditViewController: UIViewController {

    private let titleText: String
    private let initialValue: String?
    private let placeholder: String?

    var onSave: ((String?) -> Void)?

    private let textField = UITextField()

    init(title: String, initialValue: String?, placeholder: String?) {
        self.titleText = title
        self.initialValue = initialValue
        self.placeholder = placeholder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = titleText

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.text = initialValue
        textField.placeholder = placeholder
        textField.clearButtonMode = .whileEditing

        view.addSubview(textField)

        NSLayoutConstraint.activate([
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            textField.heightAnchor.constraint(equalToConstant: 60)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }

    @objc private func saveTapped() {
        onSave?(textField.text)
        navigationController?.popViewController(animated: true)
    }
}
