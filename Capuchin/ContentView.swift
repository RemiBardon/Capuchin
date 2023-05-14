//
//  ContentView.swift
//  Capuchin
//
//  Created by Rémi Bardon on 14/05/2023.
//

import CoreLocation
import SwiftUI

struct Coordinates {
  let latitude, longitude: Double

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

final class LocationManager {
  private final class Delegate: NSObject, CLLocationManagerDelegate {
    var locationCallback: ((Result<CLLocationCoordinate2D, LocationError>) -> Void)?
    var authorizationCallback: ((CLAuthorizationStatus) -> Void)?

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      assert(self.locationCallback != nil)
      if let location = locations.first {
        self.locationCallback?(.success(location.coordinate))
      } else {
        self.locationCallback?(.failure(LocationError.noLocation))
      }
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
      assert(self.locationCallback != nil)
      self.locationCallback?(.failure(LocationError.error(error as! CLError)))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
      assert(self.authorizationCallback != nil)
      self.authorizationCallback?(manager.authorizationStatus)
    }
  }

  private var locationContinuations: [CheckedContinuation<CLLocationCoordinate2D, any Error>] = []
  private var authorizationContinuations: [CheckedContinuation<CLAuthorizationStatus, Never>] = []

  private let locationManager: CLLocationManager
  private let locationManagerDelegate: Delegate

  init() {
    self.locationManager = CLLocationManager()
    self.locationManagerDelegate = Delegate()

    self.locationManagerDelegate.locationCallback = { res in
      while !self.locationContinuations.isEmpty {
        self.locationContinuations.removeFirst().resume(with: res)
      }
    }
    self.locationManagerDelegate.authorizationCallback = { status in
      while !self.authorizationContinuations.isEmpty {
        self.authorizationContinuations.removeFirst().resume(returning: status)
      }
    }

    self.locationManager.delegate = self.locationManagerDelegate
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    self.locationManager.activityType = .fitness
  }

  func location() async throws -> CLLocationCoordinate2D {
    #if !os(macOS)
    let status = await self.requestWhenInUseAuthorization()
    if !status.capuchin_isAuthorized {
      throw LocationError.notAuthorized(status)
    }
    #endif

    let location = try await withCheckedThrowingContinuation { continuation in
      self.locationContinuations.append(continuation)
      self.locationManager.requestLocation()
    }

    // Stop updating location as `requestLocation` starts it.
    // Without this, calling `requestLocation` a second time does nothing.
    self.locationManager.stopUpdatingLocation()

    return location
  }

  func requestWhenInUseAuthorization() async -> CLAuthorizationStatus {
    let status = self.locationManager.authorizationStatus
    guard !status.capuchin_isAuthorized else {
      return status
    }

    return await withCheckedContinuation { continuation in
      self.authorizationContinuations.append(continuation)
      self.locationManager.requestWhenInUseAuthorization()
    }
  }
}

struct ContentView: View {
  let locationManager = LocationManager()

  @State var places: [Place] = []
  @State var gettingLocation = false

  var body: some View {
    VStack {
      placesList()
      markLocationButton()
    }
  }

  func placesList() -> some View {
    List {
      ForEach(self.places) { place in
        Text(String(describing: place.coordinates))
      }
    }
  }

  func markLocationButton() -> some View {
    Button("Mark my location") {
      Task {
        self.gettingLocation = true
        defer { self.gettingLocation = false }

        do {
          let location = try await self.locationManager.location()
          let place = Place(
            coordinates: .init(location)
          )
          self.places.append(place)
        } catch {
          print(error)
        }
      }
    }
    .buttonStyle(.borderedProminent)
    .disabled(self.gettingLocation)
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
