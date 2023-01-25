import XCTest
import Combine
import CoreLocation
@testable import EZCoreLocation

final class EZCoreLocationTests: XCTestCase {
    var locationManager: EZCoreLocation!
    var locationMocks: [Location]!
    
    private var cancellables: [AnyCancellable]!
    
    override func setUpWithError() throws {
        locationManager = .init(locationManager: .init(), clearLocationsAtCount: 5, reportSpeedChanges: true)
        locationMocks = [locationMock(), locationMock(), locationMock(), locationMock(), locationMock()]
        cancellables = []
    }
    
    override func tearDownWithError() throws {
        locationManager = nil
        locationMocks = nil
        cancellables = nil
    }
    
    /// This test determines if the manager correctly clear values from the locations array in the manager after a given number of stores
    func testDoesClearLocationList() throws {
        XCTAssertTrue(locationManager.locations.isEmpty)
        
        let expectation = self.expectation(description: "Locations list did not become empty again")
        var iterationCount = 0
        locationManager.$locations.dropFirst().sink { locations in
            if iterationCount == self.locationMocks.count {
                XCTAssertTrue(locations.isEmpty)
                expectation.fulfill()
            }
            
            iterationCount += 1
            print(iterationCount, locations.count)
        }.store(in: &cancellables)
        
        for locationMock in locationMocks {
            locationManager.locationManager(locationManager.locationManager, didUpdateTo: locationMock.location, from: locationMock.location)
        }
        
        waitForExpectations(timeout: 10)
    }
}

private func locationMock() -> Location {
    Location(location: CLLocation(coordinate: CLLocationCoordinate2D(latitude: 53.34065646040065, longitude: -6.2361081232834215), altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1, course: 90, courseAccuracy: 1, speed: 20, speedAccuracy: 1, timestamp: Date()))
}
