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

extension ContentView {
  final class ViewModel: ObservableObject {
    @Dependency(\.locationManager) var locationManager
    @Dependency(\.locationClient) var locationClient

    @AppStorage("desiredAccuracy") var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters {
      didSet {
        self.locationManager.desiredAccuracy = self.desiredAccuracy
      }
    }

    @Published var places: [Place] = []
    @Published var gettingLocation = false

    @Published var region = MKCoordinateRegion(.world)

    init() {
      self.locationManager.desiredAccuracy = self.desiredAccuracy
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
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
