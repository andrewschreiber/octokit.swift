//
//  Events.swift
//  OctoKit
//
//  Created by Andrew Schreiber on 5/10/16.
//  Copyright © 2016 nerdish by nature. All rights reserved.
//

import Foundation
import RequestKit

// TODO: Complete fleshing out object model. Put new classes in seperate 

/*
 {
 "id": "3993547444",
 "type": "PushEvent",
 "actor": {
 "id": 1892071,
 "login": "andrewschreiber",
 "gravatar_id": "",
 "url": "https://api.github.com/users/andrewschreiber",
 "avatar_url": "https://avatars.githubusercontent.com/u/1892071?"
 },
 "repo": {
 "id": 58442531,
 "name": "andrewschreiber/octokit.swift",
 "url": "https://api.github.com/repos/andrewschreiber/octokit.swift"
 },
 "payload": {
 "push_id": 1104322952,
 "size": 1,
 "distinct_size": 1,
 "ref": "refs/heads/master",
 "head": "aadb10b29f217950450af3f948106f8603604d02",
 "before": "9464c8aea99b900d598d76787a626e1a84fdc799",
 "commits": [
 {
 "sha": "aadb10b29f217950450af3f948106f8603604d02",
 "author": {
 "email": "andrew.schreiber1@gmail.com",
 "name": "andrewschreiber"
 },
 "message": "Added pagination to myFollowing",
 "distinct": true,
 "url": "https://api.github.com/repos/andrewschreiber/octokit.swift/commits/aadb10b29f217950450af3f948106f8603604d02"
 }
 ]
 },
 "public": true,
 "created_at": "2016-05-10T08:48:27Z"
 },
 
 
 */

@objc public class Commit:NSObject {

    public let sha:String
    public let authorEmail:String
    public let authorName:String
    public let message:String
    public let distinct:Bool
    public let url:NSURL
    
    public init?(_ json: [String: AnyObject]) {
        guard let sha = json["sha"] as? String,
        authorEmail = json["author"]?["email"] as? String,
        authorName = json["author"]?["name"] as? String,
        message = json["message"] as? String,
        distinct = json["distinct"] as? Bool,
            urlString = json["url"] as? String,
        url = NSURL(string: urlString)
        else {
            print("Couldnt deserialize JSON into Commit \(json)")
            return nil
        }
        self.sha = sha
        self.authorEmail = authorEmail
        self.authorName = authorName
        self.message = message
        self.distinct = distinct
        self.url = url
    }
    
}

@objc public class Event: NSObject {
    public let id: Int
    public let type: String
    public let isPublic: Bool
    public let createdAt: NSDate
    public let actorLogin:String
    public let repoName:String
    public let payload:[String:AnyObject]
    
    public var commits:[Commit]? {
        guard let commitsJSONArray = payload["commits"] as? [[String:AnyObject]] else {
            return nil
        }
        var commits:[Commit] = []
        
        for commitJSON in commitsJSONArray {
            if let commit = Commit(commitJSON) {
                commits.append(commit)
            }
        }
        return commits
    }
    
    public init?(_ json: [String: AnyObject]) {
        guard let id = json["id"] as? Int,
        type = json["type"] as? String,
        isPublic = json["public"] as? Bool,
        createdAt = Time.rfc3339Date(json["created_at"]as? String),
        actorLogin = json["actor"]?["login"] as? String,
        repoName = json["repo"]?["name"] as? String,
        payload = json["payload"] as? [String: AnyObject]
            else {
                print("Couldnt deserialize JSON into Event \(json)")
                return nil
        }
        self.id = id
        self.type = type
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.actorLogin = actorLogin
        self.repoName = repoName
        self.payload = payload
        
    }
    
    
}


enum EventsRouter: Router {
    case ReadRepositories(Configuration, String, String, String)
    case ReadAuthenticatedRepositories(Configuration, String, String)
    case ReadRepository(Configuration, String, String)
    
    var configuration: Configuration {
        switch self {
        case .ReadRepositories(let config, _, _, _): return config
        case .ReadAuthenticatedRepositories(let config, _, _): return config
        case .ReadRepository(let config, _, _): return config
        }
    }
    
    var method: HTTPMethod {
        return .GET
    }
    
    var encoding: HTTPEncoding {
        return .URL
    }
    
    var params: [String: String] {
        switch self {
        case .ReadRepositories(_, _, let page, let perPage):
            return ["per_page": perPage, "page": page]
        case .ReadAuthenticatedRepositories(_, let page, let perPage):
            return ["per_page": perPage, "page": page]
        case .ReadRepository:
            return [:]
        }
    }
    
    var path: String {
        switch self {
        case ReadRepositories(_, let owner, _, _):
            return "/users/\(owner)/repos"
        case .ReadAuthenticatedRepositories:
            return "/user/repos"
        case .ReadRepository(_, let owner, let name):
            return "/repos/\(owner)/\(name)"
        }
    }
}