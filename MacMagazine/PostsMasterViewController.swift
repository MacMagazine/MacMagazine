//
//  PostsMasterViewController.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 18/08/17.
//  Copyright © 2017 MacMagazine. All rights reserved.
//

import AdSupport
import AppTrackingTransparency
import Combine
import CoreData
import CoreSpotlight
import Kingfisher
import SafariServices
import UIKit
import WidgetKit

// MARK: - Extensions -

extension UITableView {
	func rowNumber(indexPath: IndexPath) -> Int {
		if indexPath.section == 0 {
			return indexPath.row
		}
		var rows = 0
		for temp in 0...indexPath.section {
			if temp == indexPath.section {
				rows += indexPath.row
				break
			}
			rows += self.numberOfRows(inSection: temp)
		}
		return rows
	}
}

// MARK: -

enum Direction {
	case goingDown
	case goingUp
}

// MARK: -

class PostsMasterViewController: UITableViewController, FetchedResultsControllerDelegate, ResultsViewControllerDelegate {

	// MARK: - Properties -

    var fetchController: FetchedResultsControllerDataSource?
	var detailViewController: PostsDetailViewController?

	@IBOutlet private weak var logoView: UIView!
    @IBOutlet private weak var spin: UIActivityIndicatorView!
    @IBOutlet private weak var filter: UIBarButtonItem!

	var lastContentOffset = CGPoint()
	var direction: Direction = .goingUp
	var lastPage = -1

    var comeFrom3DTouch = false
	var viewDidAppear = false

	var selectedIndexPath: IndexPath?
	var links: [PostData] = []

	private var searchController: UISearchController?
	private var resultsTableController: ResultsViewController?
	var posts = [XMLPost]()

    let favoritePredicate = NSPredicate(format: "favorite == %@", NSNumber(value: true))
    let notReadPredicate = NSPredicate(format: "read == %@", NSNumber(value: false))
    let destaquePredicate = NSPredicate(format: "categorias contains[cd] %@", "Destaques")

    enum Status {
        case firstLoad
        case lastOpenedPost
        case recentPost
        case unknown
    }

    var status = Status.firstLoad
    var shortcutStatus = Status.unknown

    var cancellable: AnyCancellable?
    var selection = [String]() {
        didSet {
            selectedIndexPath = nil

            if selection.isEmpty {
                cancellable?.cancel()

                fetchController?.fetchRequest.predicate = nil
                reloadController(.transitionCrossDissolve)

            } else {
                fetchController?.fetchRequest.predicate = nil
                var predicates = [NSPredicate]()
                selection.forEach { selection in
                    predicates.append(NSPredicate(format: "categorias contains[cd] %@", selection))
                }
                fetchController?.fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                reloadController(.transitionCrossDissolve)
            }
        }
    }

    var postId: [String] = []

    // MARK: - View Lifecycle -

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(self, selector: #selector(onRefreshAfterBackground(_:)), name: .refreshAfterBackground, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(onShortcutActionLastPost(_:)), name: .shortcutActionLastPost, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onShortcutActionRecentPost(_:)), name: .shortcutActionRecentPost, object: nil)

		if Settings().isPad {
			NotificationCenter.default.addObserver(self, selector: #selector(onUpdateSelectedPost(_:)), name: .updateSelectedPost, object: nil)
		}

        NotificationCenter.default.addObserver(self, selector: #selector(onReloadData(_:)), name: .reloadData, object: nil)

		navigationItem.titleView = logoView
		navigationItem.title = nil
        navigationItem.preferredSearchBarPlacement = .stacked

		fetchController = FetchedResultsControllerDataSource(post: self.tableView, group: "headerDate")
        fetchController?.delegate = self
        fetchController?.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "headerDate", ascending: false),
                                                         NSSortDescriptor(key: "pubDate", ascending: false)]

		resultsTableController = ResultsViewController()
		resultsTableController?.delegate = self
		resultsTableController?.isPodcast = false

		searchController = UISearchController(searchResultsController: resultsTableController)
		searchController?.searchBar.autocapitalizationType = .none
		searchController?.searchBar.delegate = self
		searchController?.searchBar.placeholder = "Buscar nos posts..."
		searchController?.hidesNavigationBarDuringPresentation = true
        searchController?.searchBar.returnKeyType = .search

        tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 133

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 36

        // Execute the fetch to display the data
        fetchController?.reloadData()

        filter.accessibilityLabel = "Mostrar opções de filtro."
    }

