/*
 * Copyright (c) 2014-2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import XCTest
import RxSwift
import RxTest
import RxBlocking

class TestingOperators : XCTestCase {
    
    var scheduler: TestScheduler!
    var subscription: Disposable!
    
    override func setUp() {
        super.setUp()
        // TestScheduler 是一个`虚拟`时间调度器!!!
        // 也就是说这个调度器里面的时间是`假`的.
        // 这使得测试实际上是同步的.
        scheduler = TestScheduler(initialClock: 0)
    }
    
    override func tearDown() {
        scheduler.scheduleAt(1000) {
            self.subscription.dispose()
        }
        super.tearDown()
    }
    
    func testAmb() {
        // create observer
        let observer = scheduler.createObserver(String.self)
        // create observableA
        let observableA = scheduler.createHotObservable([
            next(100, "a"),
            next(200, "b"),
            next(300, "c")
            ])
        // create observableB
        let observableB = scheduler.createHotObservable([
            next(90, "1"),
            next(200, "2"),
            next(300, "3")
            ])
        // 使用 amb 操作符
        let ambObservable = observableA.amb(observableB)
        // 执行订阅
        scheduler.scheduleAt(0) {
            self.subscription = ambObservable.subscribe(observer)
        }
        // 启动调度器
        scheduler.start()
        // 搜集并分析结果
        let results = observer.events.map { $0.value.element! }
        XCTAssertEqual(results, ["1", "2", "3"])
    }
    
    func testFilter() {
        let observer = scheduler.createObserver(Int.self)
        let observable = scheduler.createHotObservable([
            next(100, 1),
            next(200, 2),
            next(300, 3),
            next(400, 2),
            next(500, 1),
            ])
        let filterObservable = observable.filter { $0 < 3 }
        scheduler.scheduleAt(0) {
            self.subscription = filterObservable.subscribe(observer)
        }
        scheduler.start()
        let results = observer.events.map { $0.value.element! }
        XCTAssertEqual(results, [1, 2, 2, 1])
    }
    
    // 异步测试 toArray 运算符
    func testToArray() {
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
        let observable = Observable.of(1, 2).subscribeOn(scheduler)
        XCTAssertEqual(try! observable.toBlocking().toArray(), [1, 2])
    }
    
    // 异步测试 materialize 运算符
    func testMaterialize() {
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
        let observable = Observable.of(1, 2).subscribeOn(scheduler)
        let result = observable
            .toBlocking()
            .materialize()
        switch result {
        case .completed(elements: let elements):
            XCTAssertEqual(elements, [1, 2])
        case .failed(elements: let elements, error: let error):
            print("❌❌❌ \(elements) ❌❌❌")
            XCTFail(error.localizedDescription)
        }
    }
    
}
