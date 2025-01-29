//
//  SettingsTableViewController.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 27/02/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import CoreSpotlight
import InAppPurchase
import Kingfisher
import MessageUI
import StoreKit
import UIKit

class SettingsTableViewController: UITableViewController {

	// MARK: - Properties -

	@IBOutlet private weak var pushOptions: UISegmentedControl!

	@IBOutlet private weak var iconOption1Btn: UIButton!
	@IBOutlet private weak var iconOption2Btn: UIButton!
	@IBOutlet private weak var iconOption3Btn: UIButton!
	@IBOutlet private weak var iconOption4Btn: UIButton!
	@IBOutlet private weak var iconOption1: UIImageView!
	@IBOutlet private weak var iconOption2: UIImageView!
	@IBOutlet private weak var iconOption3: UIImageView!
	@IBOutlet private weak var iconOption4: UIImageView!
	@IBOutlet private weak var iconOption1Selected: UIImageView!
	@IBOutlet private weak var iconOption2Selected: UIImageView!
	@IBOutlet private weak var iconOption3Selected: UIImageView!
	@IBOutlet private weak var iconOption4Selected: UIImageView!

	@IBOutlet private weak var darkModeSegmentControl: UISegmentedControl!

	@IBOutlet private weak var intensityPostRead: UISwitch!
	@IBOutlet private weak var appearanceCellIntensity: UITableViewCell!
	@IBOutlet private weak var readTransparency: UISlider!
	@IBOutlet private weak var readTransparencyValue: UILabel!

	@IBOutlet private weak var patraoButton: UIButton!

	var products = [InAppPurchase.Product]()

	@IBOutlet private weak var buyMonthBtn: UIButton!
	@IBOutlet private weak var buyYearBtn: UIButton!
	@IBOutlet private weak var purchasedMessage: UILabel!
	@IBOutlet private weak var spin: UIActivityIndicatorView!
	@IBOutlet private weak var manageBtn: UIButton!
	@IBOutlet private weak var restoreBtn: UIButton!

	@IBOutlet private weak var badge: UISwitch!
	@IBOutlet private weak var badgeMessage: UILabel!

	enum IconOptionAccessibilityLabel: String {
		case whiteBackground = "Ícone do aplicativo com fundo branco."
		case blueBackground = "Ícone do aplicativo com fundo azul."
		case blueOverBlack = "Ícone azul do aplicativo com fundo preto."
		case whiteOverBlack = "Ícone claro do aplicativo com fundo preto."

		func accessibilityText(selected: Bool) -> String {
			return "\(self)\(selected ? " Selected." : "")"
		}
	}

	// MARK: - View lifecycle -

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView?.register(UINib(nibName: "SettingsHeaderCell", bundle: nil), forHeaderFooterViewReuseIdentifier: "headerCell")
		self.tableView?.register(UINib(nibName: "SettingsSubHeaderCell", bundle: nil), forHeaderFooterViewReuseIdentifier: "subHeaderCell")
		self.tableView?.register(UINib(nibName: "SettingsDisclaimerFooter", bundle: nil), forHeaderFooterViewReuseIdentifier: "disclaimerFooter")
		self.tableView?.register(UINib(nibName: "SettingsTermsFooter", bundle: nil), forHeaderFooterViewReuseIdentifier: "termsFooter")

        registerForTraitChanges([UITraitUserInterfaceStyle.self],
                                handler: { (self: Self, _) in
            self.tableView.reloadData()
        })

        tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 50

