//
//  Observable.swift
//  Reactift
//
//  Created by karupanerura on 3/20/15.
//  Copyright (c) 2015 karupanerura. All rights reserved.
//
import Foundation

public class Observable<T> {
    typealias SubscriptionCallback = (Observar<T>)->()

    private let onSubscribe         : SubscriptionCallback
    private let observableScheduler : Scheduler
    private let observarScheduler   : Scheduler

    private init (onSubscribe: SubscriptionCallback) {
        self.observableScheduler = Scheduler()
        self.observarScheduler   = Scheduler()
        self.onSubscribe         = observableScheduler.wrap(onSubscribe)
    }

    class func create<T> (onSubscribe: (Observar<T>)->()) -> Observable<T> {
        return Observable<T>(onSubscribe: onSubscribe)
    }

    class func defer<T> (createObservable: ()->Observable<T>) -> Observable<T> {
        return Observable<T>(onSubscribe: { (subscription)->Void in
            createObservable().subscribe(
                onNext:     { element in subscription.onNext(element) },
                onComplete: { subscription.onComplete() }
            )
        })
    }

    class func empty<T> () -> Observable<T> {
        return create { subscription in
            subscription.onComplete()
        }
    }

    class func never<T> () -> Observable<T> {
        return create { subscription in }
    }

    class func from<T> (elements: [T]) -> Observable<T> {
        return create { subscription in
            for element in elements {
                subscription.onNext(element)
            }
            subscription.onComplete()
        }
    }

    class func interval (intervalSec: NSTimeInterval) -> Observable<NSTimer> {
        return Observable<NSTimer>(onSubscribe: { subscription in
            Timer.setInterval(intervalSec) { timer in
                subscription.onNext(timer)
            }
        })
    }

