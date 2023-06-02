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
    case finish = "finish"
}

protocol SocketManagerDelegate: AnyObject {
    func onConnect()
    func onInProgress(_ message: [String: String])
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
                if _heartbeatCounter > 10 {
                    onDisconnect()
                }
            }
        }
    }
    
    private var reconnectTimer: Timer?
    
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
    
    func sendStartMessage(_ templateModels: [TemplateModel]) {
        guard templateModels.count > 0, clientSocket.isConnected else { return }
        
        let ids = templateModels.map { $0.id }
        let idsString = ids.joined(separator: ",")
        
        guard idsString.count > 0 else { return }
        
        let startMessage = [
            "type": MessageType.start.rawValue,
            "ids": idsString
        ]
        
        if let startData = convertToJsonData(jsonObject: startMessage) {
            clientSocket.write(startData, withTimeout: -1, tag: 2)
            if let jsonString = NSString(data: startData, encoding: String.Encoding.utf8.rawValue) as String? {
                print(jsonString)
            }
        }
    }
    
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
    
    private func scheduleHeartbeat() {
        heartbeatCounter = 0
        invalidateHeartbeat()
        
        weak var weakSelf = self
        heartbeatTimer = .scheduledTimer(withTimeInterval: 30, repeats: true, block: { _ in
            if let data = weakSelf?.convertToJsonData(jsonObject: [ "type" : MessageType.heartbeat.rawValue]) {
                weakSelf?.clientSocket.write(data, withTimeout: -1, tag: 1)
            }
        })
    }
    
    private func invalidateHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func scheduleReconnectTimer() {
        invalidateReconnectTimer()
        weak var weakSelf = self
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true, block: { _ in
            weakSelf?.connectToServer()
        })
    }
    
    private func invalidateReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func parseData(data: String) {
        print("Received message from server: \(data)")
        guard let message = convertToJsonObject(jsonString: data), let typeString = message["type"] else { return }
        
        let type = MessageType(rawValue: typeString) ?? .invalid
        switch type {
        case .heartbeat:
            onHeartbeat(message)
        case .inProgress:
            onInProgress(message)
        case .finish:
            onFinish(message)
        default:
            break
        }
    }
    
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
    
    private func onFinish(_ message: [String: String]) {
        delegate?.onFinish(message)
    }
    
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
        if let dataString = String(data: data, encoding: .utf8) {
            let jsonComponents = dataString.components(separatedBy: "}{")
            for component in jsonComponents {
                var jsonString = component
                if !jsonString.hasPrefix("{") {
                    jsonString.insert("{", at: jsonString.startIndex)
                }
                if !jsonString.hasSuffix("}") {
                    jsonString.append("}")
                }
                jsonStrings.append(jsonString)
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
