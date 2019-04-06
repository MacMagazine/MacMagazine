//
//  ResultsViewController.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 10/03/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import UIKit

protocol ResultsViewControllerDelegate: AnyObject {
	func didSelectResultRowAt(indexPath: IndexPath)
	func configureResult(cell: PostCell, atIndexPath: IndexPath)
}

extension ResultsViewControllerDelegate {
	func didSelectResultRowAt(indexPath: IndexPath) {}
}

class ResultsViewController: UITableViewController {

	// MARK: - Properties -

	weak var delegate: ResultsViewControllerDelegate?

	var isPodcast: Bool = false {
		didSet {
			tableView.register(UINib(nibName: isPodcast ? "PodcastCell" : "FeaturedCell", bundle: nil), forCellReuseIdentifier: "featuredCell")
		}
	}
	var posts: [XMLPost] = []
	var isSearching = false {
		didSet {
			tableView.reloadData()
		}
	}

	// MARK: - View lifecycle -

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.register(UINib(nibName: "NormalCell", bundle: nil), forCellReuseIdentifier: "normalCell")
		tableView.register(UINib(nibName: isPodcast ? "PodcastCell" : "FeaturedCell", bundle: nil), forCellReuseIdentifier: "featuredCell")

		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 133
	}

	// MARK: - TableView methods -

	override func numberOfSections(in tableView: UITableView) -> Int {
		if posts.isEmpty {
			tableView.separatorStyle = .none
			if isSearching {
				let spin = UIActivityIndicatorView(style: .whiteLarge)
				spin.startAnimating()
				tableView.backgroundView = spin
			} else {
				let notFound = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
				notFound.text = "Nenhum resultado encontrado"
				notFound.textColor = Settings().isDarkMode() ? .white : .black
				notFound.textAlignment = .center
				tableView.backgroundView = notFound
				tableView.separatorStyle = .none
			}
		} else {
			tableView.backgroundView = nil
			tableView.separatorStyle = .singleLine
		}

		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return posts.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var identifier = "normalCell"
		if posts[indexPath.row].categories.contains("Destaques") {
			identifier = "featuredCell"
		}

		guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? PostCell else {
			fatalError("Unexpected Index Path")
		}
		delegate?.configureResult(cell: cell, atIndexPath: indexPath)
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		delegate?.didSelectResultRowAt(indexPath: indexPath)
	}

}
