//
//  EMVideoPlaySliderView.swift
//  HXPhotoPicker
//
//  Created by liukun on 2024/4/9.
//

import UIKit

protocol EMVideoPlaySliderViewDelegate: AnyObject {
    func videoSliderView(
        _ videoSliderView: EMVideoPlaySliderView,
        didChangedPlayDuration duration: CGFloat,
        state: EMVideoControlEvent
    )
    func videoSliderView(
        _ videoSliderView: EMVideoPlaySliderView,
        didPlayButtonClick isSelected: Bool
    )
}

extension EMVideoPlaySliderViewDelegate {
    func videoSliderView(
        _ videoSliderView: EMVideoPlaySliderView,
        didChangedPlayDuration duration: CGFloat,
        state: VideoControlEvent
    ) {}
    func videoSliderView(
        _ videoSliderView: EMVideoPlaySliderView,
        didPlayButtonClick isSelected: Bool
    ) {}
}

extension String {
    var prefixSep: String {
        " / " + self
    }
}

public class EMVideoPlaySliderView: UIView, EMSliderViewDelegate {
    weak var delegate: EMVideoPlaySliderViewDelegate?

    private var sliderView: EMSliderView!
    private var currentTimeLb: UILabel!
    private var totalTimeLb: UILabel!

    private var isSliderChanged: Bool = false

    var playDuration: CGFloat = 0
    var videoDuration: CGFloat = 0 {
        didSet {
            totalTimeLb.text = PhotoTools.transformVideoDurationToString(duration: TimeInterval(videoDuration)).prefixSep
            currentTimeLb.text = "00:00"
            currentTimeLb.width = currentTimeLb.textWidth
            totalTimeLb.width = totalTimeLb.textWidth
        }
    }

    var bufferDuration: CGFloat = 0 {
        didSet {
            let duration: CGFloat
            if bufferDuration.isNaN {
                duration = 0
            } else {
                duration = bufferDuration
            }
            if videoDuration == 0 {
                sliderView.bufferValue = 0
            } else {
                sliderView.bufferValue = duration / videoDuration
            }
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: .zero)
        initViews()
        addSubview(sliderView)
        addSubview(currentTimeLb)
        addSubview(totalTimeLb)
    }

    private func initViews() {
        sliderView = EMSliderView()
        sliderView.delegate = self

        currentTimeLb = UILabel(frame: CGRect(x: 0, y: 0, width: 65, height: 22))
        currentTimeLb.text = "--:--"
        currentTimeLb.textColor = .white
        currentTimeLb.font = .mediumPingFang(ofSize: 20)
        currentTimeLb.layer.shadowColor = UIColor.black.withAlphaComponent(0.7).cgColor
        currentTimeLb.layer.shadowOpacity = 0.5
        currentTimeLb.layer.shadowOffset = .init(width: -1, height: 1)

        totalTimeLb = UILabel(frame: CGRect(x: 0, y: 0, width: 65, height: 22))
        totalTimeLb.text = "--:--".prefixSep
        totalTimeLb.textColor = .white
        totalTimeLb.font = .mediumPingFang(ofSize: 20)
        totalTimeLb.layer.shadowColor = UIColor.black.withAlphaComponent(0.7).cgColor
        totalTimeLb.layer.shadowOpacity = 0.5
        totalTimeLb.layer.shadowOffset = .init(width: -1, height: 1)

        currentTimeLb.textAlignment = .center
        totalTimeLb.textAlignment = .center
    }

    func showSliderView(show: Bool) {
        sliderView.showMode(slider: show)
        updateLayout()
        if show {
            currentTimeLb.isHidden = false
            totalTimeLb.isHidden = false
        } else {
            currentTimeLb.isHidden = true
            totalTimeLb.isHidden = true
        }
    }

    func setPlayDuration(_ duration: CGFloat, isAnimation: Bool) {
        playDuration = duration
        let currentPlayTime: String = PhotoTools.transformVideoDurationToString(duration: TimeInterval(playDuration))
        currentTimeLb.text = currentPlayTime
        let value: CGFloat
        if videoDuration == 0 {
            value = 0
        } else {
            value = playDuration / videoDuration
        }
        sliderView.setValue(value, isAnimation: isAnimation)
    }

    func sliderView(_ sliderView: EMSliderView, didChangedValue value: CGFloat, state: EMVideoControlEvent) {
        delegate?.videoSliderView(self, didChangedPlayDuration: videoDuration * value, state: state)
    }

    func sliderView(_ sliderView: EMSliderView, didChangedAt rect: CGRect, state: EMVideoControlEvent) {}

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    private func updateLayout() {
        let hm = (sliderView.cheight + sliderView.pheight) / 2
        sliderView.frame = .init(x: sliderView.lrMargin, y: height - hm, width: width - sliderView.lrMargin * 2, height: sliderView.cheight)

        let tw = currentTimeLb.width + totalTimeLb.width
        currentTimeLb.x = (width - tw) / 2.0
        totalTimeLb.x = currentTimeLb.frame.maxX
        currentTimeLb.y = 0
        totalTimeLb.y = 0
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
