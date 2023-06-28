//
//  String+Extensions.swift
//  Probe
//
//  Created by Archie You on 2023/6/28.
//

import Cocoa

extension String {
    init?(jsonObject: Any) {
        if let jsonData = Data(jsonObject: jsonObject) {
            if let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as String? {
                self = jsonString
                return
            }
        }
        return nil
    }
    
    func toJsonObject() -> [String: String]? {
        if let jsonData = data(using: .utf8) {
            return jsonData.toJsonObject()
        }
        return nil
    }
}

