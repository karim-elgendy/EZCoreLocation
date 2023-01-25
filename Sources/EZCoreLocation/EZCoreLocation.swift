import Combine
import CoreLocation
import Contacts

public class EZCoreLocation: NSObject {
    
    // MARK: Public properties
    
    /// The `locationManager` is the engine of this class
    let locationManager: CLLocationManager
    
    /// A value that should be set if location records should be cleared from memory at a certain point
    private var clearLocationsAtCount: Int
    /// A value that indicates speed changes should be reported
    private var reportSpeedChanges: Bool
    
    // MARK: Private properties
    
    private(set) var geocoder: CLGeocoder
    private(set) var postalAddressFormatter: CNPostalAddressFormatter

    // MARK: Combine properties (outside subscribers)
    
    /// Publishes permission changes for location use authorisation
    @Published private(set) var hasPermission: CurrentValueSubject<Bool, Never>
    /// Publishes the value of the list when updated
    @Published private(set) var locations: [Location]
    /// Publishes speed change results when `reportSpeedChanges` is set to true
    @Published private(set) var speedUpdatesSubject: PassthroughSubject<SpeedChange, Never>
    
    private var cancellables: [AnyCancellable] = []
    
    /// Intialises a CLLocationManager object on the current thread, if none is given
    init(locationManager: CLLocationManager, clearLocationsAtCount: Int, reportSpeedChanges: Bool) {
        // Init
        self.locationManager = locationManager
        self.clearLocationsAtCount = clearLocationsAtCount
        self.reportSpeedChanges = reportSpeedChanges
        self.geocoder = .init()
        self.postalAddressFormatter = .init()
        self.hasPermission = .init(locationManager.authorizationStatus == .authorizedAlways)
        self.locations = []
        self.speedUpdatesSubject = .init()
        super.init()
        
        // Configuration
        setLocationManagerDefaultState()
        shouldClearLocations(at: clearLocationsAtCount)
        if hasPermission.value == false {
            requestPermissionsIfNeeded()
        } else {
            startMonitoring()
        }
    }
    
    /// Requests always in use authorisation
    private func requestPermissionsIfNeeded() {
        guard hasPermission.value else {
            locationManager.requestAlwaysAuthorization()
            return
        }
    }
    
    /// Defaults the location manager to report every 0.5 meters in the most accurate way possible
    private func setLocationManagerDefaultState() {
        locationManager.delegate = self
        locationManager.distanceFilter = 0.5
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }
    
    // MARK: Life-cycle/Manual control public methods
    
    /// Begins the monitoring of location updates via the delegate
    func startMonitoring() {
        // Though we could probably get away with calling this directly without the enclosing method, it's a good idea to wrap it in case there are other side effects in the future that we want `startMonitoring` to invoke. The same goes for `stop`, where we could, for instance, end all external subscriptions to the published properties
        locationManager.startUpdatingLocation()
    }
    
    /// Ends the monitoring of location updates
    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
    }
    
    /// Begins monitoring background location changes (more infrequent)
    func startBackgroundMonitoring() {
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    /// Ends monitoring background location changes - switch to frequent
    func stopBackgroundMonitoring() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
}

extension EZCoreLocation: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Update the auth status on change if it's what we're looking for
        hasPermission.send(locationManager.authorizationStatus == .authorizedAlways)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateTo newLocation: CLLocation, from oldLocation: CLLocation) {
        // This method should invoke all the side effects due to occur when a new location is given to us by the system
        let location = Location(location: newLocation, geocoder: geocoder, postalAddressFormatter: postalAddressFormatter)
        locations.append(location)
        sendSpeedUpdates(previousLocation: locations.last, newLocation: location)
    }
}

// MARK: Combine methods

extension EZCoreLocation {
    /// Clears the locations list after a specified value in order to free up memory
    /// - Parameter at: The in-memory storage threshold for location data
    private func shouldClearLocations(at: Int) {
        $locations.sink { [weak self] locations in
            if locations.count == at {
                self?.locations = []
            }
        }.store(in: &cancellables)
    }
    
    /// Sends speed change updates to subscribers
    /// - Parameters:
    ///   - previousLocation: The last location recorded (or measuring the speed differential against)
    ///   - newLocation: The location in which to measure against
    private func sendSpeedUpdates(previousLocation: Location?, newLocation: Location) {
        guard reportSpeedChanges, let previousLocation = previousLocation else { return }
        speedUpdatesSubject.send(previousLocation.changeInSpeed(newLocation: newLocation))
    }
}
