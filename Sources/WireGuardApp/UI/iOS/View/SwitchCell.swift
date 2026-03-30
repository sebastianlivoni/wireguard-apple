// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import SwiftUI

class SwitchCell: UITableViewCell {
    var message: String {
        get { return textLabel?.text ?? "" }
        set(value) { textLabel?.text = value }
    }

    var isOn: Bool {
        get { return switchView.isOn }
        set(value) { switchView.isOn = value }
    }

    var isEnabled: Bool {
        get { return switchView.isEnabled }
        set(value) {
            switchView.isEnabled = value
            textLabel?.textColor = value ? .label : .secondaryLabel
        }
    }

    var onSwitchToggled: ((Bool) -> Void)?

    var statusObservationToken: AnyObject?
    var isOnDemandEnabledObservationToken: AnyObject?
    var hasOnDemandRulesObservationToken: AnyObject?

    #if os(tvOS)
    let switchView = ToggleButton()
    #else
    let switchView = UISwitch()
    #endif

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        accessoryView = switchView
        switchView.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func switchToggled() {
        onSwitchToggled?(switchView.isOn)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onSwitchToggled = nil
        isEnabled = true
        message = ""
        isOn = false
        statusObservationToken = nil
        isOnDemandEnabledObservationToken = nil
        hasOnDemandRulesObservationToken = nil
    }

    #if os(tvOS)
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateAppearanceForFocusState()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateAppearanceForFocusState()
    }

    private func updateAppearanceForFocusState() {
        textLabel?.textColor = self.isFocused ? .black : .label
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        updateAppearanceForFocusState()
    }
    #endif
}

class ToggleButton: UIButton {
    var isOn = false {
        didSet {
            updateAppearance()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        self.sizeToFit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        updateAppearance()
    }

    func updateAppearance() {
        let title = isOn ? tr("tunnelOn") : tr("tunnelOff")

        self.setTitle(title, for: .normal)
        self.configuration = .plain()
        self.setTitleColor(.systemGray, for: .normal)
    }

    func setOn(_ on: Bool, animated: Bool) {
        isOn = on
    }
}
