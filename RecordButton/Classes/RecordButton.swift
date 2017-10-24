import UIKit
import AVFoundation
import PRTween

@objc public enum RecordButtonState : Int {
  case recording, idle, hidden;
}

@IBDesignable
public class RecordButton: UIButton {

  private weak var tweenOperation : PRTweenOperation?
  private var startPlayer : AVAudioPlayer?
  private var stopPlayer : AVAudioPlayer?
  
  private var isRecordingScale : CGFloat = 1.0 {
    didSet {
      setNeedsDisplay()
    }
  }

  @IBInspectable open var buttonColor: UIColor! = .red {
    didSet {
      setNeedsDisplay()
    }
  }

  @IBInspectable open var borderColor: UIColor! = .white {
    didSet {
      circleBorder.borderColor = borderColor.cgColor
      setNeedsDisplay()
    }
  }

  @IBInspectable open var progressColor: UIColor!  = .red {
    didSet {
      gradientMaskLayer.colors = [progressColor.cgColor, progressColor.cgColor]
    }
  }

  /// Closes the circle and hides when the RecordButton is finished
  open var closeWhenFinished: Bool = false

  open var buttonState : RecordButtonState = .idle {
    didSet {
      switch buttonState {
      case .idle:
        self.alpha = 1.0
        currentProgress = 0
        setProgress(0)
        setRecording(false)
      case .recording:
        self.alpha = 1.0
        setRecording(true)
      case .hidden:
        self.alpha = 0
      }
      #if !TARGET_INTERFACE_BUILDER
        //  Stop any running animation
        if let tweenOperation = tweenOperation {
          PRTween.sharedInstance().remove(tweenOperation)
        }

        //  Animate from one state to another (either 0 -> 1 or 1 -> 0)
        let period = PRTweenPeriod.period(withStartValue: isRecordingScale,
                                          endValue: buttonState == .recording ? 0.0 : 1.0,
                                          duration: 0.15) as! PRTweenPeriod

        tweenOperation = PRTween.sharedInstance().add(period, update: { (p) in
          self.isRecordingScale = p!.tweenedValue
        }, completionBlock: nil)
      #else
        //  Don't animate in IB as the changes will not be shown
        isRecordingScale = buttonState == .recording ? 0.0 : 1.0
      #endif
    }

  }

  @IBInspectable open var playSounds: Bool = true

  fileprivate var circleBorder: CALayer!
  fileprivate var progressLayer: CAShapeLayer!
  fileprivate var gradientMaskLayer: CAGradientLayer!
  fileprivate var currentProgress: CGFloat! = 0

