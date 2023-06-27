//
//  HeaderViewController.swift
//  Probe
//
//  Created by Archie You on 2023/6/26.
//

import Cocoa
import RxCocoa
import RxSwift
import SnapKit

class HeaderViewController: BaseViewController, NSComboBoxDelegate, NSComboBoxDataSource {
    
    private lazy var comboBox: NSComboBox = {
        let view = NSComboBox()
        view.usesDataSource = true
        view.dataSource = self
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let selectedIndexReplay = BehaviorRelay<Int?>(value: nil)
    lazy var selectedIndexObservable: Observable<Int?> = selectedIndexReplay.asObservable()
    
    override func loadView() {
        self.view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view .addSubview(comboBox)
        comboBox.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
            make.width.equalTo(120)
        }
        
        weak var weakSelf = self
        caseManager.currentTestCaseObservable.subscribe { _ in
            weakSelf?.comboBox.stringValue = weakSelf?.caseManager.currentTestCase?.name ?? "-"
        }.disposed(by: disposeBag)
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return caseManager.caseModels.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return caseManager.caseModels[index].name
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        if let comboBox = notification.object as? NSComboBox {
            let selectedIndex = comboBox.indexOfSelectedItem
            selectedIndexReplay.accept(selectedIndex)
            caseManager.changeCurrentTestCase(to: selectedIndex)
            print("ComboBox Selected item: \(selectedIndex )")
        }
    }
}
