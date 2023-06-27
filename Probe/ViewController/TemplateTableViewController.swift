//
//  TemplateTableViewController.swift
//  Probe
//
//  Created by Archie You on 2023/6/26.
//

import Cocoa
import RxCocoa
import RxSwift

class TemplateTableViewController: BaseViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.tableColumns.forEach { self.tableView.removeTableColumn($0) }
        
        TemplateModel.columnInfos.forEach { self.addTableColumn($0) }
    
        weak var weakSelf = self
        caseManager.currentTestCaseObservable.subscribe { _ in
            weakSelf?.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        caseManager.templateModelSubject.subscribe { _ in
            weakSelf?.tableView.reloadData()
        }.disposed(by: disposeBag)
    }
    
    private func addTableColumn(_ columnInfo: ColumnInfo) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: columnInfo.identifier))
        column.isEditable = false
        column.width = columnInfo.width
        column.title = columnInfo.identifier
        tableView.addTableColumn(column)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        caseManager.currentTestCase?.templateModels.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnIdentifier = tableColumn?.identifier,
              let model = caseManager.currentTestCase?.templateModels[row]
        else { return nil }
        
        let textField = NSTextField()
        
        textField.isBordered = false
        textField.isBezeled = false
        textField.isEditable = false
        textField.backgroundColor = .clear
        textField.alignment = .center
        
        if columnIdentifier.rawValue == "id" {
            textField.stringValue = model.id
        } else if columnIdentifier.rawValue == "name" {
            textField.stringValue = model.name
        } else if columnIdentifier.rawValue == "state" {
            textField.stringValue = "\(model.state)"
            textField.textColor = model.state.color
        } else if columnIdentifier.rawValue == "use montage" {
            textField.stringValue = "\(model.useMontage)"
        } else if columnIdentifier.rawValue == "start memory" {
            textField.stringValue = "\(model.startMemory)"
        } else if columnIdentifier.rawValue == "end memory" {
            textField.stringValue = "\(model.endMemory)"
        } else if columnIdentifier.rawValue == "max memory" {
            textField.stringValue = "\(model.maxMemory)"
        } else if columnIdentifier.rawValue == "duration" {
            textField.stringValue = "\(model.duration)"
        } else if columnIdentifier.rawValue == "error" {
            textField.stringValue = model.errorMsg ?? "-"
        } else if columnIdentifier.rawValue == "filepath" {
            textField.stringValue = model.filePath ?? "-"
        }
        
        return textField
    }
}
