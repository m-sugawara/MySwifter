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

final class TWPTwitterAPI: NSObject {

    enum APIError: Int, Error {
        case noTwitterAccount = -100
        case notGrantedACAccount = -101
        case failedToParseJSON = -102
        case failedToGetUserId = -103

        var errorCode: Int {
            return rawValue
        }

        var message: String {
            switch self {
            case .noTwitterAccount:
                return "There is no configured Twitter account"
            case .notGrantedACAccount:
                return "granted account not found"
            case .failedToParseJSON:
                return "failed to parse JSON Data"
            case .failedToGetUserId:
                return "failed to get userId"
            }
        }
    }

    typealias FailureHandler = (_ error: Error) -> Void

    private var swifter: Swifter

    // MARK: - Singleton
    static let shared = TWPTwitterAPI()

    // MARK: - Initializer
    private override init() {
        self.swifter = Swifter(
            consumerKey: "5UwojnG3QBtSA3StY4JOvjVAK",
            consumerSecret: "XAKBmM3I4Mgt1lQtICLLKkuCWZzN0nXGe4sJ5qwDhqKK4PtCYd"
        )
        super.init()
    }

    // MARK: - ErrorHelper
    func error(with error: APIError) -> NSError {
        return NSError(
            domain: NSURLErrorDomain,
            code: error.rawValue,
            userInfo: [NSLocalizedDescriptionKey: error.message])
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
                    let error = self.error(with: .notGrantedACAccount)
                    observer.send(error: error)
                    return
                }
                guard let twitterAccount = accountStore.accounts(
                    with: accountType)?.first as? ACAccount else {
                        let error = self.error(with: .noTwitterAccount)
                    observer.send(error: error)
                    return
                }
                self.swifter = Swifter(account: twitterAccount)

                // Save User's AccessToken
                _ = TWPUserHelper.saveUserAccount(account: twitterAccount)

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
            guard let userToken = TWPUserHelper.fetchUserToken() else {
                // Nothing AccessToken
                self.swifter.authorize(withCallback: URL(string: "tekitou://success")!, presentingFrom: nil,
                    success: { accessToken, _ -> Void in
                        _ = TWPUserHelper.saveUserToken(data: accessToken!)
                        observer.sendCompleted()
                    },
                    failure: { (error) -> Void in
                        let error = self.error(with: .noTwitterAccount)
                        observer.send(error: error)
                })
                return
            }
            self.swifter.client.credential = userToken
            observer.sendCompleted()
        }
    }

    // MARK: - Logout
    func logout() {
        _ = TWPUserHelper.removeUserToken()
    }

    // MARK: - Wrapper Method(Login)
    func tryToLogin() -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { [weak self] observer, _ in
            self?.twitterAuthorizeWithAccount().start { event in
                switch event {
                case .failed(let error):
                    let errorCode = (error as NSError).code
                    if errorCode == APIError.noTwitterAccount.errorCode ||
                        errorCode == APIError.notGrantedACAccount.errorCode {
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
                    } else {
                        observer.send(error: error)
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
    func getMyUser() -> SignalProducer<Void, Error> {
        return getUsersShow(with: .id(TWPUserHelper.currentUserId()!))
    }

    func getUsersShow(with userTag: UserTag, includeEntities: Bool? = nil) -> SignalProducer<Void, Error> {
        return SignalProducer<Void, Error> { [weak self] observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self?.swifter.showUser(userTag,
                includeEntities: includeEntities,
                success: { json in
                    let user = TWPUser(dictionary: json.object!)
                    TWPUserList.shared.appendUser(user)

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
    ) -> SignalProducer<[TWPUser], Error> {
        return SignalProducer<[TWPUser], Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getUserFollowingIDs(
                for: .id(id),
                cursor: cursor,
                count: count,
                success: { json, _, _ in
                    var resultUsers: [TWPUser] = []
                    for userJSON in json.array! {
                        let resultUser = TWPUser(dictionary: userJSON.object!)
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
    ) -> SignalProducer<[TWPUser], Error> {
        return SignalProducer<[TWPUser], Error> { observer, lifetime in
            guard !lifetime.hasEnded else {
                observer.sendInterrupted()
                return
            }
            self.swifter.getUserFollowersIDs(
                for: .id(id),
                cursor: cursor,
                count: count,
                success: { json, _, _ in
                    var resultUsers: [TWPUser] = []
                    for userJSON in json.array! {
                        let resultUser = TWPUser(dictionary: userJSON.object!)
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
    ) -> SignalProducer<[TWPTweet], Error> {

        return SignalProducer<[TWPTweet], Error> { observer, lifetime in
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
                        let error = self.error(with: .failedToParseJSON)
                        observer.send(error: error)
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
    ) -> SignalProducer<[TWPTweet], Error> {

        return SignalProducer<[TWPTweet], Error> { observer, lifetime in
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
                        let error = self.error(with: .failedToParseJSON)
                        observer.send(error: error)
                        return
                    }

                    observer.send(value: tweets)
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }

    private func parseTweets(from json: JSON) -> [TWPTweet]? {
        guard let statuses = json.array else {
            return nil
        }
        var tweets = [TWPTweet]()
        statuses.forEach {
            guard let tweet = parseTweet(from: $0) else { return }
            tweets.append(tweet)
        }
        return tweets
    }

    private func parseTweet(from json: JSON) -> TWPTweet? {
        guard let userDictionary = json["user"].object else {
            return nil
        }
        let user = TWPUser(dictionary: userDictionary)
        return TWPTweet(status: json, user: user)
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
    ) -> SignalProducer<TWPTweet, Error> {

        return SignalProducer<TWPTweet, Error> { observer, lifetime in
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
                        let error = self.error(with: .failedToParseJSON)
                        observer.send(error: error)
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
                        let error = self.error(with: .failedToParseJSON)
                        observer.send(error: error)
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
    ) -> SignalProducer<[TWPTweet], Error> {

        return SignalProducer<[TWPTweet], Error> { observer, lifetime in
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
                        let error = self.error(with: .failedToParseJSON)
                        observer.send(error: error)
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
                    TWPUserList.shared.setFollowing(true, toUserId: id)
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
                    TWPUserList.shared.setFollowing(false, toUserId: id)
                    observer.send(value: ())
                    observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }
}
