//
//  BinaryInspector.swift
//  PrivateAPI_TEST
//
//  Created by Aryan Rogye on 4/29/25.
//

import SwiftUI

struct BinaryInspector: View {
    private var path: String
    @State private var loadedImageInfo: [LoadedImageInfo_Swift]?
    @State private var didOpenForMachO: Bool = false
    
    init(path: String) {
        self.path = path
    }
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .white.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text(path)
                Button(action: {
                    loadedImageInfo = SystemScanner.shared.openDyib(for: path)
                    didOpenForMachO = true
                } ) {
                    Text("Open For Mach-O")
                }
                Spacer()
                if let loadedImageSafe = loadedImageInfo {
                    VStack {
                        if let header = loadedImageSafe.first?.headerPtr {
                            let addrString = String(format: "%p", header)
                            Text("Header Addy: \(addrString)")
                        }
                        ScrollView {
                            ForEach(loadedImageSafe, id: \.imageName) { info in
                                _previewMach_O(for: info)
                            }
                        }
                    }
                }
                if didOpenForMachO {
                    Button(action: {} ) {
                        Text("")
                    }
                }
            }
        }
    }
}

@ViewBuilder
func _previewMach_O(for info: LoadedImageInfo_Swift) -> some View {
    VStack {
        HStack {
            Text("Image Name: ")
            Spacer()
            Text("\(info.imageName)")
        }
        Text("Header: ")
        Divider()
        HStack {
            Text("Magic: ")
            Spacer()
            Text("\(info.header.magic)")
        }
        HStack {
            Text("CpuType:")
            Spacer()
            Text("\(info.header.cputype)")
        }
        HStack {
            Text("CpuUsbType:")
            Spacer()
            Text("\(info.header.cpusubtype)")
        }
        HStack {
            Text("fileType: ")
            Spacer()
            Text("\(info.header.filetype)")
        }
        HStack {
            Text("ncmds")
            Spacer()
            Text("\(info.header.ncmds)")
        }
        HStack {
            Text("sizeofcmds")
            Spacer()
            Text("\(info.header.sizeofcmds)")
        }
        HStack {
            Text("flags")
            Spacer()
            Text("\(info.header.flags)")
        }
        Divider()
        HStack {
            Text("slide")
            Spacer()
            Text(String(info.slide))
        }
    }

}

#Preview {
    BinaryInspector(path: "/System/Library/PrivateFrameworks/AuthKit.framework")
}
