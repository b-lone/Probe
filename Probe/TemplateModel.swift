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
    var state = State.ready
    var useMontage = false
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
    
    override var description: String {
        return "\(id) \(state) \(useMontage) \(startMemory) \(endMemory) \(maxMemory) \(duration) \(errorMsg ?? "-") \(filePath ?? "-")"
    }
}
