//
//  PreviewVideoControlViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/6/30.
//

import AVFoundation
import UIKit

open class PreviewVideoControlViewCell: PreviewVideoViewCell, EMVideoPlaySliderViewDelegate {
//    public var maskLayer: CAGradientLayer!
//    public var maskBackgroundView: UIView!
    public var sliderView: EMVideoPlaySliderView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        sliderView = EMVideoPlaySliderView()
        sliderView.delegate = self

        contentView.addSubview(sliderView)
    }

    deinit {
        debugPrint("\(Self.self) is deinit")
    }

    override public func config(videoView: PhotoPreviewContentVideoView? = nil) {
        super.config(videoView: videoView)
//        maskBackgroundView = UIView()
//        maskBackgroundView.alpha = 0
//        maskLayer = PhotoTools.getGradientShadowLayer(false)
//        maskBackgroundView.layer.addSublayer(maskLayer)
//        contentView.addSubview(maskBackgroundView)

        updateScrollContentView()
        hideToolView()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        scrollContentView?.removeFromSuperview()
        scrollContentView = nil
    }

    private func updateScrollContentView() {
        guard let scrollContentView, let currentItem = scrollContentView.videoView.player.currentItem else { return }
        videoView(scrollContentView.videoView, readyToPlay: CGFloat(CMTimeGetSeconds(currentItem.duration)))
        videoView(scrollContentView.videoView, isPlaybackLikelyToKeepUp: currentItem.isPlaybackLikelyToKeepUp)
    }

    override public func videoReadyToPlay(duration: CGFloat) {
        sliderView.videoDuration = duration
    }

    override public func videoDidChangedBuffer(duration: CGFloat) {
        sliderView.bufferDuration = duration
    }

    override public func videoDidChangedPlayTime(duration: CGFloat, isAnimation: Bool) {
        sliderView.setPlayDuration(duration, isAnimation: isAnimation)
    }

//    override public func videoDidPlay() {
////        sliderView.isPlaying = true
//    }
//
//    override public func videoDidPause() {
////        sliderView.isPlaying = false
//    }

    override public func showToolView() {
        isShowSlider = true
        sliderView.showSliderView(show: true)
        showPlayButton(show: true)
        showMask()
        resetShowToolTask()
    }

    override public func hideToolView() {
        isShowSlider = false
        sliderView.showSliderView(show: false)
        showPlayButton(show: false)
        hideMask()
    }

    override public func showMask() {
//        if maskBackgroundView.alpha == 0 {
//            maskBackgroundView.isHidden = false
//            UIView.animate(withDuration: 0.15) {
//                self.maskBackgroundView.alpha = 1
//            }
//        }
    }

    override public func hideMask() {
//        if maskBackgroundView.alpha == 1 {
//            UIView.animate(withDuration: 0.15) {
//                self.maskBackgroundView.alpha = 0
//            } completion: { isFinished in
//                if isFinished && self.maskBackgroundView.alpha == 0 {
//                    self.maskBackgroundView.isHidden = true
//                }
//            }
//        }
    }

    func videoSliderView(
        _ videoSliderView: EMVideoPlaySliderView,
        didChangedPlayDuration duration: CGFloat,
        state: EMVideoControlEvent
    ) {
        seek(to: TimeInterval(duration), isPlay: state == .touchUpInSide)
    }

    func videoSliderView(_ videoSliderView: EMVideoPlaySliderView, didPlayButtonClick isSelected: Bool) {
        if isSelected {
            playVideo()
        } else {
            pauseVideo()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        if let scrollContentView {
            sliderView.frame = CGRect(
                x: 0,
                y: scrollContentView.frame.maxY - 44,
                width: width,
                height: 44
            )
        } else {
            sliderView.frame = CGRect(
                x: 0,
                y: height - 50 - UIDevice.bottomMargin,
                width: width,
                height: 50 + UIDevice.bottomMargin
            )
        }
//        maskBackgroundView.frame = sliderView.frame
//        maskLayer.frame = CGRect(x: 0, y: -20, width: width, height: maskBackgroundView.height + 20)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
