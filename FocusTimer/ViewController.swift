import Cocoa

extension NSTouchBarItem.Identifier {
    
    static let viewControllerButton = NSTouchBarItem.Identifier(
        "com.topapps.focustimer.viewcontroller.button"
    )
    
}

extension NSSound {
    
    static func play(named name: String) {
        // NSSound(named:) returns non-unique instances for the same names
        (NSSound(named: NSSound.Name(name))?.copy() as? NSSound)?.play()
    }
    
}

// MARK: -

class ViewController: NSViewController {
    
    // MARK: - Properties
    
    lazy private var button: TouchButton = {
        guard let icon = NSImage(named: NSImage.Name("TouchBarIcon")) else {
            preconditionFailure("No icon")
        }
        let button = TouchButton(image: icon, target: nil, action: nil)
        button.delegate = self
        button.title = ""
        return button
    }()
    
    lazy private var pomodoroTimer: PomodoroTimer = {
        let timer = PomodoroTimer()
        timer.delegate = self
        return timer
    }()
    
    // Some user activities (e.g. video watching) can displace the button out of the control strip
    lazy private var controlStripTimer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler { [weak self] in
            guard
                let touchBarItem = self?.touchBar?.item(forIdentifier: .viewControllerButton)
            else {
                exit(0)
            }
            NSTouchBarItem.addSystemTrayItem(touchBarItem)
            DFRElementSetControlStripPresenceForIdentifier(touchBarItem.identifier, true)
        }
        return timer
    }()
    
    // MARK: - Life Cycle
    
    override func loadView() {
        self.view = NSView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        controlStripTimer.resume()
    }
    
    // MARK: - Touch Bar
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.defaultItemIdentifiers = [.viewControllerButton]
        touchBar.delegate = self
        return touchBar
    }
    
    // MARK: - Deinitialization
    
    deinit {
        controlStripTimer.setEventHandler(handler: nil)
        controlStripTimer.cancel()
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
        case .viewControllerButton:
            item.view = button
        default:
            break
        }
        return item
    }
    
}

// MARK: - PomodoroTimerDelegate

extension ViewController: PomodoroTimerDelegate {
    
    func pomodoroTimer(_ timer: PomodoroTimer, switchedTo mode: PomodoroTimer.Mode) {
        switch mode {
        case .rest:
            button.imagePosition = .noImage
            button.bezelColor = .systemGreen
        case .work:
            button.imagePosition = .noImage
            button.bezelColor = .systemRed
        case .idle:
            button.imagePosition = .imageOnly
            button.bezelColor = .clear
            button.title = ""
        }
    }
    
    func pomodoroTimer(_ timer: PomodoroTimer, updatedTo time: TimeInterval) {
        if time == 0 { NSSound.play(named: "Pop") }
        button.title = String(format: "%.2i:%.2i", Int(time) / 60, Int(time) % 60)
    }
    
}

// MARK: - TouchButtonDelegate

extension ViewController: TouchButtonDelegate {
    
    func tapTouchButton(_ button: TouchButton) {
        pomodoroTimer.toggle { NSSound.play(named: "Tink") }
    }
    
    func doubleTapTouchButton(_ button: TouchButton) {
        pomodoroTimer.reset { NSSound.play(named: "Pop") }
    }
    
    func holdTouchButton(_ button: TouchButton) {
        exit(0)
    }
    
    func swipeLeftTouchButton(_ button: TouchButton) {
        pomodoroTimer.add(-300) { NSSound.play(named: "Morse") }
    }
    
    func swipeRightTouchButton(_ button: TouchButton) {
        pomodoroTimer.add(300) { NSSound.play(named: "Morse") }
    }
    
}
