import Cocoa
import WebKit

class Menubar {
    static let imageSize = NSSize(width: (1152 * 0.75).rounded(), height: (963 * 0.75).rounded())
    var statusItem: NSStatusItem!
    var webView: WKWebView!
    var menu: NSMenu!
    var cityTextField: NSTextField!

    init() {
        setupStatusItem()
        setupMenu()
        if URL(string: Preferences.imageUrl) == nil {
            resetPreferencesAndCity()
        }
        webView.load(URLRequest(url: URL(string: Preferences.imageUrl)!))
    }

    private func setupMenu() {
        menu = NSMenu()
        menu.title = App.name // perf: prevent going through expensive code-path within appkit
        menu.addItem(setupWebView())
        menu.addItem(setupCityPicker())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    private func setupWebView() -> NSMenuItem {
        webView = WKWebView(frame: .init(origin: .zero, size: Menubar.imageSize))
        let webviewMenuItem = NSMenuItem()
        webviewMenuItem.view = webView
        webviewMenuItem.action = nil
        return webviewMenuItem
    }

    private func setupCityPicker() -> NSMenuItem {
        cityTextField = NSTextField(string: Preferences.city)
//        cityTextField.translatesAutoresizingMaskIntoConstraints = false
        cityTextField.frame.size.width = 300
        cityTextField.preferredMaxLayoutWidth = 300
        cityTextField.sizeToFit()
        let cityLabel = NSTextField(labelWithString: "City")
        cityLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(labelOnClick)))
        let citySubmit = NSButton(title: "Update", target: self, action: #selector(updateButtonOnClick))
        let hStack = NSStackView(views: [cityLabel, cityTextField, citySubmit])
        hStack.spacing = 10
        hStack.edgeInsets = .init(top: 10, left: 14, bottom: 8, right: 14)
        hStack.alignment = .centerY
        hStack.distribution = .equalSpacing
        let cityPicker = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        cityPicker.view = hStack
        return cityPicker
    }

    @objc private func statusItemOnClick() {
        if !webView.isLoading {
            webView.reload()
        }
        statusItem.popUpMenu(App.app.menubar.menu)
    }

    @objc private func updateButtonOnClick() {
        Task { await fetchNewImageUrlAndReloadWebview() }
    }

    @objc private func labelOnClick() {
        cityTextField.becomeFirstResponder()
    }

    func resetPreferencesAndCity() {
        Preferences.remove("city")
        Preferences.remove("imageUrl")
        cityTextField.stringValue = Preferences.city
    }

    private func fetchNewImageUrlAndReloadWebview() async {
        do {
            let city = await cityTextField.stringValue
            if let cityUrl = await fetchMatchingCities(city),
               let imageUrl = await fetchImageUrl(cityUrl) {
                if await webView.url?.absoluteString != imageUrl {
                    await webView.load(URLRequest(url: URL(string: imageUrl)!))
                } else {
                    await webView.reload()
                }
                Preferences.set("city", city)
                Preferences.set("imageUrl", imageUrl)
            } else {
                resetPreferencesAndCity()
            }
        } catch {
            resetPreferencesAndCity()
        }
    }

    private func fetchMatchingCities(_ query: String) async -> String? {
        let searchQuery = query
                .addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let searchUrl = URL(string: "https://www.meteoblue.com/fr/server/search/query3?callback=jQuery36003211564491202923_1706997521805&query=\(searchQuery)&orderBy=&itemsPerPage=10&page=1")!
        let jsonRegex = try! NSRegularExpression(pattern: "[^\\(]+\\((.+)\\)", options: [.dotMatchesLineSeparators])
        let (data, _) = try! await URLSession.shared.data(from: searchUrl)
        let s = String(data: data, encoding: .utf8)!
        let results = jsonRegex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s))!
        let r = Range(results.range(at: 1), in: s)!
        let ss = String(s[r])
        let responseJSON = try! JSONSerialization.jsonObject(with: ss.data(using: .utf8)!) as! [String: Any]
        let url = (responseJSON["results"] as! [[String: Any]]).first?["url"] as? String
        debugPrint(url)
        return url
    }

    private func fetchImageUrl(_ cityUrl: String) async -> String? {
        let url = URL(string: "https://www.meteoblue.com/fr/meteo/semaine/\(cityUrl)")!
        let regex = try! NSRegularExpression(pattern: "https:\\/\\/my\\.meteoblue\\.com\\/images\\/meteogram[^\"']+")
        let (data, _) = try! await URLSession.shared.data(from: url)
        let s = String(data: data, encoding: .utf8)!
        let results = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s))
                .flatMap { Range($0.range, in: s) }
                .map { String(s[$0]).replacingOccurrences(of: "&amp;", with: "&") }
        debugPrint(results)
        return results
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button!.target = self
        statusItem.button!.action = #selector(statusItemOnClick)
        statusItem.button!.sendAction(on: [.leftMouseDown, .rightMouseDown])
        let image = NSImage(systemSymbolName: "cloud.sun.fill", accessibilityDescription: "Weather")!
        image.isTemplate = true
        statusItem.button!.image = image
        statusItem.isVisible = true
        statusItem.button!.imageScaling = .scaleProportionallyUpOrDown
    }
}
