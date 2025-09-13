//
//  DetailPlaylistView.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 13.09.25.
//

import SwiftUI
import ToastUI

struct PlaylistDetailView: View {
    let playlist: Playlist
    
    @EnvironmentObject var network: Network
    @EnvironmentObject var spotifyController: SpotifyController
    
    @State private var tracks: [Track] = []
    @State private var filteredTracks: [Track] = []
    @State private var searchText: String = ""
    @State private var isLoading = true
    @State private var devicesError = false
    @State private var deviceName = ""
    
    var body: some View {
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
                    ProgressView("Loading playlists items...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else {
                    VStack {
                        HStack {
                            if let urlString = playlist.firstImageURL,
                               let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height:100)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .shadow(radius: 3)
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                        .overlay(ProgressView())
                                }
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text(self.playlist.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .lineLimit(1)
                                Text("Popularity: \(averagePopularity())")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Songs: \(tracks.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            Spacer()
                        }
                        .padding()
                        
                        // Search bar
                        TextField("Search by track or artist", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .onChange(of: searchText) { _ in
                                filterTracks()
                            }
                        
                        // Filtered tracks list
                        TopTracksListView(topTracks: searchText.isEmpty ? tracks : filteredTracks) { track in
                            network.fetchAvailableDevices() { devices in
                                guard let device = devices.first else {
                                    print("⚠️ No devices available")
                                    self.devicesError = true
                                    return
                                }
                                self.deviceName = device.name
                                guard let trackId = track.id else {
                                    print("⚠️ No track id available")
                                    return
                                }
                                network.playMusic(id: trackId, type: .track, deviceID: device.id)
                            }
                        }
                        .refreshable {
                            fetchData()
                        }
                    }
                    .refreshable {
                        fetchData()
                    }
                }
            }
            .toast(isPresented: $devicesError, dismissAfter: 1.5) {
                Text("⚠️ No devices available")
                    .font(.title2)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .toast(
                isPresented: Binding(
                    get: { !self.deviceName.isEmpty },
                    set: { _ in self.deviceName = "" }
                ),
                dismissAfter: 1.5,
                onDismiss: { self.deviceName = "" }
            ) {
                Text("✅ Music started playing on \(self.deviceName)")
                    .font(.title2)
                    .lineLimit(1)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .onAppear() {
                fetchData()
            }
        }
    }
    
    private func fetchData() {
        self.isLoading = true
        network.fetchPlaylistTracks(id: self.playlist.id) { tracks in
            DispatchQueue.main.async {
                self.tracks = tracks
                self.filteredTracks = tracks
                self.isLoading = false
            }
        }
    }
    
    private func averagePopularity() -> Int {
        guard !tracks.isEmpty else { return 0 }
        let total = tracks.map { $0.popularity }.reduce(0, +)
        return total / tracks.count
    }
    
    private func filterTracks() {
        if searchText.isEmpty {
            filteredTracks = tracks
        } else {
            let lowercasedSearch = searchText.lowercased()
            filteredTracks = tracks.filter { track in
                let trackNameMatches = track.name.lowercased().contains(lowercasedSearch)
                let artistMatches = track.artists.contains { $0.name.lowercased().contains(lowercasedSearch) }
                return trackNameMatches || artistMatches
            }
        }
    }
}
