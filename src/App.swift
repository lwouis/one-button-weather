import Cocoa

var activity = ProcessInfo.processInfo.beginActivity(options: .userInitiatedAllowingIdleSystemSleep,
    reason: "Prevent App Nap to preserve responsiveness")

class App: NSApplication, NSApplicationDelegate {
    static let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    static let id = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String
    static var app: App!
    var menubar: Menubar!

    override init() {
        super.init()
        delegate = self
        App.app = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Preferences.initialize()
        menubar = Menubar()
    }
}
