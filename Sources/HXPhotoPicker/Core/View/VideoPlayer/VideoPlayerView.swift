//
//  VideoPlayerView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import AVFoundation

public class VideoPlayerView: UIView {

    public override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    public var player: AVPlayer!

    public var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    public var avAsset: AVAsset?

    public init() {
        player = AVPlayer()
        super.init(frame: .zero)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
