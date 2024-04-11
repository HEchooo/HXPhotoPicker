//
//  EMFloatingPlayerView.swift
//  EchoProduct
//
//  Created by liukun on 2024/4/2.
//

import AVFoundation
import Combine
import Kingfisher
import UIKit

public class EMFloatingPlayerView: UIView {
    public weak var contentView: UIView? {
        didSet {
            self.contentView?.addSubview(self)
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(panGesture:)))
            panGesture.cancelsTouchesInView = false
            addGestureRecognizer(panGesture)
        }
    }

    public let clickPublisher = PassthroughSubject<Void, Never>()
    public var cancel: AnyCancellable?
    public var url: String? {
        didSet {
            guard let url, let URL = URL(string: url) else {
                self.vedioView.cancelRequest()
                return
            }
//            self.floatingView = self.vedioView
            addSubview(self.vedioView)
            sendSubviewToBack(self.vedioView)
            self.vedioView.frame = bounds
            self.vedioView.delegate = self
            self.vedioView.videoView.delegate = self
            self.vedioView.videoView.isMute = true
            self.vedioView.autoPlay = true
            self.vedioView.videoPlayType = .auto

            let asset: NetworkVideoAsset = .init(videoURL: URL)
            let passet: PhotoAsset = .init(networkVideoAsset: asset)
            self.vedioView.photoAsset = passet
            self.vedioView.requestNetwork()
            self.vedioView.requestPreviewAsset()
//            self.floatingView = self.player?.playerView
//            self.player?.playIfCan(url: url)
        }
    }

    public var coverUrl: String? {
        didSet {
            guard let coverUrl else { return }
            self.tmpCorverView.kf.setImage(with: URL(string: coverUrl)) { [weak tmpCorverView, weak self] result in
                switch result {
                case .success(let image):
                    tmpCorverView?.image = image.image
                    self?.updateFrameFirstTime()
                    self?.isHidden = false
                default: break
                }
            }
        }
    }

    public var presentationSize: CGSize = .zero
    public var vedioView: PhotoPreviewContentVideoView = .init() {
        didSet {
//            self.floatingView = self.vedioView
            addSubview(self.vedioView)
            sendSubviewToBack(self.vedioView)
            self.vedioView.frame = bounds
            self.vedioView.delegate = self
            self.vedioView.autoPlay = true
            updateLayoutFromTransition()
            setNeedsDisplay()
        }
    }

    private var tmpCorverView = UIImageView()

//    private lazy var player = EMPlayerManager.shared.buildPlayer()

//    private var floatingView: UIView? {
//        didSet {
//            guard let floatingView else { return }
//            addSubview(floatingView)
//            sendSubviewToBack(floatingView)
//            floatingView.frame = bounds
//        }
//    }

