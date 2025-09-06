//
//  ContentView.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 06.09.25.
//

import SwiftUI
import ToastUI

struct ContentView: View {
    
    @EnvironmentObject var spotifyController: SpotifyController
    @EnvironmentObject var network: Network
    
    @State private var selectedTimeRange: TimeRange = .short_term
    @State private var selectedPage: MusicType = .artist
    @State private var isLoading: Bool = false
    @State private var topArtists: [Artist] = []
    @State private var topTracks: [Track] = []
    @State private var devicesError: Bool = false
    @State private var deviceName: String = ""
    
    var body: some View {
        ZStack {
            if spotifyController.accessToken != nil {
                VStack {
                    HStack {
                        Spacer()
                        Picker("Zeitraum", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 250)
                        .onChange(of: selectedTimeRange) {
                            fetchData()
                        }
                        Spacer()
                        Button(action: {
                            network.refreshToken()
                            fetchData()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 15))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Circle().fill(Color.blue))
                                .shadow(radius: 5)
                        }
                    }
                    
                    TabView(selection: $selectedPage) {
                        VStack {
                            if isLoading {
                                Spacer()
                                ProgressView("Loading top artists...")
                                    .progressViewStyle(CircularProgressViewStyle())
                                Spacer()
                            }
                            else {
                                HStack {
                                    Text("Top Artists")
                                        .font(.title)
                                        .bold()
                                        .padding()
                                    Spacer()
                                }
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
                                            if let popularity = artist.popularity {
                                                Text("Popularity: \(popularity)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            network.fetchAvailableDevices() { devices in
                                                guard let device = devices.first else {
                                                    print("⚠️ No devices available")
                                                    self.devicesError = true
                                                    return
                                                }
                                                self.deviceName = device.name
                                                network.playMusic(id: artist.id, type: MusicType.artist, deviceID: device.id)
                                            }
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
                                .refreshable {
                                    fetchData()
                                }
                            }
                        }
                        .tag(MusicType.artist)
                        VStack {
                            if isLoading {
                                Spacer()
                                ProgressView("Loading top songs...")
                                    .progressViewStyle(CircularProgressViewStyle())
                                Spacer()
                            }
                            else {
                                HStack {
                                    Text("Top Tracks")
                                        .font(.title)
                                        .bold()
                                        .padding()
                                    Spacer()
                                }
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
                                            Text(track.artistNames)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text("Popularity: \(track.popularity)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        
                                        Button(action: {
                                            network.fetchAvailableDevices() { devices in
                                                guard let device = devices.first else {
                                                    print("⚠️ No devices available")
                                                    self.devicesError = true
                                                    return
                                                }
                                                self.deviceName = device.name
                                                network.playMusic(id: track.id, type: MusicType.track, deviceID: device.id)
                                            }
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
                                .refreshable {
                                    fetchData()
                                }
                                
                            }
                        }
                        .tag(MusicType.track)
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .onChange(of: selectedPage) {
                        fetchData()
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
            } else {
                Text("🔒 Not Authorized")
                Button(action: {
                    spotifyController.authorize()
                }) {
                    Text("Connect to Spotify")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
    
    private func fetchData() {
        self.isLoading = true
        if self.selectedPage == .artist {
            network.fetchTopArtists(timeRange: selectedTimeRange) { artists in
                DispatchQueue.main.async {
                    self.topArtists = artists
                    self.isLoading = false
                }
            }
        } else if self.selectedPage == .track {
            network.fetchTopTracks(timeRange:selectedTimeRange) { tracks in
                DispatchQueue.main.async {
                    self.topTracks = tracks
                    self.isLoading = false
                }
            }
        }
        
    }
}

#Preview {
    ContentView()
}