	override func viewWillAppear(_ animated: Bool) {
		clearsSelectionOnViewWillAppear = Settings().isPad

        super.viewWillAppear(animated)

        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        delegate.supportedInterfaceOrientation = Settings().orientations

        if Settings().isPhone {
			selectedIndexPath = nil
		}

        if !hasData() {
			lastPage = -1
            status = .firstLoad
        } else {
            status = .lastOpenedPost
        }
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		processSelection()
		viewDidAppear = true

		// AppTrackingTransparency
		ATTrackingManager.requestTrackingAuthorization { _ in }

//        if Settings().whatsNew != Settings().appVersion {
//            self.performSegue(withIdentifier: "showWhatsNewSegue", sender: self)
//        }
	}

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            Settings().updateCookies(based: newCollection)
        }
    }

	// MARK: - Segues -

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showKeywordsSegue" {
            guard let navVC = segue.destination as? UINavigationController,
                  let viewController = navVC.children.first as? KeywordsTableViewController else {
                      return
                  }

            cancellable = viewController.$selection
                .receive(on: RunLoop.main)
                .dropFirst()
                .compactMap { $0 }
                .removeDuplicates()
                .sink { [weak self] selection in
                    self?.selection = selection
                }

        } else {
            guard let navController = segue.destination as? UINavigationController,
                let controller = navController.topViewController as? PostsDetailViewController,
                let indexPath = selectedIndexPath
                else {
                    return
            }

            guard navigationItem.searchController != nil else {
                // Normal Posts table
                if tableView.indexPathForSelectedRow != nil {
                    guard let post = fetchController?.object(at: indexPath) else {
                        return
                    }
                    prepareDetailController(controller, using: links, compare: post.link)
                }
                return
            }
            // Search Posts table
            if resultsTableController?.tableView.indexPathForSelectedRow != nil {
                prepareDetailController(controller, using: links, compare: posts[indexPath.row].link)
            }
        }
    }

	// MARK: - View Methods -

	func willDisplayCell(indexPath: IndexPath) {
		if direction == .goingDown {
			let page = Int(tableView.rowNumber(indexPath: indexPath) / 19) + 1
			if page >= lastPage && tableView.rowNumber(indexPath: indexPath) % 19 == 0 {
				lastPage = page
				self.getPosts(paged: page)
			}
		}
	}

	func configure(cell: PostCell, atIndexPath: IndexPath) {
		guard let object = fetchController?.object(at: atIndexPath) else {
			return
		}
		cell.configurePost(object)
	}

	func didSelectRowAt(indexPath: IndexPath) {
		if selectedIndexPath != indexPath {
			links = fetchController?.links() ?? []
			selectedIndexPath = indexPath
			self.performSegue(withIdentifier: "showDetail", sender: self)

			guard let object = fetchController?.object(at: indexPath),
				let link = object.link else {
					return
			}
			updateLastSelectedPost(link: link)
		}
		if Settings().isPhone {
			self.tableView.deselectRow(at: indexPath, animated: true)
		}
	}

	func configureResult(cell: PostCell, atIndexPath: IndexPath) {
		if !posts.isEmpty {
			let object = posts[atIndexPath.row]
			cell.configureSearchPost(object)
		}
	}

	func didSelectResultRowAt(indexPath: IndexPath) {
		selectedIndexPath = indexPath
		self.links = posts.map { PostData(title: $0.title, link: $0.link, thumbnail: $0.artworkURL, favorito: $0.favorite, postId: $0.postId, shortURL: $0.shortURL) }
		self.performSegue(withIdentifier: "showDetail", sender: self)
	}

	func setFavorite(_ favorited: Bool, atIndexPath: IndexPath) {
		var object = posts[atIndexPath.row]
		object.favorite = favorited

		posts[atIndexPath.row] = object
		self.resultsTableController?.posts = self.posts

		if let cell = self.resultsTableController?.tableView.cellForRow(at: atIndexPath) as? PostCell {
			cell.configureSearchPost(object)
		}
	}

    // MARK: - Local methods -

    fileprivate func hasData() -> Bool {
        return (fetchController?.hasData() ?? false) && !spin.isAnimating
    }

	fileprivate func getPosts(paged: Int) {
        if paged == 0 {
            self.postId = []
        }

        var images: [String] = []
        var searchableItems: [CSSearchableItem] = []

        showSpin()

        API().getPosts(page: paged) { [weak self] post in
            guard let self = self else { return }

            DispatchQueue.main.async {
                guard let post = post else {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
//                        CoreDataStack.shared.delete(self.postId)
//                    }

                    // Prefetch images to be able to sent to Apple Watch
                    let urls = images.compactMap { URL(string: $0) }
                    let prefetcher = ImagePrefetcher(urls: urls)
                    prefetcher.start()

                    // Index all items to Spotlight
                    CSSearchableIndex.default().indexSearchableItems(searchableItems) {
                        if let error = $0 {
                            logE(error.localizedDescription)
                        }
                    }

                    // When post == nil, indicates the last post retrieved
                    self.hideSpin()

                    // Reload Widgets
                    WidgetCenter.shared.reloadAllTimelines()

                    if let post = (UIApplication.shared.delegate as? AppDelegate)?.widgetSpotlightPost {
                        showDetailController(with: post)
                        return
                    }

                    if paged < 1 {
                        if self.status == .recentPost ||
                            self.shortcutStatus == .recentPost {
                            // Came from 3D touch
                            let indexPath = IndexPath(row: 0, section: 0)
                            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)

                            if Settings().isPad {
                                self.fetchController?.tableView(self.tableView, didSelectRowAt: indexPath)
                            } else {
                                self.didSelectRowAt(indexPath: indexPath)
                            }
                            self.status = .unknown
                            self.shortcutStatus = .unknown
                        } else {
                            delay(0.4) {
                                self.processSelection()
                            }
                        }
                        if let shortcutAction = (UIApplication.shared.delegate as? AppDelegate)?.shortcutAction {
                            NotificationCenter.default.post(name: shortcutAction, object: nil)
                            (UIApplication.shared.delegate as? AppDelegate)?.shortcutAction = nil
                        }
                    }

                    return
                }

				self.postId.append(post.postId)
                images.append(post.artworkURL)
                searchableItems.append(self.createSearchableItem(post))

                CoreDataStack.shared.save(post: post)
            }
        }
	}

	fileprivate func createSearchableItem(_ post: XMLPost) -> CSSearchableItem {
		let attributeSet = CSSearchableItemAttributeSet(itemContentType: "kUTTypeData")
		attributeSet.title = post.title
		attributeSet.contentDescription = post.excerpt
		if let url = URL(string: post.artworkURL) {
			attributeSet.thumbnailURL = url
		}
		return CSSearchableItem(uniqueIdentifier: post.link, domainIdentifier: "MMPosts", attributeSet: attributeSet)
	}

	fileprivate func processSelection() {
        if status == .firstLoad {
            delay(0.4) {
                self.lastPage = 0
                self.getPosts(paged: 0)
			}
		}
        if status == .firstLoad ||
            status == .lastOpenedPost {
            processTabletSelection()
        }
        if Settings().isPhone {
            self.status = .unknown
        }
	}

	fileprivate func getLastSelection(_ completion: @escaping (IndexPath) -> Void) {
        let zeroedIndexPath = IndexPath(row: 0, section: 0)

        if status == .recentPost ||
            shortcutStatus == .recentPost {
			completion(zeroedIndexPath)
        } else {
            guard let selectedPostLink = UserDefaults.standard.object(forKey: "selectedPostLink") as? [String: AnyObject],
                  let link = selectedPostLink["link"] as? String,
                  let date = selectedPostLink["date"] as? Date
            else {
                completion(zeroedIndexPath)
                return
            }
            // Check for 12h selection
            if date.addingTimeInterval(12 * 60 * 60) > Date() ||
                comeFrom3DTouch {
                comeFrom3DTouch = false
                CoreDataStack.shared.get(link: link) { (posts: [Post]) in
                    if posts.isEmpty {
                        completion(zeroedIndexPath)
                    } else {
                        completion(self.fetchController?.indexPath(for: posts[0]) ?? zeroedIndexPath)
                    }
                }
            } else {
                completion(zeroedIndexPath)
            }
        }
	}

	fileprivate func processTabletSelection() {
        if Settings().isPad &&
            tableView.numberOfSections > 0 {

			getLastSelection { indexPath in
				if self.tableView.numberOfSections >= indexPath.section && self.tableView.numberOfRows(inSection: indexPath.section) >= indexPath.row {
                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
                    self.fetchController?.tableView(self.tableView, didSelectRowAt: indexPath)
                    self.status = .unknown
                    self.shortcutStatus = .unknown
				}
			}
        }
	}

	fileprivate func processPhoneSelection() {
		if Settings().isPhone &&
			tableView.numberOfSections > 0 {

			getLastSelection { indexPath in
				if self.tableView.numberOfSections >= indexPath.section &&
                    self.tableView.numberOfRows(inSection: indexPath.section) >= indexPath.row {

                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
					self.didSelectRowAt(indexPath: indexPath)
                    self.shortcutStatus = .unknown
				}
			}
		}
	}

}

