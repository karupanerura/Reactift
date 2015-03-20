//
//  Observar.swift
//  Reactift
//
//  Created by karupanerura on 3/20/15.
//  Copyright (c) 2015 karupanerura. All rights reserved.
//
import Foundation

public class Observar<T> {
    typealias OnNextCallback     = (T)->()
    typealias OnCompleteCallback = ()->()

    let onNext     : OnNextCallback
    let onComplete : OnCompleteCallback

    private var suspendFg : Bool
    init (onNext: OnNextCallback, onComplete: OnCompleteCallback) {
        self.onNext = onNext
        self.onComplete = onComplete
        self.suspendFg  = false
    }

    func suspend () -> Self {
        self.suspendFg = true
        return self
    }

    func resume () -> Self {
        self.suspendFg = false
        return self
    }

    func dispose () {
        self.suspend()
    }
}