//    public func clean() {
//        self.floatingView?.removeFromSuperview()
//        self.floatingView?.gestureRecognizers = nil
//        self.floatingView = nil
//    }

    private lazy var closeButton = EMFloatingPlayerViewButton()
    private let cwidth: CGFloat = SizeType.videoW
    private let cheight: CGFloat = SizeType.videoW
    private lazy var paddingEdgeInset: UIEdgeInsets = .init(top: 60, left: 12.5, bottom: 110, right: 12.5)

    private var cancelSet = Set<AnyCancellable>()
    override public init(frame: CGRect) {
        super.init(frame: CGRect(x: UIScreen.main.bounds.size.width - self.cwidth - 12.5, y: 138, width: self.cwidth, height: self.cheight))
        isHidden = true
        backgroundColor = .black
        addSubview(self.tmpCorverView)
        self.tmpCorverView.frame = bounds
        self.tmpCorverView.contentMode = .scaleAspectFit
        self.tmpCorverView.backgroundColor = .clear
        addSubview(self.closeButton)
        self.closeButton.frame = CGRect(x: self.cwidth - 24, y: 0, width: 24, height: 24)
        self.bind()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture(tapGesture:)))
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        debugPrint("\(Self.self) is deinit")
    }

    private func bind() {
        self.closeButton.tapPublisher.sink { [weak self] in
            self?.vedioView.cancelRequest()
            self?.removeFromSuperview()
        }.store(in: &self.cancelSet)
    }

    private var tmpBorderLayer: CAShapeLayer?

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        if let tmpBorderLayer {
            tmpBorderLayer.removeFromSuperlayer()
        }

        let halfHeight = 12
        let maskPath = UIBezierPath(roundedRect: self.bounds,
                                    byRoundingCorners: [.topLeft, .bottomRight, .topRight, .bottomLeft],
                                    cornerRadii: CGSize(width: halfHeight, height: halfHeight))

        // setup MASK
        self.layer.mask = nil
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer

        // setup Border for Mask
        let borderLayer = CAShapeLayer()
        borderLayer.path = maskPath.cgPath
        borderLayer.lineWidth = 2
        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.frame = self.bounds
        tmpBorderLayer = borderLayer
        self.layer.addSublayer(borderLayer)
    }

    @objc private func handleTapGesture(tapGesture: UITapGestureRecognizer) {
        guard self.vedioView.videoView.isStartedPlay else { return }
        self.clickPublisher.send()
    }

    @objc private func handlePanGesture(panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .began {}

        if panGesture.state == .ended {
            self.viewDidEndMove(gesture: panGesture)
        }

        if panGesture.state == .changed {
            self.viewDidMove(gesture: panGesture)
        }
        panGesture.setTranslation(CGPoint.zero, in: self.superview)
    }

    // Handleing movement of view
    private func viewDidMove(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        self.center = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
    }

    private func viewDidEndMove(gesture: UIPanGestureRecognizer) {
        guard let superview else { return }
        var cX: CGFloat = center.x
        var cY: CGFloat = center.y

        if center.x <= superview.bounds.width / 2 {
            cX = self.paddingEdgeInset.left + (self.cwidth / 2)
        } else {
            cX = superview.bounds.width - (self.cwidth / 2) - self.paddingEdgeInset.right
        }

        if center.y < ((self.cheight / 2) + self.paddingEdgeInset.top) {
            cY = (self.cheight / 2) + self.paddingEdgeInset.top
        } else if center.y > (superview.bounds.height - (self.cheight / 2) - self.paddingEdgeInset.bottom) {
            cY = superview.bounds.height - (self.cheight / 2) - self.paddingEdgeInset.bottom
        }

        UIView.animate(withDuration: 0.18) {
            self.center = CGPoint(x: cX, y: cY)
        }
    }
}

class EMFloatingPlayerViewButton: UIView {
    private lazy var closeView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = "em_player_close".eimage
//        imageView.snp.makeConstraints { $0.size.equalTo(CGSize(width: 10, height: 10)) }
//        NSLayoutConstraint.activate([
//            imageView.widthAnchor.constraint(equalToConstant: 10),
//            imageView.heightAnchor.constraint(equalToConstant: 10)
//        ])
        return imageView
    }()

    private lazy var maskLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.black.withAlphaComponent(0.9).cgColor, UIColor.black.withAlphaComponent(0.9).cgColor]
        gradient.locations = [0, 1.0]
        gradient.startPoint = .init(x: 0.0, y: 0.5)
        gradient.endPoint = .init(x: 1.0, y: 0.5)
        return gradient
    }()

    let tapPublisher = PassthroughSubject<Void, Never>()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.maskedCorners = [.layerMinXMaxYCorner]
        layer.cornerRadius = 8
        layer.masksToBounds = true

        addSubview(self.closeView)
        self.closeView.frame = CGRect(x: (24.0 - 10.0) / 2, y: (24.0 - 10.0) / 2, width: 10.0, height: 10.0)
//        self.closeView.snp.makeConstraints { $0.center.equalToSuperview() }
//        NSLayoutConstraint.activate([
//            self.closeView.topAnchor.constraint(equalTo: self.topAnchor),
//            self.closeView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
//            self.closeView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
//            self.closeView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
//        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapClick))
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        if layer.mask != self.maskLayer {
            layer.mask = self.maskLayer
            self.maskLayer.frame = bounds
        }
    }

    @objc private func tapClick() {
        self.tapPublisher.send()
    }
}

extension EMFloatingPlayerView: PhotoPreviewContentViewDelete {
    public func contentView(updateContentSize contentView: PhotoPreviewContentViewProtocol) {
        updateLayoutFirstTime()
    }
}

