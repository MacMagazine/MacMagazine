//
//  MacMagazineWidgetExtension.swift
//  MacMagazineWidgetExtension
//
//  Created by Ailton Vieira Pinto Filho on 16/01/21.
//  Copyright © 2021 MacMagazine. All rights reserved.
//

import SwiftUI
import WidgetKit

@main
struct MacMagazineWidgetExtension: Widget {
    let kind: String = "MacMagazineRecentPostsWidget"

    private var supportedFamilies: [WidgetFamily] {
#if os(iOS)
        return [.accessoryRectangular,
                .accessoryInline,
                .accessoryCircular,
                .systemSmall,
                .systemMedium,
                .systemLarge]
#else
        return [.systemSmall,
                .systemMedium]
#endif
        }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentPostsProvider()) { entry in
            RecentPostsWidget(entry: entry)
        }
        .configurationDisplayName("MacMagazine")
        .description("Confira nossos últimos posts!")
        .supportedFamilies(supportedFamilies)
        .contentMarginsDisabled()
    }
}

#Preview("Large", as: .systemLarge) {
    MacMagazineWidgetExtension()
} timeline: {
    RecentPostsEntry(date: Date(),
                     posts: [.placeholder, .placeholder, .placeholder])
}

#Preview("Rectangular", as: .accessoryRectangular) {
    MacMagazineWidgetExtension()
} timeline: {
    RecentPostsEntry(date: Date(),
                     posts: [.placeholder])
}

#Preview("Inline", as: .accessoryInline) {
    MacMagazineWidgetExtension()
} timeline: {
    RecentPostsEntry(date: Date(),
                     posts: [.placeholder])
}

#Preview("Circular", as: .accessoryCircular) {
    MacMagazineWidgetExtension()
} timeline: {
    RecentPostsEntry(date: Date(),
                     posts: [.placeholder])
}

#Preview("Small", as: .systemSmall) {
    MacMagazineWidgetExtension()
} timeline: {
    RecentPostsEntry(date: Date(),
                     posts: [.placeholder])
}

#Preview("Medium", as: .systemMedium) {
    MacMagazineWidgetExtension()
} timeline: {
    RecentPostsEntry(date: Date(),
                     posts: [.placeholder, .placeholder])
}
