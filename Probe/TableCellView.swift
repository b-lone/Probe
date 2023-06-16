//
//  TableCellView.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/30.
//

import Cocoa

class TableCellView: NSTableCellView {
    @IBOutlet weak var idLabel: NSTextField!
    @IBOutlet weak var stateLabel: NSTextField!
    @IBOutlet weak var useMotageLabel: NSTextField!
    @IBOutlet weak var startMemoryLabel: NSTextField!
    @IBOutlet weak var endMemoryLabel: NSTextField!
    @IBOutlet weak var maxMemoryLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var filePathLabel: NSTextField!
    
    func setup(_ tempalteModel: TemplateModel) {
        idLabel.stringValue = tempalteModel.id
        stateLabel.stringValue = "\(tempalteModel.state)"
        stateLabel.textColor = tempalteModel.state.color
        useMotageLabel.stringValue = "\(tempalteModel.useMotage)"
        startMemoryLabel.stringValue = "\(tempalteModel.startMemory)"
        endMemoryLabel.stringValue = "\(tempalteModel.endMemory)"
        maxMemoryLabel.stringValue = "\(tempalteModel.maxMemory)"
        durationLabel.stringValue = "\(tempalteModel.duration)"
        errorLabel.stringValue = tempalteModel.errorMsg ?? "-"
        filePathLabel.stringValue = tempalteModel.filePath ?? "-"
    }
}
