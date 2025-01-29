//
//  RecentPostsWidget.swift
//  MacMagazineWidgetExtensionExtension
//
//  Created by Ailton Vieira Pinto Filho on 16/01/21.
//  Copyright © 2021 MacMagazine. All rights reserved.
//

import SwiftUI
import WidgetKit

struct RecentPostsWidget: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: RecentPostsEntry
    var content: [PostData] { entry.posts }

    var body: some View {
        Group {
            if content.isEmpty {
                Text("Nenhum conteúdo disponível.")
                    .font(.headline)
            } else {
                switch widgetFamily {
                case .systemSmall:
                    PostCell(post: content[0])

                case .systemMedium:
                    VStack(spacing: 1) {
                        ForEach(0 ..< min(2, content.count),
                                id: \.self) { index in
                            PostCell(post: content[index])
                        }
                    }

                case .systemLarge:
                    VStack(spacing: 1) {
                        ForEach(0 ..< min(3, content.count),
                                id: \.self) { index in
                            PostCell(post: content[index])
                        }
                    }

                case .accessoryRectangular,
                        .accessoryInline,
                        .accessoryCircular:
                PostCell(post: content[0])

                case .systemExtraLarge:
                    Text("Tamanho incompatível.")

                @unknown default:
                    Text("Tamanho incompatível.")
                }
            }
        }
    }
}

struct RecentPostsWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RecentPostsWidget(entry: RecentPostsEntry(date: Date(), posts: [.placeholder]))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Rectangular")
            RecentPostsWidget(entry: RecentPostsEntry(date: Date(), posts: [.placeholder]))
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Inline")
            RecentPostsWidget(entry: RecentPostsEntry(date: Date(), posts: [.placeholder]))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Circular")
        }
    }
}
