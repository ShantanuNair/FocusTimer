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
    
    private var timer: DispatchSourceTimer? {
        didSet {
            oldValue?.setEventHandler(handler: nil)
            oldValue?.cancel()
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
    
    // MARK: - Public
    
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
    
    // MARK: - Private
    
    private func startTimer(until date: Date) {
        expiration = date
        timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        timer?.schedule(deadline: .now(), repeating: .seconds(1))
        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.updateTimer()
        }
        timer?.resume()
    }
    
    private func stopTimer() {
        expiration = nil
        timer?.setEventHandler(handler: nil)
        timer?.cancel()
        timer = nil
    }
    
    @objc
    private func updateTimer() {
        guard let _ = timer, let expiration = expiration else { return }
        let timeLeft = max(0, expiration.timeIntervalSinceNow).rounded()
        delegate?.pomodoroTimer(self, updatedTo: timeLeft)
        if timeLeft == 0 { stopTimer() }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        stopTimer()
    }
    
}
