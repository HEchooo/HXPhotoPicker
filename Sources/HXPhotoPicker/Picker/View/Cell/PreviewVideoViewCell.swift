//
//  PreviewVideoViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/3/12.
//

import AVFoundation
import UIKit

open class PreviewVideoViewCell: PhotoPreviewViewCell {
    var playButton: UIButton!

    var videoPlayType: PhotoPreviewViewController.PlayType = .normal {
        didSet {
            if videoPlayType == .auto || videoPlayType == .once {
                playButton.isSelected = true
            }
            scrollContentView.videoView.videoPlayType = videoPlayType
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    func config(videoView: PhotoPreviewContentVideoView? = nil) {
        scrollContentView = videoView ?? PhotoPreviewContentVideoView()
//        scrollContentView.videoView = videoView ?? PhotoPreviewVideoView()
        scrollContentView.delegate = self
        scrollContentView.videoView.delegate = self
        initView()
        playButton = UIButton(type: UIButton.ButtonType.custom)
        playButton.setImage(.imageResource.picker.preview.emvideoPlay.eimage, for: UIControl.State.normal)
        playButton.setImage(UIImage(), for: UIControl.State.selected)
        playButton.addTarget(self, action: #selector(didPlayButtonClick(button:)), for: UIControl.Event.touchUpInside)
        playButton.size = playButton.currentImage!.size
//        playButton.alpha = 0
        addSubview(playButton)
    }

    @objc
    private func didPlayButtonClick(button: UIButton) {
        if !button.isSelected {
            scrollContentView.videoView.startPlay()
        } else {
            scrollContentView.videoView.stopPlay()
        }
    }

    /// 指定视频播放时间
    /// - Parameters:
    ///   - time: 指定的时间
    ///   - isPlay: 设置完是否需要播放
    public func seek(to time: TimeInterval, isPlay: Bool) {
        scrollContentView.videoView.seek(to: time, isPlay: isPlay)
    }

    /// 播放视频
    public func playVideo() {
        scrollContentView.videoView.startPlay()
    }

    /// 暂停视频
    public func pauseVideo() {
        scrollContentView.videoView.stopPlay()
    }

    /// 视频加载成功准备播放
    /// - Parameter duration: 视频总时长
    open func videoReadyToPlay(duration: CGFloat) {}

    /// 视频缓冲区发生改变
    /// - Parameter duration: 缓存时长
    open func videoDidChangedBuffer(duration: CGFloat) {}

    /// 视频播放时间发生改变
    /// - Parameter duration: 当前播放的时长
    open func videoDidChangedPlayTime(duration: CGFloat, isAnimation: Bool) {}

    /// 视频播放了
    open func videoDidPlay() {}

    /// 视频暂停了
    open func videoDidPause() {}

    /// 显示工具视图(例如滑动条)
    open func showToolView() {}

    /// 隐藏工具视图(例如滑动条)
    open func hideToolView() {}

    /// 显示遮罩层
    open func showMask() {}

    /// 隐藏遮罩层
    open func hideMask() {}

    override open func layoutSubviews() {
        super.layoutSubviews()
        playButton.centerX = width * 0.5
        playButton.centerY = height * 0.5
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PreviewVideoViewCell: PhotoPreviewContentViewDelete {
    public func contentView(requestSucceed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.cell(requestSucceed: self)
    }

    public func contentView(requestFailed contentView: PhotoPreviewContentViewProtocol) {
        delegate?.cell(requestFailed: self)
    }

    public func contentView(updateContentSize contentView: PhotoPreviewContentViewProtocol) {
        setupScrollViewContentSize()
    }

    public func contentView(networkImagedownloadSuccess contentView: PhotoPreviewContentViewProtocol) {}

    public func contentView(networkImagedownloadFailed contentView: PhotoPreviewContentViewProtocol) {}
}

extension PreviewVideoViewCell: PhotoPreviewVideoViewDelegate {
    public func videoView(readyForDisplay videoView: VideoPlayerView) {}

    public func videoView(resetPlay videoView: VideoPlayerView) {
        videoDidChangedPlayTime(duration: 0, isAnimation: false)
    }

    public func videoView(_ videoView: VideoPlayerView, readyToPlay duration: CGFloat) {
        guard !duration.isNaN else { return }
        videoReadyToPlay(duration: duration)
    }

    public func videoView(_ videoView: VideoPlayerView, didChangedBuffer duration: CGFloat) {
        guard !duration.isNaN else { return }
        videoDidChangedBuffer(duration: duration)
    }

    public func videoView(_ videoView: VideoPlayerView, didChangedPlayerTime duration: CGFloat) {
        guard !duration.isNaN else { return }
        videoDidChangedPlayTime(duration: duration, isAnimation: true)
    }

    public func videoView(startPlay videoView: VideoPlayerView) {
        playButton.isSelected = true
        videoDidPlay()
    }

    public func videoView(stopPlay videoView: VideoPlayerView) {
        playButton.isSelected = false
        videoDidPause()
    }

    public func videoView(showPlayButton videoView: VideoPlayerView) {
        if playButton.alpha == 0 {
            playButton.isHidden = false
            UIView.animate(withDuration: 0.15) {
                self.playButton.alpha = 1
            }
        }
        if !statusBarShouldBeHidden {
            showToolView()
        }
    }

    public func videoView(_ videoView: VideoPlayerView, isPlaybackLikelyToKeepUp: Bool) {
        playButton.isHidden = !isPlaybackLikelyToKeepUp
    }

    public func videoView(hidePlayButton videoView: VideoPlayerView) {
        if playButton.alpha == 1 {
            UIView.animate(withDuration: 0.15) {
                self.playButton.alpha = 0
            } completion: { isFinished in
                if isFinished && self.playButton.alpha == 0 {
                    self.playButton.isHidden = true
                }
            }
        }
        hideToolView()
    }

    public func videoView(showMaskView videoView: VideoPlayerView) {
        showMask()
    }

    public func videoView(hideMaskView videoView: VideoPlayerView) {
        hideMask()
    }

    public func videoView(_ videoView: VideoPlayerView, presentationSize: CGSize) {
        if let videoAsset = photoAsset.networkVideoAsset,
           videoAsset.videoSize.equalTo(.zero),
           !videoAsset.videoSize.equalTo(presentationSize)
        {
            photoAsset.networkVideoAsset?.videoSize = presentationSize
            scrollContentView.updateContentSize(presentationSize)
        }
    }
}
