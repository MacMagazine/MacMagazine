//
//  VideosCollectionViewCell.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 12/04/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import Kingfisher
import UIKit

class VideosCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak private var thumbnailImageView: UIImageView!
	@IBOutlet weak private var headlineLabel: UILabel!
	@IBOutlet weak private var subheadlineLabel: UILabel!

	@IBOutlet weak private var favorite: UIButton!

	func configureVideo(with object: Video) {
		headlineLabel?.text = object.title
		subheadlineLabel?.text = object.pubDate?.watchDate()

		favorite.isSelected = object.favorite

		guard let artworkURL = object.artworkURL else {
			return
		}
		thumbnailImageView.kf.indicatorType = .activity
		thumbnailImageView.kf.setImage(with: URL(string: artworkURL), placeholder: UIImage(named: "image_Logo"))
	}

	// MARK: - Actions methods -

	@IBAction private func share(_ sender: Any) {
	}

	@IBAction private func favorite(_ sender: Any) {
	}

}
