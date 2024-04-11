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
            updateLayout()
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
    private let cwidth: CGFloat = 125
    private let cheight: CGFloat = 166
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

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

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
        updateLayout()
    }
}

extension EMFloatingPlayerView: PhotoPreviewVideoViewDelegate {
    public func videoView(readyToPlay: VideoPlayerView) {
        self.isHidden = false
        self.tmpCorverView.isHidden = true
        updateLayout()
    }
}

extension EMFloatingPlayerView {
    func updateLayout() {
        guard let photoAsset = vedioView.photoAsset else { return }
        let vsize = tmpCorverView.image?.size ?? photoAsset.imageSize
        let aspectRatio = width / vsize.width
        let contentWidth = width
        let contentHeight = vsize.height * aspectRatio
        self.vedioView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        if contentHeight < height {
            self.vedioView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        }
    }
}
