//
//  SocketManager.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/30.
//

import Cocoa
import CocoaAsyncSocket

enum MessageType: String {
    case invalid
    case heartbeat = "heartbeat"
    case start = "start"
    case inProgress = "inProgress"
    case update = "update"
    case useMontage = "useMontage"
    case finish = "finish"
    case end = "end"
}

protocol SocketManagerDelegate: AnyObject {
    func onConnect()
    func onInProgress(_ message: [String: String])
    func onUpdate(_ message: [String: String])
    func onUseMontage(_ message: [String: String])
    func onFinish(_ message: [String: String])
    func onDisconnect()
}

class SocketManager: NSObject, GCDAsyncSocketDelegate {
    weak var delegate: SocketManagerDelegate?
    
    private lazy var clientSocket: GCDAsyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
    private var heartbeatTimer: Timer?
    
    private let queue = DispatchQueue(label: "com.example.heartbeatCounterQueue")
    private var _heartbeatCounter: Int = 0
    private var heartbeatCounter: Int {
        get { queue.sync { _heartbeatCounter } }
        
        set {
            queue.sync {
                _heartbeatCounter = newValue
                if _heartbeatCounter > 4 {
                    onDisconnect()
                }
            }
        }
    }
    
    private var reconnectTimer: Timer?
    
    private var cacheString: String?
    
    deinit {
        heartbeatTimer?.invalidate()
    }
    
    func connectToServer() {
        guard !clientSocket.isConnected else { return }
        do {
            try clientSocket.connect(toHost: "localhost", onPort: 10010)
            print("Connected to server")
        } catch {
            print("Error connecting to server: \(error)")
        }
    }
// MARK: - write
    func sendStartMessage(_ templateModels: [TemplateModel]) {
        guard clientSocket.isConnected else { return }
        
        var ids = templateModels.map { $0.id }
        guard !ids.isEmpty else { return }
        ids = [ ids[0] ]
        
        // 分批发送
        let batchSize = 10
        var remainingIDs = ids
        while !remainingIDs.isEmpty {
            let batch = Array(remainingIDs.prefix(batchSize))
            remainingIDs.removeFirst(min(batchSize, remainingIDs.count))
            sendStartMessageBatch(batch)
        }
    }

    func sendStartMessageBatch(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        
        let idsString = ids.joined(separator: ",")
        
        let startMessage = [
            "type": MessageType.start.rawValue,
            "ids": idsString
        ]
        
        write(startMessage, tag: 2)
    }
    
    func sendEndMessage() {
        guard clientSocket.isConnected else { return }
        
        let message = [
            "type": MessageType.end.rawValue,
        ]
        
        write(message, tag: 2)
    }
    
    private func write(_ jsonObject: [String: String], tag: Int) {
        if let jsonString = convertToJsonString(jsonObject: jsonObject) {
            print(jsonString)
            let message = jsonString + "end_youkun_fengexian"
            clientSocket.write(message.data(using: .utf8), withTimeout: -1, tag: tag)
        }
    }
// MARK: - json
    private func convertToJsonData(jsonObject: Any) -> Data? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) {
            return jsonData
        }
        return nil
    }
    
    private func convertToJsonString(jsonObject: Any) -> String? {
        if let jsonData = convertToJsonData(jsonObject: jsonObject) {
            if let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as String? {
                return jsonString
            }
        }
        return nil
    }
    
    private func convertToJsonObject(jsonData: Data) -> [String: String]? {
        try? JSONSerialization.jsonObject(with: jsonData) as? [String: String]
    }
    
    private func convertToJsonObject(jsonString: String) -> [String: String]? {
        if let jsonData = jsonString.data(using: .utf8) {
            return try? JSONSerialization.jsonObject(with: jsonData) as? [String: String]
        }
        return nil
    }
// MARK: - timer
    private func scheduleHeartbeat() {
        heartbeatCounter = 0
        invalidateHeartbeat()
        
        weak var weakSelf = self
        heartbeatTimer = .scheduledTimer(withTimeInterval: 30, repeats: true, block: { _ in
            weakSelf?.write([ "type" : MessageType.heartbeat.rawValue], tag: 1)
        })
    }
    
    private func invalidateHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func scheduleReconnectTimer() {
        invalidateReconnectTimer()
        weak var weakSelf = self
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { _ in
            weakSelf?.connectToServer()
        })
    }
    
    private func invalidateReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
// MARK: - read
    private func parseData(data: String) {
        print("Received message from server: \(data)")
        guard let message = convertToJsonObject(jsonString: data), let typeString = message["type"] else { return }
        
        let type = MessageType(rawValue: typeString) ?? .invalid
        switch type {
        case .heartbeat:
            onHeartbeat(message)
        case .inProgress:
            onInProgress(message)
        case .update:
            onUpdate(message)
        case .useMontage:
            onUseMontage(message)
        case .finish:
            onFinish(message)
        default:
            break
        }
    }
// MARK: - event
    private func onConnect() {
        clientSocket.readData(withTimeout: -1, tag: 0)
        scheduleHeartbeat()
        invalidateReconnectTimer()
        delegate?.onConnect()
    }
    
    private func onDisconnect() {
        invalidateHeartbeat()
        scheduleReconnectTimer()
        delegate?.onDisconnect()
    }
    
    private func onHeartbeat(_ message: [String: String]) {
        heartbeatCounter = 0
    }
    
    private func onInProgress(_ message: [String: String]) {
        delegate?.onInProgress(message)
    }
    
    private func onUpdate(_ message: [String: String]) {
        delegate?.onUpdate(message)
    }
    
    private func onUseMontage(_ message: [String: String]) {
        delegate?.onUseMontage(message)
    }
    
    private func onFinish(_ message: [String: String]) {
        delegate?.onFinish(message)
    }
// MARK: - GCDAsyncSocketDelegate
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("didConnectToHost")
        onConnect()
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socketDidDisconnect:\(String(describing: err))")
        onDisconnect()
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
//        print("didRead:\(tag)")
        var jsonStrings = [String]()

        if var dataString = String(data: data, encoding: .utf8) {
            if let cacheString = cacheString {
                dataString = cacheString + dataString
                self.cacheString = nil
            }
            let jsonComponents = dataString.components(separatedBy: "youkun_fengexian")
            for component in jsonComponents {
                var jsonString = component
                if jsonString.hasSuffix("end_") {
                    let startIndex = jsonString.startIndex
                    let endIndex = jsonString.index(jsonString.endIndex, offsetBy: -4)
                    jsonString = String(jsonString[startIndex..<endIndex])
                    jsonStrings.append(jsonString)
                } else {
                    cacheString = jsonString
                    print(jsonString)
                }
                
            }
        }
        for jsonString in jsonStrings {
            parseData(data: jsonString)
        }
        
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("didWriteDataWithTag:\(tag)")
        if tag == 1 {
            heartbeatCounter += 1
        }
    }
}
