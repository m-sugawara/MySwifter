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
        let destinationViewController: UIViewController = self.destinationViewController as! UIViewController
        let sourceViewController: UIViewController = self.sourceViewController as! UIViewController
        
        let transition = CATransition()
        transition.duration = 0.5;
        transition.type = kCATransitionMoveIn
        transition.subtype = kCATransitionFromRight
        
        destinationViewController.view.layer.addAnimation(transition, forKey: kCATransition)
        sourceViewController.presentViewController(destinationViewController, animated: true, completion: nil)
    }
}
