//
//  TopTracksView.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 13.09.25.
//

import SwiftUI

struct TopTracksListView: View {
    var topTracks: [Track]
    var playAction: (Track) -> Void
    
    var body: some View {
        List(topTracks) { track in
            HStack(spacing: 15) {
                if let urlString = track.album.firstImageURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(radius: 3)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .overlay(ProgressView())
                    }
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(track.name)
                        .font(.system(size: 20, weight: .bold))
                        .lineLimit(2)
                    Text(track.artistNames)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Text("Popularity: \(track.popularity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    playAction(track)
                }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 25))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 5)
                }
            }
            .padding(.vertical, 5)
        }
        .listStyle(PlainListStyle())
    }
}