  override public init(frame: CGRect) {

    super.init(frame: frame)

    self.addTarget(self, action: #selector(RecordButton.didTouchDown), for: .touchUpInside)

    self.drawButton()

    if playSounds && startPlayer == nil {
      DispatchQueue.main.async { [weak self] in
        let startURL = Bundle(for: RecordButton.self).url(forResource: "StartRecording", withExtension: "aiff")!
        let stopURL = Bundle(for: RecordButton.self).url(forResource: "StopRecording", withExtension: "aiff")!

        self?.startPlayer = try? AVAudioPlayer(contentsOf: startURL)
        self?.startPlayer?.prepareToPlay()
        self?.stopPlayer = try? AVAudioPlayer(contentsOf: stopURL)
        self?.stopPlayer?.prepareToPlay()
      }
    }

  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

    self.addTarget(self, action: #selector(RecordButton.didTouchDown), for: .touchUpInside)

    self.drawButton()

    if playSounds && startPlayer == nil {
      DispatchQueue.main.async { [weak self] in
        let startURL = Bundle(for: RecordButton.self).url(forResource: "StartRecording", withExtension: "aiff")!
        let stopURL = Bundle(for: RecordButton.self).url(forResource: "StopRecording", withExtension: "aiff")!

        self?.startPlayer = try? AVAudioPlayer(contentsOf: startURL)
        self?.startPlayer?.prepareToPlay()
        self?.stopPlayer = try? AVAudioPlayer(contentsOf: stopURL)
        self?.stopPlayer?.prepareToPlay()
      }
    }
  }

  fileprivate func drawButton() {

    self.backgroundColor = UIColor.clear
    let layer = self.layer

    circleBorder = CALayer()
    circleBorder.backgroundColor = UIColor.clear.cgColor
    circleBorder.borderWidth = 1
    circleBorder.borderColor = UIColor.white.cgColor
    circleBorder.bounds = CGRect(x: 0, y: 0, width: self.bounds.size.width - 1.5, height: self.bounds.size.height - 1.5)
    circleBorder.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    circleBorder.position = CGPoint(x: self.bounds.midX,y: self.bounds.midY)
    circleBorder.cornerRadius = self.frame.size.width / 2
    layer.insertSublayer(circleBorder, at: 0)

    let startAngle: CGFloat = CGFloat(Double.pi) + CGFloat(Double.pi / 2)
    let endAngle: CGFloat = CGFloat(Double.pi) * 3 + CGFloat(Double.pi / 2)
    let centerPoint: CGPoint = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
    gradientMaskLayer = self.gradientMask()
    progressLayer = CAShapeLayer()
    progressLayer.path = UIBezierPath(arcCenter: centerPoint, radius: self.frame.size.width / 2 - 2, startAngle: startAngle, endAngle: endAngle, clockwise: true).cgPath
    progressLayer.backgroundColor = UIColor.clear.cgColor
    progressLayer.fillColor = nil
    progressLayer.strokeColor = UIColor.black.cgColor
    progressLayer.lineWidth = 4.0
    progressLayer.strokeStart = 0.0
    progressLayer.strokeEnd = 0.0
    gradientMaskLayer.mask = progressLayer
    layer.insertSublayer(gradientMaskLayer, at: 0)
  }

  override public func draw(_ rect: CGRect) {
    let buttonFrame = bounds
    let pressed = isHighlighted || isTracking

    RecordButtonKit.drawRecordButton(frame: buttonFrame,
                                     recordButtonFrameColor: buttonColor,
                                     recordButtonColor: buttonColor,
                                     isRecording: isRecordingScale,
                                     isPressed: pressed)
  }

  override public var isHighlighted: Bool {
    get {
      return super.isHighlighted
    }
    set {
      super.isHighlighted = isHighlighted
      setNeedsDisplay()
    }
  }

  fileprivate func setRecording(_ recording: Bool) {

    let duration: TimeInterval = 0.15

    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = recording ? 1.0 : 0.88
    scale.toValue = recording ? 0.88 : 1
    scale.duration = duration
    scale.fillMode = kCAFillModeForwards
    scale.isRemovedOnCompletion = false

    let color = CABasicAnimation(keyPath: "backgroundColor")
    color.duration = duration
    color.fillMode = kCAFillModeForwards
    color.isRemovedOnCompletion = false
    color.toValue = recording ? progressColor.cgColor : buttonColor.cgColor

    let circleAnimations = CAAnimationGroup()
    circleAnimations.isRemovedOnCompletion = false
    circleAnimations.fillMode = kCAFillModeForwards
    circleAnimations.duration = duration
    circleAnimations.animations = [scale, color]

    let borderColor: CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
    borderColor.duration = duration
    borderColor.fillMode = kCAFillModeForwards
    borderColor.isRemovedOnCompletion = false
    borderColor.toValue = recording ? self.borderColor.cgColor : buttonColor

    let borderScale = CABasicAnimation(keyPath: "transform.scale")
    borderScale.fromValue = recording ? 1.0 : 0.88
    borderScale.toValue = recording ? 0.88 : 1.0
    borderScale.duration = duration
    borderScale.fillMode = kCAFillModeForwards
    borderScale.isRemovedOnCompletion = false

    let borderAnimations = CAAnimationGroup()
    borderAnimations.isRemovedOnCompletion = false
    borderAnimations.fillMode = kCAFillModeForwards
    borderAnimations.duration = duration
    borderAnimations.animations = [borderColor, borderScale]

    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = recording ? 0.0 : 1.0
    fade.toValue = recording ? 1.0 : 0.0
    fade.duration = duration
    fade.fillMode = kCAFillModeForwards
    fade.isRemovedOnCompletion = false

    progressLayer.add(fade, forKey: "fade")
    circleBorder.add(borderAnimations, forKey: "borderAnimations")

  }

  fileprivate func gradientMask() -> CAGradientLayer {
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = self.bounds
    gradientLayer.locations = [0.0, 1.0]
    let topColor = progressColor
    let bottomColor = progressColor
    gradientLayer.colors = [topColor!.cgColor, bottomColor!.cgColor]
    return gradientLayer
  }

  override open func layoutSubviews() {
    circleBorder.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    circleBorder.position = CGPoint(x: self.bounds.midX,y: self.bounds.midY)
    super.layoutSubviews()
  }

  @objc open func didTouchDown(){
    if(self.buttonState != .recording) {
      self.buttonState = .recording
      if playSounds {
          startPlayer?.play()
      }
    }else{
      if playSounds {
          stopPlayer?.play()
      }
      if(closeWhenFinished) {
        self.setProgress(1)

        UIView.animate(withDuration: 0.3, animations: {
          self.buttonState = .hidden
        }, completion: { completion in
          self.setProgress(0)
          self.currentProgress = 0
        })
      } else {
        self.buttonState = .idle
      }
    }
  }

  /**
   Set the relative length of the circle border to the specified progress

   - parameter newProgress: the relative lenght, a percentage as float.
   */
  open func setProgress(_ newProgress: CGFloat) {
    progressLayer.strokeEnd = newProgress
  }

}
