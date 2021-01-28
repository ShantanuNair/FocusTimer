import Foundation

protocol PomodoroTimerDelegate {
    func timer(_ timer: PomodoroTimer, start mode: PomodoroTimer.Mode)
    func timer(_ timer: PomodoroTimer, tick seconds: TimeInterval)
    func timer(_ timer: PomodoroTimer, end mode: PomodoroTimer.Mode)
}

class PomodoroTimer {
    enum Mode: TimeInterval {
        case busy = 1500
        case free = 300
        case idle = 0
    }

    var delegate: PomodoroTimerDelegate?

    private var mode: Mode = .idle {
        didSet {
            guard oldValue != mode else { return }
            isRunning = (mode != .idle)
            left = mode.rawValue
            delegate?.timer(self, start: mode)
        }
    }

    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)

        timer.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))
        timer.setEventHandler { [weak self] in self?.update() }

        return timer
    }()

    private var until = Date.distantPast {
        didSet { update() }
    }

    private var left: TimeInterval {
        get { max(0, until.timeIntervalSinceNow).rounded() }
        set { until = max(Date(), Date().addingTimeInterval(newValue)) }
    }

    private var isRunning = false {
        didSet {
            guard oldValue != isRunning else { return }
            isRunning ? timer.resume() : timer.suspend()
        }
    }

    private var isRerunning = false

    init() {
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
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        timer.setEventHandler { }
        timer.cancel()
    }
}

extension PomodoroTimer {
    @objc
    private func willSleep() {
        isRerunning = isRunning
        isRunning = false
    }

    @objc
    private func didWake() {
        isRunning = isRerunning
        isRerunning = false
    }

    private func update() {
        guard mode != .idle else { return }

        if left == 0 {
            isRunning = false
            delegate?.timer(self, end: mode)
        } else {
            isRunning = true
            delegate?.timer(self, tick: left)
        }
    }
}

extension PomodoroTimer {
    func toggle(completion: (() -> Void)? = nil) {
        guard !isRunning else { return }
        mode = (mode != .busy) ? .busy : .free
        completion?()
    }

    func drop(completion: (() -> Void)? = nil) {
        mode = .idle
        completion?()
    }

    func add(seconds: TimeInterval, completion: (() -> Void)? = nil) {
        guard mode != .idle else { return }
        left += seconds
        completion?()
    }
}
