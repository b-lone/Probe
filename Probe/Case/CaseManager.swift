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
            if oldValue?.id != currentTestCase?.id {
                currentTestCaseRelay.accept(currentTestCase)
            }
        }
    }
    var caseModels = [TestCaseModel]()
    
    var databaseManager: DataBaseManager
    
    private let currentTestCaseRelay = BehaviorRelay<TestCaseModel?>(value: nil)
    lazy var currentTestCaseObservable: Observable<TestCaseModel?> = currentTestCaseRelay.asObservable()
    let templateModelSubject = PublishSubject<TemplateModel>()
    
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
    
    func update(_ templateModel: TemplateModel, needSave: Bool = false) {
        guard let currentTestCase = currentTestCase else { return }
        
        if needSave {
            databaseManager.update(currentTestCase, templateModel: templateModel)
        }
        
        templateModelSubject.onNext(templateModel)
    }
    
    func changeCurrentTestCase(to index: Int) {
        guard index >= 0, index < caseModels.count else { return }
        currentTestCase = caseModels[index]
    }
}
