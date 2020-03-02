import Cocoa

class AppDelegate: NSObject {
    
    private var windowController: NSWindowController?
    
}

// MARK: - NSApplicationDelegate

extension AppDelegate: NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = NSWindowController(
            window: NSWindow(
                contentViewController: ViewController()
            )
        )
        windowController?.showWindow(self)
    }
    
}
