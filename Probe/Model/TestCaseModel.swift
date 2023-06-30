//
//  TestCaseModel.swift
//  Probe
//
//  Created by Archie You on 2023/6/20.
//

import Cocoa

@propertyWrapper
struct DatabaseStoredProperty<ValueType: Equatable, ModelType: NSObject & DatabaseModelProtocol> {
    private var value: ValueType
    var wrappedValue: ValueType {
        set {
            if value != newValue {
                value = newValue
            }
        }
        get { value }
    }
    
    var tableManager: BaseDatabaseTableManager<ModelType>
    var projectedValue: BaseDatabaseTableManager<ModelType> {
        set { tableManager = newValue }
        get { tableManager }
    }
    
    init(tableManager: BaseDatabaseTableManager<ModelType>) {
        if ValueType.self is Int64.Type {
            value = -1 as! ValueType
        } else if ValueType.self is String.Type {
            value = "" as! ValueType
        } else {
            fatalError()
        }
        self.tableManager = tableManager
    }
}

class TestCaseModel: NSObject & DatabaseModelProtocol {
    var id: Int64
    var name: String
    var templateIds = [Int64]()
    var templates = [TemplateModel]()
    var runningTasks = [RunningTaskModel]()
    
    init(id: Int64, name: String, templateIds: [Int64]) {
        self.id = id
        self.name = name
        self.templateIds = templateIds
    }
    
    convenience init(name: String, templateIds: [Int64]) {
        let currentTime = Date().timeIntervalSince1970
        let id = Int64(currentTime * 1000)
        self.init(id: id, name: name, templateIds: templateIds)
    }
    
}

extension TestCaseModel {
    var mostRencentRunningTask: RunningTaskModel? {
        return runningTasks.max { $0.id < $1.id }
    }
}
