//
//  Location.swift
//  
//
//  Created by Karim Elgendy on 24/01/2023.
//

import CoreLocation
import Contacts

/// A `Location` wraps `CLLocation` and will provide convenient methods to represent & use the location in a variety of manners
public struct Location {
    /// The location to be stored
    public let location: CLLocation
    /// The reference to the CLGeocoder object, which allows reverse lookup of `CLLocations`
    weak var geocoder: CLGeocoder?
    /// An address formatter that allows us to easily create human readable addresses from `CNPostalAddress` from a `CLLocation`'s `CLPlacemark` object
    weak var postalAddressFormatter: CNPostalAddressFormatter?
    
    // MARK: Convenience properties
    
    /// Provides floor information where floor information is available for particular buildings
    var floor: Int? {
        location.floor?.level
    }
    
    /// The timestamp of the recorded location
    var timestamp: TimeInterval {
        location.timestamp.timeIntervalSince1970
    }
    
    /// The altitude in meters of the recorded location
    var altitude: Double {
        location.ellipsoidalAltitude
    }
    
    /// The direction in relation to the standard compass (north = 0 degrees) at the moment the location was recorded
    var compassDegrees: Double {
        location.course
    }
    
    /// The speed at which the device was travelling when the location was recorded
    var speed: Double {
        location.speed
    }
    
    /// Converts a `CLLocation` to a human readable "address" string
    /// - Returns: A string representation of an address, if information is present.
    public func asAddress(_ addressCompletion: @escaping (String?) -> Void) {
        guard let geocoder = geocoder else { return }
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard error == nil else { print(error as Any); addressCompletion(nil); return }
            guard let places = placemarks, let postalAddress = places.first?.postalAddress else {  addressCompletion(nil); return }
            
            addressCompletion(self.postalAddressFormatter?.string(from: postalAddress))
        }
    }
}

// MARK: Comparison

extension Location {
    /// Compares location objects on timestamp
    static func <(lhs: Location, rhs: Location) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
    
    /// Compares location objects on timestamp
    static func >(lhs: Location, rhs: Location) -> Bool {
        lhs.timestamp > rhs.timestamp
    }
    
    /// Determines if a change in direction has occurred, based on the specified threshold
    /// - Parameters:
    ///   - from: The location to compare against
    ///   - to: The new location
    ///   - degreeChange: The threshold for what determines if the direction has changed
    /// - Returns: True if the direction has changed, matching the conditions given
    func didSwitchDirection(newLocation: Location, degreeChange: Double = 45.0) -> Bool {
        let lowerBound = self.compassDegrees - degreeChange
        let upperBound = self.compassDegrees + degreeChange
        let range = lowerBound...upperBound
        return !range.contains(newLocation.compassDegrees)
    }
    
    /// Measures the change in altitude from one location instance to another.
    /// - Parameters:
    ///   - from: The location at the first altitude
    ///   - to: The location at the second altitude
    /// - Returns: A positive value where an increase in altitude is measured and a negative value where a decrease in altitude is measured
    func changeInAltitdue(newLocation: Location) -> Double {
        newLocation.altitude - self.altitude
    }
    
    /// Measures the change in speed from one location instance to another
    /// - Parameters:
    ///   - from: A previous location
    ///   - to: The location to compare against
    /// - Returns: The speed differential as a struct `SpeedChange`
    func changeInSpeed(newLocation: Location) -> SpeedChange {
        let value = newLocation.speed - self.speed
        let speedChangeType: AccelerationEnum = value.sign == .minus ? .deceleration(value) : .acceleration(value)
        return SpeedChange(speed: newLocation.speed, previousSpeed: self.speed, change: speedChangeType)
    }
}
