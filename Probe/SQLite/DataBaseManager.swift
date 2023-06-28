//
//  DataBaseManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/21.
//

import Cocoa

class DataBaseManager: NSObject {
    private var databaseWrapper: SQLiteDatabaseWrapper
    
    var caseTableManager: DatabaseCaseTableManager
    var templateTableManagers = [Int64 : DatabaseTemplateTableManager]()
    
    init(database: SQLiteDatabaseWrapper) {
        databaseWrapper = database
        caseTableManager = DatabaseCaseTableManager(database: database)
    }
    
    func insert(_ model: TestCaseModel) {
        caseTableManager.insert(model)
        let manager = getTemplateTableManager(model.id)
        manager.createTable(model.templateModels)
    }
    
    func reset(_ model: TestCaseModel) {
        let manager = getTemplateTableManager(model.id)
        manager.createTable(model.templateModels)
    }
    
    func delete(_ model: TestCaseModel) {
        caseTableManager.delete(model)
        let manager = getTemplateTableManager(model.id)
        manager.dropTable()
    }
    
    func update(_ caseModel: TestCaseModel, templateModel: TemplateModel) {
        caseTableManager.update(caseModel)
        let templateTableManager = getTemplateTableManager(caseModel.id)
        
        templateTableManager.update(templateModel)
    }
    
    func select() -> [TestCaseModel] {
        let caseModels = caseTableManager.select()
        for caseModel in caseModels {
            let templateTableManager = getTemplateTableManager(caseModel.id)
            
            caseModel.templateModels = templateTableManager.select()
        }
        return caseModels
    }
    
    private func getTemplateTableManager(_ id: Int64) -> DatabaseTemplateTableManager {
        if let templateTableManager = templateTableManagers[id] {
            return templateTableManager
        } else {
            let manager = DatabaseTemplateTableManager(database: databaseWrapper, caseId: id)
            templateTableManagers[id] = manager
            return manager
        }
    }
}
