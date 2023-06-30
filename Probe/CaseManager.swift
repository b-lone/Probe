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
                UserDefaults.standard.set(currentTestCase?.id, forKey: "current_id")
            }
        }
    }
    var testCases = [TestCaseModel]() {
        didSet {
            testCasesRelay.accept(testCases)
        }
    }
    var templates = [TemplateModel]() {
        didSet {
            templatesRelay.accept(templates)
        }
    }
    var results = [ResultModel]() {
        didSet {
            resultsRelay.accept(results)
        }
    }
    var frameRenderingTimes = [FrameRenderingTimeModel]() {
        didSet {
            frameRenderingTimesRelay.accept(frameRenderingTimes)
        }
    }
    var runningTasks = [RunningTaskModel]() {
        didSet {
            runningTasksRelay.accept(runningTasks)
        }
    }
    
    var databaseManager = DatabaseManager()
    
    private let currentTestCaseRelay = BehaviorRelay<TestCaseModel?>(value: nil)
    lazy var currentTestCaseObservable: Observable<TestCaseModel?> = currentTestCaseRelay.asObservable()
    
    private lazy var testCasesRelay = BehaviorRelay<[TestCaseModel]>(value: testCases)
    lazy var testCasesObservable: Observable<[TestCaseModel]> = testCasesRelay.asObservable()
    
    private lazy var templatesRelay = BehaviorRelay<[TemplateModel]>(value: templates)
    lazy var templatesObservable: Observable<[TemplateModel]> = templatesRelay.asObservable()
    
    private lazy var resultsRelay = BehaviorRelay<[ResultModel]>(value: results)
    lazy var resultsObservable: Observable<[ResultModel]> = resultsRelay.asObservable()
    
    private lazy var frameRenderingTimesRelay = BehaviorRelay<[FrameRenderingTimeModel]>(value: frameRenderingTimes)
    lazy var frameRenderingTimesObservable: Observable<[FrameRenderingTimeModel]> = frameRenderingTimesRelay.asObservable()
    
    private lazy var runningTasksRelay = BehaviorRelay<[RunningTaskModel]>(value: runningTasks)
    lazy var runningTasksObservable: Observable<[RunningTaskModel]> = runningTasksRelay.asObservable()
    
    let disposeBag = DisposeBag()
    
    func setup() {
        updateAll()

        let currentId = UserDefaults.standard.integer(forKey: "current_id")
        currentTestCase = testCases.first{ $0.id == currentId }
    }
    
    func appendNewCase(_ testCase: TestCaseModel) {
        var theTemplateModels = [TemplateModel]()
        var newTemplateModels = [TemplateModel]()
        for templateModel in testCase.templates {
            if let model = templates.first(where: { $0.id == templateModel.id }) {
                model.caseIds.append(testCase.id)
                theTemplateModels.append(model)
            } else {
                newTemplateModels.append(templateModel)
                theTemplateModels.append(templateModel)
            }
        }
        theTemplateModels = theTemplateModels.sorted { testCase.templateIds.firstIndex(of: $0.id)! < testCase.templateIds.firstIndex(of: $1.id)! }
        testCase.templates = theTemplateModels
        
        databaseManager.caseTableManager.insert(testCase)
        databaseManager.templateTableManager.insert(theTemplateModels)
        
        testCases.append(testCase)
        newTemplateModels += templates
        templates = newTemplateModels.sorted { $0.id < $1.id }
        
        currentTestCase = testCase
    }
    
    func delete(_ testCase: TestCaseModel) {
        testCases.removeAll { $0.id == testCase.id }
        if currentTestCase?.id == testCase.id {
            currentTestCase = testCases.first
        }
        databaseManager.caseTableManager.delete(testCase)
    }
    
    func changeCurrentTestCase(to index: Int) {
        guard index >= 0, index < testCases.count else { return }
        currentTestCase = testCases[index]
    }
    
    func updateAll() {
        testCases = databaseManager.caseTableManager.select()
        templates = databaseManager.templateTableManager.select()
        results = databaseManager.resultTableManager.select()
        frameRenderingTimes = databaseManager.frameRenderingTimeTableManager.select()
        runningTasks = databaseManager.runningTaskTableManager.select()
        
        DispatchQueue.global().async {
            for testCase in self.testCases {
                let filteredTemplates = self.templates.filter { testCase.templateIds.contains($0.id) }
                let sortedTemplates = filteredTemplates.sorted { testCase.templateIds.firstIndex(of: $0.id)! < testCase.templateIds.firstIndex(of: $1.id)! }
                testCase.templates = sortedTemplates
                testCase.runningTasks = self.runningTasks.filter{ $0.caseId == testCase.id }
            }

            print("[Running][load]testCase finished!")
        }
        
        DispatchQueue.global().async {
            for templateModel in self.templates {
                templateModel.results = self.results.filter{ $0.templateId == templateModel.id }
            }
            print("[Running][load]templateModel finished!")
        }
        
        DispatchQueue.global().async {
            for resultModel in self.results {
                    resultModel.frameRenderingTimes = self.frameRenderingTimes.filter{ $0.resultId == resultModel.id }
            }
            print("[Running][load]resultModel finished!")
        }
        
        DispatchQueue.global().async {
            for runningTaskModel in self.runningTasks {
                runningTaskModel.results = self.results.filter { $0.taskId == runningTaskModel.id }
                runningTaskModel.templates = self.templates.filter({ runningTaskModel.templateIds.contains($0.id) })
                runningTaskModel.update()
            }
            print("[Running][load]runningTaskModel finished!")
        }
    }
    
    func updateTestCases() {
        testCases = databaseManager.caseTableManager.select()
        for testCase in testCases {
            let filteredTemplates = templates.filter { testCase.templateIds.contains($0.id) }
            let sortedTemplates = filteredTemplates.sorted { testCase.templateIds.firstIndex(of: $0.id)! < testCase.templateIds.firstIndex(of: $1.id)! }
            testCase.templates = sortedTemplates
            testCase.runningTasks = runningTasks.filter{ $0.caseId == testCase.id }
        }
    }
    
    func updateTemplates() {
        templates = databaseManager.templateTableManager.select()
        for templateModel in templates {
            templateModel.results = results.filter{ $0.templateId == templateModel.id }
        }
    }
    
    func updateResult() {
        results = databaseManager.resultTableManager.select()
        for resultModel in results {
            resultModel.frameRenderingTimes = frameRenderingTimes.filter{ $0.resultId == resultModel.id }
        }
    }
    
    func updateFrameRenderingTime() {
        frameRenderingTimes = databaseManager.frameRenderingTimeTableManager.select()
    }
    
    func updateRunningTask() {
        runningTasks = databaseManager.runningTaskTableManager.select()
        for runningTaskModel in runningTasks {
            runningTaskModel.results = results.filter { $0.taskId == runningTaskModel.id }
            runningTaskModel.templates = templates.filter({ runningTaskModel.templateIds.contains($0.id) })
            runningTaskModel.update()
        }
    }
    
    func getResult(_ runningTaskId: Int64, _ templateId: Int64) -> ResultModel? {
        if let runningTask = runningTasks.first(where: { $0.id == runningTaskId }),
           let template = templates.first(where: { $0.id == templateId }) {
            if let result = template.results.first(where: { $0.taskId == runningTaskId && $0.templateId == templateId }) {
                return result
            } else {
                let result = ResultModel(templateId: templateId, taskId: runningTaskId)
                runningTask.results.append(result)
                template.results.append(result)
                results.append(result)
                
                databaseManager.resultTableManager.insert(result)
                
                return result
            }
        }
        return nil;
    }
}
