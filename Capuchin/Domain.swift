//
//  Domain.swift
//  Capuchin
//
//  Created by Rémi Bardon on 08/06/2023.
//

import Foundation
import CoreLocation
import SwiftData

@Model
final class CNMap {
  var name: String
  @Relationship(.cascade) var places: [CNPlace]
  @Relationship(.cascade) var metadata: CNMapMetadata

  init(
    name: String,
    places: [CNPlace] = [],
    metadata: CNMapMetadata = .init()
  ) {
    self.name = name
    self.places = places
    self.metadata = metadata
  }
}

@Model
final class CNMapMetadata {
  let created: Date
  var updated: Date

  init(
    created: Date = .now,
    updated: Date = .now
  ) {
    self.created = created
    self.updated = updated
  }
}

@Model
final class CNPlace {
  @Relationship(.cascade) var coordinates: CNCoordinates
  var name: String

  init(
    coordinates: CNCoordinates,
    name: String
  ) {
    self.coordinates = coordinates
    self.name = name
  }
}

@Model
final class CNCoordinates: Hashable {
  let latitude: Double
  let longitude: Double

  var clLocationCoordinate2D: CLLocationCoordinate2D {
    .init(latitude: self.latitude, longitude: self.longitude)
  }

  init(_ coordinates: CLLocationCoordinate2D) {
    self.latitude = coordinates.latitude
    self.longitude = coordinates.longitude
  }
}

enum LocationError: Error {
  case noLocation, notAuthorized(CLAuthorizationStatus), error(CLError)
}

extension CLAuthorizationStatus {
  var cn_isAuthorized: Bool {
    switch self {
    case .authorized, .authorizedAlways, .authorizedWhenInUse:
      return true
    case .denied, .notDetermined, .restricted:
      return false
    @unknown default:
      return false
    }
  }
}
