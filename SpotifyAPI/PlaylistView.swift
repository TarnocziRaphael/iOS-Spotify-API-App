//
//  PlaylistView.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 13.09.25.
//

import SwiftUI

struct PlaylistView: View {
    
    @EnvironmentObject var spotifyController: SpotifyController
    @EnvironmentObject var network: Network
    @State private var user: User?
    @State private var isLoading: Bool = true
    @State private var playlists: [Playlist] = []
    
    var body: some View {
        ZStack {
            if network.isTokenLoading {
                VStack {
                    Spacer()
                    ProgressView("Connecting to Spotify…")
                        .progressViewStyle(CircularProgressViewStyle())
                        .font(.title2)
                    Spacer()
                }
            }
            else if spotifyController.accessToken != nil {
                
                VStack {
                    if self.isLoading {
                        Spacer()
                        ProgressView("Loading playlists...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                    else {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Playlists")
                                    .font(.title)
                                    .bold()
                            }
                            .padding(.horizontal)
                            
                            Spacer()
                        }
                        List(playlists) { playlist in
                            HStack(spacing: 15) {
                                if let urlString = playlist.firstImageURL,
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
                                    Text(playlist.name)
                                        .font(.system(size: 20, weight: .bold))
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                        .listStyle(PlainListStyle())
                        .refreshable {
                            fetchData()
                        }
                    }
                }
                .onAppear() {
                    self.isLoading = true
                    fetchData()
                    network.fetchUserInformation { user in
                        DispatchQueue.main.async {
                            self.user = user
                        }
                        
                    }
                }
            }
        }
        .padding()
    }
    
    private func fetchData() {
        self.isLoading = true
        network.fetchPlaylists() { playlists in
            DispatchQueue.main.async {
                self.playlists = playlists
                self.isLoading = false
            }
        }
    }
}
