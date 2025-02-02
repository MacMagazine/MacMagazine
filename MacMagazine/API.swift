//
//  API.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 27/02/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import UIKit
#if os(iOS)
import WebKit
#endif

struct Category: Codable {
    var title: String = ""
    var parent: String = ""
    var order: Int = 0
    var id: Int = 0
}

// MARK: - Extensions -

extension URL {

	func isPatrao() -> Bool {
		return isMMAddress() && self.absoluteString.contains("/wp-login.php") && self.absoluteString.contains("novologin")
	}

	func isMMPost() -> Bool {
		return isMMAddress() && self.absoluteString.contains("/post/")
	}

	func isMMAddress() -> Bool {
		return self.absoluteString.prefix(API.APIParams.mmURL.count) == API.APIParams.mmURL
	}

	func isAppStore() -> Bool {
		return self.absoluteString.contains("apps.apple.com") ||
		self.absoluteString.contains("itunes.apple.com")
	}

	func isYouTube() -> Bool {
		let youTubeURL = "https://www.youtube.com/"
		return self.absoluteString.prefix(youTubeURL.count) == youTubeURL
	}

	func isAppStoreBadge() -> Bool {
		return self.absoluteString.contains("badge_appstore") ||
		self.absoluteString.contains("badge_macappstore")
	}

	func appStoreId() -> String? {
		var id: String?
		let components = self.absoluteString.split(separator: "/")
		if let lastComponent = components.last {
			let splittedComponents = lastComponent.split(separator: "?")
			splittedComponents.forEach { component in
				if component.contains("id") {
					id = component.replacingOccurrences(of: "id", with: "")
				}
			}
		}
		return id
	}

	func videoId() -> String? {
		let queryItems = URLComponents(string: self.absoluteString)?.queryItems
		return queryItems?.first(where: { $0.name == "v" })?.value
	}
}

class API {

	// MARK: - Definitions -

    enum APIParams {
        // Disqus
		static let disqus = "disqus.com"

        // Wordpress
        static let domainMM = "macmagazine.com.br"
        static let mmDomain: String = {
            return domainMM
        }()

        static let mmURL = "https://\(mmDomain)/"
		static let feed = "\(mmURL)feed/"
        static let patrao = "\(mmURL)loginpatrao"
		static let paged = "paged="
		static let cat = "cat="
		static let posts = "\(cat)-101"
		static let podcast = "\(cat)101"
		static let search = "s="
        static let restAPI = "\(mmURL)wp-json/menus/v2/"
        static let categories = "categories"
		static let tag = "tag="

        static let mmlive = "mmlive.json"

		// YouTube
		static let salt = "AppDelegateNSObject"
		static let keyParam = "key="
		static let key: [UInt8] = [0, 57, 10, 37, 54, 21, 36, 2, 13, 46, 93, 125, 43, 45, 86, 5, 55, 5, 57, 59, 9, 58, 118, 32, 5, 12, 4, 51, 36, 52, 36, 60, 62, 9, 91, 36, 54, 30, 50]

		static let youtubeURL = "https://www.googleapis.com/youtube/v3"
		static let sort = "order=date"

		static let playlistItems = "\(youtubeURL)/playlistItems"
		static let playlistPart = "part=snippet,contentDetails"

		static let playlistIdParam = "playlistId="
		static let playlistId: [UInt8] = [20, 37, 70, 30, 44, 1, 41, 16, 8, 61, 4, 24, 1, 22, 43, 45, 28, 0, 5, 41, 69, 25, 8, 36]

		static let maxResults = "maxResults=15"
		static let pageToken = "pageToken="

		static let statistics = "\(youtubeURL)/videos"
		static let statisticsPart = "part=statistics,contentDetails"
		static let videoId = "id="

		static let videoSearch = "\(youtubeURL)/search"
		static let videoSearchPart = "part=snippet"
		static let videoQuery = "q="

		static let channel = "channelId="
		static let channelId: [UInt8] = [20, 51, 70, 30, 44, 1, 41, 16, 8, 61, 4, 24, 1, 22, 43, 45, 28, 0, 5, 41, 69, 25, 8, 36]
	}

	// MARK: - Properties -

    var onCompletion: ((XMLPost?) -> Void)?
	var numberOfPosts = -1
	var isWatchPosts = false

    #if os(iOS) && !WIDGET
	var onVideoCompletion: ((YouTube<String>?) -> Void)?
	var onVideoSearchCompletion: ((YouTube<ResourceId>?) -> Void)?
	#endif

    // MARK: - Public methods -

    func getMMURL() -> String {
        return APIParams.mmURL
    }

