//
//  Theme.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 28/02/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import UIKit
import WebKit

class AppImageView: UIImageView {}
class AppButton: UIButton {}

protocol Theme {
	var videoLabelColor: UIColor { get }

	var barStyle: UIBarStyle { get }
	var barTintColor: UIColor { get }

	var tint: UIColor { get }
    var secondaryTint: UIColor { get }
    var onTint: UIColor { get }

    var backgroundColor: UIColor { get }
    var cellBackgroundColor: UIColor { get }
    var separatorColor: UIColor { get }
    var selectionColor: UIColor { get }
	var videoCellBackgroundColor: UIColor { get }

    var headerFooterColor: UIColor { get }
    var labelColor: UIColor { get }
    var secondaryLabelColor: UIColor { get }
    var subtleLabelColor: UIColor { get }
    var textColor: UIColor { get }
    var placeholderTextColor: UIColor { get }

    func apply(for application: UIApplication)
    func extend()
}

extension UIColor {
	func image(_ size: CGSize = CGSize(width: 1, height: 38)) -> UIImage {
		return UIGraphicsImageRenderer(size: size).image { rendererContext in
			self.setFill()
			rendererContext.fill(CGRect(origin: .zero, size: size))
		}
	}
}

extension Theme {

    func apply(for application: UIApplication) {

		// WINDOW

        application.keyWindow?.tintColor = tint

		// VIEW

		AppView.appearance().with {
			$0.tintColor = backgroundColor
			$0.backgroundColor = backgroundColor
		}

        // TABBAR

        UITabBar.appearance().with {
            $0.barStyle = barStyle
            $0.barTintColor = barTintColor
            $0.tintColor = tint
            $0.unselectedItemTintColor = secondaryTint
        }

        // NAVBAR

        UINavigationBar.appearance().with {
            $0.barStyle = barStyle
            $0.barTintColor = barTintColor
            $0.tintColor = tint
            $0.titleTextAttributes = [
                .foregroundColor: labelColor
            ]

            if #available(iOS 11.0, *) {
                $0.largeTitleTextAttributes = [
                    .foregroundColor: labelColor
                ]
            }
        }

        // SEARCHBAR

		UISearchBar.appearance().with {
			$0.barTintColor = barTintColor
			$0.setSearchFieldBackgroundImage(UIColor.lightGray.withAlphaComponent(0.3).image(), for: .normal)
			$0.searchTextPositionAdjustment = UIOffset(horizontal: 8.0, vertical: 0.0)
		}
		UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).with {
			$0.textColor = textColor
			$0.placeholderColor = placeholderTextColor
		}

        // TABLEVIEW

        UITableView.appearance().with {
            $0.backgroundColor = backgroundColor
            $0.separatorColor = separatorColor
        }

        UITableViewCell.appearance().with {
            $0.backgroundColor = .clear
            $0.contentColor = cellBackgroundColor
            $0.selectionColor = selectionColor
        }

        UIView.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).backgroundColor = backgroundColor

		UIRefreshControl.appearance().with {
			$0.tintColor = tint
			$0.backgroundColor = backgroundColor
		}

		// COLLECTIONVIEW

		UICollectionView.appearance().with {
			$0.backgroundColor = backgroundColor
		}
		UICollectionViewCell.appearance().with {
			$0.backgroundColor = cellBackgroundColor
		}

		// LABEL

        var fontSize = 1.0
        if let sliderFontSize = UserDefaults.standard.object(forKey: "font-size-settings") as? String {
            switch sliderFontSize {
            case "fontemenor":
                fontSize = 0.9
            case "fontemaior":
                fontSize = 1.1
            default:
                fontSize = 1.0
            }
        }

        UILabel.appearance().with {
            $0.textColor = labelColor
            $0.fontSize = CGFloat(fontSize)
        }
		AppLabel.appearance().with {
			$0.textColor = .black
		}
        AppHeadline.appearance().with {
            $0.textColor = labelColor
            $0.fontSize = CGFloat(fontSize)
        }
        AppSubhead.appearance().with {
            $0.textColor = secondaryLabelColor
            $0.fontSize = CGFloat(fontSize)
        }
        UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).with {
            $0.textColor = headerFooterColor
            $0.fontSize = CGFloat(0.8)
        }
        AppSmallFont.appearance().with {
            $0.textColor = labelColor
            $0.fontSize = CGFloat(1.0)
        }
        AppBigFont.appearance().with {
            $0.textColor = labelColor
            $0.fontSize = CGFloat(1.0)
        }
		VideoViewLikeLabel.appearance().with {
			$0.textColor = videoLabelColor
			$0.fontSize = CGFloat(0.65)
		}
		VideoViewLikeDataLabel.appearance().with {
			$0.textColor = secondaryLabelColor
			$0.fontSize = CGFloat(0.9)
		}

        // BUTTON

        UIButton.appearance().with {
            $0.setTitleColor(tint, for: .normal)
            $0.borderColor = tint
        }

		AppButton.appearance().tintColor = tint

		// IMAGE

		AppImageView.appearance().with {
			$0.borderColor = UIColor(hex: "dddddd", alpha: 1)
		}

		// SWITCH

        UISwitch.appearance().onTintColor = onTint

        // SLIDER

        UISlider.appearance().tintColor = tint

		// WEBVIEW

		WKWebView.appearance().with {
			$0.backgroundColor = backgroundColor
		}

		// ACTIVITYINDICATOR

		UIActivityIndicatorView.appearance().color = tint

        extend()

        // Ensure existing views render with new theme
        // https://developer.apple.com/documentation/uikit/uiappearance
        application.windows.reload()
    }

    // Optionally extend theme
    func extend() {}

}
