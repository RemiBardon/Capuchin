//
//  ContentView.swift
//  Capuchin
//
//  Created by Rémi Bardon on 14/05/2023.
//

import CoreLocation
import Dependencies
import _LocationDependency
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

final class ViewModel: ObservableObject {
  @Dependency(\.locationManager) var locationManager
  @Dependency(\.locationClient) var locationClient

  @Published var places: [Place] = []
  @Published var gettingLocation = false

  @Published var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters {
    didSet {
      self.locationManager.desiredAccuracy = self.desiredAccuracy
    }
  }

  @Published var mapPosition = MapCameraPosition.userLocation(fallback: .region(MKCoordinateRegion(.world)))

  init() {
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    self.locationManager.activityType = .fitness
  }

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
      VStack {
        markLocationButton()
        desiredAccuracyPicker()
      }
      .padding()
    }
  }

  func placesMap() -> some View {
    Map(position: self.$viewModel.mapPosition) {
      UserAnnotation()
      ForEach(self.viewModel.places) { place in
        Marker("", coordinate: place.coordinates.clLocationCoordinate2D)
      }
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
  }

  func desiredAccuracyPicker() -> some View {
    Picker("Desired accuracy", selection: self.$viewModel.desiredAccuracy) {
      Text("Best")
        .tag(kCLLocationAccuracyBest)
      Text("100 meters")
        .tag(kCLLocationAccuracyHundredMeters)
      Text("Approx.")
        .tag(kCLLocationAccuracyReduced)
    }
    .pickerStyle(.segmented)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
