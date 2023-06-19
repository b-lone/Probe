//
//  ViewController.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/24.
//

import Cocoa

class ViewController: NSViewController, ImportManagerDelegate, SocketManagerDelegate, NSTableViewDelegate, NSTableViewDataSource {
    private let importManager = ImportManager()
    private var exportManager = ExportManager()
    private let socketManager = SocketManager()
    private let cacheManager = CacheManager()
    private let launchManager = LaunchManager()
    private var templateModels = [TemplateModel]()
    private var needResendStartMessage = true
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var successCountLabel: NSTextField!
    @IBOutlet weak var failedCountLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        successCountLabel.textColor = TemplateModel.State.success.color
        failedCountLabel.textColor = TemplateModel.State.failed.color
        
        importManager.delegate = self
        socketManager.delegate = self
        cacheManager.setup()

        templateModels = cacheManager.select()
        update()
    }
    
    private func update() {
        tableView.reloadData()
        
        let totalCount = templateModels.count
        let finishedTemplateModels = templateModels.filter { $0.state == .failed || $0.state == .success }
        let finishedCount = finishedTemplateModels.count
        let successTemplateModels = finishedTemplateModels.filter { $0.state == .success }
        let successCount = successTemplateModels.count
        
        progressLabel.stringValue = "\(finishedCount)/\(totalCount)"
        successCountLabel.stringValue = "\(successCount)"
        failedCountLabel.stringValue = "\(finishedCount - successCount)"
    }
    
    private func sendStartMessage() {
        guard needResendStartMessage else { return }
        needResendStartMessage = false
        socketManager.connectToServer()
        socketManager.sendStartMessage(templateModels.filter({ $0.state == .ready }))
    }
// MARK: - IBAction
    @IBAction func onImport(_ sender: Any) {
        importManager.importFromFile()
    }
    
    @IBAction func onStart(_ sender: Any) {
        socketManager.connectToServer()
        sendStartMessage()
    }
    
    @IBAction func onExport(_ sender: Any) {
        exportManager.exprot(templateModels)
    }
    
// MARK: - ImportManagerDelegate
    func importDidFinish(_ data: [String]) {
        let templateModels = data.map { id in
            TemplateModel(id: id)
        }
        cacheManager.createTable(templateModels)

        self.templateModels = cacheManager.select()
        update()
    }
// MARK: - SocketManagerDelegate
    func onInProgress(_ message: [String : String]) {
        if let id = message["id"], let templateModel = templateModels.first(where: { $0.id == id }) {
            templateModel.state = .inProgress
            update()
        }
    }
    
    func onUseMontage(_ message: [String : String]) {
        if let id = message["id"],
           let templateModel = templateModels.first(where: { $0.id == id }) {
            templateModel.useMontage = (message["useMontage"] as? NSString)?.boolValue ?? false
            
            cacheManager.update(templateModel)
            
            update()
        }
    }
    
    func onFinish(_ message: [String : String]) {
        if let id = message["id"],
           let success = (message["success"] as? NSString)?.boolValue,
           let templateModel = templateModels.first(where: { $0.id == id }) {
            templateModel.state = success ? .success : .failed
            templateModel.useMontage = (message["useMontage"] as? NSString)?.boolValue ?? false
            templateModel.startMemory = (message["startMemory"] as? NSString)?.integerValue ?? -1
            templateModel.endMemory = (message["endMemory"] as? NSString)?.integerValue ?? -1
            templateModel.maxMemory = (message["maxMemory"] as? NSString)?.integerValue ?? -1
            templateModel.duration = (message["duration"] as? NSString)?.integerValue ?? -1
            templateModel.errorMsg = message["error_msg"]
            templateModel.filePath = message["file_path"]
            
            cacheManager.update(templateModel)
            
            update()
        }
    }
    
    func onConnect() {
        sendStartMessage()
    }
    
    func onDisconnect() {
        needResendStartMessage = true
        
        launchManager.launch()
        let inProgressTemplateModels = templateModels.filter { $0.state == .inProgress }
        inProgressTemplateModels.forEach {
            $0.state = .failed
            $0.errorMsg = "crash"
            cacheManager.update($0)
        }
        
        update()
    }
// MARK: - NSTableViewDelegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        return templateModels.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TableCellView"), owner: nil) as? TableCellView
        view?.setup(templateModels[row])
        return view ?? TableCellView()
    }
}

