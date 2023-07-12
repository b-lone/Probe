//
//  StatisticsViewController.swift
//  Probe
//
//  Created by Archie You on 2023/6/26.
//

import Cocoa
import Combine

class StatisticsViewController: BaseViewController {
    private lazy var taskStackView: NSStackView = {
        let view = NSStackView()
        view.alignment = .centerY
        view.spacing = 16
        view.orientation = .horizontal
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var taskProgressLabel: NSTextField = {
        let view = NSTextField()
        view.isBordered = false
        view.isBezeled = false
        view.isEditable = false
        view.backgroundColor = .clear
        view.alignment = .center
        return view
    }()
    
    private lazy var taskSuccessCountLabel: NSTextField = {
        let view = NSTextField()
        view.isBordered = false
        view.isBezeled = false
        view.isEditable = false
        view.backgroundColor = .clear
        view.alignment = .center
        view.textColor = ResultModel.State.success.color
        return view
    }()
    
    private lazy var taskFailedCountLabel: NSTextField = {
        let view = NSTextField()
        view.isBordered = false
        view.isBezeled = false
        view.isEditable = false
        view.backgroundColor = .clear
        view.alignment = .center
        view.textColor = ResultModel.State.failed.color
        return view
    }()
    
    private lazy var caseStackView: NSStackView = {
        let view = NSStackView()
        view.alignment = .centerY
        view.spacing = 16
        view.orientation = .horizontal
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var caseProgressLabel: NSTextField = {
        let view = NSTextField()
        view.isBordered = false
        view.isBezeled = false
        view.isEditable = false
        view.backgroundColor = .clear
        view.alignment = .center
        return view
    }()
    
    private lazy var caseSuccessCountLabel: NSTextField = {
        let view = NSTextField()
        view.isBordered = false
        view.isBezeled = false
        view.isEditable = false
        view.backgroundColor = .clear
        view.alignment = .center
        view.textColor = ResultModel.State.success.color
        return view
    }()
    
    private lazy var caseFailedCountLabel: NSTextField = {
        let view = NSTextField()
        view.isBordered = false
        view.isBezeled = false
        view.isEditable = false
        view.backgroundColor = .clear
        view.alignment = .center
        view.textColor = ResultModel.State.failed.color
        return view
    }()
    
    private var sumCancellable: AnyCancellable?
    private var finishedCountCancellable: AnyCancellable?
    private var successCountCancellable: AnyCancellable?
    private var failedCountCancellable: AnyCancellable?
    
    deinit {
        
    }
    
    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        taskStackView.addArrangedSubview(taskProgressLabel)
        taskStackView.addArrangedSubview(taskSuccessCountLabel)
        taskStackView.addArrangedSubview(taskFailedCountLabel)
        
        view.addSubview(taskStackView)
        taskStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        caseStackView.addArrangedSubview(caseProgressLabel)
        caseStackView.addArrangedSubview(caseSuccessCountLabel)
        caseStackView.addArrangedSubview(caseFailedCountLabel)
        
        view.addSubview(caseStackView)
        caseStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        weak var weakSelf = self
        caseManager.currentTestCaseObservable.subscribe { _ in
            weakSelf?.update()
        }.disposed(by: disposeBag)
        
        caseManager.runningTasksObservable.subscribe { _ in
            weakSelf?.update()
        }.disposed(by: disposeBag)
    }
    
    func update() {
        taskProgressLabel.stringValue = "0/0"
        taskSuccessCountLabel.stringValue = "0"
        taskFailedCountLabel.stringValue = "0"
        
        updateCaseStatistics()
        
        guard let runningTask = caseManager.currentTestCase?.mostRencentRunningTask else { return }
        
        weak var weakSelf = self
        sumCancellable = runningTask.$sum.sink { weakSelf?.taskProgressLabel.stringValue = "\(runningTask.finishedCount)/\($0)" }
        finishedCountCancellable = runningTask.$finishedCount.sink {
            weakSelf?.taskProgressLabel.stringValue = "\($0)/\(runningTask.sum)"
            weakSelf?.updateCaseStatistics()
        }
        successCountCancellable = runningTask.$successCount.sink { weakSelf?.taskSuccessCountLabel.stringValue = "\($0)" }
        failedCountCancellable = runningTask.$failedCount.sink { weakSelf?.taskFailedCountLabel.stringValue = "\($0)" }
    }
    
    private func updateCaseStatistics() {
        guard let testCase = caseManager.currentTestCase else { return }
        let successTemplates = caseManager.currentTestCase?.templates.filter({ $0.mostRencentResult(in: testCase)?.state == .success })
        let failedTemplates = caseManager.currentTestCase?.templates.filter({ $0.mostRencentResult(in: testCase)?.state == .failed })
        let successCount = successTemplates?.count ?? 0
        let failedCount = failedTemplates?.count ?? 0
        caseProgressLabel.stringValue = "\(successCount + failedCount)/\(caseManager.currentTestCase?.templates.count ?? 0)"
        caseSuccessCountLabel.stringValue = "\(successCount)"
        caseFailedCountLabel.stringValue = "\(failedCount)"
    }
}
