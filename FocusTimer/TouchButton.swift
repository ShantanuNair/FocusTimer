import Cocoa

protocol TouchButtonDelegate: AnyObject {
    func tapTouchButton(_ button: TouchButton)
    func doubleTapTouchButton(_ button: TouchButton)
    func holdTouchButton(_ button: TouchButton)
    func swipeLeftTouchButton(_ button: TouchButton)
    func swipeRightTouchButton(_ button: TouchButton)
}

class TouchButton: NSButton {
    weak var delegate: TouchButtonDelegate?

    var tapThreshold: TimeInterval = 0.25
    var holdThreshold: TimeInterval = 0.5
    var swipeThreshold: CGFloat = 10

    private var touchPoint: CGPoint = .zero
    private var touchTime: TimeInterval = 0

    private lazy var holdTimer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.delegate?.holdTouchButton(self)
            self.resetButtonState()
        }
        return timer
    }()

    private var isHoldTimerOn = false {
        didSet {
            guard oldValue != isHoldTimerOn else { return }
            if isHoldTimerOn { holdTimer.resume() } else { holdTimer.suspend() }
        }
    }

    deinit {
        holdTimer.setEventHandler { }
        holdTimer.cancel()
    }
}

extension TouchButton {
    override func touchesBegan(with event: NSEvent) {
        guard let touch = event.touches(matching: .began, in: self).first else { return }

        touchPoint = touch.location(in: self)
        restartHoldTimer()

        super.touchesBegan(with: event)
    }

    override func touchesEnded(with event: NSEvent) {
        guard let touch = event.touches(matching: .ended, in: self).first else { return }

        isHoldTimerOn = false

        let prevTouchTime = touchTime
        let prevTouchPoint = touchPoint

        touchTime = Date().timeIntervalSince1970
        touchPoint = touch.location(in: self)

        let distance = touchPoint.x - prevTouchPoint.x
        let period = touchTime - prevTouchTime

        switch (distance, period) {
        case (...(-swipeThreshold), _):
            delegate?.swipeLeftTouchButton(self)
            resetButtonState()
        case (swipeThreshold..., _):
            delegate?.swipeRightTouchButton(self)
            resetButtonState()
        case (_, ...tapThreshold):
            delegate?.doubleTapTouchButton(self)
            resetButtonState()
        case (_, tapThreshold...):
            delegate?.tapTouchButton(self)
        default:
            break
        }

        super.touchesEnded(with: event)
    }

    override func touchesCancelled(with event: NSEvent) {
        resetButtonState()
        super.touchesCancelled(with: event)
    }
}

extension TouchButton {
    private func restartHoldTimer() {
        isHoldTimerOn = false
        holdTimer.schedule(deadline: .now() + holdThreshold)
        isHoldTimerOn = true
    }

    private func resetButtonState() {
        touchPoint = .zero
        touchTime = 0
        isHoldTimerOn = false
    }
}
