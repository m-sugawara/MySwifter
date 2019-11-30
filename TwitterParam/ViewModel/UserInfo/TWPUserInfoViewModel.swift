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
    let twitterAPI = TWPTwitterAPI.shared

    var userId: String = ""
    var user: TWPUser?

    var favoriteList: [TWPTweet]?

    dynamic var tweets: [TWPTweet] = []

    // MARK: - Initializer
    override init() {
        super.init()
    }

    // MARK: - Signals
    func getUserInfoSignalProducer() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, _ in
            self.twitterAPI.getUsersShow(with: .id(self.userId)).startWithResult { result in
                switch result {
                case .success:
                    self.user = TWPUserList.shared.findUser(by: self.userId)
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
                }
            }
        }
    }

    func getUserTimelineSignalProducer() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, _ in
            self.twitterAPI.getStatusesHomeTimeline(count: 20).startWithResult { result in
                switch result {
                case .success(let tweets):
                    self.tweets = tweets
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
                }
            }
        }
    }

    func getUserImageListSignalProducer() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, _ in
            Thread.sleep(forTimeInterval: 0.5)
            let dummy = TWPTweet(
                tweetId: "",
                text: "not implemented",
                user: self.user)
            self.tweets = [dummy]

            observer.send(value: ())
            observer.sendCompleted()
        }
    }

    func getUserFavoritesListSignalProducer() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, _ in
            // if already have list, return it.
            if let favoriteList = self.favoriteList {
                self.tweets = favoriteList
                observer.sendCompleted()
            } else {
                self.twitterAPI.getFavoritesList(
                    with: self.userId,
                    count: 20
                ).startWithResult { result in
                    switch result {
                    case .success(let tweets):
                        self.favoriteList = tweets
                        self.tweets = tweets
                        observer.sendCompleted()
                    case .failure(let error):
                        observer.send(error: error)
                    }
                }
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
        return (self.user?.following == true) ? unfollowSignal() : followSignal()
    }

    private func followSignal() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.twitterAPI.postCreateFriendship(with: self.userId).startWithResult { result in
                switch result {
                case .success:
                    if let user = TWPUserList.shared.findUser(by: self.userId) {
                        self.user?.following = user.following
                    }
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
                }
            }
        }
    }

    private func unfollowSignal() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }

            self.twitterAPI.postDestroyFavorite(with: self.userId).startWithResult { result in
                switch result {
                case .success:
                    if let user = TWPUserList.shared.findUser(by: self.userId) {
                        self.user?.following = user.following
                    }
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
                }
            }

        }
    }
}
