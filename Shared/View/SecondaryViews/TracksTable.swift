//
//  TracksTable.swift
//  Music Transfer
//
//  Created by panandafog on 27.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct TracksTable: View {
    
    @Binding var tracks: [SharedTrack]
    let name: String
    let compact: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: nil) {
            if !compact {
                HStack {
                    Text(name)
                        .font(.body)
                    Spacer()
                    Text("count: \(tracks.count)")
                }
            }
            ZStack {
                List(tracks) { track in
                    TracksTableRow(track: track)
                        .modify {
#if os(macOS)
                            $0
#else
                            if #available(iOS 15.0, *) {
                                $0
                                    .listRowSeparator(.hidden)
                            } else {
                                $0
                            }
#endif
                        }
                }
                .listStyle(PlainListStyle())
            }
        }
        .modify {
            if compact {
                $0
            } else {
                $0.padding()
            }
        }
    }
    
    init(tracks: Binding<[SharedTrack]>, name: String, compact: Bool = false) {
        self._tracks = tracks
        self.name = name
        self.compact = compact
    }
}