		setInitialValues()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
			return
		}
		delegate.supportedInterfaceOrientation = Settings().orientations

		patraoButton.setTitle(Settings().loginPatrao, for: .normal)
		setupInAppPurchase()
	}

	// MARK: - TableView Methods -

	struct Table {
		let header: String
		var cell: String = "headerCell"
		var type: HeaderType = .none
		var heightForFooter: CGFloat = 18
		var footer: String?
		var heightForRow: CGFloat = UITableView.automaticDimension
	}

	static var getHeaders: [Table] {
		var header = [Table]()
		header.append(Table(header: "Remover propagandas",
							cell: "subHeaderCell",
							type: .subscription,
							heightForFooter: UITableView.automaticDimension,
							footer: "termsFooter"))
		header.append(Table(header: "Notificações push"))
		header.append(Table(header: "Aparência"))
		header.append(Table(header: "Posts"))
		header.append(Table(header: "Ícone do app", heightForRow: 105))
		header.append(Table(header: "Sobre",
							cell: "subHeaderCell",
							type: .version,
							heightForFooter: UITableView.automaticDimension,
							footer: "disclaimerFooter"))
		return header
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headers = SettingsTableViewController.getHeaders
		guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: headers[section].cell) as? SettingsHeaderCell else {
			return nil
		}
		header.setHeader(headers[section].header, type: headers[section].type)
		return header
	}

	override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return SettingsTableViewController.getHeaders[section].heightForFooter
	}

	override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		guard let identifier = SettingsTableViewController.getHeaders[section].footer,
			  let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as? SettingsHeaderCell else {
			return nil
		}
		footer.showFooter()
		return footer
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		// "INTENSIDADE POST LIDO"
		if indexPath.section == 3 &&
			indexPath.row == 1 {
			return appearanceCellIntensity.isHidden ? 0 : UITableView.automaticDimension
		}

		return SettingsTableViewController.getHeaders[indexPath.section].heightForRow
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}
}

// MARK: - Cache -

extension SettingsTableViewController {
	@IBAction private func clearCache(_ sender: Any) {
		self.flush(.keepAllStatus)
	}

	@IBAction private func clearCacheWithOptions(_ sender: Any) {
		guard let gesture = sender as? UILongPressGestureRecognizer,
			  let button = gesture.view as? UIButton else {
			return
		}
		if gesture.state == .began {
			let alertController = UIAlertController(title: "Limpar cache", message: "Escolha uma opção", preferredStyle: .actionSheet)

			alertController.addAction(UIAlertAction(title: "Limpar tudo", style: .destructive) { _ in
				self.flush(.all)
			})

			alertController.addAction(UIAlertAction(title: "Limpar e manter favoritos", style: .default) { _ in
				self.flush(.keepFavorite)
			})

			alertController.addAction(UIAlertAction(title: "Limpar e manter status de leitura", style: .default) { _ in
				self.flush(.keepReadStatus)
			})

			alertController.addAction(UIAlertAction(title: "Limpar e manter favoritos e status de leitura", style: .default) { _ in
				self.flush(.keepAllStatus)
			})

			alertController.addAction(UIAlertAction(title: "Apagar somente imagens", style: .default) { _ in
				self.flush(.imagesOnly)
			})

			alertController.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in
				self.dismiss(animated: true)
			})

			if let popoverController = alertController.popoverPresentationController {
				popoverController.sourceView = button
				popoverController.sourceRect = CGRect(x: button.bounds.midX, y: button.bounds.midY, width: 0, height: 0)
			}

			self.present(alertController, animated: true)
		}
	}

	fileprivate func flush(_ type: FlushType) {
		// Delete all posts and podcasts
		CoreDataStack.shared.flush(type: type)

		// Delete all downloaded images
		ImageCache.default.clearDiskCache()

		// Clean Spotlight search indexes
		CSSearchableIndex.default().deleteAllSearchableItems(completionHandler: nil)

		// Clean cookies
		if type == .all {
			UserDefaults.standard.set(true, forKey: Definitions.deleteAllCookies)
			UserDefaults.standard.synchronize()

			NotificationCenter.default.post(name: .reloadWeb, object: "")
		}

		// Feedback message
		let alertController = UIAlertController(title: "Cache limpo!", message: "O conteúdo do app será recarregado.", preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
			NotificationCenter.default.post(name: .refreshAfterBackground, object: nil)

			self.dismiss(animated: true)
		})
		self.present(alertController, animated: true)
	}
}

// MARK: - Push -

extension SettingsTableViewController {
	@IBAction private func setPushMode(_ sender: Any) {
		guard let segment = sender as? UISegmentedControl else {
			return
		}
		Settings().updatePushPreference(segment.selectedSegmentIndex)
	}
}

// MARK: - Login patrons -

extension SettingsTableViewController {
	@IBAction private func login(_ sender: Any) {
		if Settings().isPatrao {
			var settings = Settings()
			settings.isPatrao = false

			setupInAppPurchase()
		} else {
			if let url = URL(string: API.APIParams.patrao) {
				let storyboard = UIStoryboard(name: "WebView", bundle: nil)
				guard let controller = storyboard.instantiateViewController(withIdentifier: "PostDetail") as? WebViewController else {
					return
				}
				controller.postURL = url

				controller.modalPresentationStyle = .overFullScreen
				show(controller, sender: self)
			}
		}
		patraoButton.setTitle(Settings().loginPatrao, for: .normal)
	}
}

