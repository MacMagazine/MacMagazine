//
//  WebViewController.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 30/03/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import PassKit
import SafariServices
import StoreKit
import UIKit
@preconcurrency import WebKit

enum RightButtons {
	case spin
	case actions
	case close
}

class WebViewController: UIViewController {

	// MARK: - Properties -

	@IBOutlet private weak var webView: WKWebView!
	@IBOutlet private weak var hideView: UIView!
	@IBOutlet private weak var spin: UIActivityIndicatorView!
	@IBOutlet private weak var actions: UIBarButtonItem!
	@IBOutlet private weak var close: UIBarButtonItem!

	var post: PostData?

	var postURL: URL? {
		didSet {
			guard let url = postURL else {
				return
			}
			loadWebView(url: url)
		}
	}

	var commentsURL: String = ""

	var forceReload: Bool = false
	var previousIsDarkMode: Bool = false
	var previousFonteSize: String = ""

	@IBOutlet private weak var fullscreenMode: UIBarButtonItem!
	@IBOutlet private weak var splitviewMode: UIBarButtonItem!

	var showFullscreenModeButton = true

	// MARK: - View lifecycle -

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		NotificationCenter.default.addObserver(self, selector: #selector(reload(_:)), name: .reloadWeb, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateCookie(_:)), name: .updateCookie, object: nil)

		if Settings().isPad &&
			self.splitViewController != nil &&
			self.navigationController?.viewControllers.count ?? 0 > 1 {

			self.navigationItem.leftItemsSupplementBackButton = true
			self.navigationItem.leftBarButtonItem = showFullscreenModeButton ? fullscreenMode : splitviewMode
		}

		webView?.navigationDelegate = self
		webView?.uiDelegate = self

		// Tap image to zoom
		let imageScriptSource = """
			var images = document.querySelectorAll('[data-full-url]');
			for(var i = 0; i < images.length; i++) {
				images[i].addEventListener("click", function() {
					window.webkit.messageHandlers.imageTappedHandler.postMessage(this.dataset.fullUrl);
				}, false);
			}
		"""
		let imageScript = WKUserScript(source: imageScriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
		webView?.configuration.userContentController.addUserScript(imageScript)
		webView?.configuration.userContentController.add(self, name: "imageTappedHandler")

		// Disable Gallery
		let disableGalleryScriptSource = """
			var links = document.getElementsByClassName('fancybox');
			for(var i = 0; i < links.length; i++) {
				links[i].href = 'javascript:void(0);return false;';
			}
		"""
		let galleryScript = WKUserScript(source: disableGalleryScriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
		webView?.configuration.userContentController.addUserScript(galleryScript)

		// Disable Gallery - site novo
		let disableNewGalleryScriptSource = """
			var links = document.getElementsByClassName('pk-image-popup');
			for(var i = 0; i < links.length; i++) {
				links[i].href = 'javascript:void(0);return false;';
			}
		"""
		let newGalleryScript = WKUserScript(source: disableNewGalleryScriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
		webView?.configuration.userContentController.addUserScript(newGalleryScript)

		// Get URL for comments
		let commentsScriptSource = """
			var comments = document.querySelectorAll('[data-disqus-identifier]');
			window.webkit.messageHandlers.gotCommentURLHandler.postMessage(comments[0].dataset.disqusIdentifier);
		"""
		let commmentsScript = WKUserScript(source: commentsScriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
		webView?.configuration.userContentController.addUserScript(commmentsScript)
		webView?.configuration.userContentController.add(self, name: "gotCommentURLHandler")

		// Prevent tracking
		let removeBackToBlogScriptSource = "document.getElementById('backtoblog').outerHTML = '';"
		let removeBackToBlogScript = WKUserScript(source: removeBackToBlogScriptSource,
												  injectionTime: .atDocumentEnd,
												  forMainFrameOnly: true)
		webView?.configuration.userContentController.addUserScript(removeBackToBlogScript)

		setupCookies()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Hack to reload content on iPads
		configureView()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		// Hack to force a inline video to stop playning
		if post?.playable ?? false {
			webView?.loadHTMLString("", baseURL: nil)
		}
	}

	// MARK: - Local methods -

	func configureView() {
		// Update the user interface for the detail item.
		guard let post = post,
			  let link = post.link,
			  let url = URL(string: link)
		else {
			return
		}

		if webView?.url != url ||
			forceReload {
			loadWebView(url: url)
		}
	}

	func loadWebView(url: URL) {
		if UserDefaults.standard.bool(forKey: Definitions.deleteAllCookies) {
			let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
			let date = Date(timeIntervalSince1970: 0)
			if let websiteDataTypes = websiteDataTypes as? Set<String> {
				WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: date, completionHandler: {})
			}
		}

		previousIsDarkMode = Settings().isDarkMode
		previousFonteSize = Settings().fontSizeUserAgent

		forceReload = false

		// Changes the WKWebView user agent in order to hide some CSS/HT elements
		webView?.allowsBackForwardNavigationGestures = false
		webView?.evaluateJavaScript("navigator.userAgent") { [weak self] result, _ in
			if let userAgent = result as? String {
				self?.webView?.customUserAgent = userAgent + "/MacMagazine"
			}
			self?.webView?.load(URLRequest(url: url))
		}
	}

	func setRightButtomItems(_ buttons: [RightButtons]) {
		guard let viewController = getPostsDetailViewController() else {
			let rightButtons: [UIBarButtonItem] = buttons.map {
				switch $0 {
				case .spin:     return UIBarButtonItem(customView: spin)
				case .actions:  return actions
				case .close:    return close
				}
			}
			self.navigationItem.rightBarButtonItems = rightButtons
			return
		}
		viewController.setRightButtomItems(buttons)
	}

	// MARK: - Actions -

	@IBAction private func share(_ sender: Any) {
		guard let post = post,
			  let link = post.link,
			  let url = URL(string: link) else {

			guard let url = postURL else {
				let alertController = UIAlertController(title: "MacMagazine", message: "Não há nada para compartilhar", preferredStyle: .alert)
				alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
					self.dismiss(animated: true)
				})
				self.present(alertController, animated: true)

				return
			}
			let items: [Any] = [webView.title ?? "", url]
			Share().present(at: actions, using: items)
			return
		}

		let favorito = UIActivityExtensions(title: "Favorito",
											image: UIImage(systemName: post.favorito ? "star.fill" : "star")) { _ in
			Favorite().updatePostStatus(using: link) { [weak self] isFavorite in
				self?.post?.favorito = isFavorite
			}
		}

		let items: [Any] = [post.title ?? "", url]
		Share().present(at: actions, using: items, activities: [favorito])
	}

	@IBAction private func enterFullscreenMode(_ sender: Any) {
		guard let parent = self.navigationController?.viewControllers[0] as? PostsDetailViewController else {
			return
		}
		parent.enterFullscreenMode()
		self.navigationItem.leftBarButtonItem = self.splitviewMode
		self.webView.reload()
	}

	@IBAction private func enterSplitViewMode(_ sender: Any) {
		guard let parent = self.navigationController?.viewControllers[0] as? PostsDetailViewController else {
			return
		}
		parent.enterSplitViewMode()
		self.navigationItem.leftBarButtonItem = self.fullscreenMode
		self.webView.reload()
	}

	@IBAction private func close(_ sender: Any) {
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
}

// MARK: - Notifications -

extension WebViewController {

	func reload() {
		if post != nil {
			configureView()
		} else if postURL != nil {
			guard let url = postURL else {
				return
			}
			loadWebView(url: url)
		}
	}

	@objc func reload(_ notification: Notification) {
		if previousIsDarkMode != Settings().isDarkMode ||
			previousFonteSize != Settings().fontSizeUserAgent ||
			notification.object != nil {

			forceReload = true
			reload()
		}
	}
}

// MARK: - Cookies -

extension WebViewController {

	fileprivate func set(cookies: [HTTPCookie], _ callback: (() -> Void)?) {
		// Set cookies syncronuos
		let group = DispatchGroup()
		group.enter()

		var cookiesLeft = cookies.count
		cookies.forEach { cookie in
			self.webView?.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
				cookiesLeft -= 1
				if cookiesLeft <= 0 {
					group.leave()
				}
			}
		}

		group.notify(queue: .main) {
			callback?()
		}
	}

	fileprivate func delete(cookies: [HTTPCookie], _ callback: (() -> Void)? = nil) {
		// Set cookies syncronuos
		let group = DispatchGroup()
		group.enter()

		var cookiesLeft = cookies.count
		cookies.forEach { cookie in
			self.webView?.configuration.websiteDataStore.httpCookieStore.delete(cookie) {
				cookiesLeft -= 1
				if cookiesLeft <= 0 {
					group.leave()
				}
			}
		}

		group.notify(queue: .main) {
			callback?()
		}
	}

	fileprivate func deleteAllCookies(_ callback: (() -> Void)?) {
		if UserDefaults.standard.bool(forKey: Definitions.deleteAllCookies) {
			let group = DispatchGroup()
			group.enter()

			webView?.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
				self.delete(cookies: cookies) {
					group.leave()
				}
			}

			group.notify(queue: .main) {
				UserDefaults.standard.set(false, forKey: Definitions.deleteAllCookies)
				UserDefaults.standard.synchronize()

				callback?()
			}
		} else {
			callback?()
		}
	}

