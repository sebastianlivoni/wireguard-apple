// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import os.log
import Network
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var mainVC: MainViewController?
    var isLaunchedForSpecificAction = false

    var connectionManager = ConnectionManager()

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Logger.configureGlobal(tagged: "APP", withFilePath: FileManager.logFileURL?.path)

        #if !os(tvOS)
        if let launchOptions = launchOptions {
            if launchOptions[.url] != nil || launchOptions[.shortcutItem] != nil {
                isLaunchedForSpecificAction = true
            }
        }
        #endif

        #if os(visionOS)
        let window = UIWindow()
        #else
        let window = UIWindow(frame: UIScreen.main.bounds)
        #endif
        self.window = window

        let mainVC = MainViewController(connectionManager: connectionManager)
        window.rootViewController = mainVC
        window.makeKeyAndVisible()

        self.mainVC = mainVC

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        mainVC?.importFromDisposableFile(url: url)
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        mainVC?.refreshTunnelConnectionStatuses()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        guard let allTunnelNames = mainVC?.allTunnelNames() else { return }
        #if !os(tvOS) && !os(visionOS)
        application.shortcutItems = QuickActionItem.createItems(allTunnelNames: allTunnelNames)
        #endif
    }

    #if !os(tvOS) && !os(visionOS)
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        guard shortcutItem.type == QuickActionItem.type else {
            completionHandler(false)
            return
        }
        let tunnelName = shortcutItem.localizedTitle
        mainVC?.showTunnelDetailForTunnel(named: tunnelName, animated: false, shouldToggleStatus: true)
        completionHandler(true)
    }
    #endif

    #if !os(tvOS)
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        do {
            try connectionManager.createListener()
        } catch {
            fatalError("*** An error occurred: \(error.localizedDescription) ***")
        }

        return true
    }
    #endif
}

/*#if !os(tvOS)
extension AppDelegate: ConnectionManagerDelegate {
    func receive(message: MessageConfiguration) {
        DispatchQueue.main.async {
            self.mainVC?.tunnelsListVC?.presentAddTunnelAppleTV(connectionManager: self.connectionManager)
        }
    }
}
#endif*/

extension AppDelegate {
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return !self.isLaunchedForSpecificAction
    }

    func application(_ application: UIApplication, viewControllerWithRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        guard let vcIdentifier = identifierComponents.last else { return nil }
        if vcIdentifier.hasPrefix("TunnelDetailVC:") {
            let tunnelName = String(vcIdentifier.suffix(vcIdentifier.count - "TunnelDetailVC:".count))
            if let tunnelsManager = mainVC?.tunnelsManager {
                if let tunnel = tunnelsManager.tunnel(named: tunnelName) {
                    return TunnelDetailTableViewController(tunnelsManager: tunnelsManager, tunnel: tunnel)
                }
            } else {
                // Show it when tunnelsManager is available
                mainVC?.showTunnelDetailForTunnel(named: tunnelName, animated: false, shouldToggleStatus: false)
            }
        }
        return nil
    }
}
