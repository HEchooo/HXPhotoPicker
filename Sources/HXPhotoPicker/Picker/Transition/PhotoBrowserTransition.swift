//
//  PhotoBrowserTransition.swift
//  EchoProduct
//
//  Created by liukun on 2024/3/9.
//

import Photos
import UIKit
#if canImport(Kingfisher)
import Kingfisher
#endif

public enum PhotoBrowserTransitionType {
    case present
    case dismiss

    var pickTransitionType: PickerTransitionType {
        switch self {
        case .present:
            return .present
        case .dismiss:
            return .dismiss
        }
    }
}

class PhotoBrowserTransition: NSObject, UIViewControllerAnimatedTransitioning {
    private let type: PhotoBrowserTransitionType
    private var requestID: PHImageRequestID?
    private var pushImageView: UIImageView!

    init(type: PhotoBrowserTransitionType) {
        self.type = type
        super.init()
        pushImageView = UIImageView()
        pushImageView.contentMode = .scaleAspectFill
        pushImageView.clipsToBounds = true
    }

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        if type == .dismiss {
            return 0.23
        }
        return 0.4
    }

    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning)
    {
        presentTransition(using: transitionContext)
    }

    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    func presentTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        // swiftlint:enable function_body_length
        // swiftlint:enable cyclomatic_complexity
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to)
        else {
            transitionContext.completeTransition(true)
            return
        }

        let containerView = transitionContext.containerView
        let contentView = UIView()

        var pickerController: PhotoPickerController
        if type == .present {
            pickerController = toVC as! PhotoPickerController
        } else {
            pickerController = fromVC as! PhotoPickerController
        }
        let backgroundColor = PhotoManager.isDark ?
            pickerController.config.previewView.backgroundDarkColor :
            pickerController.config.previewView.backgroundColor
        var fromView: UIView
        var previewView: UIView?
        var toRect: CGRect = .zero
        let previewViewController = pickerController.previewViewController
        previewViewController?.isTransitioning = true
        if type == .present {
            contentView.frame = toVC.view.bounds
            containerView.addSubview(contentView)
            containerView.addSubview(toVC.view)
            contentView.backgroundColor = backgroundColor.withAlphaComponent(0)
            previewViewController?.view.backgroundColor = backgroundColor.withAlphaComponent(0)
            pickerController.view.backgroundColor = nil
            pickerController.navigationBar.alpha = 0
            previewViewController?.photoToolbar.alpha = 0
            previewViewController?.navBgView?.alpha = 0
            previewViewController?.collectionView.isHidden = true
            fromView = pushImageView
            let currentPreviewIndex: Int
            if let index = previewViewController?.currentPreviewIndex {
                currentPreviewIndex = index
            } else {
                currentPreviewIndex = 0
            }
            if let view = pickerController.pickerDelegate?.pickerController(
                pickerController,
                presentPreviewViewForIndexAt: currentPreviewIndex
            ) {
                let rect = view.convert(view.bounds, to: contentView)
                fromView.frame = rect
                if view.layer.cornerRadius > 0 {
                    pushImageView.layer.cornerRadius = view.layer.cornerRadius
                    pushImageView.layer.masksToBounds = true
                }
                previewView = view
            } else if let rect = pickerController.pickerDelegate?.pickerController(
                pickerController,
                presentPreviewFrameForIndexAt: currentPreviewIndex
            ),
                !rect.equalTo(.zero)
            {
                fromView.frame = rect
            } else {
                fromView.center = CGPoint(x: toVC.view.width * 0.5, y: toVC.view.height * 0.5)
            }

            if let image = pickerController.pickerDelegate?.pickerController(
                pickerController,
                presentPreviewImageForIndexAt: currentPreviewIndex
            ) {
                pushImageView.image = image
            }
            var photoAsset: PhotoAsset?
            if pickerController.previewType == .picker {
                photoAsset = pickerController.previewViewController?.photoAsset(for: currentPreviewIndex)
            } else if !pickerController.selectedAssetArray.isEmpty {
                photoAsset = pickerController.selectedAssetArray[currentPreviewIndex]
            } else {
                photoAsset = pickerController.previewViewController?.photoAsset(for: currentPreviewIndex)
            }

            if let photoAsset = photoAsset {
                var reqeustAsset = photoAsset.phAsset != nil
                #if HXPICKER_ENABLE_EDITOR
                if photoAsset.editedResult != nil {
                    reqeustAsset = false
                }
                #endif
                if let phAsset = photoAsset.phAsset, reqeustAsset {
                    requestAssetImage(for: phAsset, isGIF: photoAsset.isGifAsset, isHEIC: photoAsset.photoFormat == "heic")
                } else if pushImageView.image == nil || photoAsset.isLocalAsset {
                    if let image = photoAsset.originalImage {
                        pushImageView.image = image
                    }
                }
                #if canImport(Kingfisher)
                if let networkImage = photoAsset.networkImageAsset {
                    let cacheKey = networkImage.originalURL.cacheKey
                    if ImageCache.default.isCached(forKey: cacheKey) {
                        ImageCache.default.retrieveImage(
                            forKey: cacheKey,
                            options: [],
                            callbackQueue: .mainAsync
                        ) { [weak self] in
                            guard let self = self else { return }
                            switch $0 {
                            case .success(let value):
                                if let image = value.image, self.pushImageView.superview != nil {
                                    self.pushImageView.setImage(image, duration: 0.4, animated: true)
                                }
                            default:
                                break
                            }
                        }
                    } else {
                        let cacheKey = networkImage.thumbnailURL.cacheKey
                        if ImageCache.default.isCached(forKey: cacheKey) {
                            ImageCache.default.retrieveImage(
                                forKey: cacheKey,
                                options: [],
                                callbackQueue: .mainAsync
                            ) { [weak self] in
                                guard let self = self else { return }
                                switch $0 {
                                case .success(let value):
                                    if let image = value.image,
                                       self.pushImageView.superview != nil
                                    {
                                        self.pushImageView.setImage(image, duration: 0.4, animated: true)
                                    }
                                default:
                                    break
                                }
                            }
                        }
                    }
                }
                #endif
                if UIDevice.isPad {
                    toRect = PhotoTools.transformImageSize(
                        photoAsset.imageSize,
                        toViewSize: toVC.view.size,
                        directions: [.horizontal]
                    )
                } else {
                    toRect = PhotoTools.transformImageSize(photoAsset.imageSize, to: toVC.view)
                }
            }
        } else {
            contentView.frame = fromVC.view.bounds
            previewViewController?.view.insertSubview(contentView, at: 0)
            previewViewController?.view.backgroundColor = .clear
            previewViewController?.collectionView.isHidden = true
            pickerController.view.backgroundColor = .clear
            contentView.backgroundColor = backgroundColor
            if let pickerViewController = pickerController.pickerViewController,
               let previewViewController = previewViewController,
               pickerViewController.isShowToolbar,
               previewViewController.isShowToolbar
            {
                pickerViewController.photoToolbar.selectViewOffset = previewViewController.photoToolbar.selectViewOffset
            }
            let currentPreviewIndex: Int
            if let index = previewViewController?.currentPreviewIndex {
                currentPreviewIndex = index
            } else {
                currentPreviewIndex = 0
            }
            var hasCornerRadius = false
            if let view = pickerController.pickerDelegate?.pickerController(
                pickerController,
                dismissPreviewViewForIndexAt: currentPreviewIndex
            ) {
                toRect = view.convert(view.bounds, to: containerView)
                previewView = view
                if view.layer.cornerRadius > 0 {
                    hasCornerRadius = true
                }
            } else if let rect = pickerController.pickerDelegate?.pickerController(
                pickerController,
                dismissPreviewFrameForIndexAt: currentPreviewIndex
            ),
                !rect.equalTo(.zero)
            {
                toRect = rect
            }
            if let previewVC = previewViewController,
               let cell = previewVC.getCell(for: previewVC.currentPreviewIndex),
               let cellContentView = cell.scrollContentView
            {
                cellContentView.hiddenOtherSubview()
                fromView = cellContentView
                fromView.frame = cellContentView.convert(cellContentView.bounds, to: containerView)
            } else {
                fromView = pushImageView
            }

            if hasCornerRadius {
                fromView.layer.masksToBounds = true
            }
        }
        if let photoBrowser = pickerController as? PhotoBrowser {
            if photoBrowser.hideSourceView {
                previewView?.isHidden = true
            }
        } else {
            previewView?.isHidden = true
        }
        contentView.addSubview(fromView)
        let duration: TimeInterval = transitionDuration(using: transitionContext)