// MARK: - Initial Values -

extension SettingsTableViewController {
	fileprivate func setInitialValues() {
		pushOptions.selectedSegmentIndex = Settings().pushPreference

		let iconName = UserDefaults.standard.string(forKey: Definitions.icon)
		setIconOptionsSelection(selected: iconName ?? "option_1")

		let transparency = Settings().transparency
		intensityPostRead.isOn = transparency < 1
		readTransparency.value = Float(transparency * 100.0)
		readTransparencyValue.text = "\(String(describing: Int(readTransparency.value)))%"

		appearanceCellIntensity.isHidden = true

		darkModeSegmentControl.selectedSegmentIndex = Settings().appearance.rawValue

		badge.isEnabled = intensityPostRead.isOn
		badgeMessage.textColor = intensityPostRead.isOn ? .label : .gray
		badge.isOn = UserDefaults.standard.bool(forKey: Definitions.badge)
	}
}

// MARK: - Mail Methods -

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
	@IBAction private func reportProblem(_ sender: Any) {
		guard MFMailComposeViewController.canSendMail() else {
			if let url = URL(string: "mailto:contato@macmagazine.com.br?subject=Relato de problema no app MacMagazine \(Settings().appVersion)"),
			   UIApplication.shared.canOpenURL(url) {
				UIApplication.shared.open(url, options: [:], completionHandler: nil)
			}

			return
		}

		let composeVC = MFMailComposeViewController()
		composeVC.mailComposeDelegate = self
		composeVC.setSubject("Relato de problema no app MacMagazine \(Settings().appVersion)")
		composeVC.setToRecipients(["contato@macmagazine.com.br"])

		self.present(composeVC, animated: true, completion: nil)
	}

	public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true)
	}
}

// MARK: - Appearance Methods -

extension SettingsTableViewController {

	@IBAction private func changeDarkMode(_ sender: Any) {
		guard let darkMode = sender as? UISegmentedControl else {
			return
		}
		UserDefaults.standard.set(darkMode.selectedSegmentIndex, forKey: Definitions.darkMode)
		UserDefaults.standard.synchronize()

		Settings().applyTheme()

		NotificationCenter.default.post(name: .updateCookie, object: Definitions.darkMode)
	}
}

// MARK: - Posts lidos Methods -

extension SettingsTableViewController {

	@IBAction private func enableReadIntensity(_ sender: Any) {
		guard let intensity = sender as? UISwitch else {
			return
		}

		let value: Float = intensity.isOn ? 50.0 : 100.0

		setIntensity(value)
		readTransparency.setValue(value, animated: true)

		badge.isEnabled = intensity.isOn
		badgeMessage.textColor = intensity.isOn ? .label : .gray
		if !intensity.isOn {
			appearanceCellIntensity.isHidden = true

			// If Identificar is off, badge is off
			badge.isOn = false
			showBadge(badge as Any)

			self.tableView.reloadData()
		}
	}

	@IBAction private func showReadIntensitySlider(_ sender: Any) {
		guard let gesture = sender as? UILongPressGestureRecognizer else {
			return
		}
		if gesture.state == .began {
			let transparency = Settings().transparency
			readTransparency.value = Float(transparency * 100.0)
			readTransparencyValue.text = "\(String(describing: Int(readTransparency.value)))%"

			appearanceCellIntensity.isHidden = !appearanceCellIntensity.isHidden
			self.tableView.reloadData()
		}
	}

	@IBAction private func changeReadTransparencyIntensity(_ sender: Any) {
		guard let slider = sender as? UISlider else {
			return
		}
		setIntensity(slider.value)
	}

	fileprivate func setIntensity(_ intensity: Float) {
		readTransparencyValue.text = "\(String(describing: Int(intensity)))%"

		UserDefaults.standard.set(intensity / 100.0, forKey: Definitions.transparency)
		UserDefaults.standard.synchronize()

		NotificationCenter.default.post(name: .reloadData, object: nil)
	}

