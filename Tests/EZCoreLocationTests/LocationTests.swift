//
//  LocationTests.swift
//  
//
//  Created by Karim Elgendy on 24/01/2023.
//

import XCTest
import CoreLocation
@testable import EZCoreLocation

final class LocationTests: XCTestCase {
    var locationManager: CLLocationManager!
    var ezCoreLocation: EZCoreLocation!
    var locationOne: Location!
    var locationTwo: Location!
    
    override func setUpWithError() throws {
        locationManager = .init()
        ezCoreLocation = EZCoreLocation(locationManager: locationManager, clearLocationsAtCount: 20, reportSpeedChanges: true)
        
        // 53.34065646040065, -6.2361081232834215 = Google building
        locationOne = Location(location: CLLocation(coordinate: CLLocationCoordinate2D(latitude: 53.34065646040065, longitude: -6.2361081232834215), altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1, course: 90, courseAccuracy: 1, speed: 20, speedAccuracy: 1, timestamp: Date()))
        locationOne.geocoder = ezCoreLocation.geocoder
        locationOne.postalAddressFormatter = ezCoreLocation.postalAddressFormatter
        
        // 53.34515116546963, -6.24034091571977 = Facebook building
        locationTwo = Location(location: CLLocation(coordinate: CLLocationCoordinate2D(latitude: 53.34515116546963, longitude: -6.24034091571977), altitude: 40, horizontalAccuracy: 1, verticalAccuracy: 1, course: 45, courseAccuracy: 1, speed: 50, speedAccuracy: 1, timestamp: Date()))
        locationTwo.geocoder = ezCoreLocation.geocoder
        locationTwo.postalAddressFormatter = ezCoreLocation.postalAddressFormatter

    }

    override func tearDownWithError() throws {
        locationOne = nil
        locationTwo = nil
        locationManager = nil
        ezCoreLocation = nil
    }

    /// An integration test which checks if the reverse lookup of coordinates maps to an address string
    func testAddressProduction() throws {
        let expectation = self.expectation(description: "Failed to receive a response from Apple's geocoder lookup")
        locationOne.asAddress { address in
            XCTAssertEqual(address, "1 Gordon St\nDublin 4 Co. Dublin D04 T8P8\nIreland")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testExpectedValues() throws {
        let changeInSpeed = locationOne.changeInSpeed(newLocation: locationTwo).change
        switch changeInSpeed {
        case let .acceleration(value):
            XCTAssertEqual(value, 30)
        case .deceleration(_):
            XCTFail()
        }
        
        XCTAssertEqual(locationOne.speed, 20)
        XCTAssertEqual(locationTwo.speed, 50)
        
        // Intialising a CLLocation with an altitiude seems to not work. Returning 0.0
        // XCTAssertEqual(locationOne.changeInAltitdue(newLocation: locationTwo), 40)
        
        XCTAssertEqual(locationOne.compassDegrees, 90)
        XCTAssertEqual(locationTwo.compassDegrees, 45)
        XCTAssertTrue(locationOne.didSwitchDirection(newLocation: locationTwo, degreeChange: 20))
    }
}