//        if type == .dismiss && !toRect.isEmpty {
//            duration = transitionDuration(using: transitionContext) - 0.2
//        } else {
//            duration = transitionDuration(using: transitionContext)
//        }
        let colorDuration = 0.15
        UIView.animate(withDuration: colorDuration, delay: 0, options: [.curveLinear]) {
            if self.type == .present {
                previewViewController?.photoToolbar.alpha = 1
                previewViewController?.navBgView?.alpha = 1
                contentView.backgroundColor = backgroundColor.withAlphaComponent(1)
            } else if self.type == .dismiss {
                previewViewController?.photoToolbar.alpha = 0
                previewViewController?.navBgView?.alpha = 0
                contentView.backgroundColor = backgroundColor.withAlphaComponent(0)
            }
        }
        let currentPreviewIndex: Int
        if let index = previewViewController?.currentPreviewIndex {
            currentPreviewIndex = index
        } else {
            currentPreviewIndex = 0
        }

        UIView.animate(withDuration: duration, delay: colorDuration - 0.05, options: [.layoutSubviews, .curveEaseInOut]) {
            if self.type == .present {
                pickerController.navigationBar.alpha = 1
                if self.pushImageView.layer.cornerRadius > 0 {
                    self.pushImageView.layer.cornerRadius = 0
                }
                self.pushImageView.frame = toRect
            } else if self.type == .dismiss {
                pickerController.navigationBar.alpha = 0
                if let previewView = previewView, previewView.layer.cornerRadius > 0 {
                    fromView.layer.cornerRadius = previewView.layer.cornerRadius
                }
                if toRect.isEmpty {
                    fromView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    fromView.alpha = 0
                } else {
                    fromView.frame = toRect
                }
            }
            pickerController.pickerDelegate?
                .pickerController(pickerController, animateTransition: self.type.pickTransitionType)
        } completion: { _ in
            previewView?.isHidden = false
            previewViewController?.isTransitioning = false
            if self.type == .present {
                if let requestID = self.requestID {
                    PHImageManager.default().cancelImageRequest(requestID)
                    self.requestID = nil
                }
                pickerController.pickerDelegate?.pickerController(
                    pickerController,
                    previewPresentComplete: currentPreviewIndex
                )
                previewViewController?.view.backgroundColor = backgroundColor.withAlphaComponent(1)
                previewViewController?.setCurrentCellImage(image: self.pushImageView.image)
                previewViewController?.collectionView.isHidden = false
                previewViewController?.updateColors()
                pickerController.configBackgroundColor()
                self.pushImageView.removeFromSuperview()
                contentView.removeFromSuperview()
                transitionContext.completeTransition(true)
            } else {
                pickerController.pickerDelegate?.pickerController(
                    pickerController,
                    previewDismissComplete: currentPreviewIndex
                )
                if toRect.isEmpty {
                    contentView.removeFromSuperview()
                    transitionContext.completeTransition(true)
                } else {
                    UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction]) {
                        fromView.alpha = 0
                    } completion: { _ in
                        contentView.removeFromSuperview()
                        transitionContext.completeTransition(true)
                    }
                }
            }
        }
    }

    func requestAssetImage(for asset: PHAsset, isGIF: Bool = false, isHEIC: Bool = false) {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.deliveryMode = .highQualityFormat
        requestID = AssetManager.requestImage(
            for: asset,
            targetSize: asset.thumTargetSize,
            options: options
        ) { image, info in
            guard let image else { return }
            DispatchQueue.main.async {
                if self.pushImageView.superview != nil {
                    self.pushImageView.image = image
                }
            }
            if AssetManager.assetDownloadFinined(for: info) || AssetManager.assetCancelDownload(for: info) {
                self.requestID = nil
            }
        }
    }
}
