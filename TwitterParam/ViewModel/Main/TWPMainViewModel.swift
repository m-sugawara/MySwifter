//
//  TWPMainViewModel.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

class TWPMainViewModel: NSObject {
    let twitterAPI = TWPTwitterAPI.sharedInstance
    
    dynamic var tapCount: NSInteger = 0
    dynamic var tweets: NSArray = []
    
    private var _feedUpdateButtonSignal: RACSignal?
    
    // MARK: - Initializer
    override init() {
        super.init();
        
    }
    
    // MARK: - Public Methods
    
    // MARK: - Private Methods

    
    // MARK: - RACCommands
    var oauthButtonCommand: RACCommand {
        return RACCommand(signalBlock: { (input) -> RACSignal! in
            
            return self.oauthButtonSignal
        })
    }
    var oauthButtonSignal: RACSignal {
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.twitterAPI.twitterAuthorizeWithOAuth().subscribeNext({ (next) -> Void in
                
                self.tweets = next as! NSArray
                
                }, error: { (error) -> Void in
                    subscriber.sendError(error)
                }, completed: { () -> Void in
                    subscriber.sendNext(nil)
                    subscriber.sendCompleted()
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
            self.twitterAPI.twitterAuthorizeWithAccount().subscribeNext({ (next) -> Void in
                
                self.tweets = next as! NSArray
                
                subscriber.sendNext(next)
            }, error: { (error) -> Void in
                subscriber.sendError(error)
            }, completed: { () -> Void in
                subscriber.sendNext(nil)
                subscriber.sendCompleted()
            })
            
            return RACDisposable(block: { () -> Void in
            })
        })
    }
    
    var feedUpdateButtonCommand: RACCommand {
        return RACCommand(signalBlock: { (input) -> RACSignal! in
            return self.feedUpdateButtonSignal()
        })
    }
    func feedUpdateButtonSignal() -> RACSignal {
        if (_feedUpdateButtonSignal != nil) {
            return _feedUpdateButtonSignal!
        }
        _feedUpdateButtonSignal =  RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            self.twitterAPI.getStatusesHomeTimelineWithCount(20)?.subscribeNext({ (next) -> Void in
                self.tweets = next as! NSArray
                }, error: { (error) -> Void in
                    subscriber.sendError(error)
                }, completed: { () -> Void in
                    subscriber.sendNext(nil)
                    subscriber.sendCompleted()
            })
            
            return nil
        })
        
        return _feedUpdateButtonSignal!
    }
}