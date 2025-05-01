//
//  SystemScanner.swift
//  PrivateAPI_TEST
//
//  Created by Aryan Rogye on 4/29/25.
//

import MachO
import Foundation

struct LoadedImageInfo_Swift {
    let imageName: String
    let headerPtr : UnsafeMutablePointer<LoadedImageInfo_C>
    let header: mach_header
    let slide: Int
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
    
    func getBinary(from path: String) -> String {
//        char** getMachOBinary(char* path, int* outCount);
        var ret: String = ""
        path.withCString { cStr in
            var count: Int32 = 0
            if let result = getMachOBinary(cStr, &count) {
                for i in 0..<Int(count) {
                    if let cString = result[i] {
                        let swiftStr = String(cString: cString)
                        ret += swiftStr + "\n"
                        print(swiftStr)
                        free(cString)
                    }
                }
                free(result)
            }
        }
        return ret
    }
    
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
    
    func openDyib(for path: String) -> [UnsafeMutablePointer<LoadedImageInfo_C>] {
        var fetchedResults : [UnsafeMutablePointer<LoadedImageInfo_C>] = []
        
        path.withCString { cStr in
            var count: Int32 = 0
            let resultsPtr = openDylibABS(cStr, &count)
            if let results = resultsPtr {
                for i in 0..<Int(count) {
                    let ptr = results.advanced(by: i)
                    fetchedResults.append(ptr)
                }
                free(results)
            }
        }
        return fetchedResults
    }
    
    func resolveFrameworkBinary(for framework: String) -> String? {
        let searchPaths = [
            "/System/Library/PrivateFrameworks/",
            "/Library/Apple/System/Library/PrivateFrameworks/"
        ]
        
        for basePath in searchPaths {
            let fullPath = basePath + framework
            if let bundle = Bundle(path: fullPath),
               let binary = bundle.executablePath {
                return binary
            }
        }
        return nil
    }
    
    func convertLoadedImageSafe(_ ptrs: [UnsafeMutablePointer<LoadedImageInfo_C>]) -> [LoadedImageInfo_Swift] {
        ptrs.compactMap { ptr in
            guard let imageNameCStr = ptr.pointee.image_name,
                  let headerPtr = ptr.pointee.header else {
                return nil
            }

            let imageName = String(cString: imageNameCStr)
            let header = headerPtr.pointee

            return LoadedImageInfo_Swift(
                imageName: imageName,
                headerPtr: ptr,
                header: header,
                slide: ptr.pointee.slide
            )
        }
    }


    func canLoadBinaries(for binaries: String) -> Bool {
        return binaries.withCString { cStr in
            return canLoadDylibABS(cStr) != 0
        }
    }
    
    func viewSymbolTree(for imageInfoPtr: UnsafeMutablePointer<LoadedImageInfo_C>) -> [String] {
        var count: Int32 = 0
        guard let result = getLibFunctions(
            UnsafeRawPointer(imageInfoPtr.pointee.header).assumingMemoryBound(to: mach_header_64.self),
            imageInfoPtr.pointee.slide,
            &count
        ) else {
            return []
        }
        var symbols: [String] = []
        for i in 0..<Int(count) {
            if let cStr = result[i] {
                symbols.append(String(cString: cStr))
                free(cStr) // free strdup-ed string
            }
        }
        
        free(result) // free array of char* pointers
        return symbols
    }
}
