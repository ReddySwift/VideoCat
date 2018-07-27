//
//  AVAssetTrackResource.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import UIKit

/// Load image from PHAsset as video frame
class AVAssetTrackResource: Resource {
    
    var asset: AVAsset?
    
    init(asset: AVAsset) {
        super.init()
        self.asset = asset
        let duration = CMTimeMake(Int64(asset.duration.seconds * 600), 600)
        selectedTimeRange = CMTimeRangeMake(kCMTimeZero, duration)
    }
    
    required public init() {
        super.init()
    }
    
    // MARK: - Load Media before use resource
    
    @discardableResult
    open override func prepare(progressHandler:((Double) -> Void)? = nil, completion: @escaping (ResourceStatus, Error?) -> Void) -> ResourceTask? {
        if let asset = asset {
            asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"], completionHandler: { [weak self] in
                guard let strongSelf = self else { return }
                
                defer {
                    if asset.tracks.count > 0 {
                        if let track = asset.tracks(withMediaType: .video).first {
                            strongSelf.size = track.naturalSize.applying(track.preferredTransform)
                        }
                        strongSelf.status = .avaliable
                        strongSelf.duration = asset.duration
                    }
                    completion(strongSelf.status, strongSelf.statusError)
                }
                
                var error: NSError?
                let tracksStatus = asset.statusOfValue(forKey: "tracks", error: &error)
                if tracksStatus != .loaded {
                    Log.error("Failed to load tracks, status: \(tracksStatus), error: \(String(describing: error))")
                    return
                }
                let durationStatus = asset.statusOfValue(forKey: "duration", error: &error)
                if durationStatus != .loaded {
                    Log.error("Failed to duration tracks, status: \(tracksStatus), error: \(String(describing: error))")
                    return
                }
            })
            return ResourceTask.init(cancel: {
                asset.cancelLoading()
            })
        } else {
            completion(status, statusError)
        }
        return nil
    }
    
    // MARK: - Content provider
    
    open override func tracks(for type: AVMediaType) -> [AVAssetTrack] {
        if let asset = asset {
            return asset.tracks(withMediaType: type)
        }
        return []
    }
    
    // MARK: - NSCopying
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let resource = super.copy(with: zone) as! AVAssetTrackResource
        resource.asset = asset
        
        return resource
    }
    
}
