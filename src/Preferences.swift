import Cocoa

let defaults = UserDefaults.standard

class Preferences {
    // default values
    static var defaultValues: [String: String] = [
        "city": "Paris",
        "imageUrl": "https://my.meteoblue.com/images/meteogram?temperature_units=C&wind_units=kmh&precipitation_units=mm&winddirection=3char&iso2=fr&lat=48.8534&lon=2.3488&asl=42&tz=Europe%2FParis&apikey=jhMJTOUVRNvs25m4&lang=en&location_name=Paris&windspeed_units=kmh&sig=8c6b22716cd9700e529061870d5bf1a4",
    ]

    // persisted values
    static var city: String { defaults.string("city") }
    static var imageUrl: String { defaults.string("imageUrl") }

    static func initialize() {
        registerDefaults()
    }

    static func registerDefaults() {
        defaults.register(defaults: defaultValues)
    }

    static func getString(_ key: String) -> String? {
        defaults.string(forKey: key)
    }

    static func set<T>(_ key: String, _ value: T) where T: Encodable {
        defaults.set(value, forKey: key)
        UserDefaults.cache.removeValue(forKey: key)
    }

    static func remove(_ key: String) {
        defaults.removeObject(forKey: key)
        UserDefaults.cache.removeValue(forKey: key)
    }
}


extension UserDefaults {
    static var cache = [String: String]()

    func string(_ key: String) -> String {
        if let c = UserDefaults.cache[key] {
            return c
        }
        let v = defaults.string(forKey: key)!
        UserDefaults.cache[key] = v
        return v
    }
}