// MARK: - Scroll detection -

extension PostsMasterViewController {
	override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if navigationItem.titleView == spin &&
            direction == .goingUp {
			delay(0.4) {
				self.getPosts(paged: 0)
			}
		}
	}

	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        direction = offset.y > lastContentOffset.y ? .goingDown : .goingUp
        lastContentOffset = offset

        // Pull to Refresh
        if offset.y < -150 &&
            navigationItem.titleView == logoView &&
            navigationItem.searchController == nil &&
			fetchController?.fetchRequest.predicate == nil {
			showSpin()
        }
    }
}

// MARK: - Spin -

extension PostsMasterViewController {
    func showSpin() {
		DispatchQueue.main.async {
        	self.navigationItem.titleView = self.spin
        	self.spin.startAnimating()
		}
    }

    func hideSpin() {
		DispatchQueue.main.async {
        	self.spin.stopAnimating()
        	self.navigationItem.titleView = self.logoView
		}
    }
}

// MARK: - UISearchBarDelegate -

extension PostsMasterViewController: UISearchBarDelegate {
	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		resultsTableController?.showTyping()
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		guard let text = searchBar.text else {
			return
		}
		fetchController?.fetchRequest.predicate = nil
		resultsTableController?.posts = []
		resultsTableController?.showSpin()
		searchPosts(text)
	}

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		posts = []
		resultsTableController?.posts = posts
		searchBar.resignFirstResponder()
        navigationItem.searchController = nil
    }
}

