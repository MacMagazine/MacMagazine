import Combine
import CoreData
import CoreLibrary
import Foundation
import YouTubeLibrary

public class VideosViewModel: ObservableObject {
	@Published public var fullScreen: Bool = false
	@Published public var options: Options = .home
	@Published var status: Status = .loading

	enum Status: Equatable {
		case loading
		case done
		case error(reason: String)

		var reason: String? {
			switch self {
			case .error(let reason):
				return reason
			default:
				return nil
			}
		}
	}

	public enum Options: Equatable {
		case all
		case home
		case favorite
		case search(text: String)
	}

	public let youtube: YouTubeAPI
	public let context: NSManagedObjectContext

	let credentials = YouTubeCredentials(salt: "AppDelegateNSObject",
										 keys: [
											[0, 57, 10, 37, 54, 21, 36, 2, 13, 46, 93, 125, 43, 45, 86, 5, 55, 5, 57, 59, 9, 58, 118, 32, 5, 12, 4, 51, 36, 52, 36, 60, 62, 9, 91, 36, 54, 30, 50]
										 ],
										 playlistId: [20, 37, 70, 30, 44, 1, 41, 16, 8, 61, 4, 24, 1, 22, 43, 45, 28, 0, 5, 41, 69, 25, 8, 36],
										 channelId: [20, 51, 70, 30, 44, 1, 41, 16, 8, 61, 4, 24, 1, 22, 43, 45, 28, 0, 5, 41, 69, 25, 8, 36])

	public init(mock: [String: String]? = nil) {
		youtube = YouTubeAPI(credentials: credentials,
							 mock: mock,
                             containerIdentifier: "iCloud.com.brit.beta.macmagazine",
							 inMemory: mock != nil)
		context = youtube.mainContext
	}

	@MainActor
	public func save() {
		try? context.save()
	}
}
