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
    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var filePathLabel: NSTextField!
    
    func setup(_ tempalteModel: TemplateModel) {
        idLabel.stringValue = tempalteModel.id
        stateLabel.stringValue = "\(tempalteModel.state)"
        errorLabel.stringValue = tempalteModel.errorMsg ?? "-"
        filePathLabel.stringValue = tempalteModel.filePath ?? "-"
    }
}
