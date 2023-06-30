//
//  TemplateTableViewController.swift
//  Probe
//
//  Created by Archie You on 2023/6/26.
//

import Cocoa
import RxCocoa
import RxSwift
import Combine

class CustomTableView: NSTableView {
    override func menu(for event: NSEvent) -> NSMenu? {
        if event.type == .rightMouseDown {
            return createContextMenu()
        }
        return nil
    }
    
    private func createContextMenu() -> NSMenu {
        let menu = NSMenu(title: "Context Menu")
        
        let menuItem1 = NSMenuItem(title: "Run", action: #selector(menuItemAction(_:)), keyEquivalent: "")
//        let menuItem2 = NSMenuItem(title: "Menu Item 2", action: #selector(menuItemAction(_:)), keyEquivalent: "")
//        let menuItem3 = NSMenuItem(title: "Menu Item 3", action: #selector(menuItemAction(_:)), keyEquivalent: "")
        
        menu.addItem(menuItem1)
//        menu.addItem(menuItem2)
//        menu.addItem(menuItem3)
        
        return menu
    }
    
    @objc private func menuItemAction(_ sender: NSMenuItem) {
        if sender.title == "Run" {
            if selectedRow >= 0 && selectedRow <= numberOfRows {
                if let testCase = AppContext.shared.caseManager.currentTestCase {
                    AppContext.shared.runningManager.start(testCase, templateIndexs: [selectedRow])
                }
            }
        }
    }
}

class TemplateTableViewController: BaseViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var tableView: CustomTableView!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.tableColumns.forEach { self.tableView.removeTableColumn($0) }
        
        TemplateModel.columnInfos.forEach { self.addTableColumn($0) }
    
        weak var weakSelf = self
        caseManager.currentTestCaseObservable.subscribe { _ in
            weakSelf?.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        caseManager.resultsObservable.subscribe { _ in
            weakSelf?.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onReload), name: NSNotification.Name("Reload"), object: nil)
    }
    
    @objc
    func onReload() {
        tableView.reloadData()
    }
    
    private func addTableColumn(_ columnInfo: ColumnInfo) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: columnInfo.identifier))
        column.isEditable = false
        column.width = columnInfo.width
        column.minWidth = columnInfo.width
        column.title = columnInfo.identifier
        tableView.addTableColumn(column)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        caseManager.currentTestCase?.templates.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnIdentifier = tableColumn?.identifier,
              let model = caseManager.currentTestCase?.templates[row]
        else { return nil }
        
        let textField = CancellableTextField()
        
        textField.isBordered = false
        textField.isBezeled = false
        textField.isEditable = false
        textField.backgroundColor = .clear
        textField.alignment = .center
        
        if columnIdentifier.rawValue == "id" {
            textField.cancellable = model.$id.sink { textField.stringValue = "\($0)" }
        } else if columnIdentifier.rawValue == "name" {
            textField.cancellable = model.$name.sink { textField.stringValue = $0 }
        } else if columnIdentifier.rawValue == "sdk tag" {
            textField.cancellable = model.$sdkTag.sink { textField.stringValue = "\($0)" }
        } else if columnIdentifier.rawValue == "usage" {
            textField.cancellable = model.$usage.sink { textField.stringValue = "\($0)" }
        } else if columnIdentifier.rawValue == "clip count" {
            textField.cancellable = model.$clipCount.sink { textField.stringValue = "\($0)" }
        } else if columnIdentifier.rawValue == "can replace clip count" {
            textField.cancellable = model.$canReplaceClipCount.sink { textField.stringValue = "\($0)" }
        } else if columnIdentifier.rawValue == "preview url" {
            textField.cancellable = model.$previewUrl.sink { textField.stringValue = $0 }
        } else if columnIdentifier.rawValue == "cover url" {
            textField.cancellable = model.$coverUrl.sink { textField.stringValue = $0 }
        } else if columnIdentifier.rawValue == "download url" {
            textField.cancellable = model.$downloadUrl.sink { textField.stringValue = $0 }
        } else if let result = model.mostRencentResult {
            if columnIdentifier.rawValue == "state" {
                textField.cancellable = result.$state.sink {
                    textField.stringValue = "\($0)"
                    textField.textColor = $0.color
                }
            } else if columnIdentifier.rawValue == "use montage" {
                textField.cancellable = result.$useMontage.sink { textField.stringValue = "\($0)" }
            } else if columnIdentifier.rawValue == "montage ability" {
                textField.cancellable = result.$montageAbility.sink { textField.stringValue = "\($0)" }
            } else if columnIdentifier.rawValue == "start memory" {
                textField.cancellable = result.$startMemory.sink { textField.stringValue = "\($0)" }
            } else if columnIdentifier.rawValue == "end memory" {
                textField.cancellable = result.$endMemory.sink { textField.stringValue = "\($0)" }
            } else if columnIdentifier.rawValue == "max memory" {
                textField.cancellable = result.$maxMemory.sink { textField.stringValue = "\($0)" }
            } else if columnIdentifier.rawValue == "duration" {
                textField.cancellable = result.$duration.sink { textField.stringValue = "\($0)" }
            }  else if columnIdentifier.rawValue == "rendering" {
                textField.cancellable = result.$frameRenderingTimes.sink { _ in textField.stringValue = "\(result.longRenderingTimeFrameCount)" }
            } else if columnIdentifier.rawValue == "error" {
                textField.cancellable = result.$errorMsg.sink { textField.stringValue = $0 ?? "-" }
            } else if columnIdentifier.rawValue == "filepath" {
                textField.cancellable = result.$filePath.sink { textField.stringValue = $0 ?? "-" }
            }
        } else {
            textField.stringValue = "-"
        }
        
        return textField
    }
}
