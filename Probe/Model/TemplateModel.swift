//
//  TemplateModel.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/30.
//

import Cocoa
import Combine

class TemplateModel: NSObject & DatabaseModelProtocol {
    @Published var id: Int64
    @Published var name = "unknown"
    @Published var sdkTag: Bool
    @Published var usage: Int64
    @Published var clipCount: Int64
    @Published var canReplaceClipCount: Int64
    @Published var previewUrl: String
    @Published var coverUrl: String
    @Published var downloadUrl: String
    var caseIds: [Int64]
    
    @Published var results = [ResultModel]()
    
    init(id: Int64,
         name: String = "unknown",
         sdkTag: Bool = false,
         usage: Int64 = 0,
         clipCount: Int64 = 0,
         canReplaceClipCount: Int64 = 0,
         previewUrl: String = "",
         coverUrl: String = "",
         downloadUrl: String = "",
         caseIds: [Int64]) {
        self.id = id
        self.name = name
        self.sdkTag = sdkTag
        self.usage = usage
        self.clipCount = clipCount
        self.canReplaceClipCount = canReplaceClipCount
        self.previewUrl = previewUrl
        self.coverUrl = coverUrl
        self.downloadUrl = downloadUrl
        self.caseIds = caseIds
    }

    convenience init(name: String = "unknown",
                     sdkTag: Bool = false,
                     usage: Int64 = 0,
                     clipCount: Int64 = 0,
                     canReplaceClipCount: Int64 = 0,
                     previewUrl: String = "",
                     coverUrl: String = "",
                     downloadUrl: String = "",
                     caseIds: [Int64]) {
        let currentTime = Date().timeIntervalSince1970
        let id = Int64(currentTime * 1000)
        self.init(id: id,
                  name: name,
                  sdkTag: sdkTag,
                  usage: usage,
                  clipCount: clipCount,
                  canReplaceClipCount: canReplaceClipCount,
                  previewUrl: previewUrl,
                  coverUrl: coverUrl,
                  downloadUrl: downloadUrl,
                  caseIds: caseIds)
    }
}

extension TemplateModel {
    var mostRencentResult: ResultModel? {
        return results.filter({ $0.state != .ready }).max { $0.id < $1.id }
    }
}

extension TemplateModel {
    var space: String {
        "$"
    }
    
    override var description: String {
        var content = "\(id)\(space)\(name)\(space)\(sdkTag)\(space)\(usage)\(space)\(clipCount)\(space)\(canReplaceClipCount)\(space)\(previewUrl)\(space)\(coverUrl)\(space)\(downloadUrl)"
        if let result = mostRencentResult {
            content += "\(space)\(result.state)\(space)\(result.montageAbility)\(space)\(result.montageAbilityFlag ?? "-")\(space)\(result.startMemory)\(space)\(result.endMemory)\(space)\(result.maxMemory)\(space)\(result.duration)\(space)\(result.errorMsg ?? "-")\(space)\(result.filePath ?? "-")\(space)\(result.longRenderingTimeFrameCount)"
        }
        return content
    }
}

class ColumnInfo {
    let identifier: String
    let width: CGFloat
    
    init(identifier: String, width: CGFloat) {
        self.identifier = identifier
        self.width = width
    }
}

extension TemplateModel {
    static var columnInfos: [ColumnInfo] {
        return [
            ColumnInfo(identifier: "id", width: 64),
            ColumnInfo(identifier: "name", width: 84),
            ColumnInfo(identifier: "sdk tag", width: 64),
            ColumnInfo(identifier: "state", width: 72),
            ColumnInfo(identifier: "use montage", width: 72),
            ColumnInfo(identifier: "montage ability", width: 72),
            ColumnInfo(identifier: "start memory", width: 72),
            ColumnInfo(identifier: "end memory", width: 72),
            ColumnInfo(identifier: "max memory", width: 72),
            ColumnInfo(identifier: "duration", width: 72),
            ColumnInfo(identifier: "rendering", width: 72),
            ColumnInfo(identifier: "error", width: 160),
            ColumnInfo(identifier: "usage", width: 64),
            ColumnInfo(identifier: "clip count", width: 64),
            ColumnInfo(identifier: "can replace clip count", width: 64),
            ColumnInfo(identifier: "preview url", width: 160),
            ColumnInfo(identifier: "cover url", width: 160),
            ColumnInfo(identifier: "download url", width: 160),
            ColumnInfo(identifier: "filepath", width: 160),
        ]
    }
}
