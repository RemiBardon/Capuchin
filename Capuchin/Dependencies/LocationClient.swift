//
//  LocationClient.swift
//  Capuchin
//
//  Created by Rémi Bardon on 15/05/2023.
//

import CoreLocation
import Dependencies

public struct LocationClient: Sendable {
  public var authorizationStatus: @Sendable () -> CLAuthorizationStatus
  public var requestWhenInUseAuthorization: @Sendable () async -> CLAuthorizationStatus
  public var requestAlwaysAuthorization: @Sendable () async -> CLAuthorizationStatus
  public var getLocation: @MainActor @Sendable () async throws -> CLLocationCoordinate2D
}

extension DependencyValues {
  public var locationClient: LocationClient {
    get { self[LocationClient.self] }
    set { self[LocationClient.self] = newValue }
  }
}

final class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
  private var locationContinuations = [CheckedContinuation<CLLocationCoordinate2D, any Error>]()
  private var authorizationContinuations = [CheckedContinuation<CLAuthorizationStatus, Never>]()

  func registerLocationContinuation(_ continuation: CheckedContinuation<CLLocationCoordinate2D, any Error>) {
    self.locationContinuations.append(continuation)
  }
  func registerAuthorizationContinuation(_ continuation: CheckedContinuation<CLAuthorizationStatus, Never>) {
    self.authorizationContinuations.append(continuation)
  }

  private func locationReceived(_ res: Result<CLLocationCoordinate2D, LocationError>) -> Void {
    while !self.locationContinuations.isEmpty {
      self.locationContinuations.removeFirst().resume(with: res)
    }
  }

  func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let location = locations.first {
      self.locationReceived(.success(location.coordinate))
    } else {
      self.locationReceived(.failure(LocationError.noLocation))
    }
  }

  func locationManager(_: CLLocationManager, didFailWithError error: Error) {
    self.locationReceived(.failure(LocationError.error(error as! CLError)))
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    while !self.authorizationContinuations.isEmpty {
      self.authorizationContinuations.removeFirst().resume(returning: status)
    }
  }
}

extension LocationClient: DependencyKey {
  public static var liveValue: LocationClient {
    let requestWhenInUseAuthorization = { @Sendable @MainActor in
      let locationManager = CLLocationManager()
      let locationManagerDelegate = LocationManagerDelegate()

      let status = locationManager.authorizationStatus
      if status.capuchin_isAuthorized {
        return status
      }

      return await withCheckedContinuation { continuation in
        locationManagerDelegate.registerAuthorizationContinuation(continuation)
        locationManager.requestWhenInUseAuthorization()
      }
    }

    return LocationClient(
      authorizationStatus: { CLLocationManager().authorizationStatus },
      requestWhenInUseAuthorization: requestWhenInUseAuthorization,
      requestAlwaysAuthorization: {
        let locationManager = CLLocationManager()
        let locationManagerDelegate = LocationManagerDelegate()

        let status = locationManager.authorizationStatus
        if status == .authorizedAlways {
          return status
        }

        return await withCheckedContinuation { continuation in
          locationManagerDelegate.registerAuthorizationContinuation(continuation)
          locationManager.requestAlwaysAuthorization()
        }
      },
      getLocation: {
        let locationManager = CLLocationManager()
        let locationManagerDelegate = LocationManagerDelegate()

        locationManager.delegate = locationManagerDelegate
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.activityType = .fitness

        #if !os(macOS)
        let status = await requestWhenInUseAuthorization()
        if !status.capuchin_isAuthorized {
          throw LocationError.notAuthorized(status)
        }
        #endif

        let location = try await withCheckedThrowingContinuation { [weak locationManagerDelegate] continuation in
          locationManagerDelegate?.registerLocationContinuation(continuation)
          locationManager.requestLocation()
        }

        // Stop updating location as `requestLocation` starts it.
        // Without this, calling `requestLocation` a second time does nothing.
//        locationManager.stopUpdatingLocation()

        return location
      }
    )
  }

  public static var previewValue: LocationClient {
    let authorized: CLAuthorizationStatus
    #if os(macOS)
    authorized = .authorized
    #else
    authorized = .authorizedAlways
    #endif

    return LocationClient(
      authorizationStatus: { authorized },
      requestWhenInUseAuthorization: { authorized },
      requestAlwaysAuthorization: { authorized },
      getLocation: {
        // Coordinates of the "Dame du Lac" spot in Lisses, France
        CLLocationCoordinate2D(latitude: 48.61739, longitude: 2.41905)
      }
    )
  }


  public static let testValue = LocationClient(
    authorizationStatus: unimplemented("LocationClient.authorizationStatus", placeholder: .denied),
    requestWhenInUseAuthorization: unimplemented("LocationClient.requestWhenInUseAuthorization", placeholder: .denied),
    requestAlwaysAuthorization: unimplemented("LocationClient.requestAlwaysAuthorization", placeholder: .denied),
    getLocation: unimplemented("LocationClient.getLocation")
  )
}
