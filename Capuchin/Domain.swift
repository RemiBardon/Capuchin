//
//  Domain.swift
//  Capuchin
//
//  Created by Rémi Bardon on 08/06/2023.
//

import Foundation
import CoreLocation

struct Place: Identifiable {
  let id = UUID()
  let coordinates: Coordinates
}

struct Coordinates {
  let latitude, longitude: Double

  var clLocationCoordinate2D: CLLocationCoordinate2D {
    .init(latitude: self.latitude, longitude: self.longitude)
  }

  init(_ coordinates: CLLocationCoordinate2D) {
    self.latitude = coordinates.latitude
    self.longitude = coordinates.longitude
  }
}
