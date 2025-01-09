import SwiftUI

public var logo: Image { Image("logo", bundle: .module) }

public enum APIParams {
	// Disqus
	public static let disqus = "disqus.com"

	// Wordpress
	public static let mainDomain = "macmagazine.com.br"
	public static let mainURL = "https://\(mainDomain)/"

	public static let patraoLoginUrl = "\(mainURL)loginpatrao"
	public static let patraoSuccessUrl = "\(mainURL)wp-admin/profile.php"

	public static let privacyUrl = "\(mainURL)politica-privacidade/"
	public static let termsUrl = "\(mainURL)termos-de-uso/"

	public static let feed = "/feed/"
	public static let paged = "paged"
	public static let cat = "cat"
	public static let tag = "tag"
	public static let search = "s"

	public static let mmlive = "mmlive.json"
}
