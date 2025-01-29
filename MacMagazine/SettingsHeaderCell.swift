//
//  SettingsHeaderCell.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 28/09/20.
//  Copyright © 2020 MacMagazine. All rights reserved.
//

import SafariServices
import UIKit

enum HeaderType {
    case version
    case subscription
    case none
}

class SettingsHeaderCell: UITableViewHeaderFooterView {

    // MARK: - Properties -

    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var subHeaderLabel: UILabel!
    @IBOutlet private weak var footerLabel: UITextView!

    // MARK: - Methods -

    func setHeader(_ text: String?, type: HeaderType) {
        headerLabel?.font = Settings().getMetricBoldFont(forTextStyle: .title2)
        headerLabel?.text = text
        switch type {
        case .version:
            subHeaderLabel?.text = "VERSÃO \(Settings().appVersion)"

        case .subscription:
			// swiftlint:disable:next line_length
            subHeaderLabel?.text = "Assine o app para navegar por ele sem ver propagandas — ou, alternativamente, use o seu login de patrão (do Patreon ou do Catarse) para usufruir do mesmo benefício.\n"

        default:
            break
        }
    }

    var disclaimerAttributedString: NSAttributedString {
        guard let github = URL(string: "https://github.com/MacMagazine/app-iOS"),
              let kazzio = URL(string: "http://kazziosoftware.com") else {
            return NSMutableAttributedString()
        }

        let font = UIFont.preferredFont(forTextStyle: .caption1)

        let prefix = "MacMagazine é um "
        let prefixAttributedString = NSMutableAttributedString(string: prefix, attributes: [.font: font,
                                                                                            .foregroundColor: UIColor.label])

        let linkGithub = "projeto de código aberto no GitHub"
        let linkGithubAttributedString = NSMutableAttributedString(string: linkGithub,
                                                                   attributes: [.font: font,
                                                                                .link: github])

        let suffix = " liderado por Cassio Rossi, da "
        let suffixAttributedString = NSMutableAttributedString(string: suffix, attributes: [.font: font,
                                                                                            .foregroundColor: UIColor.label])

        let linkKazzio = "KazzioSoftware"
        let linkKazzioAttributedString = NSMutableAttributedString(string: linkKazzio,
                                                                   attributes: [.font: font,
                                                                                .link: kazzio])

        let endText = "."
        let endTextAttributedString = NSMutableAttributedString(string: endText, attributes: [.font: font,
                                                                                              .foregroundColor: UIColor.label])

        let fullAttributedString = NSMutableAttributedString()
        fullAttributedString.append(prefixAttributedString)
        fullAttributedString.append(linkGithubAttributedString)
        fullAttributedString.append(suffixAttributedString)
        fullAttributedString.append(linkKazzioAttributedString)
        fullAttributedString.append(endTextAttributedString)

        return fullAttributedString
    }

    func showFooter() {
        footerLabel?.attributedText = disclaimerAttributedString
        footerLabel?.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "MMBlue") ?? UIColor.systemBlue]
        footerLabel?.textContainerInset = UIEdgeInsets.zero
        footerLabel?.textContainer.lineFragmentPadding = 0
    }

    func footerHeight(width: CGFloat) -> CGFloat {
        let height = disclaimerAttributedString.string.height(withWidth: width,
                                                              font: UIFont.preferredFont(forTextStyle: .caption1))
        return height
    }

}

// MARK: - Privacidade -

extension SettingsHeaderCell {
    @IBAction private func showPrivacy(_ sender: Any) {
        openSafari(url: "https://macmagazine.com.br/politica-privacidade/")
    }

    @IBAction private func showTermsUse(_ sender: Any) {
        openSafari(url: "https://macmagazine.com.br/termos-de-uso/")
    }

    fileprivate func openSafari(url: String) {
        guard let url = URL(string: url),
              url.scheme?.lowercased().contains("http") != nil else {
            return
        }
        let safari = SFSafariViewController(url: url)
        safari.setup()
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.last?.rootViewController?.present(safari, animated: true)
    }
}