	fileprivate func setupCookies() {
		// Make sure that all cookies are loaded before continue
		// to prevent Disqus from being loogoff
		// and to set MM properties to properly load the content

		deleteAllCookies {
			// Set cookies syncronuos
			let group = DispatchGroup()
			group.enter()

			self.webView?.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
				var cookies = cookies

				// Dark mode
				if let darkmode = Cookies().createDarkModeCookie(Settings().darkModeUserAgent) {
					cookies.append(darkmode)
				}

				// Font size
				if let font = Cookies().createFonteCookie(Settings().fontSizeUserAgent) {
					cookies.append(font)
				}

				// Purchased
				if Settings().purchased || Settings().isPatrao {
					if let purchased = Cookies().createPurchasedCookie("true") {
						cookies.append(purchased)
					}
				} else {
					let patrCookie = cookies.filter { $0.name == "patr" }
					self.delete(cookies: patrCookie)
				}

				if cookies.isEmpty {
					group.leave()
				} else {
					self.set(cookies: cookies) {
						group.leave()
					}
				}
			}

			group.notify(queue: .main) {
				self.reload()
			}
		}
	}

	@objc func updateCookie(_ notification: Notification) {
		guard let cookieName = notification.object as? String else {
			return
		}

		var cookie: HTTPCookie?
		if cookieName == Definitions.fontSize {
			cookie = Cookies().createFonteCookie(Settings().fontSizeUserAgent)
		}
		if cookieName == Definitions.darkMode {
			cookie = Cookies().createDarkModeCookie(Settings().darkModeUserAgent)
		}

		guard let cookieToSet = cookie else {
			return
		}
		self.set(cookies: [cookieToSet]) {
			self.webView?.reload()
		}
	}

}

