import Cocoa

class AppDelegate: NSObject {
    
    private var windowController: WindowController?
    
}

// MARK: - NSApplicationDelegate

extension AppDelegate: NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = WindowController(
            window: NSWindow(
                contentViewController: ViewController()
            )
        )
        windowController?.showWindow(self)
    }
    
}
