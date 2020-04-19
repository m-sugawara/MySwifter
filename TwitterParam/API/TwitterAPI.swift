//
//  TwitterAPI.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/02.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

import Accounts
import SwifteriOS
import ReactiveSwift

final class TwitterAPI {

    typealias FailureHandler = (_ error: Error) -> Void

    private var swifter: Swifter

    var userHelper: UserHelper!

    // MARK: - Initializer
    init(secrets: TwitterSecrets) {
        self.swifter = Swifter(
            consumerKey: secrets.consumerKey,
            consumerSecret: secrets.consumerSecret
        )
    }

    // MARK: - ACAccount
    func twitterAuthorizeWithAccount() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }

            let accountStore = ACAccountStore()
            let accountType = accountStore.accountType(
                withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
            accountStore.requestAccessToAccounts(
                with: accountType,
                options: nil
            ) { [weak self] granted, error in
                guard let self = self else {
                    observer.sendInterrupted()
                    return
                }
                guard granted else {
                    observer.send(error: APIError.notGrantedACAccount)
                    return
                }
                guard let twitterAccount = accountStore.accounts(
                    with: accountType)?.first as? ACAccount else {
                    observer.send(error: APIError.noTwitterAccount)
                    return
                }
                self.swifter = Swifter(account: twitterAccount)

                // Save User's AccessToken
                _ = self.userHelper.saveUserAccount(account: twitterAccount)

                observer.sendCompleted()
            }
        }
    }

    // MARK: - OAuth
    func twitterAuthorizeWithOAuth() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { [weak self] observer, lifetime in
            guard let self = self, !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            guard let userToken = self.userHelper.fetchUserToken() else {
                // Nothing AccessToken
                self.swifter.authorize(withCallback: URL(string: "tekitou://success")!, presentingFrom: nil,
                    success: { [weak self] accessToken, _ -> Void in
                        _ = self?.userHelper.saveUserToken(data: accessToken!)
                        observer.sendCompleted()
                    },
                    failure: { (error) -> Void in
                        observer.send(error: APIError.noTwitterAccount)
                })
                return
            }
            self.swifter.client.credential = userToken
            observer.sendCompleted()
        }
    }

    // MARK: - Wrapper Method(Login)
    func tryToLogin() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { [weak self] observer, _ in
            self?.twitterAuthorizeWithAccount().start { event in
                switch event {
                case .failed(let error):
                    guard let apiError = error as? APIError,
                        apiError == .noTwitterAccount,
                        apiError == .notGrantedACAccount else {
                            observer.send(error: error)
                            return
                    }
                    // if try to login for using ACAccount failed, try to login with OAuth.
                    self?.twitterAuthorizeWithOAuth().start { event in
                        switch event {
                        case .failed(let error):
                            observer.send(error: error)
                        case .completed:
                            observer.sendCompleted()
                        default:
                            break
                        }
                    }
                case .completed:
                    observer.sendCompleted()
                default:
                    break
                }
            }
        }
    }

    // MARK: - Wrapper Method(User)
    func getMyUser() -> SignalProducer<User, Error> {
        return getUsersShow(with: .id(userHelper.currentUserId()!))
    }

    func getUsersShow(with userTag: UserTag, includeEntities: Bool = false) -> SignalProducer<User, Error> {
        return SignalProducer<User, Error> { [weak self] observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self?.swifter.showUser(userTag,
                includeEntities: includeEntities,
                success: { json in
                    let user = User(dictionary: json.object!)

                    observer.send(value: user)
                    observer.sendCompleted()
                }, failure: { (error) -> Void in
                    observer.send(error: error)
            })
        }
    }
    // MARK: - Wrapper Method(Follow)
    func getFriendList(
        with id: String,
        cursor: String? = nil,
        count: Int? = nil,
        skipStatus: Bool? = nil,
        includeUserEntities: Bool? = nil
    ) -> SignalProducer<[User], Error> {
        return SignalProducer<[User], Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getUserFollowingIDs(
                for: .id(id),
                cursor: cursor,
                count: count,
                success: { json, _, _ in
                    var resultUsers: [User] = []
                    for userJSON in json.array! {
                        let resultUser = User(dictionary: userJSON.object!)
                        resultUsers.append(resultUser)
                    }
                    observer.send(value: resultUsers)
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }
    // MARK: - Wrapper Method(Followers)
    func getFollowersList(
        with id: String,
        cursor: String? = nil,
        count: Int? = nil,
        skipStatus: Bool? = nil,
        includeUserEntities: Bool? = nil
    ) -> SignalProducer<[User], Error> {
        return SignalProducer<[User], Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getUserFollowersIDs(
                for: .id(id),
                cursor: cursor,
                count: count,
                success: { json, _, _ in
                    var resultUsers: [User] = []
                    for userJSON in json.array! {
                        let resultUser = User(dictionary: userJSON.object!)
                        resultUsers.append(resultUser)
                    }
                    observer.send(value: resultUsers)
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    // MARK: - Wrapper Method(Timeline)
    func getStatusesHomeTimeline(
        count: Int? = nil,
        sinceID: String? = nil,
        maxID: String? = nil,
        trimUser: Bool? = nil,
        contributorDetails: Bool? = nil,
        includeEntities: Bool? = nil,
        tweetMode: TweetMode = .default
    ) -> SignalProducer<[Tweet], Error> {

        return SignalProducer<[Tweet], Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getHomeTimeline(
                count: count,
                sinceID: sinceID,
                maxID: maxID,
                trimUser: trimUser,
                contributorDetails: contributorDetails,
                includeEntities: includeEntities,
                tweetMode: tweetMode,
                success: { json in
                    guard let tweets = self.parseTweets(from: json) else {
                        observer.send(error: APIError.failedToParseJSON)
                        return
                    }

                    observer.send(value: tweets)
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    func getUserTimeline(
        with userId: String,
        customParam: [String: Any] = [:],
        count: Int? = nil,
        sinceID: String? = nil,
        maxID: String? = nil,
        trimUser: Bool? = nil,
        excludeReplies: Bool? = nil,
        includeRetweets: Bool? = nil,
        contributorDetails: Bool? = nil,
        includeEntities: Bool? = nil,
        tweetMode: TweetMode = .default
    ) -> SignalProducer<[Tweet], Error> {

        return SignalProducer<[Tweet], Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getTimeline(
                for: .id(userId),
                customParam: customParam,
                count: count,
                sinceID: sinceID,
                maxID: maxID,
                trimUser: trimUser,
                excludeReplies: excludeReplies,
                includeRetweets: includeRetweets,
                contributorDetails: contributorDetails,
                includeEntities: includeEntities,
                tweetMode: tweetMode,
                success: { json in
                    guard let tweets = self.parseTweets(from: json) else {
                        observer.send(error: APIError.failedToParseJSON)
                        return
                    }

                    observer.send(value: tweets)
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    private func parseTweets(from json: JSON) -> [Tweet]? {
        guard let statuses = json.array else {
            return nil
        }
        var tweets = [Tweet]()
        statuses.forEach {
            guard let tweet = parseTweet(from: $0) else { return }
            tweets.append(tweet)
        }
        return tweets
    }

    private func parseTweet(from json: JSON) -> Tweet? {
        guard let userDictionary = json["user"].object else {
            return nil
        }
        let user = User(dictionary: userDictionary)
        return Tweet(status: json, user: user)
    }

    // MARK: - Wrapper Method(Tweet)
    func postStatusUpdate(
        status: String,
        inReplyToStatusID: String? = nil,
        coordinate: (lat: Double, long: Double)? = nil,
        autoPopulateReplyMetadata: Bool? = nil,
        excludeReplyUserIds: Bool? = nil,
        placeID: Double? = nil,
        displayCoordinates: Bool? = nil,
        trimUser: Bool? = nil,
        mediaIDs: [String] = [],
        attachmentURL: URL? = nil,
        tweetMode: TweetMode = .default
    ) -> SignalProducer<Void, Error> {

        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.postTweet(
                status: status,
                inReplyToStatusID: inReplyToStatusID,
                coordinate: coordinate,
                autoPopulateReplyMetadata: autoPopulateReplyMetadata,
                excludeReplyUserIds: excludeReplyUserIds,
                placeID: placeID,
                displayCoordinates: displayCoordinates,
                trimUser: trimUser,
                mediaIDs: mediaIDs,
                attachmentURL: attachmentURL,
                tweetMode: tweetMode,
                success: { _ in
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    func getStatuesShow(
        with id: String,
        trimUser: Bool? = nil,
        includeMyRetweet: Bool? = nil,
        includeEntities: Bool? = nil,
        includeExtAltText: Bool? = nil,
        tweetMode: TweetMode = .default
    ) -> SignalProducer<Tweet, Error> {

        return SignalProducer<Tweet, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getTweet(
                for: id,
                trimUser: trimUser,
                includeMyRetweet: includeMyRetweet,
                includeEntities: includeEntities,
                includeExtAltText: includeExtAltText,
                tweetMode: tweetMode,
                success: { json in
                    guard let tweet = self.parseTweet(from: json) else {
                        observer.send(error: APIError.failedToParseJSON)
                        return
                    }
                    observer.send(value: tweet)
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    // MARK: - Wrapper Method(Retweet)
    func getCurrentUserRetweetId(with id: String) -> SignalProducer<String, Error> {
        return SignalProducer<String, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getTweet(
                for: id,
                includeMyRetweet: true,
                tweetMode: .default,
                success: { json in
                    let currentUserRetweet = json["current_user_retweet"].object
                    guard let currentUserRetweetId = currentUserRetweet?["id_str"]?.string else {
                        observer.send(error: APIError.failedToParseJSON)
                        return
                    }
                    observer.send(value: currentUserRetweetId)
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    func postStatusRetweet(
        with id: String,
        trimUser: Bool? = nil,
        tweetMode: TweetMode = .default
    ) -> SignalProducer<Void, Error> {

        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.retweetTweet(
                forID: id,
                trimUser: trimUser,
                tweetMode: tweetMode,
                success: { _ in
                    observer.send(value: ())
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    func postStatusesDestroy(
        with id: String,
        trimUser: Bool? = nil,
        tweetMode: TweetMode = .default
    ) -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.destroyTweet(
                forID: id,
                trimUser: trimUser,
                tweetMode: tweetMode,
                success: { _ in
                    observer.send(value: ())
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    // MARK: - Wrapper Methods(favorite)
    func getFavoritesList(
        with userId: String,
        count: Int? = nil,
        sinceID: String? = nil,
        maxID: String? = nil,
        tweetMode: TweetMode = .default
    ) -> SignalProducer<[Tweet], Error> {

        return SignalProducer<[Tweet], Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getRecentlyFavoritedTweets(
                for: .id(userId),
                count: count,
                sinceID: sinceID,
                maxID: maxID,
                tweetMode: tweetMode,
                success: { json in
                    guard let tweets = self.parseTweets(from: json) else {
                        observer.send(error: APIError.failedToParseJSON)
                        return
                    }
                    observer.send(value: tweets)
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    func postCreateFavorite(
        with id: String,
        includeEntities: Bool? = nil,
        tweetMode: TweetMode = .default
    ) -> SignalProducer<Void, Error> {

        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.favoriteTweet(
                forID: id,
                includeEntities: includeEntities,
                tweetMode: tweetMode,
                success: { _ in
                    observer.send(value: ())
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    func postDestroyFavorite(
        with id: String,
        includeEntities: Bool? = nil,
        tweetMode: TweetMode = .default
    ) -> SignalProducer<Void, Error> {

        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.unfavoriteTweet(
                forID: id,
                includeEntities: includeEntities,
                tweetMode: tweetMode,
                success: { _ in
                    observer.send(value: ())
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    // MARK: - Wrapper Methods(follow)
    func postCreateFriendship(with id: String, follow: Bool? = nil) -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.followUser(
                .id(id),
                follow: follow,
                success: { _ in
                    observer.send(value: ())
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    func postDestroyFriendship(with id: String) -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.unfollowUser(
                .id(id),
                success: { _ in
                    observer.send(value: ())
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }
}
