//
//  WalkieTalkieWidget.UI.swift
//  WalkieTalkieWidgetExtension
//
//  Created by mayue on 2020/9/24.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import SwiftUI
import WidgetKit

struct WalkieTalkieWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family
    
    private var scaledFactor: CGFloat {
        switch family {
        case .systemSmall:
            return 1.0
        case .systemMedium:
            return 2.0
        case .systemLarge:
            return 2.0
        @unknown default:
            return 1.0
        }
    }
    
    private let titleFontSize: CGFloat = 18
    private let sharpFontSize: CGFloat = 13
    private let nameFontSize: CGFloat = 14
    private let countFontSize: CGFloat = 12
    private let countWidth: CGFloat = 25
    
    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall, .systemMedium, .systemLarge:
            
            VStack(alignment: .leading, spacing: 4, content: {
                Spacer()
                HStack {
                    Spacer()
                    Text("Hot Channels".uppercased())
                        .multilineTextAlignment(.center)
                        .font(customizeFont(size: titleFontSize * scaledFactor))
                        .minimumScaleFactor(0.8)
                    Spacer()
                }
                Spacer()
                ForEach(entry.topChannels, id: \.self) { channel in
                    HStack(alignment: .center, spacing: 4, content: {
                        Text("#")
                            .font(customizeFont(size: sharpFontSize * scaledFactor))
                            .foregroundColor(.black)
                        Link(channel.name, destination: URL(string: "https://walkietalkie.live/channel/\(channel.name)")!)
                            .lineLimit(1)
                            .font(customizeFont(size: nameFontSize * scaledFactor))
                            .foregroundColor(.black)
                        Spacer()
                        Image("icon_mic")
                        Text("\(channel.userCount)")
                            .multilineTextAlignment(.trailing)
                            .font(customizeFont(size: countFontSize * scaledFactor))
                            .foregroundColor(.black)
                            .frame(width: countWidth * scaledFactor)
                    })
                    .padding([.leading, .trailing], 5)
                }
                Spacer()
            })
            .padding([.top, .bottom], 10)
            .background(Color("WidgetBackground"))
            .widgetURL(URL(string: "https://walkietalkie.live/channel/\(entry.topChannels.first?.name ?? "")"))
            
        @unknown default:
            Text("unknown error")
        }
    }
    
    private func customizeFont(size: CGFloat) -> Font {
        return Font.custom("BlackOpsOne-Regular", size: size)
    }
    
}
