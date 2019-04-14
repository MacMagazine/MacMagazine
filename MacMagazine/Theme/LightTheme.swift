//
//  LightTheme.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 28/02/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import UIKit

struct LightTheme: Theme {
	let videoLabelColor: UIColor = UIColor(hex: "0097d4", alpha: 1)

	let barStyle: UIBarStyle = .default
    let barTintColor: UIColor = .white

    let tint: UIColor = UIColor(hex: "0097d4", alpha: 1)
    let secondaryTint: UIColor = .lightGray
    let onTint: UIColor = UIColor(hex: "0097d4", alpha: 1)

    let backgroundColor: UIColor = .groupTableViewBackground
    let cellBackgroundColor: UIColor = .white
    let separatorColor: UIColor = .lightGray
    let selectionColor: UIColor = UIColor(hex: "008ACA", alpha: 0.3)
	let videoCellBackgroundColor: UIColor = .lightGray

	let headerFooterColor: UIColor = .darkGray
    let labelColor: UIColor = .black
    let secondaryLabelColor: UIColor = .darkGray
    let subtleLabelColor: UIColor = .lightGray
    let textColor: UIColor = .black
    let placeholderTextColor: UIColor = .gray
}
