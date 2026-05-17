// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.


import Cocoa

class AlwaysSelectedRowView: NSTableRowView {
    override var isEmphasized: Bool {
        get { return true }   // Always draw as if the window is key
        set { }
    }
}