//
//  TemplateModel.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/30.
//

import Cocoa

class TemplateModel: NSObject {
    enum State: Int {
        case ready = 0
        case inProgress = 1
        case success = 2
        case failed = 3
        
        var color: NSColor {
            switch self {
            case .ready:
                return .gray
            case .inProgress:
                return .blue
            case .success:
                return .green
            case .failed:
                return .red
            }
        }
    }
    
    var id: String
    var name = "unknown"
    var state = State.ready
    
    var useMontage = false
    private var _useMontageFlag: String?
    var useMontageFlag: String? {
        get {
            if _useMontageFlag?.isEmpty == true {
                return nil
            }
            return _useMontageFlag
        }
        set {
            _useMontageFlag = newValue
        }
    }
    
    var startMemory: Int = -1
    var endMemory: Int = -1
    var maxMemory: Int = -1
    var duration: Int = -1
    
    private var _errorMsg: String?
    var errorMsg: String? {
        get {
            if _errorMsg?.isEmpty == true {
                return nil
            }
            return _errorMsg
        }
        set {
            _errorMsg = newValue
        }
    }
    private var _filePath: String?
    var filePath: String? {
        get {
            if _filePath?.isEmpty == true {
                return nil
            }
            return _filePath
        }
        set {
            _filePath = newValue
        }
    }
    
    init(id: String) {
        self.id = id
    }
    
    let space = "$"
    
    override var description: String {
        return "\(id)\(space)\(name)\(space)\(state)\(space)\(useMontage)\(space)\(useMontageFlag ?? "-")\(space)\(startMemory)\(space)\(endMemory)\(space)\(maxMemory)\(space)\(duration)\(space)\(errorMsg ?? "-")\(space)\(filePath ?? "-")"
    }
}

class ColumnInfo {
    let identifier: String
    let width: CGFloat
    
    init(identifier: String, width: CGFloat) {
        self.identifier = identifier
        self.width = width
    }
}

extension TemplateModel {
    static var columnInfos: [ColumnInfo] {
        return [
            ColumnInfo(identifier: "id", width: 72),
            ColumnInfo(identifier: "name", width: 72),
            ColumnInfo(identifier: "state", width: 72),
            ColumnInfo(identifier: "use montage", width: 72),
            ColumnInfo(identifier: "start memory", width: 72),
            ColumnInfo(identifier: "end memory", width: 72),
            ColumnInfo(identifier: "max memory", width: 72),
            ColumnInfo(identifier: "duration", width: 72),
            ColumnInfo(identifier: "error", width: 160),
            ColumnInfo(identifier: "filepath", width: 160),
        ]
    }
}
