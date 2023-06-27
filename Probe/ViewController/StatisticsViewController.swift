//
//  StatisticsViewController.swift
//  Probe
//
//  Created by Archie You on 2023/6/26.
//

import Cocoa

class StatisticsViewController: BaseViewController {
    private lazy var stackView: NSStackView = {
        let view = NSStackView()
        view.alignment = .centerY
        view.spacing = 16
        view.orientation = .horizontal
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var progressLabel: NSTextField = {
        let view = NSTextField()
        view.isBordered = false
        view.isBezeled = false
        view.isEditable = false
        view.backgroundColor = .clear
        view.alignment = .center
        return view
    }()
    
    private lazy var successCountLabel: NSTextField = {
        let view = NSTextField()
        view.isBordered = false
        view.isBezeled = false
        view.isEditable = false
        view.backgroundColor = .clear
        view.alignment = .center
        view.textColor = TemplateModel.State.success.color
        return view
    }()
    
    private lazy var failedCountLabel: NSTextField = {
        let view = NSTextField()
        view.isBordered = false
        view.isBezeled = false
        view.isEditable = false
        view.backgroundColor = .clear
        view.alignment = .center
        view.textColor = TemplateModel.State.failed.color
        return view
    }()
    
    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        stackView.addArrangedSubview(progressLabel)
        stackView.addArrangedSubview(successCountLabel)
        stackView.addArrangedSubview(failedCountLabel)
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        weak var weakSelf = self
        caseManager.currentTestCaseObservable.subscribe { _ in
            weakSelf?.update()
        }.disposed(by: disposeBag)
        
        caseManager.templateModelSubject.subscribe { _ in
            weakSelf?.update()
        }.disposed(by: disposeBag)
    }
    
    func update() {
        guard let templateModels = caseManager.currentTestCase?.templateModels else { return }
        
        let totalCount = templateModels.count
        let finishedTemplateModels = templateModels.filter { $0.state == .failed || $0.state == .success }
        let finishedCount = finishedTemplateModels.count
        let successTemplateModels = finishedTemplateModels.filter { $0.state == .success }
        let successCount = successTemplateModels.count
        
        progressLabel.stringValue = "\(finishedCount)/\(totalCount)"
        successCountLabel.stringValue = "\(successCount)"
        failedCountLabel.stringValue = "\(finishedCount - successCount)"
    }
}
