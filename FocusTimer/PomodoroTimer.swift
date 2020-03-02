import Foundation

protocol PomodoroTimerDelegate: AnyObject {
    
    func pomodoroTimer(_ timer: PomodoroTimer, switchedTo mode: PomodoroTimer.Mode)
    func pomodoroTimer(_ timer: PomodoroTimer, updatedTo timeLeft: TimeInterval)
    
}

// MARK: -

class PomodoroTimer: NSObject {
    
    // MARK: - Subtypes
    
    enum Mode: TimeInterval {
        case work = 1500
        case rest = 300
        case idle = 0
    }
    
    // MARK: - Properties
    
    weak var delegate: PomodoroTimerDelegate?
    
    private var mode: Mode = .idle {
        didSet {
            guard oldValue != mode else { return }
            delegate?.pomodoroTimer(self, switchedTo: mode)
        }
    }
    
    private var timer: Timer? {
        didSet {
            guard oldValue != timer else { return }
            oldValue?.invalidate()
        }
    }
    
    private var expiration: Date?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(updateTimer),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    // MARK: - Implementation
    
    func toggle(completionHandler: (() -> Void)? = nil) {
        guard timer == nil else { return }
        mode = (mode != .work) ? .work : .rest
        startTimer(until: Date().addingTimeInterval(mode.rawValue))
        completionHandler?()
    }
    
    func reset(completionHandler: (() -> Void)? = nil) {
        mode = .idle
        stopTimer()
        completionHandler?()
    }
    
    func add(_ time: TimeInterval, completionHandler: (() -> Void)? = nil) {
        guard mode != .idle else { return }
        startTimer(until: max(Date(), expiration ?? Date()).addingTimeInterval(time))
        completionHandler?()
    }
    
    private func startTimer(until date: Date) {
        expiration = date
        timer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(updateTimer),
            userInfo: nil,
            repeats: true
        )
        updateTimer()
    }
    
    private func stopTimer() {
        expiration = nil
        timer?.invalidate()
        timer = nil
    }
    
    @objc
    private func updateTimer() {
        guard let _ = timer, let expiration = expiration else { return }
        let timeLeft = max(0, expiration.timeIntervalSinceNow).rounded(.down)
        delegate?.pomodoroTimer(self, updatedTo: timeLeft)
        if timeLeft == 0 { stopTimer() }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        stopTimer()
    }
    
}