// MARK: - WebView Delegate -

extension WebViewController: WKNavigationDelegate, WKUIDelegate {

	fileprivate func getPostsDetailViewController() -> PostsDetailViewController? {
		if let parent = self.parent,
		   parent.isKind(of: UINavigationController.self) {
			return nil
		}
		let detailController = self.navigationController?.viewControllers.filter { $0.isKind(of: PostsDetailViewController.self) }
		return detailController?.first as? PostsDetailViewController
	}

	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
		self.navigationItem.rightBarButtonItems = nil
		hideView.alpha = 1
		spin.startAnimating()

		Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { timer in
			DispatchQueue.main.async {
				self.hideView.alpha = 0
				self.spin.stopAnimating()
			}
			timer.invalidate()
		}
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
		self.navigationItem.rightBarButtonItems = nil

		var items = [RightButtons]()
		if webView.url?.isMMPost() ?? false {
			if webView.url?.isMMAddress() ?? false {
				items.append(.actions)
			}
		} else {
			items.append(.close)
		}
		if post == nil && items.isEmpty {
			items.append(.close)
		}
		if webView.url?.isPatrao() ?? false {
			items.removeAll()
		}
		setRightButtomItems(items)

		hideView.alpha = 0
		spin.stopAnimating()
	}

	func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

		if !(navigationAction.targetFrame?.isMainFrame ?? false) {
			guard let url = navigationAction.request.url else {
				return nil
			}

			if url.isMMAddress() {
				pushNavigation(url, isPost: url.isMMPost())

			} else if url.isAppStore() {
				guard let id = url.appStoreId() else {
					return nil
				}
				openStoreProduct(with: id)

			} else if url.isYouTube() {
				openYouTube(with: url)

			} else {
				openInSafari(url)
			}
		}
		return nil
	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		var actionPolicy: WKNavigationActionPolicy = .allow

		guard let url = navigationAction.request.url else {
			decisionHandler(actionPolicy)
			return
		}

		switch navigationAction.navigationType {
		case .linkActivated:
			if navigationAction.request.url?.absoluteString.contains("comments://") ?? false {
				if let URL = navigationAction.request.url?.absoluteString.replacingOccurrences(of: "comments://", with: "") {
					commentsURL = URL.replacingOccurrences(of: "%20", with: " ")
					self.performSegue(withIdentifier: "showCommentsSegue", sender: self)
				}
			} else if navigationAction.request.url?.absoluteString.contains("#disqus_thread") ?? false {
				self.performSegue(withIdentifier: "showCommentsSegue", sender: self)
			} else if navigationAction.request.url?.absoluteString.hasSuffix(".pkpass") ?? false {
				if let url = navigationAction.request.url {
					openPassKit(url: url)
				}
			} else {
				openURLinBrowser(url)
			}
			actionPolicy = .cancel

		case .formSubmitted:
			if url.absoluteString == navigationAction.request.mainDocumentURL?.absoluteString &&
				webView.isLoading {
				actionPolicy = processLogin(for: webView.url?.absoluteString)
			}

		case .other:
			if url.absoluteString == navigationAction.request.mainDocumentURL?.absoluteString &&
				webView.isLoading {
				if navigationAction.request.url?.absoluteString.contains("https://disqus.com/next/login-success") ?? false {
					actionPolicy = .cancel
					self.navigationController?.popViewController(animated: true)
					NotificationCenter.default.post(name: .reloadAfterLogin, object: nil)
				}
			}

		default:
			break
		}
		decisionHandler(actionPolicy)
	}

	fileprivate func backAndReload() {
		delay(0.8) {
			self.navigationController?.popViewController(animated: true)
			delay(0.8) {
				NotificationCenter.default.post(name: .reloadWeb, object: true)
			}
		}
	}

	fileprivate func processLogin(for url: String?) -> WKNavigationActionPolicy {
		var actionPolicy: WKNavigationActionPolicy = .allow

		let mmURL = "\(API.APIParams.mmURL)wp-admin/profile.php"

		if url == mmURL {
			var settings = Settings()
			settings.isPatrao = true

			actionPolicy = .cancel
			backAndReload()
		}
		return actionPolicy
	}

	fileprivate func openURLinBrowser(_ url: URL) {
		if url.isMMAddress() {
			pushNavigation(url, isPost: url.isMMPost())
		} else {
			openInSafari(url)
		}
	}
}

