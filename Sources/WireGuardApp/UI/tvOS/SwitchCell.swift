// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class SwitchCell: UITableViewCell {

    var isOn: Bool = false {
        didSet {
            value = isOn ? "On" : "Off"
        }
    }

    var isEnabled: Bool = false

    var onSwitchToggled: ((Bool) -> Void)?

    var statusObservationToken: AnyObject?
    var isOnDemandEnabledObservationToken: AnyObject?
    var hasOnDemandRulesObservationToken: AnyObject?

    @objc func switchToggled() {
        onSwitchToggled?(isOn)
    }

    let keyLabel: UILabel = {
        let keyLabel = UILabel()
        keyLabel.font = UIFont.preferredFont(forTextStyle: .body)
        keyLabel.adjustsFontForContentSizeCategory = true
        keyLabel.textColor = .label
        keyLabel.textAlignment = .left
        return keyLabel
    }()

    let valueLabelScrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.isDirectionalLockEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    let valueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        if self.isFocused {
            keyLabel.textColor = .black
            valueLabel.textColor = .darkGray
        } else {
            keyLabel.textColor = .label
            valueLabel.textColor = .secondaryLabel
        }
    }

    var key: String {
        get { return keyLabel.text ?? "" }
        set(value) { keyLabel.text = value }
    }

    var value: String {
        get { valueLabel.text ?? "" }
        set { valueLabel.text = newValue }
    }

    var isStackedHorizontally = false
    var isStackedVertically = false
    var contentSizeBasedConstraints = [NSLayoutConstraint]()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(keyLabel)
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            keyLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            keyLabel.topAnchor.constraint(equalToSystemSpacingBelow: contentView.layoutMarginsGuide.topAnchor, multiplier: 0.5)
        ])

        valueLabelScrollView.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            valueLabel.leadingAnchor.constraint(equalTo: valueLabelScrollView.contentLayoutGuide.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: valueLabelScrollView.contentLayoutGuide.trailingAnchor),
            valueLabel.topAnchor.constraint(equalTo: valueLabelScrollView.contentLayoutGuide.topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: valueLabelScrollView.contentLayoutGuide.bottomAnchor),
            valueLabel.heightAnchor.constraint(equalTo: valueLabelScrollView.heightAnchor)
        ])

        let expandConstraint = valueLabel.widthAnchor.constraint(equalTo: valueLabelScrollView.widthAnchor)
        expandConstraint.priority = .defaultLow + 1
        expandConstraint.isActive = true

        contentView.addSubview(valueLabelScrollView)
        valueLabelScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            valueLabelScrollView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.layoutMarginsGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: valueLabelScrollView.bottomAnchor, multiplier: 0.5)
        ])

        keyLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        keyLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        valueLabelScrollView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        isUserInteractionEnabled = true

        configureForContentSize()
    }

    func configureForContentSize() {
        var constraints = [NSLayoutConstraint]()
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            // Stack vertically
            if !isStackedVertically {
                constraints = [
                    valueLabelScrollView.topAnchor.constraint(equalToSystemSpacingBelow: keyLabel.bottomAnchor, multiplier: 0.5),
                    valueLabelScrollView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                    keyLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
                ]
                isStackedVertically = true
                isStackedHorizontally = false
            }
        } else {
            // Stack horizontally
            if !isStackedHorizontally {
                constraints = [
                    contentView.layoutMarginsGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: keyLabel.bottomAnchor, multiplier: 0.5),
                    valueLabelScrollView.leadingAnchor.constraint(equalToSystemSpacingAfter: keyLabel.trailingAnchor, multiplier: 1),
                    valueLabelScrollView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.layoutMarginsGuide.topAnchor, multiplier: 0.5)
                ]
                isStackedHorizontally = true
                isStackedVertically = false
            }
        }
        if !constraints.isEmpty {
            NSLayoutConstraint.deactivate(contentSizeBasedConstraints)
            NSLayoutConstraint.activate(constraints)
            contentSizeBasedConstraints = constraints
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.first?.type == .select {
            guard isEnabled else { return }
            isOn.toggle()
            onSwitchToggled?(isOn)
        } else {
            super.pressesEnded(presses, with: event)
        }
    }
}
