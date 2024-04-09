//
//  EMSliderView.swift
//  HXPhotoPicker
//
//  Created by liukun on 2024/4/9.
//

import UIKit

public enum EMVideoControlEvent {
    case touchDown
    case touchUpInSide
    case changed
}

protocol EMSliderViewDelegate: AnyObject {
    func sliderView(
        _ sliderView: EMSliderView,
        didChangedValue value: CGFloat,
        state: EMVideoControlEvent
    )

    func sliderView(
        _ sliderView: EMSliderView,
        didChangedAt rect: CGRect,
        state: EMVideoControlEvent
    )
}

class EMSliderView: UIView {
    weak var delegate: EMSliderViewDelegate?

    private var trackView: UIView!
    private var progressView: UIView!
    private var bufferView: UIView!
    private var panGR: PhotoPanGestureRecognizer!

    private let thumbScale: CGFloat = 0.7
    private var thumbView: UIImageView!
    private var value: CGFloat = 0
    private var thumbViewFrame: CGRect = .zero

    var cheight: CGFloat {
        18
    }

    var lrMargin: CGFloat {
        showSlider ? 16 : 0
    }


    var pheight: CGFloat {
        showSlider ? 4 : 2
    }

    var showSlider: Bool = false

    var bufferValue: CGFloat = 0 {
        didSet {
            let value: CGFloat
            if bufferValue.isNaN {
                value = 0
            } else {
                value = bufferValue
            }
            bufferView.width = width * value
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        addSubview(progressView)
        addSubview(bufferView)
        addSubview(trackView)
        addSubview(thumbView)
        addGestureRecognizer(panGR)
    }

    private func initViews() {
        panGR = .init(target: self, action: #selector(panGestureRecognizerClick(pan:)))

        let imageSize: CGSize = .init(width: cheight, height: cheight)
        thumbView = UIImageView()
//        thumbView = UIImageView(image: .image(for: .white, havingSize: imageSize, radius: 9))
        thumbView.size = imageSize
        thumbView.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        thumbView.layer.shadowOpacity = 0.3

        trackView = UIView()
        trackView.backgroundColor = UIColor(hexString: "#EC4949")
        trackView.layer.masksToBounds = true
        trackView.layer.cornerRadius = pheight/2
        trackView.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        trackView.layer.shadowOpacity = 0.3

        progressView = UIView()
        progressView.backgroundColor = .white.withAlphaComponent(0.2)
        progressView.layer.masksToBounds = true
        progressView.layer.cornerRadius = pheight/2

        bufferView = UIView()
        bufferView.backgroundColor = .white.withAlphaComponent(0.4)
        bufferView.layer.masksToBounds = true
        bufferView.layer.cornerRadius = pheight/2
    }

    func showMode(slider: Bool){
        showSlider = slider
        updateLayout()
        if slider {
            panGR.isEnabled = true
            trackView.layer.cornerRadius = pheight/2
            progressView.layer.cornerRadius = pheight/2
            bufferView.layer.cornerRadius = pheight/2
        } else {
            panGR.isEnabled = false
            trackView.layer.cornerRadius = 0
            progressView.layer.cornerRadius = 0
            bufferView.layer.cornerRadius = 0
        }
    }

    func setValue(
        _ value: CGFloat,
        isAnimation: Bool
    ) {
        switch panGR.state {
        case .began, .changed, .ended:
            return
        default:
            break
        }
        if value < 0 {
            self.value = 0
        } else if value > 1 {
            self.value = 1
        } else {
            self.value = value
        }
        let currentWidth: CGFloat = self.value * width
        if isAnimation {
            UIView.animate(
                withDuration: 0.1,
                delay: 0,
                options: [
                    .curveLinear,
                    .allowUserInteraction
                ]
            ) {
                self.thumbView.centerX = 5 + (self.width - 10) * self.value
                self.trackView.width = currentWidth
            }
        } else {
            thumbView.centerX = 5 + (width - 10) * value
            trackView.width = currentWidth
        }
    }

    @objc
    private func panGestureRecognizerClick(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            let point: CGPoint = pan.location(in: self)
            let rect: CGRect = .init(
                x: thumbView.x - 20,
                y: thumbView.y - 20,
                width: thumbView.width + 40,
                height: thumbView.height + 40
            )
            if !rect.contains(point) {
                pan.isEnabled = false
                pan.isEnabled = true
                return
            }
            if thumbViewFrame.equalTo(.zero) {
                thumbViewFrame = thumbView.frame
            }
            delegate?.sliderView(self, didChangedValue: value, state: .touchDown)
            delegate?.sliderView(self, didChangedAt: convert(thumbView.frame, to: superview), state: .touchDown)
        case .changed:
            let specifiedPoint: CGPoint = pan.translation(in: self)
            var rect: CGRect = thumbViewFrame
            rect.origin.x += specifiedPoint.x
            if rect.midX < 5 {
                rect.origin.x = -thumbView.width * 0.5 + 5
            }
            if rect.midX > width - 5 {
                rect.origin.x = width - 5 - thumbView.width * 0.5
            }
            value = (rect.midX - 5)/(width - 10)
            trackView.width = width * value
            thumbView.frame = rect
            delegate?.sliderView(self, didChangedValue: value, state: .changed)
            delegate?.sliderView(self, didChangedAt: convert(thumbView.frame, to: superview), state: .changed)
        case .cancelled, .ended, .failed:
            thumbViewFrame = .zero
            delegate?.sliderView(self, didChangedValue: value, state: .touchUpInSide)
            delegate?.sliderView(self, didChangedAt: convert(thumbView.frame, to: superview), state: .touchUpInSide)
        default:
            break
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    private func updateLayout() {
        trackView.frame = CGRect(x: 0, y: (height - pheight) * 0.5, width: width * value, height: pheight)
        progressView.frame = CGRect(x: 0, y: (height - pheight) * 0.5, width: width, height: pheight)
        bufferView.frame = CGRect(x: 0, y: (height - pheight) * 0.5, width: width * bufferValue, height: pheight)
        thumbView.centerY = height * 0.5
        thumbView.centerX = 5 + (width - 10) * value
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
