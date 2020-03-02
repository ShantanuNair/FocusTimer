import Cocoa

protocol TouchButtonDelegate: AnyObject {
    
    func tapTouchButton(_ button: TouchButton)
    func doubleTapTouchButton(_ button: TouchButton)
    func holdTouchButton(_ button: TouchButton)
    func swipeLeftTouchButton(_ button: TouchButton)
    func swipeRightTouchButton(_ button: TouchButton)
    
}

// MARK: -

class TouchButton: NSButton {
    
    // MARK: - Properties
    
    weak var delegate: TouchButtonDelegate?
    
    var tapThreshold: TimeInterval = 0.25
    var holdThreshold: TimeInterval = 0.5
    var swipeThreshold: CGFloat = 10
    
    private var beginningTouchTime: TimeInterval = 0
    private var beginningTouchPoint: CGPoint = .zero
    
    private var endingTouchTime: TimeInterval = 0
    private var endingTouchPoint: CGPoint = .zero
    
    private var holdTimer: Timer?
    
    // MARK: - Touches
    
    override func touchesBegan(with event: NSEvent) {
        guard let touch = event.touches(matching: .began, in: self).first else { return }
        
        dropHoldTimer()
        
        beginningTouchTime = Date().timeIntervalSince1970
        beginningTouchPoint = touch.location(in: self)
        
        holdTimer = Timer.scheduledTimer(
            withTimeInterval: holdThreshold,
            repeats: false,
            block: { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.holdTouchButton(self)
                self.dropButton()
            }
        )
        
        super.touchesBegan(with: event)
    }
    
    override func touchesEnded(with event: NSEvent) {
        guard let touch = event.touches(matching: .ended, in: self).first else { return }
        guard let _ = holdTimer else { return }
        
        let lastEndingTouchTime = endingTouchTime
        
        endingTouchTime = Date().timeIntervalSince1970
        endingTouchPoint = touch.location(in: self)
        
        if -swipeThreshold...swipeThreshold ~= endingTouchPoint.x - beginningTouchPoint.x {
            if endingTouchTime - lastEndingTouchTime < tapThreshold {
                delegate?.doubleTapTouchButton(self)
                dropButton()
            } else {
                delegate?.tapTouchButton(self)
                dropHoldTimer()
            }
        } else {
            if endingTouchPoint.x - beginningTouchPoint.x > 0 {
                delegate?.swipeRightTouchButton(self)
            } else {
                delegate?.swipeLeftTouchButton(self)
            }
            dropButton()
        }
        
        super.touchesEnded(with: event)
    }
    
    override func touchesCancelled(with event: NSEvent) {
        dropButton()
        super.touchesCancelled(with: event)
    }
    
    // MARK: - Deinitialization
    
    private func dropHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
    }
    
    private func dropButton() {
        beginningTouchTime = 0
        beginningTouchPoint = .zero
        endingTouchTime = 0
        endingTouchPoint = .zero
        dropHoldTimer()
    }
    
    deinit {
        dropHoldTimer()
    }
    
}
