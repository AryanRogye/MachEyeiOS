//
//  PrivateFrameworksView.swift
//  PrivateAPI_TEST
//
//  Created by Aryan Rogye on 4/29/25.
//
import SwiftUI

struct Home: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .white.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            VStack {
                HStack(alignment: .center) {
                    NavigationLink(destination: PrivateFrameworksView()) {
                        WidgetBox(
                            title: "Private Frameworks",
                            color: Color.blue
                        )
                    }
                    NavigationLink(destination: LoadedBinariesView()) {
                        WidgetBox(title: "Loaded Binaries",
                                  color: Color.red
                        )
                    }
                }
                .padding(.top, 100)
                Spacer()
            }
            .frame(alignment: .center)
        }
    }
}

struct WidgetBox: View {
    private var title: String
    private var color: Color
    
    init(title: String, color: Color) {
        self.title = title
        self.color = color
    }
    
    var body: some View {
        VStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .padding()
        }
        .frame(width: 150, height: 140)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}


#Preview {
    Home()
}
