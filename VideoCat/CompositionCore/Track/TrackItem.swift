//
//  TrackItem.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import CoreImage

public class TrackItem: NSObject, NSCopying {
    
    public var identifier: String
    public var resource: Resource
    public var configuration: TrackConfiguration
    
    public var videoTransition: VideoTransition?
    public var audioTransition: AudioTransition?
    
    public required init(resource: Resource) {
        identifier = ProcessInfo.processInfo.globallyUniqueString
        self.resource = resource
        configuration = TrackConfiguration()
        super.init()
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let item = type(of: self).init(resource: resource.copy() as! Resource)
        item.identifier = identifier
        item.configuration = configuration.copy() as! TrackConfiguration
        item.videoTransition = videoTransition
        item.audioTransition = audioTransition
        return item
    }
}

public extension TrackItem {
    
    func reloadTimelineDuration() {
        let duration = resource.selectedTimeRange.duration
        var timeRange = configuration.timelineTimeRange
        timeRange.duration = duration
        configuration.timelineTimeRange = timeRange
    }
    
}

extension TrackItem: CompositionTimeRangeProvider {
    
    public var timeRange: CMTimeRange {
        get {
            return configuration.timelineTimeRange
        }
        set {
            configuration.timelineTimeRange = newValue
        }
    }
    
}

// MARK: - TransitionableVideoProvider

extension TrackItem: TransitionableVideoProvider {
    
    public func numberOfVideoTracks() -> Int {
        return resource.tracks(for: .video).count
    }
    
    public func videoCompositionTrack(for composition: AVMutableComposition, at index: Int, preferredTrackID: Int32) -> AVCompositionTrack? {
        let track = resource.tracks(for: .video)[index]
        
        let compositionTrack = composition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: preferredTrackID)
        if let compositionTrack = compositionTrack {
            compositionTrack.preferredTransform = track.preferredTransform
            do {
                /*
                 Special logic for ImageResource, because of it provides a placeholder track,
                 Maybe not enough to fill the selectedTimeRange.
                 But ImageResource usually support unlimited time.
                 */
                if resource.isKind(of: ImageResource.self) {
                    let emptyDuration = CMTime(value: 1, 30)
                    let range = CMTimeRangeMake(kCMTimeZero, emptyDuration)
                    try compositionTrack.insertTimeRange(range, of: track, at: timeRange.start)
                    compositionTrack.scaleTimeRange(CMTimeRangeMake(timeRange.start, emptyDuration), toDuration: resource.selectedTimeRange.duration)
                } else {
                    try compositionTrack.insertTimeRange(resource.selectedTimeRange, of: track, at: timeRange.start)
                }
            } catch {
                Log.error(#function + error.localizedDescription)
            }
        }
        return compositionTrack
    }
    
    public func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        var finalImage: CIImage = {
            if let resource = resource as? ImageResource {
                let relativeTime = time - timeRange.start
                if let resourceImage = resource.image(at: relativeTime, renderSize: renderSize) {
                    return resourceImage
                }
            }
            return sourceImage
        }()
        
        var transform = CGAffineTransform.identity
        switch configuration.videoConfiguration.baseContentMode {
        case .aspectFit:
            let fitTransform = CGAffineTransform.transform(by: finalImage.extent, aspectFitInRect: CGRect(origin: .zero, size: renderSize))
            transform = transform.concatenating(fitTransform)
        case .aspectFill:
            let fillTransform = CGAffineTransform.transform(by: finalImage.extent, aspectFillRect: CGRect(origin: .zero, size: renderSize))
            transform = transform.concatenating(fillTransform)
        case .custom:
            break
        }
        finalImage = finalImage.transformed(by: transform)
        
        if let filterProcessor = configuration.videoConfiguration.filterProcessor {
            finalImage = filterProcessor(finalImage)
        }
        return finalImage
    }
    
}

// MARK: - TransitionableAudioProvider
extension TrackItem: TransitionableAudioProvider {
    
    public func numberOfAudioTracks() -> Int {
        return resource.tracks(for: .audio).count
    }
    
    public func audioCompositionTrack(for composition: AVMutableComposition, at index: Int, preferredTrackID: Int32) -> AVCompositionTrack? {
        let track = resource.tracks(for: .audio)[index]
        let compositionTrack = composition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: preferredTrackID)
        if let compositionTrack = compositionTrack {
            do {
                try compositionTrack.insertTimeRange(resource.selectedTimeRange, of: track, at: timeRange.start)
            } catch {
                Log.error(#function + error.localizedDescription)
            }
        }
        return compositionTrack
    }
    
    public func configure(audioMixParameters: AVMutableAudioMixInputParameters) {
        let volume = configuration.audioConfiguration.volume
        audioMixParameters.setVolumeRamp(fromStartVolume: volume, toEndVolume: volume, timeRange: configuration.timelineTimeRange)
        audioMixParameters.audioProcessingTapHolder = configuration.audioConfiguration.audioTapHolder
    }
    
}

private extension CIImage {
    
    func flipYCoordinate() -> CIImage {
        let flipYTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: extent.origin.y * 2 + extent.height)
        return transformed(by: flipYTransform)
    }
    
}

extension TrackItem {
    
    func generateFullRangeImageGenerator(size: CGSize = .zero) -> AVAssetImageGenerator? {
        let item = self.copy() as! TrackItem
        let imageGenerator = AVAssetImageGenerator.createFullRangeGenerator(from: item, renderSize: size)
        imageGenerator?.updateAspectFitSize(size)
        return imageGenerator
    }
    
    func generateFullRangePlayerItem(size: CGSize = .zero) -> AVPlayerItem? {
        let item = self.copy() as! TrackItem
        item.resource.selectedTimeRange = CMTimeRange.init(start: kCMTimeZero, duration: item.resource.duration)
        item.timeRange = CMTimeRange.init(start: kCMTimeZero, duration: item.resource.duration)
        let timeline = Timeline()
        timeline.videoChannel = [item]
        timeline.audioChannel = [item]
        let generator = CompositionGenerator(timeline: timeline)
        generator.renderSize = size
        let playerItem = generator.buildPlayerItem()
        return playerItem
    }
    
}
