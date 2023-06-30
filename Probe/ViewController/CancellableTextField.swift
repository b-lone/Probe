//
//  CancellableTextField.swift
//  Probe
//
//  Created by Archie You on 2023/7/3.
//

import Cocoa
import Combine

class CancellableTextField: NSTextField {
    var cancellable: AnyCancellable?
    
    deinit {
        cancellable?.cancel()
    }
}
