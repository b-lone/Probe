//
//  CreateCaseWindowController.swift
//  Probe
//
//  Created by Archie You on 2023/6/21.
//

import Cocoa
import RxSwift
import RxCocoa
import SnapKit

class NewCaseWindowController: NSWindowController, NSWindowDelegate {
    private let nameLabel: NSTextField = {
        let label = NSTextField(frame: NSRect(x: 20, y: 120, width: 80, height: 22))
        label.stringValue = "用例名:"
        label.isBordered = false
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameTextField: NSTextField = {
        let textField = NSTextField(frame: NSRect(x: 110, y: 120, width: 200, height: 22))
        textField.placeholderString = "输入测试用例名"
        textField.isBordered = true
        textField.isBezeled = true
        textField.isEditable = true
        textField.isSelectable = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let importLabel: NSTextField = {
        let label = NSTextField(frame: NSRect(x: 20, y: 80, width: 80, height: 22))
        label.stringValue = "导入路径:"
        label.isBordered = false
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let importTextField: NSTextField = {
        let textField = NSTextField(frame: NSRect(x: 110, y: 80, width: 200, height: 22))
        textField.placeholderString = "输入导入路径"
        textField.isBordered = true
        textField.isBezeled = true
        textField.isEditable = true
        textField.isSelectable = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var importButton: NSButton = {
        let button = NSButton(frame: NSRect(x: 320, y: 80, width: 80, height: 22))
        button.title = "选择文件"
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(importButtonClicked)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var confirmButton: NSButton = {
        let button = NSButton(frame: NSRect(x: 160, y: 20, width: 120, height: 30))
        button.title = "确定"
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(confirmButtonClicked)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var nameStackView: NSStackView = {
        let view = NSStackView()
        view.orientation = .horizontal
        view.alignment = .centerY
        view.spacing = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var importStackView: NSStackView = {
        let view = NSStackView()
        view.orientation = .horizontal
        view.alignment = .centerY
        view.spacing = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var confirmView: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override var windowNibName: NSNib.Name? {
        return "NewCaseWindowController"
    }
    
    private let importManager = ImportManager()
    
    let manualReplay = BehaviorRelay<Bool>(value: false)
    private let disposeBag = DisposeBag()
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = self.window, let contentView = window.contentView else { return }
        
        
        nameStackView.addArrangedSubview(nameLabel)
        nameStackView.addArrangedSubview(nameTextField)
        
        contentView.addSubview(nameStackView)
        
        importStackView.addArrangedSubview(importLabel)
        importStackView.addArrangedSubview(importTextField)
        importStackView.addArrangedSubview(importButton)
        
        contentView.addSubview(importStackView)
        
        confirmView.addSubview(confirmButton)
        
        contentView.addSubview(confirmView)
        
        nameStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(20)
        }
        importStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(nameStackView.snp.bottom).offset(16)
            make.height.equalTo(20)
        }
        confirmView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(importStackView.snp.bottom).offset(16)
        }
        confirmButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        weak var weakSelf = self
        
        let manualValid = manualReplay.asObservable()
        let everythingValid = Observable.combineLatest(nameTextField.rx.text.orEmpty, importTextField.rx.text.orEmpty, manualValid){ _,_,_  in
            if let strongSelf = weakSelf {
                return !strongSelf.nameTextField.stringValue.isEmpty && !strongSelf.importTextField.stringValue.isEmpty
            }
            return false
        }.share(replay: 1)
        everythingValid.bind(to: confirmButton.rx.isEnabled).disposed(by: disposeBag)
    }
    
    @objc func importButtonClicked() {
        weak var weakSelf = self
        importManager.importFromFile { url in
            guard let url = url else { return }
            weakSelf?.importTextField.stringValue = url.path
            weakSelf?.manualReplay.accept(false)
        }
    }
    
    @objc func confirmButtonClicked() {
        let name = nameTextField.stringValue
        if AppContext.shared.caseManager.testCases.contains(where: { $0.name == name }) {
            let alert = NSAlert()
            alert.messageText = "名字重复"
            alert.informativeText = "请重新输入一个唯一的名字。"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")

            alert.runModal()
            return
        }
        
        let ids = importManager.parseFile(importTextField.stringValue).map {($0 as NSString).longLongValue}
        let testCase = TestCaseModel(name: nameTextField.stringValue, templateIds: ids)
        let templateModels = ids.map { id in
            TemplateModel(id: id, caseIds: [testCase.id])
        }
        
        guard !templateModels.isEmpty else {
            print("Import Failed!")
            return
        }
        
        testCase.templates = templateModels
        
        AppContext.shared.caseManager.appendNewCase(testCase)
        
        close()
    }
}
