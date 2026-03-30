// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class TunnelEditKeyValueCell: KeyValueCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        #if os(tvOS)
        keyLabel.textAlignment = .left
        #else
        keyLabel.textAlignment = .right
        valueTextField.textAlignment = .left
        #endif

        let widthRatioConstraint = NSLayoutConstraint(item: keyLabel, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.4, constant: 0)
        // In case the key doesn't fit into 0.4 * width,
        // set a CR priority > the 0.4-constraint's priority.
        widthRatioConstraint.priority = .defaultHigh + 1
        widthRatioConstraint.isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class TunnelEditEditableKeyValueCell: TunnelEditKeyValueCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        copyableGesture = false
        valueLabelScrollView.isScrollEnabled = false
        #if !os(tvOS)
        valueTextField.textColor = .label
        valueTextField.isEnabled = true
        valueTextField.widthAnchor.constraint(equalTo: valueLabelScrollView.widthAnchor).isActive = true
        #endif

        #if os(tvOS)
        valueTextField.isUserInteractionEnabled = true
        #endif
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        copyableGesture = false
    }

}
