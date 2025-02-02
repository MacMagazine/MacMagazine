//
//  XMLParser.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 15/04/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import UIKit

struct XMLPost: Hashable {
	var title: String = ""
	var link: String = ""
	var pubDate: String = ""
	var categories: [String] = []
	var excerpt: String = ""
	var artworkURL: String = ""
	var podcastURL: String = ""
	var podcast: String = ""
	var duration: String = ""
	var podcastFrame: String = ""
	var favorite: Bool = false
	var postId: String = ""
	var shortURL: String = ""
	var playable: Bool = false
	var fullContent: String = ""

	fileprivate func decodeHTMLString(string: String) -> String {
		guard let encodedData = string.data(using: String.Encoding.utf8) else {
			return ""
		}
		do {
			return try NSAttributedString(data: encodedData, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil).string
		} catch {
			return error.localizedDescription
		}
	}

	func getCategorias() -> String {
		return self.categories.joined(separator: ",")
	}
}

class APIXMLParser: NSObject, XMLParserDelegate {

	// MARK: - Properties -

	var onCompletion: ((XMLPost?) -> Void)?
	var currentPost = XMLPost()
	var processItem = false
	var value = ""
	var attributes: [String: String]?
	var numberOfPosts = -1
	var parsedPosts = 0

	var isWatchPosts = false

	// MARK: - Init -

	init(onCompletion: ((XMLPost?) -> Void)?, numberOfPosts: Int) {
		self.onCompletion = onCompletion
		self.numberOfPosts = numberOfPosts
	}

	// MARK: - Parse Delegate -

	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {

		value = ""
		if elementName == "item" {
			processItem = true
			currentPost = XMLPost()
		}
		if elementName == "media:content" {
			attributes = attributeDict
		}
		if elementName == "enclosure" {
			attributes = attributeDict
		}
	}

	func parser(_ parser: XMLParser, foundCharacters string: String) {
		if processItem {
			value += string
		}
	}

	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		if processItem {
			value = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            // swiftlint:disable switch_case_alignment
			switch elementName {
			case "post-id":
				currentPost.postId = value
			case "title":
				currentPost.title = value
			case "link":
				currentPost.link = value
			case "pubDate":
				currentPost.pubDate = value
			case "category":
				if currentPost.categories.isEmpty {
					currentPost.categories = []
				}
				currentPost.categories.append(value)
			case "description":
				currentPost.excerpt = value
            case "media:content":
                guard let url = attributes?["url"] else {
                    return
                }
                #if WIDGET
                guard attributes?["image_size"] != nil else {
                    return
                }
                currentPost.artworkURL = url
                #else
                currentPost.artworkURL = url
                #endif
			case "enclosure":
				guard let url = attributes?["url"] else {
					return
				}
				currentPost.podcastURL = url
			case "itunes:subtitle":
				currentPost.podcast = value
			case "itunes:duration":
				currentPost.duration = value
			case "rawvoice:embed":
				currentPost.podcastFrame = value
			case "item":
				onCompletion?(currentPost)
				parsedPosts += 1
				processItem = false
				if numberOfPosts > 0 &&
					parsedPosts >= numberOfPosts {
					parser.abortParsing()
				}
			case "guid":
				currentPost.shortURL = value
			case "content:encoded":
				currentPost.playable = value.contains("youtube.com/embed/")
				if isWatchPosts {
					currentPost.fullContent = value.toHtmlDecoded()
						.replacingOccurrences(of: "\n\n", with: "\n")
						.replacingOccurrences(of: "\n\n", with: "\n")
						.replacingOccurrences(of: "\n\n", with: "\n")
						.replacingOccurrences(of: "\n\n", with: "\n")
						.replacingOccurrences(of: "\n\n", with: "\n")
				}
			default:
				return
			}
            // swiftlint:enable switch_case_alignment
		}
	}

	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
		onCompletion?(nil)
	}

	func parserDidEndDocument(_ parser: XMLParser) {
		onCompletion?(nil)
	}

}
