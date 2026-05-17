// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Cocoa

class ManageTunnelsRootViewController: NSSplitViewController {

    let tunnelsManager: TunnelsManager
    var tunnelsListVC: TunnelsListTableViewController?
    var tunnelDetailVC: TunnelDetailTableViewController? {
        didSet {
            setEditToolbarItemVisible(tunnelDetailVC != nil)
        }
    }
    let tunnelDetailContainerView = NSView()
    var tunnelDetailContentVC: NSViewController?

    init(tunnelsManager: TunnelsManager) {
        self.tunnelsManager = tunnelsManager
        super.init(nibName: nil, bundle: nil)
    }

    // Remove drag indicator on sidebar
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        return .zero
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let listVC = TunnelsListTableViewController(tunnelsManager: tunnelsManager)
        tunnelsListVC = listVC

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: listVC)
        sidebarItem.allowsFullHeightLayout = true
        sidebarItem.canCollapse = false
        sidebarItem.isCollapsed = false

        let placeholderVC = ButtonedDetailViewController()
        let detailItem = NSSplitViewItem(viewController: placeholderVC)

        addSplitViewItem(sidebarItem)
        addSplitViewItem(detailItem)

        listVC.delegate = self

        if tunnelsManager.numberOfTunnels() == 0 {
            tunnelsListEmpty()
        }
    }

    private func setDetailViewController(_ vc: NSViewController) {
        let detailItem = NSSplitViewItem(viewController: vc)
        if splitViewItems.count > 1 {
            removeSplitViewItem(splitViewItems[1])
        }
        addSplitViewItem(detailItem)
    }

    private func setEditToolbarItemVisible(_ visible: Bool) {
        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
        appDelegate.setEditToolbarItemVisible(visible)
    }
}

extension ManageTunnelsRootViewController: TunnelsListTableViewControllerDelegate {
    func tunnelsSelected(tunnelIndices: [Int]) {
        assert(!tunnelIndices.isEmpty)
        if tunnelIndices.count == 1 {
            let tunnel = tunnelsManager.tunnel(at: tunnelIndices.first!)
            if tunnel.isTunnelAvailableToUser {
                let tunnelDetailVC = TunnelDetailTableViewController(tunnelsManager: tunnelsManager, tunnel: tunnel)
                setDetailViewController(tunnelDetailVC)
                self.tunnelDetailVC = tunnelDetailVC
            } else {
                let unusableTunnelDetailVC = tunnelDetailContentVC as? UnusableTunnelDetailViewController ?? UnusableTunnelDetailViewController()
                unusableTunnelDetailVC.onButtonClicked = { [weak tunnelsListVC] in
                    tunnelsListVC?.handleRemoveTunnelAction()
                }
                setDetailViewController(unusableTunnelDetailVC)
                self.tunnelDetailVC = nil
            }
        } else if tunnelIndices.count > 1 {
            let multiSelectionVC = tunnelDetailContentVC as? ButtonedDetailViewController ?? ButtonedDetailViewController()
            multiSelectionVC.setButtonTitle(tr(format: "macButtonDeleteTunnels (%d)", tunnelIndices.count))
            multiSelectionVC.onButtonClicked = { [weak tunnelsListVC] in
                tunnelsListVC?.handleRemoveTunnelAction()
            }
            setDetailViewController(multiSelectionVC)
            self.tunnelDetailVC = nil
        }
    }

    func tunnelsListEmpty() {
        let noTunnelsVC = ButtonedDetailViewController()
        noTunnelsVC.setButtonTitle(tr("macButtonImportTunnels"))
        noTunnelsVC.onButtonClicked = { [weak self] in
            guard let self = self else { return }
            ImportPanelPresenter.presentImportPanel(tunnelsManager: self.tunnelsManager, sourceVC: self)
        }
        setDetailViewController(noTunnelsVC)
        self.tunnelDetailVC = nil
    }
}

extension ManageTunnelsRootViewController {
    override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
        switch action {
        case #selector(TunnelsListTableViewController.handleViewLogAction),
             #selector(TunnelsListTableViewController.handleAddEmptyTunnelAction),
             #selector(TunnelsListTableViewController.handleImportTunnelAction),
             #selector(TunnelsListTableViewController.handleExportTunnelsAction),
             #selector(TunnelsListTableViewController.handleRemoveTunnelAction):
            return tunnelsListVC
        case #selector(TunnelDetailTableViewController.handleToggleActiveStatusAction),
             #selector(TunnelDetailTableViewController.handleEditTunnelAction):
            return tunnelDetailVC
        default:
            return super.supplementalTarget(forAction: action, sender: sender)
        }
    }
}
