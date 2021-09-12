//
//  CaptchaRequestView.swift
//  Music Transfer
//
//  Created by panandafog on 09.09.2021.
//

import SwiftUI

struct CaptchaRequestView: View {
    var openCaptcha: (() -> Void)?
    var body: some View {
        ZStack {
            Color.orange
            Text("Need to solve captcha")
                .foregroundColor(.white)
        }
        .frame(height: 40)
        .gesture(
            TapGesture()
                .onEnded { _ in
                    openCaptcha?()
                }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CaptchaRequestView()
    }
}