extension EMFloatingPlayerView: PhotoPreviewVideoViewDelegate {
    public func videoView(readyToPlay: VideoPlayerView) {
        updateFrameFirstTime()
        self.isHidden = false
        self.tmpCorverView.isHidden = true
        updateLayoutFirstTime()
    }
}

extension EMFloatingPlayerView {
    var videoSizeFirstFromTmpCorverView: CGSize? {
        var vsize = self.tmpCorverView.image?.size
        if vsize == nil {
            guard let photoAsset = vedioView.photoAsset else { return nil }
            vsize = photoAsset.imageSize
        }
        return vsize
    }

    var videoSizeFirstFromVideoView: CGSize? {
        guard let photoAsset = vedioView.photoAsset else {
            return self.tmpCorverView.image?.size
        }
        return photoAsset.imageSize
    }

    var ratioSizeFromTmpCorverView: CGSize {
        guard let videoSizeFirstFromTmpCorverView else { return .init(width: self.cwidth, height: self.cheight) }
        return SizeType.sizeType(size: videoSizeFirstFromTmpCorverView).size
    }

    var ratioSizeFromFromVideoView: CGSize {
        guard let videoSizeFirstFromVideoView else { return .init(width: self.cwidth, height: self.cheight) }
        return SizeType.sizeType(size: videoSizeFirstFromVideoView).size
    }

    public func updateFrameFirstTime() {
        var tmpFrame = frame
        tmpFrame.size = self.ratioSizeFromTmpCorverView
        frame = tmpFrame
    }

    public func updateLayoutFirstTime() {
        guard let vsize = videoSizeFirstFromTmpCorverView else { return }
        let aspectRatio = width / vsize.width
        let contentWidth = width
        let contentHeight = vsize.height * aspectRatio
        self.vedioView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        if contentHeight < height {
            self.vedioView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        }
    }

    private func updateLayoutFromTransition() {
        guard let vsize = videoSizeFirstFromVideoView else { return }
        let aspectRatio = width / vsize.width
        let contentWidth = width
        let contentHeight = vsize.height * aspectRatio
        self.vedioView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        if contentHeight < height {
            self.vedioView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        }
    }

    public func updateFrameWithNewVideoView(size: CGSize) {
        let newSize = SizeType.sizeType(size: size).size
        var tmpFrame = frame
        tmpFrame.size = newSize
        frame = tmpFrame
    }
}

enum SizeType {
    case s1v1
    case s3v4
    case s9v16

    var rate: Double {
        switch self {
        case .s1v1:
            return 1.0
        case .s3v4:
            return 4.0 / 3.0
        case .s9v16:
            return 16.0 / 9.0
        }
    }

    var size: CGSize {
        switch self {
        case .s1v1:
            return .init(width: Self.videoW, height: self.height)
        case .s3v4:
            return .init(width: Self.videoW, height: self.height)
        case .s9v16:
            return .init(width: Self.videoW, height: self.height)
        }
    }

    var height: CGFloat {
        switch self {
        case .s1v1:
            return SizeType.videoW
        case .s3v4:
            return SizeType.videoW * (4.0 / 3.0)
        case .s9v16:
            return SizeType.videoW * (16.0 / 9.0)
        }
    }

    static var videoW: CGFloat {
        126
    }

    static func sizeType(size: CGSize) -> Self {
        let width = size.width
        let height = size.height
        let r1v1 = 1.0
        let r3v4 = 3.0 / 4.0
        let r9v16 = 9.0 / 16.0
        let rate = CGFloat(width) / CGFloat(height)
        if rate >= 1.0 {
            return .s1v1
        } else if r3v4 <= rate && rate < 1.0 {
            let d1 = abs(rate - r1v1)
            let d2 = abs(rate - r3v4)
            return d1 > d2 ? .s3v4 : .s1v1
        } else if r9v16 <= rate && rate < r3v4 {
            let d2 = abs(rate - r3v4)
            let d3 = abs(rate - r9v16)
            return d2 > d3 ? .s9v16 : .s3v4
        } else {
            return .s9v16
        }
    }
}
