import Cocoa

class WindowController: NSWindowController {
    
    override func makeTouchBar() -> NSTouchBar? {
        return window?.contentViewController?.makeTouchBar()
    }
    
}
