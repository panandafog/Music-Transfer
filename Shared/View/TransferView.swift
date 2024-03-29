//
//  TransferView.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI

struct TransferView: View {
    
    @ObservedObject private var model = TransferManager.shared
    
    var bottomView: some View {
        Group {
            if let captcha = model.captcha {
                CaptchaRequestView {
                    model.solvingCaptcha = true
                }
                .padding()
                .sheet(isPresented: $model.solvingCaptcha) {
                    CaptchaView(captcha: captcha) {
                        model.solvingCaptcha = false
                        model.captcha = nil
                    }
                }
            } else {
                if model.progressActive {
                    MainProgressView()
                        .padding()
                } else {
                    ToolsView()
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            
#if os(macOS)
            HStack {
                ServiceView(serviceType: .primary)
                ServiceView(serviceType: .secondary)
            }
#else
            ServiceView(serviceType: .primary)
                .padding([.top], defaultToolbarPadding)
                .padding([.horizontal], 20)
            ServiceView(serviceType: .secondary)
                .padding([.top], 10)
                .padding([.horizontal], 20)
#endif
            
            Spacer()
            
            bottomView
        }
        .navigationTitle("Transfer")
    }
}
