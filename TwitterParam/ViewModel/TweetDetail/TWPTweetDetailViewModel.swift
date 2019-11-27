//
//  TWPTweetDetailViewModel.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/19.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import ReactiveSwift

class TWPTweetDetailViewModel {
    
    var tweetId = ""
    var tweet: TWPTweet?
    
    // MARK: - Deinit
    deinit {
        print("TweetDetailViewModel deinit")
    }
    
    func getTweetSignalProducer() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            TWPTwitterAPI.shared.getStatuesShow(with: self.tweetId).startWithResult { result in
                switch result {
                case .success(let tweet):
                    self.tweet = tweet
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
                }
            }
        }
    }
    
    
}
