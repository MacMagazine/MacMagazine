//
//  ComplicationController.swift
//  MacMagazineWatch Extension
//
//  Created by Cassio Rossi on 08/04/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import ClockKit
import WatchKit

class ComplicationController: NSObject, CLKComplicationDataSource {

	// MARK: - Properties -

	struct Complication {
		var header: String?
		var line1: String?
		var line2: String?

		init(header: String?, line1: String?, line2: String) {
			self.header = header
			self.line1 = line1
			self.line2 = line2
		}
	}

    // MARK: - Timeline Configuration -

    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward])
    }

    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
		handler(Date())
    }

    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
		let currentDate = Date()
		let endDate = currentDate.addingTimeInterval(TimeInterval(1 * 60 * 60))
		handler(endDate)
	}

    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population -

    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
		API().getComplications { post in
			guard let post = post else {
				return
			}
			let entry = self.prepareEntry(with: post, for: complication)
			handler(entry)
		}
    }

    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
		handler(nil)
	}

    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
		handler(nil)
    }

    // MARK: - Placeholder Templates -

    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
		let message = Complication(header: "MacMagazine", line1: "Veja nossas últimas", line2: "publicações")
		let entry = createComplicationTemplate(for: complication, message: message)
		handler(entry)
	}

	// MARK: - Methods -

	func prepareEntry(with post: XMLPost, for complication: CLKComplication) -> CLKComplicationTimelineEntry? {
		let timeString = post.pubDate.toComplicationDate()
		var message = Complication(header: "\(timeString)", line1: post.title, line2: "")
		var texts = post.title.pairs
		if !texts.isEmpty {
			let line1 = texts.first
			texts.removeFirst()
			let line2 = texts.joined()
			message = Complication(header: "\(timeString)", line1: line1, line2: line2)
		}
		let entry = self.createTimeLineEntry(for: complication, message: message, date: post.pubDate.toDate())

		return entry
	}

	func createComplicationTemplate(for complication: CLKComplication, message: Complication) -> CLKComplicationTemplate? {

		if complication.family == .modularLarge {
            return CLKComplicationTemplateModularLargeStandardBody(headerTextProvider: CLKSimpleTextProvider(text: message.header ?? ""),
                                                                           body1TextProvider: CLKSimpleTextProvider(text: message.line1 ?? ""),
                                                                           body2TextProvider: CLKSimpleTextProvider(text: message.line2 ?? ""))

		} else if complication.family == .utilitarianLarge {
            return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: CLKSimpleTextProvider(text: message.line1 ?? ""))

		} else if complication.family == .graphicRectangular {
            return CLKComplicationTemplateGraphicRectangularStandardBody(headerTextProvider: CLKSimpleTextProvider(text: message.line1 ?? ""),
                                                                         body1TextProvider: CLKSimpleTextProvider(text: message.line2 ?? ""),
                                                                         body2TextProvider: CLKSimpleTextProvider(text: message.header ?? ""))

		} else {
			return nil
		}
	}

	func createTimeLineEntry(for complication: CLKComplication, message: Complication, date: Date) -> CLKComplicationTimelineEntry? {
		guard let template = createComplicationTemplate(for: complication, message: message) else {
			return nil
		}

		let entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
		return(entry)
	}

	func reloadData() {
		let server = CLKComplicationServer.sharedInstance()
		guard let complications = server.activeComplications,
			!complications.isEmpty else {
				return
		}

		for complication in complications {
			server.reloadTimeline(for: complication)
		}
	}

}

extension Collection {
	var pairs: [String] {
		let size = 18
		var startIndex = self.startIndex
		let count = self.count
		let temp = count / size + (count % size == 0 ? 0 : 1)
		return (0..<temp).map { _ in
			let endIndex = index(startIndex, offsetBy: size, limitedBy: self.endIndex) ?? self.endIndex
			defer { startIndex = endIndex }
			return "\(self[startIndex..<endIndex])"
		}
	}
}