    class func just<T> (element: T) -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            subscription.onNext(element)
            subscription.onComplete()
        })
    }

    class func range (from: Int, _ to: Int) -> Observable<Int> {
        return Observable<Int>(onSubscribe: { subscription in
            for i in from...to {
                subscription.onNext(i)
            }
            subscription.onComplete()
        })
    }

    class func repeat<T> (element: T) -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            while true {
                subscription.onNext(element)
            }
            subscription.onComplete()
        })
    }

    class func start<T> (createElement: ()->T) -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            subscription.onNext(createElement())
            subscription.onComplete()
        })
    }

    class func timer (intervalSec: NSTimeInterval) -> Observable<NSTimer> {
        return Observable<NSTimer>(onSubscribe: { subscription in
            Timer.setTimeout(intervalSec) { timer in
                subscription.onNext(timer)
            }
        })
    }

    func subscribe (#onNext: (T)->(), onComplete: ()->()) -> Observar<T> {
        let observar = Observar<T>(
            onNext:     self.observarScheduler.wrap(onNext),
            onComplete: self.observarScheduler.wrap(onComplete)
        )
        self.onSubscribe(observar)
        return observar
    }

    func filter (filter: (T)->Bool) -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            self.subscribe(
                onNext: { element in
                    if filter(element) {
                        subscription.onNext(element)
                    }
                },
                onComplete: { subscription.onComplete() }
            )
        })
    }

    func map<G> (converter: (T)->G) -> Observable<G> {
        return Observable<G>(onSubscribe: { subscription in
            self.subscribe(
                onNext: { element in subscription.onNext(converter(element)) },
                onComplete: { subscription.onComplete() }
            )
        })
    }

    func flatMap<G> (converter: (T)->Observable<G>) -> Observable<G> {
        return Observable<G>(onSubscribe: { subscription in
            var running     = 0
            var canComplete = false
            self.subscribe(
                onNext: { element in
                    running++
                    converter(element).subscribe(
                        onNext: { element in subscription.onNext(element) },
                        onComplete: {
                            running--
                            if canComplete && running == 0 {
                                subscription.onComplete()
                            }
                        }
                    )
                },
                onComplete: { canComplete = true }
            )
        })
    }

    func buffer(count: Int, skip: Int = 0) -> Observable<[T]> {
        return Observable<[T]>(onSubscribe: { subscription in
            var buffer : [T] = []
            self.subscribe(
                onNext: { element in
                    buffer.append(element)
                    if buffer.count == count + skip {
                        let element = [T](buffer[0...count-skip])
                        subscription.onNext(element)
                        buffer.removeAll()
                    }
                },
                onComplete: { subscription.onComplete() }
            )
        })
    }

    func scan(cb: (T,T)->T) -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            var last : T?
            self.subscribe(
                onNext: { right in
                    var element = right
                    if let left = last {
                        element = cb(left, right)
                    }
                    subscription.onNext(element)
                    last = element
                },
                onComplete: { subscription.onComplete() }
            )
        })
    }

    func tap (cb: (T)->()) -> Observable<T> {
        return self.map { element in
            cb(element)
            return element
        }
    }

    func debounce (intervalSec: NSTimeInterval) -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            var latest : NSTimeInterval = 0.0
            self.subscribe(
                onNext: { element in
                    latest = NSDate().timeIntervalSince1970
                    Timer.setTimeout(intervalSec) { _ in
                        let current = NSDate().timeIntervalSince1970
                        if current > latest + intervalSec {
                            subscription.onNext(element)
                        }
                    }
                },
                onComplete: {
                    Timer.setTimeout(intervalSec) { _ in subscription.onComplete() }
                }
            )
        })
    }

    func elementAt (index: Int) -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            var i = 0
            self.subscribe(
                onNext: { element in
                    if i == index {
                        subscription.onNext(element)
                    }
                    else if i == index + 1 {
                        subscription.onComplete()
                    }
                    i++
                },
                onComplete: {}
            )
        })
    }

    func first() -> Observable<T> {
        return self.take(1)
    }

    func ignoreElements () -> Observable<T> {
        return self.filter { _ in false }
    }

    func last() -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            var latest : T?
            self.subscribe(
                onNext: { element in latest = element },
                onComplete: {
                    if let element = latest {
                        subscription.onNext(element)
                    }
                    subscription.onComplete()
                }
            )
        })
    }

    func take(count: Int) -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            var rest = count
            self.subscribe(
                onNext: { element in
                    if rest == 0 {
                        subscription.onComplete()
                        rest--
                    }
                    else if rest > 0 {
                        subscription.onNext(element)
                        rest--
                    }
                },
                onComplete: {}
            )
        })
    }

    func skip(count: Int) -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            var rest = count
            self.subscribe(
                onNext: { element in
                    if rest > 0 {
                        rest--
                        return
                    }
                    subscription.onNext(element)
                },
                onComplete: { subscription.onComplete() }
            )
        })
    }

    func throttle (intervalSec: NSTimeInterval) -> Observable<T> {
        var latest : NSTimeInterval = 0.0
        return self.filter { _ in
            let current = NSDate().timeIntervalSince1970
            if current > latest + intervalSec {
                latest = current
                return true
            }
            else {
                return false
            }
        }
    }

    func merge (observables: Observable<T>...) -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            var rest = observables.count
            for observable in observables {
                observable.subscribe(
                    onNext: { element in
                        subscription.onNext(element)
                    },
                    onComplete: {
                        if --rest == 0 {
                            subscription.onComplete()
                        }
                    }
                )
            }
        })
    }

    func startWith(elements: T...) -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            for element in elements {
                subscription.onNext(element)
            }
            self.subscribe(
                onNext: { element in subscription.onNext(element) },
                onComplete: { subscription.onComplete() }
            )
        })
    }

    func count() -> Observable<Int> {
        return Observable<Int>(onSubscribe: { subscription in
            var i = 0
            self.subscribe(
                onNext: { _ in i++ },
                onComplete: {
                    subscription.onNext(i)
                    subscription.onComplete()
                }
            )
        })
    }

    func reduce(cb: (T, T)->T) -> Observable<T> {
        return Observable<T>(onSubscribe: { subscription in
            var last : T?
            self.subscribe(
                onNext: { r in
                    if let l = last {
                        last = cb(l, r)
                    }
                    else {
                        last = r
                    }
                },
                onComplete: {
                    if let result = last {
                        subscription.onNext(result)
                    }
                    subscription.onComplete()
                }
            )
        })
    }
}