extension WebViewController {

	func pushNavigation(_ url: URL, isPost: Bool) {
		// Prevent double pushViewController due decidePolicyFor navigationAction == .other
		if self.navigationController?.viewControllers.count ?? 0 <= 1 {
			processURL(url, isPost) { post, url in
				let storyboard = UIStoryboard(name: "WebView", bundle: nil)
				guard let controller = storyboard.instantiateViewController(withIdentifier: "PostDetail") as? WebViewController else {
					return
				}
				controller.post = post
				controller.postURL = url

				if let parent = self.navigationController?.viewControllers[0] as? PostsDetailViewController {
					controller.showFullscreenModeButton = parent.showFullscreenModeButton
				}
				self.show(controller, sender: self)
			}

		} else {
			loadWebView(url: url)
		}
	}

	fileprivate func processURL(_ url: URL, _ isPost: Bool, _ completionHandler: @escaping ((PostData?, URL?)) -> Void) {
		var data: PostData?

		let group = DispatchGroup()
		group.enter()

		CoreDataStack.shared.get(link: url.absoluteString) { (posts: [PostData]) in
			data = posts.isEmpty ? nil : posts.first
			group.leave()
		}

		group.notify(queue: .main) {
			completionHandler((data, data == nil ? url : nil))
		}
	}

