//
//  PostCell.swift
//  MacMagazineWidgetExtensionExtension
//
//  Created by Ailton Vieira Pinto Filho on 16/01/21.
//  Copyright © 2021 MacMagazine. All rights reserved.
//

import Kingfisher
import SwiftUI
import WidgetKit

struct PostCell: View {
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.redactionReasons) var redactionReasons
    @Environment(\.accessibilityEnabled) var accessibilityEnabled

    let post: PostData

    var image: KFImage {
        KFImage(URL(string: redactionReasons == .placeholder ? "" : post.thumbnail ?? ""))
            .placeholder { Image("image_logo_feature") }
    }

    @ViewBuilder
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            coverStyle
                .widgetURL(post.url)

        case .accessoryInline:
            Text("MM \(post.title ?? "")")
                .widgetURL(post.url)

        case .accessoryCircular:
            ZStack {
                Circle()
                    .stroke(lineWidth: 10)
                VStack(spacing: 0) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                    Text("\(Helper().badgeCount)")
                        .widgetURL(post.url)
                }
            }
            .widgetBackground(Color.clear)

        case .accessoryRectangular:
            HStack(spacing: 5) {
                VStack {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    Spacer(minLength: 0)
                }
                VStack(spacing: 0) {
                    Text(post.title ?? "")
                        .widgetURL(post.url)
                    Spacer(minLength: 0)
                }
            }
            .widgetBackground(Color.clear)

        default:
            Link(destination: post.url) {
                coverStyle
            }
        }
    }

    var contentView: some View {
        VStack(spacing: 2) {
            if let title = post.title {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    var coverStyle: some View {
        VStack {
            Spacer(minLength: 0)
            contentView.shadow(color: .black, radius: 5)
                .padding()
        }
        .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.01), Color.black]),
                                         startPoint: .top,
                                         endPoint: .bottom))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .background(image.resizable().scaledToFill())
        .widgetBackground(Color.clear)
        .clipped()
        .colorScheme(.dark)
    }
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        containerBackground(for: .widget) {
            backgroundView
        }
    }
}

struct PostCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PostCell(post: .placeholder)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Rectangular")
            PostCell(post: .placeholder)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Inline")
            PostCell(post: .placeholder)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Circular")

            VStack(spacing: 1) {
                PostCell(post: .placeholder)
            }
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")

            VStack(spacing: 1) {
                PostCell(post: .placeholder)
                PostCell(post: .placeholder)
            }
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.sizeCategory, .extraExtraLarge)
            .previewDisplayName("Medium")

            VStack(spacing: 1) {
                PostCell(post: .placeholder)
                PostCell(post: .placeholder)
                PostCell(post: .placeholder)
            }
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large")
        }
    }
}
