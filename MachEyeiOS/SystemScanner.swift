//
//  SystemScanner.swift
//  PrivateAPI_TEST
//
//  Created by Aryan Rogye on 4/29/25.
//

import MachO
import Foundation

struct LoadedImageInfo_Swift {
    var imageName : String,
    headerPtr: UnsafePointer<mach_header>,
    header : mach_header,
    slide : Int
}

final class SystemScanner {
    
    static let shared = SystemScanner()
    
    private init() {}
    
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
    
    func openDyib(for path: String) -> [LoadedImageInfo_Swift] {
        var fetchedResults : [LoadedImageInfo_Swift] = []
        
        path.withCString { cStr in
            var count: Int32 = 0
            let resultsPtr = openDylibABS(cStr, &count)
            if let results = resultsPtr {
                for i in 0..<Int(count) {
                    let image = results[i]
                    if let name = image.image_name {
                        fetchedResults.append(
                            LoadedImageInfo_Swift(
                                imageName: String(cString: name),
                                headerPtr: image.header,
                                header: image.header!.pointee,
                                slide: image.slide
                            )
                        )
                    }
                }
                free(results) // VERY IMPORTANT — you allocated in C
            }
        }
        return fetchedResults
    }


    func canLoadBinaries(for binaries: String) -> Bool {
        return binaries.withCString { cStr in
            return canLoadDylibABS(cStr) != 0
        }
    }
}
