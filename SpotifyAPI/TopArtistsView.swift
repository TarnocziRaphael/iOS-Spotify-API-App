//
//  TopArtistsView.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 13.09.25.
//

import SwiftUI

struct TopArtistsView: View {
    var topArtists: [Artist]
    var playAction: (Artist) -> Void
    
    var body: some View {
        List(topArtists) { artist in
            HStack(spacing: 15) {
                if let urlString = artist.firstImageURL,
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
                    Text(artist.name)
                        .font(.system(size: 20, weight: .bold))
                        .lineLimit(1)
                    if let popularity = artist.popularity {
                        Text("Popularity: \(popularity)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    playAction(artist)
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
