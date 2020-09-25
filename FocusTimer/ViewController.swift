import AVFoundation
import Cocoa

class ViewController: NSViewController {
    private lazy var pomodoroTouchButton: TouchButton = {
        guard let icon = NSImage(named: NSImage.Name("TouchBarIcon")) else {
            preconditionFailure("No icon")
        }
        let button = TouchButton(image: icon, target: nil, action: nil)
        button.delegate = self
        button.title = ""
        return button
    }()

    private lazy var pomodoroTimer: PomodoroTimer = {
        let timer = PomodoroTimer()
        timer.delegate = self
        return timer
    }()

    // Some user activities (e.g. video watching) can displace the button out of the control strip
    private lazy var controlStripTimer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: DispatchQueue.main)
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

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        controlStripTimer.resume()
    }

    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.defaultItemIdentifiers = [.viewControllerButton]
        touchBar.delegate = self
        return touchBar
    }

    deinit {
        controlStripTimer.setEventHandler(handler: nil)
        controlStripTimer.cancel()
    }
}

extension ViewController: NSTouchBarDelegate {
    func touchBar(
        _ touchBar: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier
    ) -> NSTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: identifier)
        switch identifier {
        case .viewControllerButton:
            item.view = pomodoroTouchButton
        default:
            break
        }
        return item
    }
}

extension ViewController: PomodoroTimerDelegate {
    func pomodoroTimer(_ timer: PomodoroTimer, switchedTo mode: PomodoroTimer.Mode) {
        switch mode {
        case .rest:
            pomodoroTouchButton.imagePosition = .noImage
            pomodoroTouchButton.bezelColor = .systemGreen
        case .work:
            pomodoroTouchButton.imagePosition = .noImage
            pomodoroTouchButton.bezelColor = .systemRed
        case .idle:
            pomodoroTouchButton.imagePosition = .imageOnly
            pomodoroTouchButton.bezelColor = .clear
            pomodoroTouchButton.title = ""
        }
    }

    func pomodoroTimer(_ timer: PomodoroTimer, updatedTo seconds: Int) {
        if seconds == 0 { NSSound.play(named: "Pop") }
        pomodoroTouchButton.title = String(format: "%.2i:%.2i", seconds / 60, seconds % 60)
    }
}

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

extension NSSound {
    static func play(named name: String) {
        guard
            let path = Bundle.main.path(
                forResource: "\(name)", ofType: "aiff", inDirectory: "Sounds"
            ),
            let sound = NSSound(contentsOfFile: path, byReference: true)
        else { return }

        sound.play()
    }
}

extension NSTouchBarItem.Identifier {
    static let viewControllerButton = NSTouchBarItem.Identifier(
        "com.aloshev.focustimer.viewcontroller.button"
    )
}
