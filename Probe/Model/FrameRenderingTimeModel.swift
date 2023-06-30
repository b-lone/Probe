//
//  FrameRenderingTimeModel.swift
//  Probe
//
//  Created by Archie You on 2023/6/29.
//

import Cocoa

class FrameRenderingTimeModel: NSObject & DatabaseModelProtocol {
    var id: Int64
    let postition: Int64
    let renderingTime: Int64
    let resultId: Int64
    
    init(id: Int64,
         postition: Int64,
         renderingTime: Int64,
         resultId: Int64) {
        self.id = id
        self.postition = postition
        self.renderingTime = renderingTime
        self.resultId = resultId
    }

    convenience init(postition: Int64, renderingTime: Int64, resultId: Int64) {
        let currentTime = Date().timeIntervalSince1970
        let id = Int64(currentTime * 1000000)
        self.init(id: id, postition: postition, renderingTime: renderingTime, resultId: resultId)
    }
}
