//
//  AppContext.swift
//  Probe
//
//  Created by Archie You on 2023/6/21.
//

import Cocoa

class AppContext: NSObject {
    static let shared = AppContext()
    
    let caseManager = CaseManager()
}
