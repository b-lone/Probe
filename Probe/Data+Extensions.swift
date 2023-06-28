//
//  Data+Extensions.swift
//  Probe
//
//  Created by Archie You on 2023/6/28.
//

import Cocoa

extension Data {
    init?(jsonObject: Any) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            self = jsonData
        } catch {
            return nil
        }
    }
    
    func toJsonObject() -> [String: String]? {
        try? JSONSerialization.jsonObject(with: self) as? [String: String]
    }
}
