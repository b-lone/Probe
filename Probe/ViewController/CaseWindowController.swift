//
//  CaseWindowController.swift
//  Probe
//
//  Created by Archie You on 2023/7/5.
//

import Cocoa

import RxSwift
import RxCocoa
import SnapKit

class CaseWindowController: NSWindowController {
    lazy var viewController: CaseViewContoller = CaseViewContoller()
    
    override var windowNibName: NSNib.Name? {
        return "CaseWindowController"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.contentViewController = viewController
    }
    
}
