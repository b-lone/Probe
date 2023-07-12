//
//  ControlViewController.swift
//  Probe
//
//  Created by Archie You on 2023/6/27.
//

import Cocoa
import SnapKit

class ControlViewController: BaseViewController {
    private var exportManager = ExportManager()
    private var runningManager: RunningManager {
        AppContext.shared.runningManager
    }
    
    private lazy var stackView: NSStackView = {
        let view = NSStackView()
        view.alignment = .centerY
        view.spacing = 16
        view.orientation = .horizontal
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var newCaseWindowController: NewCaseWindowController?
    
    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let buttonInfos = [
            ("Import", #selector(onImport(_:))),
            ("Start", #selector(onStart(_:))),
            ("Stop", #selector(onStop(_:))),
            ("Export", #selector(onExport(_:))),
            ("Export Failed IDs", #selector(onExportFailedIds(_:))),
            ("Delete", #selector(onDelete(_:))),
            ("Reveal in Finder", #selector(onRevealInFinder(_:))),
            ("Reload", #selector(onReload(_:))),
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
    
    private func makeButton(_ buttonInfo: (title: String, selector: Selector)) {
        let button = NSButton()
        button.title = buttonInfo.title
        button.bezelStyle = .rounded
        button.target = self
        button.action = buttonInfo.selector
        stackView.addArrangedSubview(button)
    }
    
    @objc
    private func onImport(_ sender: Any) {
        newCaseWindowController = NewCaseWindowController()
        newCaseWindowController?.window?.center()
        newCaseWindowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    @objc
    private func onStart(_ sender: Any) {
        guard let currentTestCase = caseManager.currentTestCase else { return }
        runningManager.start(currentTestCase)
    }
    
    @objc
    private func onStop(_ sender: Any) {
        runningManager.stop()
    }
    
    @objc
    private func onExport(_ sender: Any) {
        if let templateModels = caseManager.currentTestCase?.templates {
            exportManager.exprot(templateModels)
        }
    }
    
    @objc
    private func onExportFailedIds(_ sender: Any) {
        if let testCase = caseManager.currentTestCase, let templateModels = caseManager.currentTestCase?.templates.filter({ $0.mostRencentResult(in: testCase)?.state == .failed }) {
            exportManager.exportFailedIds(templateModels)
        }
    }
    
    @objc
    private func onDelete(_ sender: Any) {
        guard let testCase = caseManager.currentTestCase else { return }
        caseManager.delete(testCase)
    }
    
    @objc
    private func onRevealInFinder(_ sender: Any) {
        let fileURL = URL(fileURLWithPath: AppContext.shared.fileManager.rootPath)
            
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
    
    @objc
    private func onReload(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("Reload"), object: self)
    }
}
