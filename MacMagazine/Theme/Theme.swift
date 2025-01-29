//
//  Theme.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 28/02/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import UIKit
import WebKit

class AppCollectionViewCell: UICollectionViewCell {}

protocol Theme {
    var tint: UIColor { get }

    func apply(for application: UIApplication)
    func extend(_ application: UIApplication)
}

extension Theme {

    func apply(for application: UIApplication) {
        extend(application)

        // Ensure existing views render with new theme
        // https://developer.apple.com/documentation/uikit/uiappearance
        (application.connectedScenes.first as? UIWindowScene)?.windows.last?.reload()
    }

    // Optionally extend theme
    func extend(_ application: UIApplication) {

        // WINDOW
        let window = (application.connectedScenes.first as? UIWindowScene)?.windows.last
        window?.tintColor = tint

        let selectedMode: UIUserInterfaceStyle = Settings().isDarkMode ? .dark : .light
        let overrideInterfaceStyle: UIUserInterfaceStyle = Settings().appearance == .native ? .unspecified : selectedMode
        window?.overrideUserInterfaceStyle = overrideInterfaceStyle

        // SEGMENTCONTROL

        UILabel.appearance(whenContainedInInstancesOf: [UISegmentedControl.self]).with {
            $0.textColor = tint
        }

    }

}
