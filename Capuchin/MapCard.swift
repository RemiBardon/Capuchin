//
//  MapCard.swift
//  Capuchin
//
//  Created by Rémi Bardon on 08/06/2023.
//

import MapKit
import SwiftUI

struct MapCard: View {
  static let cornerRadius: CGFloat = 12
  static let clipShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

  let map: CNMap

  var body: some View {
    NavigationLink(value: self.map) {
      Map(interactionModes: []) {
        ForEach(self.map.places, content: PlaceMarker.init(place:))
      }
      .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: [], showsTraffic: false))
      .mapControlVisibility(.hidden)
      .overlay(alignment: .topLeading) {
        Text(self.map.name)
          .font(.title2.bold())
          .lineLimit(2)
          .padding(8)
          .frame(maxWidth: .infinity)
          .background(.thickMaterial)
      }
//      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .aspectRatio(4.0/3.0, contentMode: .fit)
//      .background(.fill)
//      .overlay {
//        Self.clipShape.strokeBorder(.primary, lineWidth: 4)
//      }
      .clipShape(Self.clipShape)
    }
  }
}

//#Preview {
////  Text("Test")
////  Group {
//    MapCard(map: CNMap(name: "My first trip"))
////    MapCard(map: CNMap(name: "\(UUID().uuidString) \(UUID().uuidString)"))
////  }
//    .modelContainer(for: CNMap.self, inMemory: true)
//    .buttonStyle(.plain)
//    .border(Color.red)
//    .padding()
//    .frame(width: 300, height: 300)
//}
