import Cocoa

extension NSTouchBarItem.Identifier {
    static let viewControllerTouchBarButton = NSTouchBarItem.Identifier(
        "com.topapps.focustimer.viewcontroller.bar.button"
    )
}

extension NSTouchBar.CustomizationIdentifier {
    static let viewControllerTouchBar = NSTouchBar.CustomizationIdentifier(
        "com.topapps.focustimer.viewcontroller.bar"
    )
}

// MARK: -

class ViewController: NSViewController {
    
    // MARK: - Properties
    
    lazy private var timer: PomodoroTimer = {
        let timer = PomodoroTimer()
        timer.delegate = self
        return timer
    }()
    
    private var button: TouchButton?
    
    // MARK: - LifeCycle
    
    override func loadView() {
        self.view = NSView()
    }
    
    override func viewDidLoad() {
        if let item = touchBar?.item(
            forIdentifier: .viewControllerTouchBarButton
        ) {
            NSTouchBarItem.addSystemTrayItem(item)
            DFRElementSetControlStripPresenceForIdentifier(item.identifier, true)
        }
        
        super.viewDidLoad()
    }
    
    // MARK: - TouchBar
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        
        touchBar.delegate = self
        touchBar.customizationIdentifier = .viewControllerTouchBar
        touchBar.defaultItemIdentifiers = [.viewControllerTouchBarButton]
        
        return touchBar
    }
    
}

// MARK: - NSTouchBarDelegate

extension ViewController: NSTouchBarDelegate {
    
    func touchBar(
        _ touchBar: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier
    ) -> NSTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: identifier)
        
        switch identifier {
        case .viewControllerTouchBarButton:
            guard let icon = NSImage(named: NSImage.Name("TouchBarIcon")) else {
                return nil
            }
            
            let touchButton = TouchButton(image: icon, target: nil, action: nil)
            touchButton.delegate = self
            touchButton.title = ""
            
            item.view = touchButton
            button = touchButton
        default:
            return nil
        }
        
        return item
    }
    
}

// MARK: - TouchButtonDelegate

extension ViewController: TouchButtonDelegate {
    
    func touchButtonTap(_ button: TouchButton) {
        if timer.start() {
            NSSound(named: NSSound.Name("Tink"))?.play()
        }
    }
    
    func touchButtonDoubleTap(_ button: TouchButton) {
        if timer.reset() {
            NSSound(named: NSSound.Name("Pop"))?.play()
        }
    }

    func touchButtonTapAndHold(_ button: TouchButton) {
        exit(0)
    }
    
}

// MARK: - PomodoroTimerDelegate

extension ViewController: PomodoroTimerDelegate {
    
    func pomodoroTimer(_ timer: PomodoroTimer, switchedTo newMode: PomodoroTimer.Mode) {
        switch newMode {
        case .rest:
            button?.imagePosition = .noImage
            button?.bezelColor = .systemGreen
        case .work:
            button?.imagePosition = .noImage
            button?.bezelColor = .systemRed
        case .idle:
            button?.imagePosition = .imageOnly
            button?.bezelColor = .clear
            button?.title = ""
        }
    }
    
    func pomodoroTimer(_ timer: PomodoroTimer, updatedTo timeLeft: TimeInterval) {
        if timeLeft == 0 {
            button?.title = "00:00"
            NSSound(named: NSSound.Name("Pop"))?.play()
        } else {
            button?.title = String(format: "%.2i:%.2i", Int(timeLeft) / 60, Int(timeLeft) % 60)
        }
    }
    
}
