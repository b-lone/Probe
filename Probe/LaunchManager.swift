//
//  LaunchManager.swift
//  Probe
//
//  Created by 尤坤 on 2023/6/1.
//

import Cocoa
import CocoaAsyncSocket

class LaunchManager: NSObject, GCDAsyncSocketDelegate {
    private lazy var clientSocket: GCDAsyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
    
    private var date: Date?
    
    func launch() {
        guard !checkOverrun() else { return }
        
        date = Date.now
        if clientSocket.isConnected {
            clientSocket.write("{launch}".data(using: .utf8), withTimeout: -1, tag: 0)
        } else {
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
            print("Connected to server")
        } catch {
            print("Error connecting to server: \(error)")
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("launch didConnectToHost")
        
        sock.readData(withTimeout: -1, tag: 0)
        sock.write("{launch}".data(using: .utf8), withTimeout: -1, tag: 0)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("launch socketDidDisconnect:\(String(describing: err))")
        date = nil
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        var jsonStrings = [String]()
        if let dataString = String(data: data, encoding: .utf8) {
            print("launch didRead:\(tag) \(dataString)")
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
            if jsonString == "{launch fininsh}" {
                date = nil
            }
        }
        
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("launch didWriteDataWithTag:\(tag)")
    }
}

//func relaunch1() {
//    DispatchQueue.global(qos: .default).async {
//        let appBundle = Bundle.main
//        if let executableURL = appBundle.url(forResource: "ios-deploy", withExtension: nil) {
//            let process = Process()
//            process.executableURL = executableURL
//            process.arguments = ["--justlaunch", "--noinstall", "--debug", "--bundle", "/Users/archie/Library/Developer/Xcode/DerivedData/bili-studio-agjocrxtfxnuzqfnyzfzikswasiu/Build/Products/Debug-iphoneos/bazel-out/applebin_ios-ios_arm64-dbg-ST-3a8ae290c50a/bin/bilistudio-universal/bili-studio.app"]
//
//            let pipe = Pipe()
//            process.standardOutput = pipe
//
//            do {
//                try process.run()
//                process.waitUntilExit()
//
//                let data = pipe.fileHandleForReading.readDataToEndOfFile()
//                if let output = String(data: data, encoding: .utf8) {
//                    print(output)
//                }
//            } catch {
//                print("Failed to run the executable: \(error)")
//            }
//        } else {
//            print("Executable not found in the app bundle.")
//        }
//    }
//}
//
//func relaunch2() {
//    DispatchQueue.global(qos: .default).async {
//        let command = "ios-deploy --justlaunch --noinstall --debug --bundle /Users/archie/Library/Developer/Xcode/DerivedData/bili-studio-agjocrxtfxnuzqfnyzfzikswasiu/Build/Products/Debug-iphoneos/bazel-out/applebin_ios-ios_arm64-dbg-ST-3a8ae290c50a/bin/bilistudio-universal/bili-studio.app"
//
//        let scriptSource = """
//        tell application "Terminal"
//            do script "\(command)"
//        end tell
//        """
//
//        if let script = NSAppleScript(source: scriptSource) {
//            var error: NSDictionary?
//            script.executeAndReturnError(&error)
//
//            if let error = error {
//                print("Failed to execute script: \(error)")
//            }
//        } else {
//            print("Failed to create NSAppleScript instance.")
//        }
//    }
//}
//
//func relaunch3() {
//    let appBundle = Bundle.main
//    if let scriptURL = appBundle.url(forResource: "script", withExtension: "sh") {
//        let configuration = NSWorkspace.OpenConfiguration()
//        NSWorkspace.shared.open([scriptURL], withApplicationAt: URL(string: "/System/Applications/Utilities/Terminal.app")!, configuration: configuration, completionHandler: {
//            app, error in
//            print(error as Any)
//        })
//    }
//}
//
//func relaunch4() {
//    DispatchQueue.global(qos: .default).async {
//        if let executableURL = URL(string:"file://opt/homebrew/Cellar/ios-deploy/1.12.2/bin/ios-deploy") {
//            let process = Process()
//            process.executableURL = executableURL
//            process.arguments = ["--justlaunch", "--noinstall", "--debug", "--bundle", "/Users/archie/Library/Developer/Xcode/DerivedData/bili-studio-agjocrxtfxnuzqfnyzfzikswasiu/Build/Products/Debug-iphoneos/bazel-out/applebin_ios-ios_arm64-dbg-ST-3a8ae290c50a/bin/bilistudio-universal/bili-studio.app"]
//
//            let pipe = Pipe()
//            process.standardOutput = pipe
//
//            do {
//                try process.run()
//                process.waitUntilExit()
//
//                let data = pipe.fileHandleForReading.readDataToEndOfFile()
//                if let output = String(data: data, encoding: .utf8) {
//                    print(output)
//                }
//            } catch {
//                print("Failed to run the executable: \(error)")
//            }
//        } else {
//            print("Executable not found in the app bundle.")
//        }
//    }
//}
//
//func relaunch5() {
//    DispatchQueue.global(qos: .default).async {
//        let task = Process()
//        let pipe = Pipe()
//
//        task.standardOutput = pipe
//        task.standardError = pipe
//        task.arguments = ["-c", "ios-deploy --justlaunch --noinstall --debug --bundle /Users/archie/Library/Developer/Xcode/DerivedData/bili-studio-agjocrxtfxnuzqfnyzfzikswasiu/Build/Products/Debug-iphoneos/bazel-out/applebin_ios-ios_arm64-dbg-ST-3a8ae290c50a/bin/bilistudio-universal/bili-studio.app"]
//        task.launchPath = "/bin/bash"
//        task.standardInput = nil
//        task.launch()
//        task.waitUntilExit()
//
//        let data = pipe.fileHandleForReading.readDataToEndOfFile()
//        let output = String(data: data, encoding: .utf8)!
//
//        print(output)
//    }
//}
