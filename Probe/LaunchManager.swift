//
//  LaunchManager.swift
//  Probe
//
//  Created by 尤坤 on 2023/6/1.
//

import Cocoa
import CocoaAsyncSocket

protocol LaunchManagerDelegate: AnyObject {
    func onDownloadFinished(_ templateId: String)
}

class LaunchManager: NSObject, GCDAsyncSocketDelegate {
    private lazy var clientSocket: GCDAsyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
    private var messagesToSend = [String]()
    private var date: Date?
    weak var delegate: LaunchManagerDelegate?
    
    func sendConfigMessage(_ vidoOutputPath: String) {
        let message = "{config:\(vidoOutputPath)}"
        write(message)
    }
    
    func sendLaunchMessage() {
        guard !checkOverrun() else { return }
        
        date = Date.now
        
        let message = "{launch}"
        write(message)
    }
    
    func sendDownloadMessage(_ templateId: Int64, filePath: String) {
        let message = "{download:\(templateId)&\(filePath)}"
        write(message)
    }
    
    func sendEndMessage() {
        let message = "{end}"
        write(message)
    }
    
    private func write(_ message: String) {
        if clientSocket.isConnected {
            print("[Socket][helper]Write:\(message)")
            clientSocket.write(message.data(using: .utf8), withTimeout: -1, tag: 0)
        } else {
            if !messagesToSend.contains(message) {
                messagesToSend.append(message)
            }
            connectToServer()
        }
    }
    
    private func checkOverrun() -> Bool {
        if let date = date {
            let timeInterval = Date.now.timeIntervalSince(date)
            return timeInterval < 300//5min
        } else {
            return false
        }
    }
    
    private func connectToServer() {
        do {
            try clientSocket.connect(toHost: "localhost", onPort: 1234)
            print("[Socket][helper]Connected to server")
        } catch {
            print("[Socket][helper]Error connecting to server: \(error)")
        }
    }
    
    private func extractCommandAndParameter(from input: String) -> (command: String?, parameter: String?) {
        let pattern = #"\{([^:}]+)(?::([^}]+))?\}"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return (nil, nil)
        }
        
        if let commandRange = Range(match.range(at: 1), in: input) {
            let command = String(input[commandRange])
            
            if let parameterRange = Range(match.range(at: 2), in: input) {
                let parameter = String(input[parameterRange])
                return (command, parameter)
            } else {
                return (command, nil)
            }
        }
        
        return (nil, nil)
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("[Socket][helper]Did Connect")
        
        sock.readData(withTimeout: -1, tag: 0)
       
        for message in messagesToSend {
            write(message)
        }
        messagesToSend.removeAll()
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("[Socket][helper]Did Disconnect:\(String(describing: err))")
        date = nil
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
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
            let commandAndParamter = extractCommandAndParameter(from: jsonString)
            print("[Socket][helper]Did Read:\(commandAndParamter)")
            if commandAndParamter.command == "launch fininsh" {
                date = nil
            } else if commandAndParamter.command == "download finish", let parameter = commandAndParamter.parameter {
                delegate?.onDownloadFinished(parameter)
            } else if commandAndParamter.command == "end finish" {
                clientSocket.disconnect()
            }
        }
        
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("[Socket][helper]Did Write")
    }
}
