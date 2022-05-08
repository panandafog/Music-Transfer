//
//  ActivityViewController.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 08.05.2022.
//

import UIKit

class ActivityViewController: UIViewController {
    
    var activityDetails = ActivityDetails()
    
    @objc func share(animated: Bool = true, completion: (() -> Void)? = nil) {
        let activityVC = UIActivityViewController(
            activityItems: activityDetails.activityItems,
            applicationActivities: activityDetails.applicationActivities
        )
        activityVC.excludedActivityTypes = activityDetails.excludedActivityTypes
        present(
            activityVC,
            animated: animated,
            completion: completion
        )
        activityVC.popoverPresentationController?.sourceView = self.view
    }
}

extension ActivityViewController {
    
    struct ActivityDetails {
        var activityItems: [Any] = []
        var applicationActivities: [UIActivity]?
        var excludedActivityTypes: [UIActivity.ActivityType]?
        
        init() {
            activityItems = []
        }
        
        init(
            activityItems: [Any],
            applicationActivities: [UIActivity]? = nil,
            excludedActivityTypes: [UIActivity.ActivityType]? = nil
        ) {
            self.activityItems = activityItems
            self.applicationActivities = applicationActivities
            self.excludedActivityTypes = excludedActivityTypes
        }
    }
}
