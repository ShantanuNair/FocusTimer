import Foundation

protocol PomodoroTimerDelegate: AnyObject {
    func pomodoroTimer(_ timer: PomodoroTimer, switchedTo mode: PomodoroTimer.Mode)
    func pomodoroTimer(_ timer: PomodoroTimer, updatedTo seconds: Int)
}

class PomodoroTimer: NSObject {
    enum Mode: TimeInterval {
        case work = 1500
        case rest = 300
        case idle = 0
    }

    weak var delegate: PomodoroTimerDelegate?

    private var mode: Mode = .idle {
        didSet {
            guard oldValue != mode else { return }

            isTimerOn = mode != .idle
            timeLeft = mode.rawValue

            delegate?.pomodoroTimer(self, switchedTo: mode)
        }
    }

    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.updateTimeState()
        }
        return timer
    }()

    private var isTimerOn = false {
        didSet {
            guard oldValue != isTimerOn else { return }
            if isTimerOn { timer.resume() } else { timer.suspend() }
        }
    }

    private var lastDate = Date(timeIntervalSince1970: 0) {
        didSet {
            updateTimeState()
        }
    }

    private var timeLeft: TimeInterval {
        get {
            max(0, lastDate.timeIntervalSinceNow).rounded()
        }
        set {
            lastDate = max(Date(), Date().addingTimeInterval(newValue))
        }
    }

    override init() {
        super.init()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(updateTimeState),
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
    private func updateTimeState() {
        guard mode != .idle else { return }
        isTimerOn = timeLeft != 0
        delegate?.pomodoroTimer(self, updatedTo: Int(timeLeft))
    }
}

extension PomodoroTimer {
    func toggle(completionHandler: (() -> Void)? = nil) {
        guard !isTimerOn else { return }
        mode = mode != .work ? .work : .rest
        completionHandler?()
    }

    func reset(completionHandler: (() -> Void)? = nil) {
        mode = .idle
        completionHandler?()
    }

    func add(_ time: TimeInterval, completionHandler: (() -> Void)? = nil) {
        guard mode != .idle else { return }
        timeLeft += time
        completionHandler?()
    }
}