	@IBAction private func showBadge(_ sender: Any) {
		guard let badge = sender as? UISwitch else {
			return
		}

		UserDefaults.standard.set(badge.isOn, forKey: Definitions.badge)
		UserDefaults.standard.synchronize()

		Helper().showBadge()
	}

	@IBAction private func setAllRead(_ sender: Any) {
		CoreDataStack.shared.read(.all) {
			let alertController = UIAlertController(title: "Sucesso!",
													message: "Todos os posts foram marcados como lidos.",
													preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
				delay(0.1) {
                    UNUserNotificationCenter.current().setBadgeCount(0)
				}
				self.dismiss(animated: true)
			})
			self.present(alertController, animated: true)
		}
	}
}

// MARK: - App Icon Methods -

extension SettingsTableViewController {

	struct IconOptions {
		static let option1 = "option_1"
		static let option2 = "option_2"
		static let option3 = "option_3"
		static let option4 = "option_4"
		static let icon1 = "AppIcon-1"
		static let icon2 = "AppIcon-2"
		static let icon3 = "AppIcon-3"
		static let icon4 = "AppIcon-4"

		func getIcon(for option: String) -> String? {
			var icon: String?

			switch option {
			case IconOptions.option1:
				icon = IconOptions.icon1
			case IconOptions.option2:
				icon = IconOptions.icon2
			case IconOptions.option3:
				icon = IconOptions.icon3
			case IconOptions.option4:
				icon = IconOptions.icon4
			default:
				break
			}

			return icon
		}
	}

	@IBAction private func changeAppIcon(_ sender: Any) {
		guard let button = sender as? UIButton,
			  let option = button.restorationIdentifier else {
			return
		}
		changeIcon(to: option)
	}

	fileprivate func setIconOptionsSelection(selected iconName: String) {
		let selectedImage = UIImage(systemName: "checkmark.circle.fill")
		let normal = UIImage(systemName: "circle")

		let tintSelectedColor = UIColor(named: "MMBlue")
		let tintColor = UIColor.systemGray

		iconOption1Selected.image = iconName == IconOptions.option1 ? selectedImage : normal
		iconOption1Selected.tintColor = iconName == IconOptions.option1 ? tintSelectedColor : tintColor
		iconOption1Btn.accessibilityLabel = IconOptionAccessibilityLabel.whiteBackground.accessibilityText(selected: iconName == IconOptions.option1)

		iconOption2Selected.image = iconName == IconOptions.option2 ? selectedImage : normal
		iconOption2Selected.tintColor = iconName == IconOptions.option2 ? tintSelectedColor : tintColor
		iconOption2Btn.accessibilityLabel = IconOptionAccessibilityLabel.blueBackground.accessibilityText(selected: iconName == IconOptions.option2)

		iconOption3Selected.image = iconName == IconOptions.option3 ? selectedImage : normal
		iconOption3Selected.tintColor = iconName == IconOptions.option3 ? tintSelectedColor : tintColor
		iconOption3Btn.accessibilityLabel = IconOptionAccessibilityLabel.blueOverBlack.accessibilityText(selected: iconName == IconOptions.option3)

		iconOption4Selected.image = iconName == IconOptions.option4 ? selectedImage : normal
		iconOption4Selected.tintColor = iconName == IconOptions.option4 ? tintSelectedColor : tintColor
		iconOption4Btn.accessibilityLabel = IconOptionAccessibilityLabel.whiteOverBlack.accessibilityText(selected: iconName == IconOptions.option4)
	}

	fileprivate func changeIcon(to iconName: String) {
		guard UIApplication.shared.supportsAlternateIcons,
			  let icon = IconOptions().getIcon(for: iconName) else {
			return
		}

		UIApplication.shared.setAlternateIconName(icon) { error in
			if error == nil {
				UserDefaults.standard.set(iconName, forKey: Definitions.icon)
				UserDefaults.standard.synchronize()

				self.setIconOptionsSelection(selected: iconName)
			}
		}
	}
}

// MARK: - Subscriptions -

