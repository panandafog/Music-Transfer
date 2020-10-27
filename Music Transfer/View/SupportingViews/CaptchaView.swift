//
//  CaptchaView.swift
//  Music Transfer
//
//  Created by panandafog on 21.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI
import URLImage

struct CaptchaView: View {

    @State private var key = ""
    let errorInfo: VKCaptcha.ErrorMessage
    let url: URL
    let completion: ((_: VKCaptcha.Solved) -> Void)
    
    var body: some View {
        VStack {
            URLImage(url)
            TextField("Captcha", text: $key)
            Button("Apply", action: {
                completion(VKCaptcha.Solved(captcha_sid: errorInfo.error.captcha_sid,
                                            captcha_key: key))
                CaptchaViewDelegate.shared.close()
            })
            Spacer()
        }
        .padding()
    }
}
