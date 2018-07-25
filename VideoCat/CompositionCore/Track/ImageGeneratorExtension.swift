//
//  ImageGeneratorExtension.swift
//  VideoCat
//
//  Created by Vito on 2018/7/23.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation
import UIKit

extension AVAssetImageGenerator {
    
    static func create(from items: [TrackItem], renderSize: CGSize) -> AVAssetImageGenerator? {
        let timeline = Timeline()
        timeline.videoChannel = items
        let generator = CompositionGenerator(timeline: timeline)
        generator.renderSize = renderSize
        let imageGenerator = generator.buildImageGenerator()
        
        return imageGenerator
    }
    
    static func createFullRangeGenerator(from item: TrackItem, renderSize: CGSize) -> AVAssetImageGenerator? {
        item.resource.selectedTimeRange = CMTimeRange.init(start: kCMTimeZero, duration: item.resource.duration)
        return create(from: [item], renderSize: renderSize)
    }
    
    static func create(fromAsset asset: AVAsset) -> AVAssetImageGenerator {
        let ge = ImageGenerator(asset: asset)
        ge.requestedTimeToleranceBefore = kCMTimeZero
        ge.requestedTimeToleranceAfter = kCMTimeZero
        ge.appliesPreferredTrackTransform = true
        return ge
    }
    
    func updateAspectFitSize(_ size: CGSize) {
        var maximumSize = size
        if !maximumSize.equalTo(.zero) {
            let tracks = asset.tracks(withMediaType: .video)
            if tracks.count > 0 {
                let videoTrack = tracks[0]
                let width = videoTrack.naturalSize.width
                let height = videoTrack.naturalSize.height
                var side: CGFloat
                if width > height {
                    side = maximumSize.width / height * width
                } else {
                    side = maximumSize.width / width * height
                }
                side = side * UIScreen.main.scale
                maximumSize = CGSize(width: side, height: side)
            }
        }
        
        self.maximumSize = maximumSize
    }
    
    func makeCopy() -> AVAssetImageGenerator {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = appliesPreferredTrackTransform
        generator.maximumSize = maximumSize
        generator.apertureMode = apertureMode
        generator.videoComposition = videoComposition
        generator.requestedTimeToleranceBefore = requestedTimeToleranceBefore
        generator.requestedTimeToleranceAfter = requestedTimeToleranceAfter
        return generator
    }
    
}
