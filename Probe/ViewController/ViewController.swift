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
    private lazy var caseWindowController = {
        CaseWindowController()
    }()
    
    private lazy var stackView: NSStackView = {
        let view = NSStackView()
        view.alignment = .centerY
        view.spacing = 16
        view.orientation = .horizontal
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let buttonInfos = [
            ("Show Case Window", #selector(onShowCaseWindow(_:))),
        ]
        
        for buttonInfo in buttonInfos {
            makeButton(buttonInfo)
        }
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    @objc
    private func onShowCaseWindow(_ sender: Any) {
        caseWindowController.window?.center()
        caseWindowController.window?.makeKeyAndOrderFront(nil)
    }
    
    private func makeButton(_ buttonInfo: (title: String, selector: Selector)) {
        let button = NSButton()
        button.title = buttonInfo.title
        button.bezelStyle = .rounded
        button.target = self
        button.action = buttonInfo.selector
        stackView.addArrangedSubview(button)
    }
}

