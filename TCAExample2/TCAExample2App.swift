//
//  TCAExample2App.swift
//  TCAExample2
//
//  Created by Abdulrahman Qabbout on 18/04/2024.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCAExample2App: App {
    var body: some Scene {
        WindowGroup {
            SearchView(
              store: Store(initialState: Search.State()) {
                Search()
                  ._printChanges()
              }
            )
        }
    }
}
