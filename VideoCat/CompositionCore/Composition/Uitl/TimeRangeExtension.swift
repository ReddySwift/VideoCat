//
//  TimeRangeExtension.swift
//  VideoCat
//
//  Created by Vito on 2018/6/22.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

extension CMTimeRange {
    
    /// 将两个 time range 根据重合部分切割成多个 time range
    /// 1.考虑一个 timeRange 包含了另一个 timeRange 的情况
    /// 2. 左边/右边重合
    /// 3. 完全重合
    ///
    /// - Parameters:
    ///   - timeRange1: 第一个 time range
    ///   - timeRange2:  第二个 time range
    /// - Returns:  切割后的 time range 数组
    static func sliceTimeRanges(for timeRange1: CMTimeRange, timeRange2: CMTimeRange) -> [CMTimeRange] {
        var timeRanges: [CMTimeRange] = []
        let instersectionTimeRange = timeRange1.intersection(timeRange2)
        if instersectionTimeRange.duration.seconds > 0 {
            if (timeRange1.start.seconds < timeRange2.start.seconds) {
                timeRanges = mixTimeRanges(minTimeRange: timeRange1, instersectionTimeRange: instersectionTimeRange, maxTimeRange: timeRange2)
            } else {
                timeRanges = mixTimeRanges(minTimeRange: timeRange2, instersectionTimeRange: instersectionTimeRange, maxTimeRange: timeRange1)
            }
        } else {
            timeRanges.append(timeRange1)
            timeRanges.append(timeRange2)
        }
        return timeRanges
    }
    
    static func mixTimeRanges(minTimeRange: CMTimeRange, instersectionTimeRange: CMTimeRange, maxTimeRange: CMTimeRange) -> [CMTimeRange] {
        if maxTimeRange.containsTimeRange(minTimeRange) {
            var timeRanges: [CMTimeRange] = []
            let leftTimeRangeDuration = instersectionTimeRange.start - minTimeRange.start
            if leftTimeRangeDuration.seconds > 0 {
                let leftTimeRange = CMTimeRangeMake(minTimeRange.start, leftTimeRangeDuration)
                timeRanges.append(leftTimeRange)
            }
            timeRanges.append(instersectionTimeRange)
            let rightTimeRangeDuration = maxTimeRange.end - instersectionTimeRange.end
            if rightTimeRangeDuration.seconds > 0 {
                let rightTimeRange = CMTimeRangeMake(instersectionTimeRange.end, rightTimeRangeDuration)
                timeRanges.append(rightTimeRange)
            }
            return timeRanges
        }
        
        if minTimeRange == maxTimeRange {
            return [instersectionTimeRange]
        }
        
        var timeRanges: [CMTimeRange] = []
        let duration1 = minTimeRange.duration - instersectionTimeRange.duration
        let timeRange1SubstructRange = CMTimeRange.init(start: minTimeRange.start, duration: duration1)
        if timeRange1SubstructRange.duration.seconds > 0 {
            timeRanges.append(timeRange1SubstructRange)
        }
        
        timeRanges.append(instersectionTimeRange)
        
        let duration2 = maxTimeRange.end - instersectionTimeRange.end
        let timeRange2SubstructRange = CMTimeRange.init(start: instersectionTimeRange.end, duration: duration2)
        if timeRange2SubstructRange.duration.seconds > 0 {
            timeRanges.append(timeRange2SubstructRange)
        }
        return timeRanges
    }
    
    func substruct(_ timeRange: CMTimeRange) -> [CMTimeRange] {
        let intersectionTimeRange = self.intersection(timeRange)
        guard intersectionTimeRange.duration.seconds > 0 else {
            return [self]
        }
        var timeRanges: [CMTimeRange] = []
        let leftTimeRange = CMTimeRange(start: self.start, end: intersectionTimeRange.start)
        if leftTimeRange.duration.seconds > 0 {
            timeRanges.append(leftTimeRange)
        }
        let rightTimeRange = CMTimeRange(start: intersectionTimeRange.end, end: self.end)
        if rightTimeRange.duration.seconds > 0 {
            timeRanges.append(rightTimeRange)
        }
        return timeRanges
    }
    
}

extension CMTimeRange: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "{\(self.start.value)/\(self.start.timescale),\(self.duration.value)/\(self.duration.timescale)}"
    }
    public var debugDescription: String {
        return "{start:\(self.start), duration:\(self.duration)}"
    }
}
