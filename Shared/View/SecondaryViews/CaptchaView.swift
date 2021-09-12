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
    
    let captcha: Captcha
    var solveAction: (() -> Void)?
    
    @State private var key = ""
    
    var body: some View {
        VStack {
            if let url = captcha.url {
                URLImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 180, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            }
            HStack {
                Spacer()
                HStack {
                    TextField("Captcha", text: $key)
                    Button("Apply", action: {
                        captcha.solveCompletion(
                            Captcha.Solved(
                                sid: captcha.errorMessage.error.captcha_sid,
                                key: key
                            )
                        )
                        #if os(macOS)
                            CaptchaViewDelegate.shared.close()
                        #endif
                        solveAction?()
                    })
                }
                .frame(width: 180)
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
}

struct CaptchaView_Preview: PreviewProvider {
    static var previews: some View {
        CaptchaView(
            captcha: .init(
                errorMessage: VKCaptcha.ErrorMessage(
                    error: VKCaptcha.Error(
                        error_code: 123,
                        error_msg: "Captcha needed",
                        request_params: [VKCaptcha.RequestParam](),
                        captcha_sid: "149876991953",
                        captcha_img: "https://api.vk.com/captcha.php?sid=149876991953&s=1")
                ),
                solveCompletion: {_ in }
            )
        )
    }
}
