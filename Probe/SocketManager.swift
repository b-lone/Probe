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
    case montageAbility = "montageAbility"
    case frameRenderingTime = "frameRenderingTime"
    case finish = "finish"
    case end = "end"
}

protocol SocketManagerDelegate: AnyObject {
    func onConnect()
    func onInProgress(_ message: [String: String])
    func onUpdate(_ message: [String: String])
    func onMontageAbility(_ message: [String: String])
    func onFrameRenderingTime(_ message: [String: String])
    func onFinish(_ message: [String: String])
    func onDisconnect()
    func onTimeout()
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
    private var timeoutTimer: Timer?
    
    private var cacheString: String?
    
    deinit {
        heartbeatTimer?.invalidate()
        reconnectTimer?.invalidate()
        timeoutTimer?.invalidate()
    }
    
    func connectToServer() {
        guard !clientSocket.isConnected else { return }
        do {
            try clientSocket.connect(toHost: "localhost", onPort: 10010)
            print("[Socket][iPhone]Connected to server")
        } catch {
            print("[Socket][iPhone]Error connecting to server: \(error)")
        }
    }
    
    func disconnectToServer() {
        invalidateHeartbeat()
        invalidateReconnectTimer()
        invalidateTimeoutTimer()
    }
// MARK: - write
    func sendStartMessage(_ model: [TemplateModel]) {
        guard clientSocket.isConnected else { return }
        
        var ids = model.map { $0.id }
        guard !ids.isEmpty else { return }
        ids = [ ids[0] ]
        
        let batchSize = 10
        var remainingIDs = ids
        while !remainingIDs.isEmpty {
            let batch = Array(remainingIDs.prefix(batchSize))
            remainingIDs.removeFirst(min(batchSize, remainingIDs.count))
            sendStartMessageBatch(batch)
        }
        
        scheduleTimeoutTimer()
    }

    func sendStartMessageBatch(_ ids: [Int64]) {
        guard !ids.isEmpty else { return }
        
        let idsString = ids.map({ "\($0)" }).joined(separator: ",")
        
        let startMessage = [
            "type": MessageType.start.rawValue,
            "ids": idsString
        ]
        
        write(startMessage)
    }
    
    func sendEndMessage() {
        guard clientSocket.isConnected else { return }
        
        let message = [
            "type": MessageType.end.rawValue,
        ]
        
        write(message)
    }
    
    private func write(_ jsonObject: [String: String]) {
        if let jsonString = String(jsonObject: jsonObject) {
            print("[Socket][iPhone]Write:\(jsonString)")
            let message = jsonString + "end_youkun_fengexian"
            clientSocket.write(message.data(using: .utf8), withTimeout: -1, tag: 0)
        }
    }
// MARK: - timer
    private func scheduleHeartbeat() {
        heartbeatCounter = 0
        invalidateHeartbeat()
        
        weak var weakSelf = self
        heartbeatTimer = .scheduledTimer(withTimeInterval: 30, repeats: true, block: { _ in
            weakSelf?.write([ "type" : MessageType.heartbeat.rawValue])
            weakSelf?.heartbeatCounter += 1
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
    
    private func scheduleTimeoutTimer() {
        invalidateTimeoutTimer()
        weak var weakSelf = self
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false, block: { _ in
            weakSelf?.onTimeout()
        })
    }
    
    private func invalidateTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    private func onTimeout() {
        delegate?.onTimeout()
    }
// MARK: - read
    private func parseData(data: String) {
        guard let message = data.toJsonObject(), let typeString = message["type"] else { return }
        
        print("[Socket][iPhone]Read: \(message)")
        
        let type = MessageType(rawValue: typeString) ?? .invalid
        switch type {
        case .heartbeat:
            onHeartbeat(message)
        case .inProgress:
            onInProgress(message)
        case .update:
            onUpdate(message)
        case .montageAbility:
            onMontageAbility(message)
        case .frameRenderingTime:
            onFrameRenderingTime(message)
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
    
    private func onMontageAbility(_ message: [String: String]) {
        delegate?.onMontageAbility(message)
    }
    
    private func onFrameRenderingTime(_ message: [String: String]) {
        delegate?.onFrameRenderingTime(message)
    }
    
    private func onFinish(_ message: [String: String]) {
        invalidateTimeoutTimer()
        delegate?.onFinish(message)
    }
// MARK: - GCDAsyncSocketDelegate
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("[Socket][iPhone]Did Connect")
        onConnect()
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("[Socket][iPhone]Did Disconnect:\(String(describing: err))")
        onDisconnect()
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
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
        print("[Socket][iPhone]Did Write")
    }
}
