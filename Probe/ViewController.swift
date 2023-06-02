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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        importManager.delegate = self
        socketManager.delegate = self
        cacheManager.setup()
        
        templateModels = cacheManager.select()
        tableView.reloadData()
    }
    
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
    
    func importDidFinish(_ data: [String]) {
        let templateModels = data.map { id in
            TemplateModel(id: id)
        }
        cacheManager.createTable(templateModels)

        self.templateModels = cacheManager.select()
        tableView.reloadData()
    }
    
    func onInProgress(_ message: [String : String]) {
        if let id = message["id"], let templateModel = templateModels.first(where: { $0.id == id }) {
            templateModel.state = .inProgress
            tableView.reloadData()
        }
    }
    
    func onFinish(_ message: [String : String]) {
        if let id = message["id"],
           let success = (message["success"] as? NSString)?.boolValue,
           let templateModel = templateModels.first(where: { $0.id == id }) {
            templateModel.state = success ? .success : .failed
            templateModel.errorMsg = message["error_msg"]
            templateModel.filePath = message["file_path"]
            
            cacheManager.update(templateModel)
            
            tableView.reloadData()
        }
    }
    
    func onConnect() {
        sendStartMessage()
    }
    
    func onDisconnect() {
        launchManager.launch()
        let inProgressTemplateModels = templateModels.filter { $0.state == .inProgress }
        inProgressTemplateModels.forEach {
            $0.state = .failed
            cacheManager.update($0)
        }
        
        tableView.reloadData()
        needResendStartMessage = true
    }
    
    private func sendStartMessage() {
        guard needResendStartMessage else { return }
        needResendStartMessage = false
        socketManager.connectToServer()
        socketManager.sendStartMessage(templateModels.filter({ $0.state == .ready }))
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return templateModels.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TableCellView"), owner: nil) as? TableCellView
        view?.setup(templateModels[row])
        return view ?? TableCellView()
    }
}

