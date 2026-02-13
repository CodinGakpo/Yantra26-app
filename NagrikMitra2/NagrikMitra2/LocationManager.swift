//
//  LocationManager.swift
//  NagrikMitra2
//
//  Location services manager
//

import Foundation
import CoreLocation
import MapKit
import Contacts
import Combine

class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var locationString: String = ""
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        
        isLoading = true
        errorMessage = nil
        locationManager.requestLocation()
    }
    
    func reverseGeocode(location: CLLocation) async throws -> String {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        )
        searchRequest.resultTypes = .address
        
        let search = MKLocalSearch(request: searchRequest)
        let response = try await search.start()
        
        guard let mapItem = response.mapItems.first else {
            throw LocationError.noAddress
        }
        
        // Use the formatted address from mapItem
        if let name = mapItem.name {
            return name
        }
        
        // Fallback to coordinates if no formatted address
        return "\(location.coordinate.latitude), \(location.coordinate.longitude)"
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        Task { @MainActor in
            self.location = location
            
            do {
                let address = try await reverseGeocode(location: location)
                self.locationString = address
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to get address"
                self.locationString = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
                self.isLoading = false
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}

enum LocationError: Error, LocalizedError {
    case noAddress
    
    var errorDescription: String? {
        switch self {
        case .noAddress:
            return "Could not find address for location"
        }
    }
}
