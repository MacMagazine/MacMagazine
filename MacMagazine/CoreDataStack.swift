//
//  CoreDataStack.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 23/03/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import CoreData
import Foundation

class CoreDataStack {

	// MARK: - Singleton -

	static let shared = CoreDataStack()

	// MARK: - Initialization -

	private init() {}

	let postEntityName = "Post"
	let videoEntityName = "Video"

	lazy var persistentContainer: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "macmagazine")
		container.loadPersistentStores { _, error in
			guard let error = error as NSError? else {
				return
			}
			fatalError("Unresolved error: \(error), \(error.userInfo)")
		}

		return container
	}()

	var viewContext: NSManagedObjectContext {
		return persistentContainer.viewContext
	}

	// MARK: - Context Methods -

	func save() {
		save(nil)
	}

	func save(_ context: NSManagedObjectContext?) {
		let desiredContext = context ?? viewContext
		if desiredContext.hasChanges {
			do {
				try desiredContext.save()
			} catch {
				logE(error.localizedDescription)
			}
		}
	}

	func flush() {
		flush(entityName: postEntityName)
		flush(entityName: videoEntityName)
	}

	func flush(entityName: String) {
		let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
		let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
		deleteRequest.resultType = .resultTypeObjectIDs

		do {
			let result = try viewContext.execute(deleteRequest) as? NSBatchDeleteResult
			guard let objectIDs = result?.result as? [NSManagedObjectID] else {
				return
			}

			// Updates the main context
			NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [self.viewContext])

		} catch {
			fatalError("Failed to execute request: \(error)")
		}
	}

	// MARK: - Post Video -

	func getPostsForWatch(completion: @escaping ([PostData]) -> Void) {
		let request = NSFetchRequest<NSFetchRequestResult>(entityName: postEntityName)
		request.sortDescriptors = [NSSortDescriptor(key: "pubDate", ascending: false)]
		request.fetchLimit = 10

		// Creates `asynchronousFetchRequest` with the fetch request and the completion closure
		let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: request) { asynchronousFetchResult in
			guard let result = asynchronousFetchResult.finalResult as? [Post] else {
				return
			}
			let watchPosts = result.map {
				PostData(title: $0.title, link: $0.link, thumbnail: $0.artworkURL, favorito: false, pubDate: $0.pubDate?.watchDate(), excerpt: $0.excerpt)
			}
			completion(watchPosts)
		}

		do {
			try viewContext.execute(asynchronousFetchRequest)
		} catch let error {
			logE(error.localizedDescription)
		}
	}

	func get(post link: String, completion: @escaping ([Post]) -> Void) {
		let request = NSFetchRequest<NSFetchRequestResult>(entityName: postEntityName)
		request.predicate = NSPredicate(format: "link == %@", link)

		// Creates `asynchronousFetchRequest` with the fetch request and the completion closure
		let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: request) { asynchronousFetchResult in
			guard let result = asynchronousFetchResult.finalResult as? [Post] else {
				completion([])
				return
			}
			completion(result)
		}

		do {
			try viewContext.execute(asynchronousFetchRequest)
		} catch let error {
			logE(error.localizedDescription)
		}
	}

	func save(post: XMLPost) {
		// Cannot duplicate links
		get(post: post.link) { items in
			if items.isEmpty {
				self.insert(post: post)
			} else {
				self.update(post: items[0], with: post)
			}
			self.save()
		}
	}

	func insert(post: XMLPost) {
		let newItem = Post(context: viewContext)
		newItem.title = post.title
		newItem.link = post.link
		newItem.excerpt = post.excerpt
		newItem.artworkURL = post.artworkURL.escape()
		newItem.categorias = post.getCategorias()
		newItem.pubDate = post.pubDate.toDate()
		newItem.podcast = post.podcast
		newItem.podcastURL = post.podcastURL
		newItem.duration = post.duration
		newItem.headerDate = post.pubDate.toDate().sortedDate()
		newItem.favorite = false
        newItem.podcastFrame = post.podcastFrame
	}

	func update(post: Post, with item: XMLPost) {
		post.title = item.title
		post.link = item.link
		post.excerpt = item.excerpt
		post.artworkURL = item.artworkURL.escape()
		post.categorias = item.getCategorias()
		post.pubDate = item.pubDate.toDate()
		post.podcast = item.podcast
		post.podcastURL = item.podcastURL
		post.duration = item.duration
		post.headerDate = item.pubDate.toDate().sortedDate()
        post.podcastFrame = item.podcastFrame
	}

	// MARK: - Entity Video -

	func get(video videoId: String, completion: @escaping ([Video]) -> Void) {
		let request = NSFetchRequest<NSFetchRequestResult>(entityName: videoEntityName)
		request.predicate = NSPredicate(format: "videoId == %@", videoId)

		// Creates `asynchronousFetchRequest` with the fetch request and the completion closure
		let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: request) { asynchronousFetchResult in
			guard let result = asynchronousFetchResult.finalResult as? [Video] else {
				completion([])
				return
			}
			completion(result)
		}

		do {
			try viewContext.execute(asynchronousFetchRequest)
		} catch let error {
			logE(error.localizedDescription)
		}
	}

	struct JSONVideo {
		var title: String = ""
		var videoId: String = ""
		var pubDate: String = ""
		var artworkURL: String = ""
		var views: String = ""
		var likes: String = ""
	}

	func save(playlist: YouTube, statistics: [Item]) {
		// Cannot duplicate videos
		guard let videos = playlist.items else {
			return
		}
		Settings().setVideoNextToken(playlist.nextPageToken)

		let mappedVideos: [JSONVideo] = videos.compactMap {
			guard let title = $0.snippet?.title,
				let videoId = $0.snippet?.resourceId?.videoId
				else {
					return nil
			}

			var likes = ""
			var views = ""
			let stat = statistics.filter {
				$0.id == videoId
			}
			if !stat.isEmpty {
				views = stat[0].statistics?.viewCount ?? ""
				likes = stat[0].statistics?.likeCount ?? ""
			}

			return JSONVideo(title: title, videoId: videoId, pubDate: $0.snippet?.publishedAt ?? "", artworkURL: $0.snippet?.thumbnails?.maxres?.url ?? "", views: views, likes: likes)
		}

		mappedVideos.forEach { video in
			get(video: video.videoId) { items in
				if items.isEmpty {
					self.insert(video: video)
				} else {
					self.update(video: items[0], with: video)
				}
				self.save()
			}
		}
	}

	func insert(video: JSONVideo) {
		let newItem = Video(context: viewContext)
		newItem.favorite = false
		newItem.title = video.title
		newItem.artworkURL = video.artworkURL.escape()
		newItem.pubDate = video.pubDate.toDate("yyyy-MM-dd'T'HH:mm:ss.000'Z'")
		newItem.videoId = video.videoId
		newItem.likes = video.likes
		newItem.views = video.views
	}

	func update(video: Video, with item: JSONVideo) {
		video.title = item.title
		video.artworkURL = item.artworkURL.escape()
		video.pubDate = item.pubDate.toDate("yyyy-MM-dd'T'HH:mm:ss.000'Z'")
		video.videoId = item.videoId
		video.likes = item.likes
		video.views = item.views
	}

}
