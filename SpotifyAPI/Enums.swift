//
//  Enums.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 06.09.25.
//

import Foundation

enum MusicType: String, Identifiable, CaseIterable {
    case artist
    case track
    
    var id: String { self.rawValue }
}

enum TimeRange: String, Identifiable, CaseIterable {
    case short_term
    case medium_term
    case long_term
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .short_term: return "4 Wochen"
        case .medium_term: return "6 Monate"
        case .long_term: return "1 Jahr"
        }
    }
}

enum NavigationGoal: Hashable {
    case playlist
    case playlistDetail(Playlist)
    case topItem
}
