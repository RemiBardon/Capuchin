//
//  MapList.swift
//  Capuchin
//
//  Created by Rémi Bardon on 08/06/2023.
//

import SwiftData
import SwiftUI

struct MapList: View {
  @Environment(\.modelContext) private var modelContext

  @Query private var maps: [CNMap]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 192, maximum: 320), spacing: 16)], spacing: 16) {
          Button {
            let newMap = CNMap(name: "Map \(self.maps.count)")
            self.modelContext.insert(newMap)
          } label: {
            Label("New map", systemImage: "plus")
              .frame(maxWidth: .infinity, minHeight: 128, maxHeight: .infinity)
              .background(.fill)
              .clipShape(MapCard.clipShape)
          }
          ForEach(self.maps, content: MapCard.init(map:))
            .aspectRatio(4.0/3.0, contentMode: .fit)
        }
        // Fix cards displayed as buttons
        .buttonStyle(.plain)
        .padding()
      }
      .navigationDestination(for: CNMap.self, destination: MapDetailView.init(map:))
    }
  }
}

#Preview {
  MapList()
}
