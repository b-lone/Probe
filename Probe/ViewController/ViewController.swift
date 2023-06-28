//
//  ViewController.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/24.
//

import Cocoa
import RxSwift
import RxCocoa
import SnapKit

class ViewController: BaseViewController {
    @IBOutlet weak var headerContainerView: NSView!
    @IBOutlet weak var separator: NSView!
    @IBOutlet weak var tableContainerView: NSView!
    @IBOutlet weak var statisticsContainerView: NSView!
    @IBOutlet weak var controlContainerView: NSView!
    
    private lazy var headerViewController: HeaderViewController = {
        let vc = HeaderViewController()
        return vc
    }()
    private lazy var templateTableViewController: TemplateTableViewController = {
        let vc = TemplateTableViewController()
        return vc
    }()
    private lazy var statisticsViewController: StatisticsViewController = {
        let vc = StatisticsViewController()
        return vc
    }()
    private lazy var controlViewController: ControlViewController = {
        weak var weakSelf = self
        let vc = ControlViewController()
        return vc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(headerViewController)
        headerContainerView.addSubview(headerViewController.view)
        headerViewController.view.snp.makeConstraints { make in
            make.top.leading.bottom.trailing.equalToSuperview()
        }
        
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.gray.cgColor
        
        addChild(templateTableViewController)
        tableContainerView.addSubview(templateTableViewController.view)
        templateTableViewController.view.snp.makeConstraints { make in
            make.top.leading.bottom.trailing.equalToSuperview()
        }
        
        addChild(statisticsViewController)
        statisticsContainerView.addSubview(statisticsViewController.view)
        statisticsViewController.view.snp.makeConstraints { make in
            make.top.leading.bottom.trailing.equalToSuperview()
        }
        
        addChild(controlViewController)
        controlContainerView.addSubview(controlViewController.view)
        controlViewController.view.snp.makeConstraints { make in
            make.top.leading.bottom.trailing.equalToSuperview()
        }

        AppContext.shared.caseManager.setup()
    }
}

