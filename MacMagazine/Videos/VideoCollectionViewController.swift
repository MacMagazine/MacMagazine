//
//  VideoCollectionViewController.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 12/04/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import CoreData
import UIKit

class VideoCollectionViewController: UICollectionViewController {

	// MARK: - Properties -

	@IBOutlet private weak var logoView: UIView!
	@IBOutlet private weak var favorite: UIBarButtonItem!
	@IBOutlet private weak var spin: UIActivityIndicatorView!

	fileprivate let managedObjectContext = CoreDataStack.shared.viewContext

	fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Video> = {
		let fetchRequest: NSFetchRequest<Video> = Video.fetchRequest()

		let sortDescriptor = NSSortDescriptor(key: "pubDate", ascending: false)
		fetchRequest.sortDescriptors = [sortDescriptor]

		// Initialize Fetched Results Controller
		let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		controller.delegate = self

		do {
			try controller.performFetch()
		} catch {
			let fetchError = error as NSError
			print("\(fetchError), \(fetchError.userInfo)")
		}

		return controller
	}()

	// MARK: - View lifecycle -

	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		self.navigationItem.titleView = logoView
		self.navigationItem.title = nil
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if !hasData() {
			getVideos()
		}
	}

    /*
    // MARK: - Navigation -

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

	// MARK: - Local methods -

	fileprivate func hasData() -> Bool {
		return !(fetchedResultsController.fetchedObjects?.isEmpty ?? true)
			//&& !(self.refreshControl?.isRefreshing ?? true)
	}

	fileprivate func getVideos() {
		self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: spin)]

		API().getVideos { videos in
			guard let videos = videos else {
				return
			}
			DispatchQueue.main.async {
				self.navigationItem.rightBarButtonItems = nil
				CoreDataStack.shared.save(playlist: videos)
			}
		}
	}

}

// MARK: - UICollectionViewDataSource -

extension VideoCollectionViewController {

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		guard let sections = fetchedResultsController.sections else {
			return 0
		}
		return sections.count
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard let sections = fetchedResultsController.sections else {
			return 0
		}
		let sectionInfo = sections[section]
		return sectionInfo.numberOfObjects
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "video", for: indexPath)

		// Configure the cell
		print(indexPath.item)
		return cell
	}

	// MARK: - UICollectionViewDelegate -

	override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return true
	}
}

// MARK: - FetchedResultsController Delegate -

extension VideoCollectionViewController: NSFetchedResultsControllerDelegate {

	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {}

	private func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {

		switch type {
		case .insert:
			self.collectionView?.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
		case .update:
			self.collectionView?.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
		case .delete:
			self.collectionView?.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
		case .move:
			break
		@unknown default:
			break
		}
	}

	private func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeObject anObject: Any, atIndexPath indexPath: IndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

		guard let newIndexPath = newIndexPath,
			let indexPath = indexPath
			else {
				return
		}

		switch type {
		case .insert:
			self.collectionView?.insertItems(at: [newIndexPath])
		case .update:
			self.collectionView?.reloadItems(at: [indexPath])
		case .delete:
			self.collectionView?.deleteItems(at: [indexPath])
		case .move:
			self.collectionView?.moveItem(at: indexPath, to: newIndexPath)
		@unknown default:
			break
		}
	}

	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		DispatchQueue.main.async {
			self.collectionView?.reloadData()
		}
	}

}