	func getComplications(_ completion: ((XMLPost?) -> Void)?) {
        numberOfPosts = 1
		getPosts(page: 0, completion)
	}

    func getPosts(page: Int = 0, _ completion: ((XMLPost?) -> Void)?) {
        #if WIDGET
        numberOfPosts = 3
        #endif
        onCompletion = completion
        let host = "\(APIParams.feed)?\(APIParams.paged)\(page)"
        executeGetContent(host)
    }

	func getWatchPosts(_ completion: ((XMLPost?) -> Void)?) {
		numberOfPosts = 10
		isWatchPosts = true
		getPosts(page: 0, completion)
	}

	func getPodcasts(page: Int = 1, _ completion: ((XMLPost?) -> Void)?) {
        onCompletion = completion
        let host = "\(APIParams.feed)?\(APIParams.podcast)&\(APIParams.paged)\(page)"
        executeGetContent(host)
    }

    func searchPosts(_ text: String, _ completion: ((XMLPost?) -> Void)?) {
        onCompletion = completion
        let host = "\(APIParams.feed)?\(APIParams.search)'\(text)'"
        executeGetContent(host)
    }

    func searchPosts(category: String, _ completion: ((XMLPost?) -> Void)?) {
        onCompletion = completion
		let host = "\(APIParams.feed)?\(APIParams.tag)'\(category.replacingOccurrences(of: " ", with: "-"))'"
        executeGetContent(host)
    }

	func searchPodcasts(_ text: String, _ completion: ((XMLPost?) -> Void)?) {
		onCompletion = completion
		let host = "\(APIParams.feed)?\(APIParams.podcast)&\(APIParams.search)'\(text)'"
		executeGetContent(host)
	}

    func getCategories(_ completion: (([Category]?) -> Void)?) {
        let host = "\(APIParams.restAPI)\(APIParams.categories)"

        guard let url = URL(string: "\(host.escape())") else {
            return
        }

		Network.get(url: url) { (result: Result<Data, RestAPIError>) in
			switch result {
			case .failure(_):
				completion?(nil)

			case .success(let response):
				let categories = self.decodeJSON(response)
				DispatchQueue.main.async {
					completion?(categories)
				}
			}
		}
    }

    // MARK: - Internal methods -

    fileprivate func decodeJSON(_ data: Data) -> [Category]? {
        let decoder = JSONDecoder()

        do {
            return try decoder.decode([Category].self, from: data)

        } catch {
            return nil
        }
    }

    fileprivate func executeGetContent(_ host: String) {
        Cookies().cleanCookies()

        guard let url = URL(string: "\(host.escape())") else {
            return
        }

        Network.get(url: url) { (result: Result<Data, RestAPIError>) in
			switch result {
			case .failure(_):
				self.onCompletion?(nil)

			case .success(let response):
				self.parse(response,
						   onCompletion: self.onCompletion,
						   numberOfPosts: self.numberOfPosts)
			}
        }
    }

}

extension API {
	func parse(_ data: Data, onCompletion: ((XMLPost?) -> Void)?, numberOfPosts: Int) {
		let parser = XMLParser(data: data)
		let apiParser = APIXMLParser(onCompletion: onCompletion, numberOfPosts: numberOfPosts)
		apiParser.isWatchPosts = isWatchPosts
		parser.delegate = apiParser
		parser.parse()
	}
}

struct MMLive: Codable {
    var inicio: Date
    var fim: Date
    var lastChecked: Date?
}

extension API {
    static func mmLiveMock(onCompletion: ((MMLive?) -> Void)?) {
        guard let path = Bundle(for: Self.self).path(forResource: "mmlive", ofType: "json"),
              let content = FileManager.default.contents(atPath: path) else {
            onCompletion?(nil)
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970

            let event = try decoder.decode(MMLive.self, from: content)

            DispatchQueue.main.async {
                onCompletion?(event)
            }
        } catch {
            onCompletion?(nil)
        }
    }

    static func mmLive(onCompletion: ((MMLive?) -> Void)?) {
        let host = "\(APIParams.mmURL)\(APIParams.mmlive)"

        guard let url = URL(string: "\(host.escape())") else {
            onCompletion?(nil)
            return
        }

        Network.get(url: url) { (result: Result<Data, RestAPIError>) in
            switch result {
			case .failure(_):
				onCompletion?(nil)

			case .success(let response):
				do {
					let decoder = JSONDecoder()
					decoder.dateDecodingStrategy = .secondsSince1970

					let event = try decoder.decode(MMLive.self, from: response)

					DispatchQueue.main.async {
						onCompletion?(event)
					}
				} catch {
					onCompletion?(nil)
				}
			}
        }
    }
}
