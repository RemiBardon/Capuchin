//
//  MapDetailView.swift
//  Capuchin
//
//  Created by Rémi Bardon on 14/05/2023.
//

import CoreLocation
import Dependencies
import _LocationDependency
import MapKit
import SwiftData
import SwiftUI

struct MapDetailView: View {
  @StateObject var viewModel: ViewModel

  init(map: CNMap) {
    self._viewModel = StateObject(wrappedValue: ViewModel(map: map))
  }

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
      ForEach(self.viewModel.map.places, content: PlaceMarker.init(place:))
    }
  }

  func placesList() -> some View {
    List {
      ForEach(self.viewModel.map.places) { place in
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

extension MapDetailView {
  final class ViewModel: ObservableObject {
    @Dependency(\.locationManager) var locationManager
    @Dependency(\.locationClient) var locationClient

    @Environment(\.modelContext) private var modelContext

    @Published var map: CNMap
    @Published var gettingLocation = false

    @AppStorage("desiredAccuracy") var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters {
      didSet {
        self.locationManager.desiredAccuracy = self.desiredAccuracy
      }
    }

    @Published var mapPosition = MapCameraPosition.userLocation(fallback: .region(MKCoordinateRegion(.world)))

    init(map: CNMap) {
      self.map = map

      self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
      self.locationManager.activityType = .fitness
    }

    @MainActor
    func markMyLocationTapped() async {
      self.gettingLocation = true
      defer { self.gettingLocation = false }

      do {
        let location = try await self.locationClient.getLocation()
        let newPlace = CNPlace(
          coordinates: .init(location),
          name: "Place \(self.map.places.count)"
        )
        self.map.places.append(newPlace)
      } catch {
        print(error)
      }
    }
  }
}

//#Preview {
//  MapDetailView(map: CNMap())
//}
