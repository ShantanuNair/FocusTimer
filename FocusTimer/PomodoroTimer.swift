import Foundation

protocol PomodoroTimerDelegate: AnyObject {

    func pomodoroTimer(_ timer: PomodoroTimer, switchedTo newMode: PomodoroTimer.Mode)
    func pomodoroTimer(_ timer: PomodoroTimer, updatedTo timeLeft: TimeInterval)
    
}

// MARK: -

class PomodoroTimer: NSObject {
    
    // MARK: - Subtypes
    
    enum Mode {
        case work
        case rest
        case idle
        
        var time: TimeInterval {
            switch self {
            case .idle:
                return 0
            case .rest:
                return 5 * 60
            case .work:
                return 25 * 60
            }
        }
    }
    
    // MARK: - Properties
    
    weak var delegate: PomodoroTimerDelegate?
    
    private var mode: Mode = .idle {
        didSet {
            let newValue = mode
            
            guard newValue != oldValue else { return }
            
            dropTimer()
            
            delegate?.pomodoroTimer(self, switchedTo: newValue)
            
            guard newValue != .idle else { return }
            
            delegate?.pomodoroTimer(self, updatedTo: mode.time)
            
            timer = Timer(
                timeInterval: 0.1,
                target: self,
                selector: #selector(fireTimer(_:)),
                userInfo: Date(timeIntervalSinceNow: mode.time),
                repeats: true
            )
            
            RunLoop.current.add(timer!, forMode: .commonModes)
        }
    }
    
    private var timer: Timer?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(fireTimer(_:)),
            name: NSWorkspace.didWakeNotification,
            object: timer
        )
    }
    
    // MARK: - Implementation
    
    @discardableResult
    func start() -> Bool {
        guard timer == nil || !timer!.isValid else { return false }
        
        switch mode {
        case .idle, .rest:
            mode = .work
        case .work:
            mode = .rest
        }
        
        return true
    }
    
    @discardableResult
    func reset() -> Bool {
        mode = .idle
        return true
    }
    
    @objc
    private func fireTimer(_ timer: Timer?) {
        guard let timer = timer,
              let timeLeft = (timer.userInfo as? Date)?.timeIntervalSinceNow
        else {
            return
        }

        if timeLeft > 1 {
            delegate?.pomodoroTimer(self, updatedTo: timeLeft)
        } else {
            dropTimer()
            delegate?.pomodoroTimer(self, updatedTo: 0)
        }
    }
    
    private func dropTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Deinit
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        dropTimer()
    }
    
}
