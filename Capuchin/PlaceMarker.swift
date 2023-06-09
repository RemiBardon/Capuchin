//
//  PlaceMarker.swift
//  Capuchin
//
//  Created by Rémi Bardon on 08/06/2023.
//

import MapKit
import SwiftUI

struct PlaceMarker: MapContent {
  let place: CNPlace
  var body: some MapContent {
    Marker(
      self.place.name,
      coordinate: self.place.coordinates.clLocationCoordinate2D
    )
  }
}