extension SettingsTableViewController {
	@IBAction private func manage(_ sender: Any) {
		guard let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") else {
			return
		}
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}

	@IBAction private func buy(_ sender: Any) {
		let product = products.filter { $0.identifier == (sender as? UIButton)?.accessibilityIdentifier }
		guard let product = product.first else { return }
		Subscriptions.shared.purchase(product: product)
	}

	fileprivate func setContent(for button: UIButton?, filtering: String, using products: [InAppPurchase.Product]) {
		let product = products.first(where: { $0.subscription?.contains(filtering) ?? false })
		if let price = product?.price,
		   let subscription = product?.subscription?.replacingOccurrences(of: "1 ", with: ""),
		   let identifier = product?.identifier {
			button?.setTitle("\(price)/\(subscription)", for: .normal)
			button?.accessibilityIdentifier = identifier
		}
	}

	fileprivate func setupInAppPurchase() {
		enableBuyObjects(true)
		manageBtn.isEnabled = false
		restoreBtn.isEnabled = false

		Subscriptions.shared.status = { [weak self] status in
			self?.manageBtn.isEnabled = true
			self?.restoreBtn.isEnabled = true
			self?.purchasedMessage.textColor = UIColor(named: "MMDarkGreyWhite")

			switch status {
			case .canPurchase:
				var settings = Settings()
				settings.purchased = false

				self?.showBuyObjects(true)

			case .expired:
				var settings = Settings()
				settings.purchased = false

				self?.showBuyObjects(true)

				self?.purchasedMessage.text = "Sua assinatura está vencida"
				self?.purchasedMessage.textColor = .systemRed

			case .processing:
				self?.showBuyObjects(false)
				self?.purchasedMessage.isHidden = true
				self?.spin.startAnimating()
				self?.manageBtn.isEnabled = false
				self?.restoreBtn.isEnabled = false

			case .gotProducts(let products):
				if products.count == 2 {
					self?.products = products
					self?.setContent(for: self?.buyMonthBtn, filtering: "mês", using: products)
					self?.setContent(for: self?.buyYearBtn, filtering: "ano", using: products)

					self?.enableBuyObjects(true)
					Subscriptions.shared.checkSubscriptions()
				} else {
					self?.enableBuyObjects(false)
					self?.purchasedMessage.text = "Erro ao obter assinaturas."
					self?.purchasedMessage.textColor = .systemRed
				}

			case .purchasedSuccess:
				self?.showBuyObjects(false)
				self?.purchasedMessage.isHidden = false
				self?.manageBtn.isEnabled = true
				self?.restoreBtn.isEnabled = false
				self?.patraoButton.isEnabled = false

				var settings = Settings()
				settings.purchased = true

				self?.purchasedMessage.text = "Você já é nosso assinante!"

			case .disabled:
				self?.enableBuyObjects(false)

				self?.purchasedMessage.text = "Compras dentro de Apps desabilitada."
				self?.purchasedMessage.textColor = .systemRed
				self?.manageBtn.isEnabled = false
				self?.restoreBtn.isEnabled = false

			case .fail:
				self?.enableBuyObjects(false)
				self?.purchasedMessage.text = "Erro ao obter assinaturas."
				self?.purchasedMessage.textColor = .systemRed

			case .nothingToRestore:
				self?.showBuyObjects(true)

				let alertController = UIAlertController(title: "Assinaturas", message: "Nenhuma assinatura disponível para restaurar.", preferredStyle: .alert)
				alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
					self?.dismiss(animated: true)
				})
				self?.present(alertController, animated: true)
			}
		}

		hideObjects(Settings().isPatrao)
		if !Settings().isPatrao {
			Subscriptions.shared.getProducts()
		}
	}

	fileprivate func showBuyObjects(_ show: Bool) {
		spin.stopAnimating()
		buyMonthBtn.isHidden = !show
		buyYearBtn.isHidden = !show
		purchasedMessage.isHidden = show
	}

	fileprivate func enableBuyObjects(_ enable: Bool) {
		showBuyObjects(true)
		buyMonthBtn.isEnabled = enable
		buyMonthBtn.isHidden = !enable
		buyYearBtn.isEnabled = enable
		buyYearBtn.isHidden = !enable
	}

	fileprivate func hideObjects(_ enable: Bool) {
		showBuyObjects(!enable)
		purchasedMessage.isHidden = !enable
		purchasedMessage.text = enable ? "Você está logado como patrão!" : "Você já é nosso assinante!"
	}
}

extension SettingsTableViewController {
	@IBAction private func restore(_ sender: Any) {
		Subscriptions.shared.restore()
	}

}
