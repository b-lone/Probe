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
    private let socketManager: SocketManager
    private let launchManager: LaunchManager
    
    private lazy var stackView: NSStackView = {
        let view = NSStackView()
        view.alignment = .centerY
        view.spacing = 16
        view.orientation = .horizontal
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var newCaseWindowController: NewCaseWindowController?
    private let sendStartMessage: ()->Void
    
    init(socketManager: SocketManager, launchManager: LaunchManager, sendStartMessage: @escaping ()->Void) {
        self.socketManager = socketManager
        self.launchManager = launchManager
        self.sendStartMessage = sendStartMessage
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let buttonInfos = [
            ("Import", #selector(onImport(_:))),
            ("Start", #selector(onStart(_:))),
            ("Export", #selector(onExport(_:))),
            ("Export Failed IDs", #selector(onExportFailedIds(_:))),
            ("End", #selector(onEnd(_:))),
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
        socketManager.connectToServer()
        sendStartMessage()
    }
    
    @objc
    private func onExport(_ sender: Any) {
        if let templateModels = caseManager.currentTestCase?.templateModels {
            exportManager.exprot(templateModels)
        }
    }
    
    @objc
    private func onExportFailedIds(_ sender: Any) {
        if let templateModels = caseManager.currentTestCase?.templateModels {
            exportManager.exportFailedIds(templateModels)
        }
    }
    
    @objc
    private func onEnd(_ sender: Any) {
        launchManager.end()
    }
}
