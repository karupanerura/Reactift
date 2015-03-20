//
//  Scheduler.swift
//  Reactift
//
//  Created by karupanerura on 3/20/15.
//  Copyright (c) 2015 karupanerura. All rights reserved.
//
import Foundation

internal class Scheduler {
    var queue : dispatch_queue_t?

    init () {
    }

    func wrap(cb: ()->()) -> ()->() {
        return { self.dispatch(cb) }
    }

    func wrap<T>(cb: (T)->()) -> (T)->() {
        return { arg1 in self.dispatch { cb(arg1) } }
    }

    func wrap<T, U>(cb: (T, U)->()) -> (T, U)->() {
        return { arg1, arg2 in self.dispatch { cb(arg1, arg2) } }
    }

    func wrap<T, U, V>(cb: (T, U, V)->()) -> (T, U, V)->() {
        return { arg1, arg2, arg3 in self.dispatch { cb(arg1, arg2, arg3) } }
    }

    func dispatch(cb: ()->()) {
        if let queue = self.queue {
            dispatch_async(queue, cb)
        }
        else {
            if NSThread.isMainThread() {
                cb()
            }
            else {
                let queue = dispatch_get_main_queue()
                dispatch_async(queue, cb)
            }
        }
    }
}