// MARK: - Notifications -

extension PostsMasterViewController {
    @objc func onRefreshAfterBackground(_ notification: Notification) {
        delay(0.2) {
            self.getPosts(paged: 0)
        }
    }

	@objc func onUpdateSelectedPost(_ notification: Notification) {
		guard let link = notification.object as? String else {
			return
		}
		CoreDataStack.shared.get(link: link) { (posts: [Post]) in
            var indexPath = IndexPath(row: 0, section: 0)
            if !posts.isEmpty {
                indexPath = self.fetchController?.indexPath(for: posts[0]) ?? indexPath
            }
			self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)

			// Validate selection
			self.updateLastSelectedPost(link: link)
		}
	}

	fileprivate func updateLastSelectedPost(link: String) {
		// Validate selection
		guard let selectedPostLink = UserDefaults.standard.object(forKey: "selectedPostLink") as? [String: AnyObject],
			let previouslink = selectedPostLink["link"] as? String
			else {
				let selectedPostLink: [String: AnyObject] = ["link": link as AnyObject, "date": Date() as AnyObject]
				UserDefaults.standard.set(selectedPostLink, forKey: "selectedPostLink")
				UserDefaults.standard.synchronize()

				return
		}

		if previouslink != link {
			let selectedPostLink: [String: AnyObject] = ["link": link as AnyObject, "date": Date() as AnyObject]
			UserDefaults.standard.set(selectedPostLink, forKey: "selectedPostLink")
			UserDefaults.standard.synchronize()
		}
	}

    @objc func onReloadData(_ notification: Notification) {
        self.tableView.reloadData()
    }
}

// MARK: - Peek&Pop -

extension PostsMasterViewController {

