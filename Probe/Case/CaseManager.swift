//
//  CaseManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/20.
//

import Cocoa
import RxSwift
import RxCocoa

class CaseManager: NSObject {
    var currentTestCase: TestCaseModel? {
        didSet {
            currentTestCaseRelay.accept(currentTestCase)
        }
    }
    var testCases = [TestCaseModel]()
    
    private let currentTestCaseRelay = BehaviorRelay<TestCaseModel?>(value: nil)
    var currentTestCaseObservable: Observable<TestCaseModel?> {
        return currentTestCaseRelay.asObservable()
    }
    
    func appendNewCase(_ testCase: TestCaseModel) {
        testCases.append(testCase)
        currentTestCase = testCase
    }
}
