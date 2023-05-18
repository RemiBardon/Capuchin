//
//  ContentView.swift
//  Capuchin
//
//  Created by Rémi Bardon on 14/05/2023.
//

import CoreLocation
import Dependencies
import MapKit
import SwiftUI

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

struct Place: Identifiable {
  let id = UUID()
  let coordinates: Coordinates
}

enum LocationError: Error {
  case noLocation, notAuthorized(CLAuthorizationStatus), error(CLError)
}

extension CLAuthorizationStatus {
  var capuchin_isAuthorized: Bool {
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

final class ViewModel: ObservableObject {
  @Dependency(\.locationClient) var locationClient

  @Published var places: [Place] = []
  @Published var gettingLocation = false

  @Published var region = MKCoordinateRegion(.world)

  @MainActor
  func markMyLocationTapped() async {
    self.gettingLocation = true
    defer { self.gettingLocation = false }

    do {
      let location = try await self.locationClient.getLocation()
      let place = Place(
        coordinates: .init(location)
      )
      self.places.append(place)
    } catch {
      print(error)
    }
  }
}

struct ContentView: View {
  @StateObject var viewModel = ViewModel()

  var body: some View {
    VStack {
      placesMap()
      markLocationButton()
    }
  }

  func placesMap() -> some View {
    Map(
      coordinateRegion: self.$viewModel.region,
      showsUserLocation: true,
      annotationItems: self.viewModel.places
    ) { place in
      MapMarker(coordinate: place.coordinates.clLocationCoordinate2D)
    }
  }

  func placesList() -> some View {
    List {
      ForEach(self.viewModel.places) { place in
        Text(String(describing: place.coordinates))
      }
    }
  }

  func markLocationButton() -> some View {
    Button("Mark my location") {
      Task {
        await self.viewModel.markMyLocationTapped()
      }
    }
    .buttonStyle(.borderedProminent)
    .disabled(self.viewModel.gettingLocation)
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
