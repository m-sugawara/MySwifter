//
//  UserInfoViewModel.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/03.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import ReactiveSwift

class UserInfoViewModel: NSObject {

    enum UserInfoViewModelError: Error {
        case interrupted

        var message: String {
            switch self {
            case .interrupted:
                return "Action has interupted"
            }
        }
    }

    var twitterAPI: TwitterAPI!
    var userHelper: UserHelper!

    var userId: String = ""
    var user: User?

    var favoriteList: [Tweet]?

    private(set) var tweets: [Tweet] = []

    // MARK: - Initializer
    override init() {
        super.init()
    }

    // MARK: - Actions
    var getUserAction: Action<Void, Void, Error> {
        return Action { _ in
            return self.getUserInfo()
        }
    }

    var getUserTimeLineAction: Action<Void, Void, Error> {
        return Action { _ in
            return self.getUserTimeline()
        }
    }

    var getUserImageListAction: Action<Void, Void, Error> {
        return Action { _ in
            return self.getUserImageList()
        }
    }

    var getUserFavoritesAction: Action<Void, Void, Error> {
        return Action { _ in
            return self.getUserFavorites()
        }
    }

    var followAction: Action<Void, Void, Error> {
        return Action { _ in
            return self.postFollow()
        }
    }

    var userIsMe: Bool {
        return user?.userId == userHelper.currentUserId()
    }

    // MARK: - Signals
    // MARK: UserInfo
    func getUserInfo() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, _ in
            self.twitterAPI.getUsersShow(with: .id(self.userId)).startWithResult { result in
                switch result {
                case .success(let user):
                    self.user = user
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
                }
            }
        }
    }

    // MARK: Timeline
    func getUserTimeline() -> SignalProducer<Void, Error> {
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

    // MARK: ImageList
    func getUserImageList() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, _ in
            Thread.sleep(forTimeInterval: 0.5)
            let dummy = Tweet(
                tweetId: "",
                text: "not implemented",
                user: self.user)
            self.tweets = [dummy]

            observer.send(value: ())
            observer.sendCompleted()
        }
    }

    // MARK: Favorites
    func getUserFavorites() -> SignalProducer<Void, Error> {
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

    // MARK: Follow/Unfollow
    func postFollow() -> SignalProducer<Void, Error> {
        return (user?.following == true) ? unfollowSignal() : followSignal()
    }

    private func followSignal() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { [weak self] observer, lifetime in
            guard !lifetime.hasEnded, let self = self else {
                observer.send(error: UserInfoViewModelError.interrupted)
                observer.sendInterrupted()
                return
            }
            self.twitterAPI.postCreateFriendship(with: self.userId).startWithResult { result in
                switch result {
                case .success:
                    self.user?.following = true
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
                }
            }
        }
    }

    private func unfollowSignal() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { [weak self] observer, lifetime in
            guard !lifetime.hasEnded, let self = self else {
                observer.send(error: UserInfoViewModelError.interrupted)
                observer.sendInterrupted()
                return
            }

            self.twitterAPI.postDestroyFriendship(with: self.userId).startWithResult { result in
                switch result {
                case .success:
                    self.user?.following = false
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
                }
            }

        }
    }
}
