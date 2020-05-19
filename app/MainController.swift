import Cocoa
import WebKit

let TENOR_BASE_URL = "https://tenor.com/"
let TENOR_VIEW_URL = "https://tenor.com/view/"
let TENOR_FAVICON_URL = "https://tenor.com/favicon.ico"

let MARKDOWN_PREFIX = "![]("
let MARKDOWN_SUFFIX = ")"

let STATUS_ITEM_TITLE = "Tenor Anywhere"
let COPY_URL_MENU_ITEM_TITLE = "Copy GIF URL"
let COPY_MARKDOWN_MENU_ITEM_TITLE = "Copy GIF URL (GitHub Markdown)"
let QUIT_MENU_ITEM_TITLE = "Quit"

let URL_KEY_PATH = "URL"

func gifURL(url: URL?) -> String? {
    guard let string = url?.absoluteString else { return nil }
    if (!string.starts(with: TENOR_VIEW_URL)) { return nil }
    return string + ".gif";
}

func gifMarkdown(url: URL?) -> String? {
    guard let url = gifURL(url: url) else { return nil }
    return MARKDOWN_PREFIX + url + MARKDOWN_SUFFIX
}

func getTenorImage() -> NSImage? {
    guard let path = Bundle.main.pathForImageResource("tenor") else { return nil }
    guard let image = NSImage.init(byReferencingFile: path) else { return nil }
    image.isTemplate = true
    image.size = NSSize(width: 24, height: 24)
    return image;
}

func getiPhoneWebView() -> WKWebView {
    let webViewRect = NSMakeRect(0, 0, 360, 640)
    let webViewConf = WKWebViewConfiguration.init()
    webViewConf.preferences.plugInsEnabled = true
    let webView = WKWebView.init(frame: webViewRect, configuration: webViewConf)
    return webView
}

func setPasteboard(string: String?) {
    guard let string = string else { NSSound.beep(); return }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(string, forType: .string)
}

class MainController: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    
    class func run() {
        let app = NSApplication.shared
        let mainController = MainController.init()
        app.delegate = mainController
        app.run()
    }
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let statusMenu = NSMenu.init()
    let url = URL.init(string: TENOR_BASE_URL)!
    let webView = getiPhoneWebView()
    let webViewItem = NSMenuItem.init()
    let copyURLItem = NSMenuItem.init()
    let copyMarkdownItem = NSMenuItem.init()
    let quitItem = NSMenuItem.init()
    
    override init() {
        super.init()
        setLoginItem(enabled: true)
        setupStatusItem()
        setupStatusMenu()
        setupWebView()
    }
    
    func setupStatusItem() {
        let tenorImage = getTenorImage()
        if let tenorImage = tenorImage {
            statusItem.button?.image = tenorImage
        }
        else {
            statusItem.button?.title = STATUS_ITEM_TITLE
        }
        statusItem.button?.target = self
        statusItem.button?.action = #selector(MainController.statusItemClicked(_:))
        statusItem.button?.highlight(false)
    }
    
    func setupStatusMenu() {
        webViewItem.view = webView
        copyURLItem.title = COPY_URL_MENU_ITEM_TITLE
        copyURLItem.target = self
        copyURLItem.action = #selector(MainController.copyURL(_:))
        copyMarkdownItem.title = COPY_MARKDOWN_MENU_ITEM_TITLE
        copyMarkdownItem.target = self
        copyMarkdownItem.action = #selector(MainController.copyMarkdown(_:))
        quitItem.title = QUIT_MENU_ITEM_TITLE
        quitItem.target = self
        quitItem.action = #selector(MainController.quit(_:))
        statusMenu.addItem(webViewItem)
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(copyURLItem)
        statusMenu.addItem(copyMarkdownItem)
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(quitItem)
    }
    
    func setupWebView() {
        webView.navigationDelegate = self
        webView.addObserver(self, forKeyPath: URL_KEY_PATH, options: .new, context: nil)
        reloadWebView()
    }
    
    func reloadWebView() {
        webView.load(URLRequest.init(url: url))
    }
    
    func popUpStatusItem() {
        statusItem.menu = statusMenu
        statusItem.button?.performClick(self)
        statusItem.menu = nil
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        popUpStatusItem()
    }
    
    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(MainController.copyURL(_:)),
             #selector(MainController.copyMarkdown(_:)):
            return gifURL(url: webView.url) != nil
        default:
            return true
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        let enabled = gifURL(url: webView.url) != nil
        copyURLItem.isEnabled = enabled
        copyMarkdownItem.isEnabled = enabled
    }
    
    @objc func statusItemClicked(_ sender: AnyObject) {
        NSApp.isActive ?
            popUpStatusItem() : NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func copyURL(_ sender: AnyObject) {
        setPasteboard(string: gifURL(url: webView.url))
    }
    
    @objc func copyMarkdown(_ sender: AnyObject) {
        setPasteboard(string: gifMarkdown(url: webView.url))
    }
    
    @objc func quit(_ sender: AnyObject) {
        setLoginItem(enabled: false)
        NSApp.terminate(sender)
    }
    
}
