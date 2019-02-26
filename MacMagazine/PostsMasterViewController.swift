//
//  PostsMasterViewController.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 18/08/17.
//  Copyright © 2017 MacMagazine. All rights reserved.
//

import CoreData
import Kingfisher
import UIKit

class PostsMasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

	// MARK: - Properties -

	let managedObjectContext = DataController.sharedInstance.managedObjectContext
	var detailViewController: PostsDetailViewController?

	// MARK: - View Lifecycle -

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 133

		self.getPosts()
	}

	override func viewWillAppear(_ animated: Bool) {
		clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
		super.viewWillAppear(animated)

		if (self.refreshControl?.isRefreshing)! {
			self.tableView.setContentOffset(CGPoint(x: 0, y: -(self.refreshControl?.frame.size.height)!), animated: true)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Segues -

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
		    if let indexPath = tableView.indexPathForSelectedRow {
		        let object = Posts.getPost(atIndex: indexPath.row)
		        let controller = (segue.destination as! UINavigationController).topViewController as! PostsDetailViewController
		        controller.detailItem = object
		        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
		        controller.navigationItem.leftItemsSupplementBackButton = true
		    }
		}
	}

	// MARK: - Fetched Results Controller Methods -

	lazy var fetchedResultsController: NSFetchedResultsController<Posts> = {
		let fetchRequest: NSFetchRequest<Posts> = Posts.fetchRequest()

		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]

		if self.tabBarController!.selectedIndex == 0 {
			fetchRequest.predicate = NSPredicate(format: "NOT categorias CONTAINS[cd] %@", String(Categoria.podcast.rawValue))
		} else if self.tabBarController!.selectedIndex == 1 {
			fetchRequest.predicate = NSPredicate(format: "categorias CONTAINS[cd] %@", String(Categoria.podcast.rawValue))
		}

		// Initialize Fetched Results Controller
		let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		controller.delegate = self

		do {
			try controller.performFetch()
		} catch {
			let fetchError = error as NSError
			print("\(fetchError), \(fetchError.userInfo)")
		}

		return controller
	}()

	// MARK: - Fetched Results Controller Delegate Methods -

	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

		switch type {
		case .insert:
			if let indexPath = newIndexPath {
				tableView.insertRows(at: [indexPath], with: .fade)
			}
		case .delete:
			if let indexPath = indexPath {
				tableView.deleteRows(at: [indexPath], with: .fade)
			}
		case .update:
			if let indexPath = indexPath {
				if let cell = tableView.cellForRow(at: indexPath) as? PostCell {
					configure(cell: cell, atIndexPath: indexPath)
				}
			}
		case .move:
			if let indexPath = indexPath {
				tableView.deleteRows(at: [indexPath], with: .fade)
			}

			if let newIndexPath = newIndexPath {
				tableView.insertRows(at: [newIndexPath], with: .fade)
			}
		}
	}

	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.endUpdates()
	}

	// MARK: - Table View -

	override func numberOfSections(in tableView: UITableView) -> Int {
		if let sections = self.fetchedResultsController.sections {
			return sections.count
		}
		return 0
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let sections = self.fetchedResultsController.sections {
			let sectionInfo = sections[section]
			return sectionInfo.numberOfObjects
		}
		return 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let object = fetchedResultsController.object(at: indexPath)

		let identifier = (object.categorias.contains(String(Categoria.destaque.rawValue)) ? "featuredCell" : "normalCell")
		guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? PostCell else {
            fatalError("Unexpected Index Path")
        }

		let bgColorView = UIView()
		bgColorView.backgroundColor = UIColor(hex: "008aca", alpha: 0.3)
		cell.selectedBackgroundView = bgColorView

		configure(cell: cell, atIndexPath: indexPath)

        return cell
	}

	func configure(cell: PostCell, atIndexPath: IndexPath) {
		let object = fetchedResultsController.object(at: atIndexPath)

		cell.headlineLabel!.text = object.title

		if object.categorias.contains(String(Categoria.destaque.rawValue)) == false {
			if cell.subheadlineLabel != nil {
				cell.subheadlineLabel!.text = object.excerpt
			}
		}

		// Lazy load of image from Marvel server
		let defaultImage = UIImage(named: "image_Logo")

		if let url = object.artworkURL {
			cell.thumbnailImageView.kf.indicatorType = .activity
			cell.thumbnailImageView.kf.setImage(with: URL(string: url), placeholder: defaultImage)
		} else {

			Network.getImageURL(host: Site.artworkURL.withParameter(nil), query: "\(object.artwork)") {
				(result: String?) in

				if result != nil {
					DispatchQueue.main.async {
						object.artworkURL = result!
						cell.thumbnailImageView.kf.indicatorType = .activity
						cell.thumbnailImageView.kf.setImage(with: URL(string: object.artworkURL!), placeholder: defaultImage)
					}
				}
			}
		}
	}

	// MARK: - View Methods -

	@IBAction private func getPosts() {

		self.refreshControl?.beginRefreshing()

		let pages = (Posts.getNumberOfPosts() / 20) + 1

		let query = "\(Site.perPage.withParameter(20))&\(Site.page.withParameter(pages))"
		Network.getPosts(host: Site.posts.withParameter(nil), query: query) { () in

			DispatchQueue.main.async {
				self.refreshControl?.endRefreshing()
				// Execute the fetch to display the data
				do {
					try self.fetchedResultsController.performFetch()
				} catch {
					print("An error occurred")
				}
			}
		}
	}
}