	fileprivate func processOption() {
		comeFrom3DTouch = true

        if status == .lastOpenedPost ||
			viewDidAppear {
			if Settings().isPad {
				processTabletSelection()
			} else {
				processPhoneSelection()
			}
		}
	}

	@objc func onShortcutActionLastPost(_ notification: Notification) {
        status = .lastOpenedPost
        shortcutStatus = .lastOpenedPost
        processOption()
	}

	@objc func onShortcutActionRecentPost(_ notification: Notification) {
        status = .recentPost
        shortcutStatus = .recentPost
		processOption()
	}

}

// MARK: - Common Methods -

func prepareDetailController(_ controller: PostsDetailViewController, using links: [PostData], compare link: String?) {
	controller.navigationItem.leftItemsSupplementBackButton = true

	controller.selectedIndex = links.firstIndex(where: { $0.link == link }) ?? 0
	controller.links = links
	controller.createWebViewController = createWebViewController
}

func createWebViewController(post: PostData) -> WebViewController? {
	let storyboard = UIStoryboard(name: "WebView", bundle: nil)
	guard let controller = storyboard.instantiateViewController(withIdentifier: "PostDetail") as? WebViewController else {
		return nil
	}
	controller.post = post
	return controller
}

func showDetailController(with link: String) {
    guard let rootViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.last?.rootViewController else {
        logE("Failed to load RootViewController")
        return
    }

    logD("rootViewController: \(rootViewController)")

    CoreDataStack.shared.links { links in
        guard let tabController = rootViewController as? UITabBarController else {
            logE("Failed to load UITabBarController")
            open(link: link, mainController: rootViewController)
            return
        }

        // Check if URL exist
        if links.firstIndex(where: { $0.link == link }) != nil {
            logD("tabController.selectedIndex: \(tabController.selectedIndex)")

            // Force first tab to prevent losing of reference
            tabController.selectedIndex = (UIApplication.shared.delegate as? AppDelegate)?.isMMLive ?? false ? 1 : 0

            logD("tabController.selectedViewController: \(tabController.selectedViewController.debugDescription)")

            if let splitVC = tabController.selectedViewController as? UISplitViewController,
               let navVC = splitVC.children[Settings().isPhone ? 0 : 1] as? UINavigationController {

                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                guard let controller = storyboard.instantiateViewController(withIdentifier: "detailController") as? PostsDetailViewController else {
                    logE("Failed to load PostsDetailViewController")
                    return
                }

                prepareDetailController(controller, using: links, compare: link)

                if Settings().isPhone {
                    splitVC.showDetailViewController(controller, sender: nil)
                } else {
                    // Need to add the controller to navigation to see the nav bar
                    navVC.viewControllers = [controller]
                    splitVC.showDetailViewController(navVC, sender: nil)

                    delay(0.4) {
                        NotificationCenter.default.post(name: .updateSelectedPost, object: link)
                    }
                }
            } else {
                logE("Failed to load UISplitViewController or UINavigationController")
                open(link: link, mainController: rootViewController)
            }
        } else {
            logE("Failed to load database URL")
            open(link: link, mainController: tabController)
        }

        (UIApplication.shared.delegate as? AppDelegate)?.widgetSpotlightPost = nil
    }

    func open(link: String, mainController: UIViewController?) {
        (UIApplication.shared.delegate as? AppDelegate)?.widgetSpotlightPost = nil

        // Open single view
        let storyboard = UIStoryboard(name: "WebView", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "PostDetail") as? WebViewController,
              let url = URL(string: link) else {
            return
        }
        let navVC = UINavigationController(rootViewController: controller)

        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance

        controller.postURL = url
        navVC.modalPresentationStyle = .automatic
        mainController?.show(navVC, sender: nil)
    }
}

func delay(_ delay: Double, closure: @escaping () -> Void) {
    let when = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
}

// MARK: - Easter Egg -

extension PostsMasterViewController {
    @IBAction private func easterEgg(_ sender: Any) {
        let api = API().getMMURL()
        let urls = ["\(api)sobre/",
                    "\(api)usados-apple/",
                    "\(api)equipe/",
                    "\(api)patroes/",
                    "\(api)tour/"
        ]
        guard let url = URL(string: urls[Int.random(in: 0..<urls.count)]) else {
            return
        }
        openInSafari(url)
    }

