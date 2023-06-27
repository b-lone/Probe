//
//  BaseViewController.swift
//  Probe
//
//  Created by Archie You on 2023/6/26.
//

import Cocoa
import RxCocoa
import RxSwift

class BaseViewController: NSViewController {
    var caseManager: CaseManager {
        AppContext.shared.caseManager
    }
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
