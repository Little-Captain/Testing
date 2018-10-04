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
import RxCocoa
import RxTest
@testable import Testing

class TestingViewModel : XCTestCase {
    
    var viewModel: ViewModel!
    var scheduler: ConcurrentDispatchQueueScheduler!
    
    override func setUp() {
        super.setUp()
        viewModel = ViewModel()
        scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
    }
    
    override func tearDown() {
        viewModel = nil
        scheduler = nil
        super.tearDown()
    }
    
    // 传统的异步测试实现
    func testColorIsRedWhenHexStringIsFF0000_async() {
        let bag = DisposeBag()
        // 创建测试期望
        let expect = expectation(description: #function)
        let expectedColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        var result: UIColor!
        viewModel
            .color.asObservable()
            .skip(1)
            .subscribe(onNext: {
                result = $0
                // 达成期望
                expect.fulfill()
            })
            .disposed(by: bag)
        viewModel.hexString.value = "#ff0000"
        // 等待达成期望(上面定义的所有期望都达成才算达成)
        // If provided, the handler will be invoked both on timeout or fulfillment
        // of all expectations. Timeout is always treated as a test failure.
        // 如果提供了 handler, 超时或所有期望都达成, 这个 handler 就会被调用.
        // 超时被视为测试失败
        waitForExpectations(timeout: 1.0) { error in
            // `等待时间到` or `相关的期望都达成了`调用
            guard let error = error else {
                // 相关的期望都达成了, 断言测试结果是否符合预期
                XCTAssertEqual(expectedColor, result)
                return
            }
            // 发生错误(等待时间到了, 但相关的期望未完全达成, 即超时!!!)
            XCTFail(error.localizedDescription)
        }
    }
    
    func testColorIsRedWhenHexStringIsFF0000() {
        let colorObservable = viewModel
            .color.asObservable()
            .subscribeOn(scheduler)
        
        viewModel.hexString.value = "#ff0000"
        
        do {
            // toBlocking() 的作用就是阻塞当前线程
            guard let result = try colorObservable.toBlocking().first() else {
                return
            }
            XCTAssertEqual(result, .red)
        } catch {
            print(error)
        }
    }
    
    func testRgbIs010WhenHexStringIs00FF00() {
        let rgbObservable = viewModel
            .rgb.asObservable()
            .subscribeOn(scheduler)
        
        viewModel.hexString.value = "#ebf2ab"
        
        let result = try! rgbObservable.toBlocking().first()!
        
        XCTAssertEqual(0xeb, result.0)
        XCTAssertEqual(0xf2, result.1)
        XCTAssertEqual(0xab, result.2)
    }
    
    func testColorNameIsRayWenderlichGreenWhenHexStringIs006636() {
        let colorNameObservable = viewModel
            .colorName.asObservable()
            .subscribeOn(scheduler)
        
        viewModel.hexString.value = "#006636"
        
        XCTAssertEqual("rayWenderlichGreen", try! colorNameObservable.toBlocking().first()!)
    }
    
    func testColorNameIsNamelessWhenHexStringIs006635() {
        let colorNameObservable = viewModel
            .colorName.asObservable()
            .subscribeOn(scheduler)
        
        viewModel.hexString.value = "#006635"
        
        XCTAssertEqual("--", try! colorNameObservable.toBlocking().first()!)
    }
    
}
