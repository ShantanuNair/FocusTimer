import Cocoa
import UserNotifications

class PomodoroController: NSViewController {
    private lazy var pomodoroButton: TouchButton = {
        let button = TouchButton(
            image: NSImage(named: NSImage.Name("TouchBarIcon"))!,
            target: nil,
            action: nil
        )
        button.title = ""
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .medium)
        button.delegate = self
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

        timer.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            guard
                let touchBarItem = self?.touchBar?.item(forIdentifier: .pomodoroButton)
            else {
                exit(0)
            }
            NSTouchBarItem.addSystemTrayItem(touchBarItem)
            DFRElementSetControlStripPresenceForIdentifier(touchBarItem.identifier, true)
        }

        return timer
    }()

    private let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    private let notifier = FeedbackNotifier()

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(willSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        controlStripTimer.resume()
    }

    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.defaultItemIdentifiers = [.pomodoroButton]
        touchBar.delegate = self
        return touchBar
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        controlStripTimer.setEventHandler { }
        controlStripTimer.cancel()
    }
}

extension PomodoroController {
    @objc
    private func willSleep() {
        controlStripTimer.suspend()
    }

    @objc
    private func didWake() {
        controlStripTimer.resume()
    }
}

extension PomodoroController: NSTouchBarDelegate {
    func touchBar(
        _ touchBar: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier
    ) -> NSTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: identifier)
        switch identifier {
        case .pomodoroButton:
            item.view = pomodoroButton
        default:
            break
        }
        return item
    }
}

extension PomodoroController: PomodoroTimerDelegate {
    func timer(_ timer: PomodoroTimer, start mode: PomodoroTimer.Mode) {
        switch mode {
        case .free:
            pomodoroButton.imagePosition = .noImage
            pomodoroButton.bezelColor = .systemGreen
        case .busy:
            pomodoroButton.imagePosition = .noImage
            pomodoroButton.bezelColor = .systemRed
        case .idle:
            pomodoroButton.imagePosition = .imageOnly
            pomodoroButton.bezelColor = .clear
            pomodoroButton.title = ""
        }
    }

    func timer(_ timer: PomodoroTimer, tick seconds: TimeInterval) {
        pomodoroButton.title = (formatter.string(from: seconds) ?? "")
    }

    func timer(_ timer: PomodoroTimer, end mode: PomodoroTimer.Mode) {
        pomodoroButton.title = "00:00"
        notifier.handle(event: .stop(mode))
    }
}

extension PomodoroController: TouchButtonDelegate {
    func tapTouchButton(_ button: TouchButton) {
        pomodoroTimer.toggle() { [weak self] in self?.notifier.handle(event: .start) }
    }

    func doubleTapTouchButton(_ button: TouchButton) {
        pomodoroTimer.drop() { [weak self] in self?.notifier.handle(event: .drop) }
    }

    func holdTouchButton(_ button: TouchButton) {
        exit(0)
    }

    func swipeLeftTouchButton(_ button: TouchButton) {
        pomodoroTimer.add(seconds: -300) { [weak self] in self?.notifier.handle(event: .swipe) }
    }

    func swipeRightTouchButton(_ button: TouchButton) {
        pomodoroTimer.add(seconds: 300) { [weak self] in self?.notifier.handle(event: .swipe) }
    }
}

extension NSTouchBarItem.Identifier {
    static let pomodoroButton = NSTouchBarItem.Identifier(
        "com.aloshev.focustimer.pomodoroButton"
    )
}
