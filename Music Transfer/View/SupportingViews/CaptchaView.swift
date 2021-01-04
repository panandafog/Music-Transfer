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
            HStack {
                Spacer()
                TextField("Captcha", text: $key)
                    .frame(width: 150)
                Spacer()
            }
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

struct CaptchaView_Preview: PreviewProvider {
    static var previews: some View {
        CaptchaView(errorInfo: VKCaptcha.ErrorMessage(
                        error: VKCaptcha.Error(error_code: 123,
                                               error_msg: "Captcha needed",
                                               request_params: [VKCaptcha.RequestParam](),
                                               captcha_sid: "149876991953",
                                               captcha_img: "https://api.vk.com/captcha.php?sid=149876991953&s=1")),
                    url: URL(string: "https://api.vk.com/captcha.php?sid=149876991953&s=1")!,
                    completion: {_ in })
    }
}
