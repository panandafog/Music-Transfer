//
//  CreateAccountView.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import SwiftUI

struct CreateAccountView: View {
    
    @Binding var service: APIService
    
    var mainView: some View {
        if let mtService = service as? MTService {
            return AnyView(SignUpView(model: mtService.signUpViewModel))
        }
        return AnyView(EmptyView())
    }
    
    var body: some View {
        mainView
    }
}
