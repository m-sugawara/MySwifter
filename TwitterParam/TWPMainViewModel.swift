//
//  TWPMainViewModel.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation




class TWPMainViewModel: NSObject {
    dynamic var tapCount: NSInteger = 0;
    dynamic var tweets: NSArray = [];
    
    // MARK: Initializer
    override init() {
        super.init();
        
    }
    
    // MARK: Public Methods
    
    // MARK: Private Methods

    
    // MARK: RACCommands
    var oauthButtonCommand: RACCommand {
        return RACCommand(signalBlock: { (input) -> RACSignal! in
            return self.oauthButtonSignal
        })
    }
    var oauthButtonSignal: RACSignal {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            TWPTwitterAPI.twitterAuthorizeWithOAuth().subscribeNext({ (next) -> Void in
                println("next:\(next)")
                
                self.tweets = next as! NSArray
                
            }, error: { (error) -> Void in
                subscriber.sendError(error)
                println("error:\(error)")
            }, completed: { () -> Void in
                subscriber.sendCompleted()
                println("completed")
            })
            
            return RACDisposable(block: { () -> Void in
            })
        })
    }
    
    var accountButtonCommand: RACCommand {
        return RACCommand(signalBlock: { (input) -> RACSignal! in
            return self.accountButtonSignal
        })
    }
    var accountButtonSignal: RACSignal {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            TWPTwitterAPI.twitterAuthorizeWithAccount()
            
            subscriber.sendCompleted()
            
            return RACDisposable(block: { () -> Void in
            })
        })
    }
}