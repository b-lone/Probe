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
    var caseModels = [TestCaseModel]()
    
    var databaseManager: DataBaseManager
    
    private let currentTestCaseRelay = BehaviorRelay<TestCaseModel?>(value: nil)
    var currentTestCaseObservable: Observable<TestCaseModel?> {
        return currentTestCaseRelay.asObservable()
    }
    
    init(database: SQLiteDatabaseWrapper) {
        databaseManager = DataBaseManager(database: database)
    }
    
    func setup() {
        caseModels = databaseManager.select()
        currentTestCase = caseModels.first
    }
    
    func appendNewCase(_ testCase: TestCaseModel) {
        caseModels.append(testCase)
        currentTestCase = testCase
        
        databaseManager.insert(testCase)
    }
    
    func update(_ templateModel: TemplateModel) {
        guard let currentTestCase = currentTestCase else { return }
        
        databaseManager.update(currentTestCase, templateModel: templateModel)
    }
}
