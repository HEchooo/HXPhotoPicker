//
//  EMPlayerView.swift
//  AVFoundationQueuePlayer-iOS
//
//  Created by liukun on 2024/4/1.
//

import AVFoundation
import UIKit

class EMPlayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
