//
//  LocationManager.swift
//  JanSaathi2
//
//  Modern location services manager with MKReverseGeocodingRequest
//

import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    // Published properties for UI binding
    @Published var location: CLLocation?
    @Published var locationString: String = ""
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private var locationUpdateTask: Task<Void, Never>?
    private let accuracyThreshold: CLLocationAccuracy = 100.0 // meters
    private let timeout: TimeInterval = 8.0 // seconds
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10 // Update only if moved 10m
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
        
        startLocationUpdates()
    }
    
    private func startLocationUpdates() {
        isLoading = true
        errorMessage = nil
        
        // Cancel any existing task
        locationUpdateTask?.cancel()
        
        // Start location updates
        locationManager.startUpdatingLocation()
        
        // Setup timeout
        locationUpdateTask = Task {
            do {
                try await Task.sleep(for: .seconds(timeout))
            } catch {
                return
            }
            
            if !Task.isCancelled {
                handleTimeout()
            }
        }
    }
    
    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationUpdateTask?.cancel()
        locationUpdateTask = nil
    }
    
    private func handleTimeout() {
        stopLocationUpdates()
        
        if location == nil {
            errorMessage = "Location detection timed out"
            isLoading = false
        }
        // If we have a location but no address, the reverse geocoding task will handle it
    }
    
    private func processLocation(_ location: CLLocation) {
        // Stop updates once we have acceptable accuracy
        if location.horizontalAccuracy <= accuracyThreshold {
            stopLocationUpdates()
        }
        
        self.location = location
        
        // Perform reverse geocoding
        Task {
            do {
                let address = try await reverseGeocode(location: location)
                self.locationString = address
                self.isLoading = false
            } catch {
                // Fallback to coordinates
                self.locationString = formatCoordinates(location.coordinate)
                self.isLoading = false
                
                // Only show error if it's not a simple "no address found" case
                if !error.localizedDescription.contains("not found") {
                    self.errorMessage = "Using coordinates (address unavailable)"
                }
            }
        }
    }
    
    private func reverseGeocode(location: CLLocation) async throws -> String {
        // Use CLGeocoder with modern async/await
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            guard let placemark = placemarks.first else {
                throw LocationError.noAddress
            }
            
            // Format address with available components
            return formatAddress(from: placemark, location: location)
        } catch {
            // Gracefully handle errors (including simulator issues)
            throw LocationError.reverseGeocodingFailed(error)
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark, location: CLLocation) -> String {
        var components: [String] = []
        
        // Add name if available (e.g., building, landmark)
        if let name = placemark.name, !name.isEmpty {
            // Avoid duplicate if name matches other components
            let isDuplicate = name == placemark.locality || 
                             name == placemark.thoroughfare ||
                             name == placemark.subLocality
            if !isDuplicate {
                components.append(name)
            }
        }
        
        // Add street address (thoroughfare)
        if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
            components.append(thoroughfare)
        }
        
        // Add locality (city/town)
        if let locality = placemark.locality, !locality.isEmpty {
            components.append(locality)
        }
        
        // Add administrative area (state/province)
        if let adminArea = placemark.administrativeArea, !adminArea.isEmpty {
            components.append(adminArea)
        }
        
        // Add country
        if let country = placemark.country, !country.isEmpty {
            components.append(country)
        }
        
        // If we have components, join them
        if !components.isEmpty {
            return components.joined(separator: ", ")
        }
        
        // Fallback to coordinates if no address components
        return formatCoordinates(location.coordinate)
    }
    
    private func formatCoordinates(_ coordinate: CLLocationCoordinate2D) -> String {
        return String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            processLocation(location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            stopLocationUpdates()
            
            // Handle specific error cases
            if let clError = error as? CLError {
                switch clError.code {
                case .locationUnknown:
                    // Temporary error, keep trying (timeout will handle it)
                    return
                case .denied:
                    errorMessage = "Location access denied"
                case .network:
                    errorMessage = "Network error - check connection"
                default:
                    errorMessage = "Location error: \(error.localizedDescription)"
                }
            } else {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            
            // Automatically start location updates when authorization is granted
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                startLocationUpdates()
            }
        }
    }
}

// MARK: - Location Errors
enum LocationError: Error, LocalizedError {
    case noAddress
    case reverseGeocodingFailed(Error)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .noAddress:
            return "Could not find address for location"
        case .reverseGeocodingFailed(let error):
            return "Geocoding failed: \(error.localizedDescription)"
        case .timeout:
            return "Location request timed out"
        }
    }
}
