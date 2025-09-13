//
//  NavigationModel.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 13.09.25.
//

import SwiftUI

class NavigationModel: ObservableObject {
    @Published var path: [NavigationGoal] = []
}
