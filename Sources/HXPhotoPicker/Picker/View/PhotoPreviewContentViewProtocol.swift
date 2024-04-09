//
//  PhotoPreviewContentView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import PhotosUI
import UIKit

#if canImport(Kingfisher)
import Kingfisher
#endif

public protocol PhotoPreviewContentViewDelete: AnyObject {
    func contentView(requestSucceed contentView: PhotoPreviewContentViewProtocol)
    func contentView(requestFailed contentView: PhotoPreviewContentViewProtocol)
    func contentView(networkImagedownloadSuccess contentView: PhotoPreviewContentViewProtocol)
    func contentView(networkImagedownloadFailed contentView: PhotoPreviewContentViewProtocol)
    func contentView(updateContentSize contentView: PhotoPreviewContentViewProtocol)
    func contentView(livePhotoWillBeginPlayback contentView: PhotoPreviewContentViewProtocol)
    func contentView(livePhotoDidEndPlayback contentView: PhotoPreviewContentViewProtocol)
}

extension PhotoPreviewContentViewDelete {
    public func contentView(requestSucceed contentView: PhotoPreviewContentViewProtocol) {}
    public func contentView(requestFailed contentView: PhotoPreviewContentViewProtocol) {}
    public func contentView(networkImagedownloadSuccess contentView: PhotoPreviewContentViewProtocol) {}
    public func contentView(networkImagedownloadFailed contentView: PhotoPreviewContentViewProtocol) {}
    public func contentView(updateContentSize contentView: PhotoPreviewContentViewProtocol) {}
    public func contentView(livePhotoWillBeginPlayback contentView: PhotoPreviewContentViewProtocol) {}
    public func contentView(livePhotoDidEndPlayback contentView: PhotoPreviewContentViewProtocol) {}
}

public protocol PhotoPreviewContentViewProtocol: UIView {
    var delegate: PhotoPreviewContentViewDelete? { get set }
    var photoAsset: PhotoAsset! { get set }
    var livePhotoPlayType: PhotoPreviewViewController.PlayType { get set }
    var videoPlayType: PhotoPreviewViewController.PlayType { get set }

    var isPeek: Bool { get set }
    var isBacking: Bool { get set }

    var imageView: ImageView! { get set }
    var livePhotoView: PHLivePhotoView! { get set }
    var videoView: PhotoPreviewVideoView! { get set }

    var hudSuperview: UIView? { get }
    var isLivePhotoAnimating: Bool { get set }
    var requestCompletion: Bool { get set }

    func updateContentSize(_ size: CGSize)
    func requestPreviewAsset()
    func cancelRequest()

    func startAnimated()
    func stopAnimated()
    func stopVideo()
    func stopLivePhoto()
    func showOtherSubview()
    func hiddenOtherSubview()
}
