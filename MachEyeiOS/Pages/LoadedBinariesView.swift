//
//  LoadedBinaries.swift
//  PrivateAPI_TEST
//
//  Created by Aryan Rogye on 4/29/25.
//

import SwiftUI

struct LoadedBinariesView: View {
    
    @State private var searchItem: String = ""
    
    private var binaries: [String] {
        SystemScanner.shared.getLoadedBinaries()
    }
    
    private var filteredBinaries: [String] {
        let trimmed = searchItem.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return binaries
        }

        return binaries.filter { binary in
            let fullPath = binary.lowercased()
            let fileName = URL(fileURLWithPath: binary).lastPathComponent.lowercased()
            
            return fullPath.contains(trimmed) || fileName.contains(trimmed)
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .white.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Loaded Binaries: ")
                /// Search Bar
                searchBar()
                    .padding(.bottom, 5)
                ScrollView {
                    ForEach(filteredBinaries, id: \.self) { binary in
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
    
    @ViewBuilder
    func searchBar() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: $searchItem)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}


#Preview {
    NavigationStack {
        LoadedBinariesView()
    }
}
