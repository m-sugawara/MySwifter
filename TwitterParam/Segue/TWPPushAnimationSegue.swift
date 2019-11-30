//
//  TWPPushAnimationSegue.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/29.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

class TWPPushAnimationSegue: UIStoryboardSegue {
    override func perform() {
        let destinationViewController: UIViewController = self.destination
        let sourceViewController: UIViewController = self.source

        let transition = CATransition()
        transition.duration = 0.5
        transition.type = CATransitionType.moveIn
        transition.subtype = CATransitionSubtype.fromRight

        destinationViewController.view.layer.add(transition, forKey: kCATransition)
        sourceViewController.present(destinationViewController, animated: true, completion: nil)
    }
}