    func openInSafari(_ url: URL) {
        if url.scheme?.lowercased().contains("http") ?? false {
            let safari = SFSafariViewController(url: url)
            safari.setup()
            self.present(safari, animated: true, completion: nil)
        }
    }
}

// MARK: - Favorite Action methods -

extension PostsMasterViewController {
    @IBAction private func showHideFilter(_ sender: Any) {
        if fetchController?.fetchRequest.predicate == nil {
            filter.image = UIImage(named: "line.3.horizontal.decrease.circle.fill")
            filter.accessibilityLabel = "Mostrat posts."
            showFilter()
        } else {
            filter.image = UIImage(named: "line.3.horizontal.decrease.circle")
            filter.accessibilityLabel = "Mostrar opções de filtro."
            showAllPosts()
        }
    }

    fileprivate func showFilter() {
        let alertController = UIAlertController(title: "Filtros", message: "Escolha uma opção", preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "Mostrar favoritos", style: .default) { _ in
            self.showFavorites()
        })

        alertController.addAction(UIAlertAction(title: "Mostrar posts não lidos", style: .default) { _ in
            self.showNotRead()
        })

        alertController.addAction(UIAlertAction(title: "Mostrar destaques", style: .default) { _ in
            self.showDestaques()
        })

        alertController.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in
            self.dismiss(animated: true)
        })

        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = filter
        }

        self.present(alertController, animated: true)
    }

    fileprivate func showFavorites() {
        fetchController?.fetchRequest.predicate = favoritePredicate

        self.navigationItem.titleView = nil
        self.navigationItem.title = "Favoritos"

        reloadController(.transitionFlipFromRight)
    }

    fileprivate func showNotRead() {
        fetchController?.fetchRequest.predicate = notReadPredicate

        self.navigationItem.titleView = nil
        self.navigationItem.title = "Não Lidos"

        reloadController(.transitionFlipFromRight)
    }

    fileprivate func showDestaques() {
        fetchController?.fetchRequest.predicate = destaquePredicate

        self.navigationItem.titleView = nil
        self.navigationItem.title = "Destaques"

        reloadController(.transitionFlipFromRight)
    }

    fileprivate func showAllPosts() {
        fetchController?.fetchRequest.predicate = nil

        self.navigationItem.titleView = logoView
        self.navigationItem.title = nil

        reloadController(.transitionFlipFromLeft)
    }

    fileprivate func reloadController(_ direction: UIView.AnimationOptions) {
        fetchController?.reloadData()
        UIView.transition(with: tableView,
                          duration: 0.4,
                          options: direction,
                          animations: {
            self.tableView.reloadData()
        })
    }
}

// MARK: - Search Action methods -

extension PostsMasterViewController {
    @IBAction private func search(_ sender: Any) {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        resultsTableController?.showTyping()

        delay(0.01) {
            self.searchController?.searchBar.becomeFirstResponder()
        }
    }

	fileprivate func searchPosts(_ text: String) {
		var items: [CSSearchableItem] = []
		posts = []
        API().searchPosts(text) { post in
            guard let post = post else {
                self.posts.removeDuplicates()
                self.posts.sort(by: {
                    $0.pubDate.toDate().sortedDate().compare($1.pubDate.toDate().sortedDate()) == .orderedDescending
                })

                DispatchQueue.main.async {
                    CSSearchableIndex.default().indexSearchableItems(items)
                    self.resultsTableController?.posts = self.posts
                }
                return
            }
            self.posts.append(post)
            CoreDataStack.shared.save(post: post)
            items.append(self.createSearchableItem(post))
        }
	}

	fileprivate func searchPosts(category: String) {
        showSpin()

		var items: [CSSearchableItem] = []
		let processResponse: (XMLPost?) -> Void = { post in
			guard let post = post else {
				DispatchQueue.main.async {
                    self.hideSpin()

					CSSearchableIndex.default().indexSearchableItems(items)

					self.fetchController?.fetchRequest.predicate = NSPredicate(format: "categorias contains[cd] %@", category)
					self.reloadController(.transitionFlipFromRight)
				}
				return
			}
			CoreDataStack.shared.save(post: post)
			items.append(self.createSearchableItem(post))
		}

		API().searchPosts(category: category, processResponse)
	}
}
