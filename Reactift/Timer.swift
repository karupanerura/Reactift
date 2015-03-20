//
//  Timer.swift
//  Reactift
//
//  Created by karupanerura on 3/21/15.
//  Copyright (c) 2015 karupanerura. All rights reserved.
//
import Foundation

internal class Timer {
    private class Callback : NSObject {
        let cb: (NSTimer)->()

        init(cb: (NSTimer)->()) {
            self.cb = cb
            super.init()
        }

        func onUpdate(timer: NSTimer) {
            self.cb(timer)
        }
    }

    class func setTimeout(interval: NSTimeInterval, cb: (NSTimer)->()) -> NSTimer {
        return create(interval, repeats: false, cb: cb)
    }

    class func setInterval(interval: NSTimeInterval, cb: (NSTimer)->()) -> NSTimer {
        return create(interval, repeats: true, cb: cb)
    }

    private class func create(interval: NSTimeInterval, repeats: Bool, cb: (NSTimer)->()) -> NSTimer {
        let callback = Callback(cb: cb)
        let timer = NSTimer(timeInterval: interval, target: callback, selector: "onUpdate:", userInfo: nil, repeats: repeats)
        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
        return timer
    }
}
