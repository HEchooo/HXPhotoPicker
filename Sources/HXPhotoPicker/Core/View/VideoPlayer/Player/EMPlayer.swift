////
////  EMPlayer.swift
////  AVFoundationQueuePlayer-iOS
////
////  Created by liukun on 2024/4/1.
////
//
//import AVFoundation
//import Combine
//import CombineExt
//import UIKit
//
//private var playerViewControllerKVOContext = 0
//
//class EMPlayer: NSObject, EMWeakArrayValueType {
//    static let identifier: String = "em.player"
//
//    enum VideoState {
//        case loading
//        case done(AVPlayerItem)
//        case failure
//    }
//
//    let playerView: EMPlayerView = .init()
//
//    private var cancelSet = Set<AnyCancellable>()
//    @objc private(set) lazy var player: AVPlayer = {
//        let player = AVPlayer()
////        player.actionAtItemEnd = .pause
////        player.volume = 0
////        player.automaticallyWaitsToMinimizeStalling = false
//        return player
//    }()
//
//    private var timeObserverToken: Any?
//    private let playUrlPublisher = PassthroughSubject<URL?, Never>()
//    private let playPublisher = PassthroughSubject<VideoState, Never>()
//
//    override init() {
//        super.init()
//        setupPlayer()
//        playUrlPublisher
//            .removeDuplicates()
//            .flatMapLatest { [player, weak self] url -> AnyPublisher<Void, Never> in
//                guard let url = url else {
//                    player.replaceCurrentItem(with: nil)
//                    player.pause()
//                    return Just(()).eraseToAnyPublisher()
//                }
//                self?.playPublisher.send(.loading)
//                return AVURLAsset(url: url).loadValuesAsync()
//                    .handleEvents(receiveOutput: { state in
//                        switch state {
//                        case .loading:
//                            break
//                        case .loaded(let item, _):
//                            self?.playPublisher.send(.done(item))
//                        }
//                    }).mapToVoid()
//                    .catch { _ -> AnyPublisher<Void, Never> in
//                        self?.playPublisher.send(.failure)
//                        return Just(()).eraseToAnyPublisher()
//                    }.eraseToAnyPublisher()
//            }.sink(receiveValue: { _ in })
//            .store(in: &cancelSet)
//
//        playPublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [player] state in
//                switch state {
//                case .loading:
//                    break
//                case .done(let item):
//                    player.replaceCurrentItem(with: item)
//                    player.play()
//                case .failure:
//                    break
//                }
//            }.store(in: &cancelSet)
//    }
//
//    deinit {
//        debugPrint("\(Self.self) is deinit")
//        if let timeObserverToken = timeObserverToken {
//            player.removeTimeObserver(timeObserverToken)
//            self.timeObserverToken = nil
//        }
//
//        player.pause()
//        removeObserver(self, forKeyPath: #keyPath(EMPlayer.player.currentItem.duration), context: &playerViewControllerKVOContext)
//        removeObserver(self, forKeyPath: #keyPath(EMPlayer.player.rate), context: &playerViewControllerKVOContext)
//        removeObserver(self, forKeyPath: #keyPath(EMPlayer.player.currentItem.status), context: &playerViewControllerKVOContext)
//        removeObserver(self, forKeyPath: #keyPath(EMPlayer.player.currentItem), context: &playerViewControllerKVOContext)
//    }
//
//    private func setupPlayer() {
//        playerView.playerLayer.player = player
//
//        addObserver(self, forKeyPath: #keyPath(EMPlayer.player.currentItem.duration), options: [.new, .initial], context: &playerViewControllerKVOContext)
//        addObserver(self, forKeyPath: #keyPath(EMPlayer.player.rate), options: [.new, .initial], context: &playerViewControllerKVOContext)
//        addObserver(self, forKeyPath: #keyPath(EMPlayer.player.currentItem.status), options: [.new, .initial], context: &playerViewControllerKVOContext)
//        addObserver(self, forKeyPath: #keyPath(EMPlayer.player.currentItem), options: [.new, .initial], context: &playerViewControllerKVOContext)
//
//        let interval = CMTimeMake(value: 1, timescale: 1)
//        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [unowned self] time in
//            let timeElapsed = Float(CMTimeGetSeconds(time))
//
//            print(timeElapsed)
////            self.timeSlider.value = Float(timeElapsed)
////            self.startTimeLabel.text = self.createTimeString(time: timeElapsed)
//        }
//    }
//
//    // MARK: KVO Observation
//
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
//        guard context == &playerViewControllerKVOContext else {
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//            return
//        }
//
//        if keyPath == #keyPath(EMPlayer.player.currentItem) {}
//        else if keyPath == #keyPath(EMPlayer.player.currentItem.duration) {
//            // Update `timeSlider` and enable / disable controls when `duration` > 0.0.
//
//            /*
//                 Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
//                 `player.currentItem` is nil.
//             */
//            let newDuration: CMTime
//            if let newDurationAsValue = change?[NSKeyValueChangeKey.newKey] as? CMTime {
//                newDuration = newDurationAsValue
//            }
//            else {
//                newDuration = CMTime.zero
//            }
//
//            let isIndefinite = newDuration.flags.contains(.indefinite) && newDuration.flags.contains(.valid)
//            let hasValidDuration = (newDuration.isNumeric && newDuration.value != 0) || isIndefinite
//            let newDurationSeconds = hasValidDuration && !isIndefinite ? CMTimeGetSeconds(newDuration) : 0.0
//            let currentTime = hasValidDuration && !isIndefinite ? Float(CMTimeGetSeconds(player.currentTime())) : 0.0
//        }
//        else if keyPath == #keyPath(EMPlayer.player.rate) {
//            // Update `playPauseButton` image.
//
//            let newRate = (change?[NSKeyValueChangeKey.newKey] as! NSNumber).doubleValue
//
//            let buttonImageName = newRate == 1.0 ? "PauseButton" : "PlayButton"
//
//            let buttonImage = UIImage(named: buttonImageName)
//        }
//        else if keyPath == #keyPath(EMPlayer.player.currentItem.status) {
//            // Display an error if status becomes `.Failed`.
//
//            /*
//                 Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
//                 `player.currentItem` is nil.
//             */
//            let newStatus: AVPlayerItem.Status
//
//            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
//                newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
//            }
//            else {
//                newStatus = .unknown
//            }
//
//            if newStatus == .failed {}
//        }
//    }
//
//    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
//        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
//            "duration": [#keyPath(EMPlayer.player.currentItem.duration)],
//            "rate": [#keyPath(EMPlayer.player.rate)]
//        ]
//
//        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
//    }
//}
//
//extension EMPlayer {
//    func playIfCan(url: String?) {
//        playUrlPublisher.send(url == nil ? nil : URL(string: url!))
//    }
//
//    func extractImage(complete: ((UIImage?) -> Void)?) {
//        guard let asset = player.currentItem?.asset as? AVURLAsset else {
//            complete?(nil)
//            return
//        }
//        asset.extractUIImage(size: CGSize(width: 1000, height: 1000), complete: complete)
//    }
//}
//
//extension AVURLAsset {
//    enum ImageGeneratorError: Error {
//        case `internal`(Error)
//    }
//
//    private func _generator(size: CGSize) -> AVAssetImageGenerator {
//        let generator = AVAssetImageGenerator(asset: self)
////        generator.maximumSize = size
//        generator.appliesPreferredTrackTransform = true
//        return generator
//    }
//
//    enum AVAssetError: Error {
//        case general(Error)
//        case unknown
//        case cancelled
//    }
//
//    enum AVAssetLoadingState: Equatable {
//        case loading
//        case loaded(AVPlayerItem, isVideoAvailable: Bool)
//    }
//
//    func loadValuesAsync() -> AnyPublisher<AVAssetLoadingState, AVAssetError> {
//        let asset = self
//        let playableKey = "playable"
//        let hasProtectedContentKey = "hasProtectedContent"
//
//        return AnyPublisher<AVAssetLoadingState, AVAssetError>.create { seal in
//            seal.send(.loading)
//
//            asset.loadValuesAsynchronously(forKeys: [playableKey, hasProtectedContentKey]) {
//                var error: NSError?
//                let status = asset.statusOfValue(forKey: playableKey, error: &error)
//
//                switch status {
//                case .loading:
//                    seal.send(.loading)
//                case .loaded:
//                    let playerItem = AVPlayerItem(asset: asset)
//                    if let e = playerItem.error {
//                        seal.send(completion: .failure(AVAssetError.general(e)))
//                    }
//                    else {
//                        seal.send(.loaded(playerItem, isVideoAvailable: asset.isVideoAvailable))
//                        seal.send(completion: .finished)
//                    }
//                case .failed:
//                    let error = error.flatMap { AVAssetError.general($0) } ?? .unknown
//                    seal.send(completion: .failure(error))
//                case .cancelled:
//                    seal.send(completion: .failure(.cancelled))
//                case .unknown:
//                    seal.send(completion: .failure(.unknown))
//                @unknown default:
//                    seal.send(completion: .failure(.unknown))
//                }
//            }
//
//            return AnyCancellable {
//                asset.cancelLoading()
//            }
//        }.removeDuplicates()
//            .eraseToAnyPublisher()
//    }
//
//    func extractUIImageAsync(size: CGSize) -> AnyPublisher<UIImage?, ImageGeneratorError> {
//        let generator = _generator(size: size)
//        return AnyPublisher<UIImage?, ImageGeneratorError>.create { observer in
//            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: .zero)]) { _, image, _, _, error in
//                DispatchQueue.main.async {
//                    if let error = error {
//                        observer.send(completion: .failure(.internal(error)))
//                        return
//                    }
//                    observer.send(image.map(UIImage.init(cgImage:)))
//                    observer.send(completion: .finished)
//                }
//            }
//
//            return AnyCancellable {
//                generator.cancelAllCGImageGeneration()
//            }
//        }
//    }
//
//    func extractUIImage(size: CGSize, complete: ((UIImage?) -> Void)?) {
//        let generator = _generator(size: size)
//        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: .zero)]) { [generator] _, cgimage, _, _, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print(error)
//                    complete?(nil)
//                    return
//                }
//                let image = cgimage.map(UIImage.init(cgImage:))
//                print(image)
//                complete?(image)
//                generator.cancelAllCGImageGeneration()
//            }
//        }
//    }
//}
//
//extension AVAsset {
//    var isAudioAvailable: Bool {
//        return !tracks.filter { $0.mediaType == .audio }.isEmpty
//    }
//
//    var isVideoAvailable: Bool {
//        return !tracks.filter { $0.mediaType == .video }.isEmpty
//    }
//}
