//
//  SwiftUIActivityViewController.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 08.05.2022.
//

import SwiftUI

struct SwiftUIActivityViewController: UIViewControllerRepresentable {

    let activityViewController = ActivityViewController()

    func makeUIViewController(context: Context) -> ActivityViewController {
        activityViewController
    }
    
    func updateUIViewController(
        _ uiViewController: ActivityViewController,
        context: Context
    ) { }
    
    func share(
        _ activityDetails: ActivityViewController.ActivityDetails,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        activityViewController.activityDetails = activityDetails
        activityViewController.share(animated: animated, completion: completion)
    }
}
