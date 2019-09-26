//
//  TWPUserInfoViewModel.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/03.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import ReactiveCocoa
import ReactiveSwift

class TWPUserInfoViewModel: NSObject {
    let twitterAPI = TWPTwitterAPI.sharedInstance
    
    var userID: String = ""
    var user: TWPUser = TWPUser()
    
    var favoriteList: Array<TWPTweet>?
    
    dynamic var tweets: Array<TWPTweet> = []

    // MARK: - Initializer
    override init() {
        super.init()
    }
    
    // MARK: - Signals
    func getUserInfoSignal() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { innerObserver, _ in
            self.twitterAPI.getUsersShowWithUserID(self.userID)?.subscribeError({ (error) -> Void in
                innerObserver.sendError(error)
            }, completed: { [weak self] () -> Void in
                guard let self = self else { return }
                self.user = TWPUserList.sharedInstance.findUserByUserID(self.userID)

                innerObserver.sendCompleted()
            })
        }
    }
    
    func getUserTimelineSignal() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { innerObserver, _ in
            self.twitterAPI.getStatusesUserTimelineWithUserID(self.userID, count: 20)?.subscribeNext({ [weak self] (next) -> Void in
                self?.tweets = next as! NSArray
            }, error: { (error) -> Void in
                innerObserver.sendError(error)
            }, completed: { () -> Void in
                innerObserver.send(value: ())
                innerObserver.sendCompleted()
            })
        }
    }
    
    // FIXME: - dummy method
    func getUserImageList() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { innerObserver, _ in
            Thread.sleep(forTimeInterval: 0.5)
            let dummy = TWPTweet(tweetID: "", text: "not implemented", user: self.user, retweeted: false, favorited: false)
            self.tweets = [dummy]

            innerObserver.send(value: ())
            innerObserver.sendCompleted()
        }
    }
    
    func getUserFavoritesList() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { innerObserver, _ in
            // if already have got list, return it.
            if let favoriteList = self.favoriteList {
                self.tweets = favoriteList
                innerObserver.send(value: ())
                innerObserver.sendCompleted()
            }
                // if not, try to get favorites list
            else {
                self.twitterAPI.getFavoritesListWithUserID(self.userID, count: 20)?.subscribeNext({ (next) -> Void in
                    self.favoriteList = next as? Array
                    self.tweets = self.favoriteList!
                }, error: { (error) -> Void in
                    innerObserver.sendError(error)
                }, completed: { () -> Void in
                    innerObserver.send(value: ())
                    innerObserver.sendCompleted()
                })
            }
        }
    }
    
    // MARK: - RACCommands
    var followButtonCommand: CocoaAction<UIButton> {
        return CocoaAction(Action { _ in
            return self.followButtonSignal()
        }, input: "")
    }
    
    func followButtonSignal() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { innerObserver, _ in
            if self.user.following == false {
                self.twitterAPI.postCreateFriendshipWithID(self.userID)?.subscribeNext({ (user) -> Void in
                }, error: { (error) -> Void in
                    innerObserver.sendError(error)
                }, completed: { [weak self] () -> Void in
                    guard let self = self else { return }
                    self.user.following = TWPUserList.sharedInstance.findUserByUserID(self.userID)?.following

                    innerObserver.send(value: ())
                    innerObserver.sendCompleted()
                })
            }
                // user.following = true
            else {
                self.twitterAPI.postDestroyFriendshipWithID(self.userID)?.subscribeNext({ (user) -> Void in
                }, error: { (error) -> Void in
                    innerObserver.sendError(error)
                }, completed: { () -> Void in
                    print("unfollow success")
                    self!.user.following = TWPUserList.sharedInstance.findUserByUserID(self.userID)?.following

                    innerObserver.send(value: ())
                    innerObserver.sendCompleted()
                })
            }
        }
    }
}
