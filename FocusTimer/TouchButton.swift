import Cocoa

protocol TouchButtonDelegate: AnyObject {
    
    func touchButtonTap(_ button: TouchButton)
    func touchButtonDoubleTap(_ button: TouchButton)
    func touchButtonTapAndHold(_ button: TouchButton)
    
}

// MARK: -

class TouchButton: NSButton {

    // MARK: - Properties

    weak var delegate: TouchButtonDelegate?

    private var timer: Timer?
    private let intervals = (
        doubleTap: 0.25,
        tapAndHold: 0.5
    )

    private var lastTapDate: Date?
    private var touchBeganTime: TimeInterval = 0

    // MARK: - Actions

    @objc
    private func tapAndHold(_ object: Any) {
        delegate?.touchButtonTapAndHold(self)
    }

    // MARK: - Touches

    override func touchesBegan(with event: NSEvent) {
        if event.touches(matching: .began, in: self).first?.type == .direct {
            touchBeganTime = Date().timeIntervalSince1970
            timer = Timer.scheduledTimer(
                timeInterval: intervals.tapAndHold,
                target: self,
                selector: #selector(tapAndHold),
                userInfo: self,
                repeats: false
            )
        }
        super.touchesBegan(with: event)
    }

    override func touchesEnded(with event: NSEvent) {
        for touch in event.touches(matching: .ended, in: self) where touch.type == .direct {
            if Date().timeIntervalSince1970 - touchBeganTime >= intervals.tapAndHold {
                // Tap and Hold
                // delegate will be called by timer
                break
            } else if let lastTapDate = lastTapDate,
                -lastTapDate.timeIntervalSinceNow <= intervals.doubleTap {
                delegate?.touchButtonDoubleTap(self)
                self.lastTapDate = nil
            } else {
                delegate?.touchButtonTap(self)
                self.lastTapDate = Date()
            }
        }

        timer?.invalidate()
        timer = nil

        super.touchesEnded(with: event)
    }

    override func touchesCancelled(with event: NSEvent) {
        timer?.invalidate()
        timer = nil

        super.touchesCancelled(with: event)
    }

}
