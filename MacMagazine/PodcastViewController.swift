//
//  PodcastViewController.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 03/04/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import UIKit

class PodcastViewController: UIViewController {

	// MARK: - Properties -

	@IBOutlet private weak var logoView: UIView!
    @IBOutlet private weak var playerHeight: NSLayoutConstraint!
	@IBOutlet private weak var favorite: UIBarButtonItem!
    @IBOutlet private weak var spin: UIActivityIndicatorView!

	var searchController: UISearchController?

    // MARK: - View lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.titleView = logoView
		navigationItem.title = nil
        navigationItem.preferredSearchBarPlacement = .stacked

        playerHeight.constant = 0.0

		guard let viewController = self.children[0] as? PodcastMasterViewController else {
			return
		}
		viewController.play = play
        viewController.showSpin = showSpin
        viewController.hideSpin = hideSpin

		viewController.resultsTableController = ResultsViewController()
		viewController.resultsTableController?.delegate = viewController
		viewController.resultsTableController?.isPodcast = true

		searchController = UISearchController(searchResultsController: viewController.resultsTableController)
		searchController?.searchBar.autocapitalizationType = .none
		searchController?.searchBar.delegate = self
		searchController?.searchBar.placeholder = "Buscar nos podcasts..."
        searchController?.searchBar.returnKeyType = .search

        favorite.accessibilityLabel = "Listar podcasts favoritos."
    }

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)

		coordinator.animate(alongsideTransition: { _ in
			self.reloadData()
		}, completion: { _ in
			self.reloadData()
		})
	}

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        delegate.supportedInterfaceOrientation = Settings().orientations
    }

    fileprivate func reloadData() {
		if self.tabBarController?.selectedIndex == 1 {
            guard let viewController = self.children[0] as? PodcastMasterViewController else {
                return
            }
			viewController.tableView.reloadData()
			viewController.resultsTableController?.tableView.reloadData()
		}
	}

	// MARK: - Actions -

	@IBAction private func search(_ sender: Any) {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        delay(0.01) {
            self.searchController?.searchBar.becomeFirstResponder()
        }
	}

	@IBAction private func showFavorites(_ sender: Any) {
        guard let viewController = self.children[0] as? PodcastMasterViewController else {
            return
        }
        viewController.showFavoritesAction()

		if viewController.showFavorites {
			self.navigationItem.titleView = nil
			self.navigationItem.title = "Favoritos"
			favorite.image = UIImage(systemName: "star.fill")
            favorite.accessibilityLabel = "Listar podcasts."
		} else {
			self.navigationItem.titleView = logoView
			self.navigationItem.title = nil
			favorite.image = UIImage(systemName: "star")
            favorite.accessibilityLabel = "Listar podcasts favoritos."
        }
    }

    // MARK: - Methods -

    fileprivate func showWebView(_ show: Bool) {
        playerHeight.constant = show ? 166.0 : 0.0
        UIView.animate(withDuration: 0.4) {
            self.view.layoutIfNeeded()
        }
    }

    fileprivate func play(_ podcast: Podcast?) {
        guard let viewController = self.children[1] as? PlayerViewController else {
            return
        }
		viewController.show = showWebView
        viewController.podcast = podcast
    }

}

// MARK: - UISearchBarDelegate -

extension PodcastViewController: UISearchBarDelegate {
	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		guard let viewController = self.children[0] as? PodcastMasterViewController else {
			return
		}
		viewController.resultsTableController?.showTyping()
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		guard let text = searchBar.text,
			let viewController = self.children[0] as? PodcastMasterViewController
			else {
				return
		}
		searchBar.resignFirstResponder()
		viewController.resultsTableController?.posts = []
		viewController.resultsTableController?.showSpin()
		viewController.searchPodcasts(text)
	}

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
		navigationItem.searchController = nil
	}
}

// MARK: - Spin -

extension PodcastViewController {
    func showSpin() {
        navigationItem.titleView = spin
    }

    func hideSpin() {
        navigationItem.titleView = logoView
    }
}
