//
//  CapuchinApp.swift
//  Capuchin
//
//  Created by Rémi Bardon on 14/05/2023.
//

import SwiftUI
import SwiftData

@main
struct CapuchinApp: App {
  var body: some Scene {
    WindowGroup {
      MapList()
    }
    .modelContainer(for: CNMap.self)
  }
}
