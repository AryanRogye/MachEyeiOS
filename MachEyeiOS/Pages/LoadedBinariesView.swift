//
//  LoadedBinaries.swift
//  PrivateAPI_TEST
//
//  Created by Aryan Rogye on 4/29/25.
//

import SwiftUI

struct LoadedBinariesView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .white.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Loaded Binaries: ")
                ScrollView {
                    ForEach(SystemScanner.shared.getLoadedBinaries(), id: \.self) { binary in
                        if binary.contains("PrivateFramework") {
                            NavigationLink(destination: BinaryInspector(path: binary)) {
                                HStack {
                                    Text(binary)
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                        .padding()
                                    Spacer()
                                    if SystemScanner.shared.canLoadBinaries(for: binary) {
                                        Text("Can Load")
                                            .foregroundStyle(.green)
                                    } else {
                                        Text("Cannot Load")
                                            .foregroundStyle(.red)
                                    }
                                }
                                .frame(maxHeight: .infinity)
                                .padding(.horizontal, 10)
                                .border(Color.white, width: 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}


#Preview {
    NavigationStack {
        LoadedBinariesView()
    }
}
