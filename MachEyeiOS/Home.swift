//
//  ContentView.swift
//  PrivateAPI_TEST
//
//  Created by Aryan Rogye on 4/29/25.
//

import SwiftUI
import Darwin
import Foundation
import Security


func testGetTaskAllow() -> Bool {
    var task: mach_port_t = 0
    let pid = getpid()
    let result = task_for_pid(mach_task_self_, pid, &task)
    
    if result == KERN_SUCCESS {
        return true
    } else {
        return false
    }
}

struct Home: View {
    
    let privateFrameworks = [
        "MobileWiFi.framework",
        "BluetoothManager.framework",
        "MediaRemote.framework",
        "SpringBoardServices.framework",
        "BackBoardServices.framework",
        "CoreDuet.framework",
        "AppPredictionClient.framework",
        "FrontBoard.framework",
        "AuthKit.framework",
        "AppleIDAuthSupport.framework",
        "AXSpringBoardServer.framework",
        "LocationSupport.framework",
        "RunningBoardServices.framework",
        "Celestial.framework",
        "BiometricKit.framework",
        "ProactiveSupport.framework"
    ]
    
    func checkFrameworkExists(path frameworkName: String) -> Bool {
        let fullPath = "/System/Library/PrivateFrameworks/\(frameworkName)"
        return FileManager.default.fileExists(atPath: fullPath)
    }
    
    func canLoadPrivateFrameworks(for frameworkName: String) -> Bool {
        return frameworkName.withCString { cStr in
            return canLoadDylib(cStr) != 0
        }
    }
    
    func getLoadedBinaries() -> [String] {
        var count: Int32 = 0
        guard let cArray = get_loaded_binaries_via_memory(&count) else {
            return []
        }
        
        var result: [String] = []
        for i in 0..<Int(count) {
            if let cStr = cArray[i] {
                result.append(String(cString: cStr))
                free(UnsafeMutableRawPointer(mutating: cStr)) // free strdup
            }
        }
        
        free(cArray) // free the array of pointers
        
        return result
    }
    
    var body: some View {
        VStack {
            if testGetTaskAllow() {
                Text("Can Attach Debugger")
            } else {
                Text("Cannot Attach Debugger")
            }
            Text("PID: \(isTaskForPidAllowed() == 1 ? "YES" : "NO")")
            ScrollView {
                ForEach(privateFrameworks, id: \.self) { framework in
                    HStack {
                        Text(framework)
                        Spacer()
                        VStack {
                            if checkFrameworkExists(path: framework) {
                                Text("API THERE")
                                if canLoadPrivateFrameworks(for: framework) {
                                    Text("Can Load Lib")
                                } else {
                                    Text("Cannot Load Lib")
                                }
                            } else {
                                Text("API NOT THERE")
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                    .padding(.horizontal, 10)
                    .border(Color.black, width: 1)
                }
                ForEach(getLoadedBinaries(), id: \.self) { binary in
                    if binary.contains("PrivateFramework") {
                        HStack {
                            Text(binary)
                        }
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 10)
                        .border(Color.black, width: 1)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            
        }
    }
}

#Preview {
    ContentView()
}
