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
import MachO

struct PrivateFrameworksView: View {
    
    @State private var frameworkResults: [String: Bool] = [:]
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .white.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            VStack {
                if SystemScanner.shared.testGetTaskAllow() {
                    Text("Can Attach Debugger")
                } else {
                    Text("Cannot Attach Debugger")
                }
                Text("PID: \(isTaskForPidAllowed() == 1 ? "YES" : "NO")")
                ScrollView {
                    ForEach(SystemScanner.shared.privateFrameworks, id: \.self) { framework in
                        HStack {
                            Text(framework)
                            Spacer()
                            VStack {
                                if SystemScanner.shared.checkFrameworkExists(path: framework) {
                                    Text("API THERE")
                                    if SystemScanner.shared.canLoadPrivateFrameworks(for: framework) {
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
                }
            }
            .padding()
        }
        .onAppear {
            var temp: [String: Bool] = [:]
            for fw in SystemScanner.shared.privateFrameworks {
                temp[fw] = SystemScanner.shared.checkFrameworkExists(path: fw)
            }
            frameworkResults = temp
        }
    }
}

#Preview {
    ContentView()
}