	func openInSafari(_ url: URL) {
		if url.scheme?.lowercased().contains("http") ?? false {
			let safari = SFSafariViewController(url: url)
			safari.setup()
			self.present(safari, animated: true, completion: nil)
		}
	}

}

extension WebViewController: WKScriptMessageHandler {
	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		switch message.name {
		case "imageTappedHandler":
			guard let body = message.body as? String,
				  let url = URL(string: body) else {
				return
			}
			if url.isMMAddress() &&
				!url.isAppStoreBadge() {
				openInSafari(url)
			}

		case "gotCommentURLHandler":
			guard let body = message.body as? String else {
				return
			}
			commentsURL = body

		default:
			break
		}
	}
}

// MARK: - Segues -

extension WebViewController {
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let navController = segue.destination as? UINavigationController,
			  let controller = navController.topViewController as? DisqusViewController else {
			return
		}
		controller.commentsURL = commentsURL
	}
}

// MARK: - External Apps -

extension WebViewController {
	func openStoreProduct(with identifier: String) {
		let storeViewController = SKStoreProductViewController()
		self.present(storeViewController, animated: true, completion: nil)

		storeViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: identifier])
	}

	func openYouTube(with url: URL) {
		guard let videoId = url.videoId(),
			  let youtubeAppUrl = URL(string: "youtube://\(videoId)") else {
			if UIApplication.shared.canOpenURL(url) {
				UIApplication.shared.open(url, options: [:], completionHandler: nil)
			}
			return
		}

		if UIApplication.shared.canOpenURL(youtubeAppUrl) {
			UIApplication.shared.open(youtubeAppUrl, options: [:], completionHandler: nil)
		} else {
			if UIApplication.shared.canOpenURL(url) {
				UIApplication.shared.open(url, options: [:], completionHandler: nil)
			}
		}
	}
}

// MARK: - PassKit -

extension WebViewController: PKAddPassesViewControllerDelegate {
	func openPassKit(url: URL) {
		Network.get(url: url) { (result: Result<Data, RestAPIError>) in
			switch result {
			case .failure(_):   break

			case .success(let response):
				self.processPass(response)
			}
		}
	}

	fileprivate func processPass(_ pass: Data) {
		do {
			let pass = try PKPass(data: pass)
			DispatchQueue.main.async {
				guard let pkvc = PKAddPassesViewController(pass: pass) else { return }
				pkvc.delegate = self
				self.present(pkvc, animated: true, completion: nil)
			}

		} catch {
			logE(error.localizedDescription)
		}
	}

	func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
		controller.dismiss(animated: true, completion: nil)
	}
}
