//
//  WalkieTalkieWidget.swift
//  WalkieTalkieWidget
//
//  Created by mayue on 2020/9/22.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    
    typealias Entry = TopChannelsEntry
        
    private var plachholderEntry: TopChannelsEntry {
        return TopChannelsEntry(date: Date(), topChannels: Network.Entity.Channel.defaultTopChannels)
    }
    
    func placeholder(in context: Context) -> TopChannelsEntry {
        return plachholderEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> ()) {
        completion(plachholderEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        
        DataLoader.fetchTopChannels { (result) in
            
            let topChannels: [Network.Entity.Channel]
            
            switch result {
            case .success(let channels):
                topChannels = channels.count > 0 ? channels : Network.Entity.Channel.defaultTopChannels
                Network.Entity.Channel.updateDefaultTopChannels(channels)
            case .failure(_):
                topChannels = Network.Entity.Channel.defaultTopChannels
            }
            
            let timeline = Timeline(entries: [TopChannelsEntry(date: Date(), topChannels: topChannels)], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct TopChannelsEntry: TimelineEntry {
    var date: Date
    let topChannels: [Network.Entity.Channel]
}

@main
struct WalkieTalkieWidget: Widget {
    let kind: String = "WalkieTalkieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WalkieTalkieWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Walkie Talkie Widget")
        .description("Hot Public Channels")
    }
}

struct WalkieTalkieWidget_Previews: PreviewProvider {
    static var previews: some View {
        WalkieTalkieWidgetEntryView(entry: TopChannelsEntry(date: Date(), topChannels: [Network.Entity.Channel.init(with: [:]), Network.Entity.Channel.init(with: [:])]))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

extension Network.Entity.Channel {
    
    init(with dict: [String : Any]) {
        self.name = "Welcome"
        self.userCount = 88
    }
    
}
