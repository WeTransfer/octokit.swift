//
//  Releases.swift
//  OctoKit
//
//  Created by Antoine van der Lee on 31/01/2020.
//  Copyright © 2020 nerdish by nature. All rights reserved.
//

import Foundation
import RequestKit
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: model

public struct Release: Codable {
    public let id: Int
    public let url: URL
    public let htmlURL: URL
    public let assetsURL: URL
    public let tarballURL: URL?
    public let zipballURL: URL?
    public let nodeId: String
    public let tagName: String
    public let commitish: String
    public let name: String
    public let body: String
    public let draft: Bool
    public let prerelease: Bool
    public let createdAt: Date
    public let publishedAt: Date?
    public let author: User

    enum CodingKeys: String, CodingKey {
        case id, url, name, body, draft, prerelease, author

        case htmlURL = "html_url"
        case assetsURL = "assets_url"
        case tarballURL = "tarball_url"
        case zipballURL = "zipball_url"
        case nodeId = "node_id"
        case tagName = "tag_name"
        case commitish = "target_commitish"
        case createdAt = "created_at"
        case publishedAt = "published_at"
    }
}

public struct ReleaseNotes: Codable {
    public let name: String
    public let body: String
}

// MARK: request

public extension Octokit {
    /// Fetches the list of releases.
    /// - Parameters:
    ///   - session: RequestKitURLSession, defaults to URLSession.shared()
    ///   - owner: The user or organization that owns the repositories.
    ///   - repository: The name of the repository.
    ///   - perPage: Results per page (max 100). Default: `30`.
    ///   - completion: Callback for the outcome of the fetch.
    @discardableResult
    func listReleases(_ session: RequestKitURLSession = URLSession.shared,
                      owner: String,
                      repository: String,
                      perPage: Int = 30,
                      completion: @escaping (_ response: Result<[Release], Error>) -> Void) -> URLSessionDataTaskProtocol?
    {
        let router = ReleaseRouter.listReleases(configuration, owner, repository, perPage)
        return router.load(session, dateDecodingStrategy: .formatted(Time.rfc3339DateFormatter), expectedResultType: [Release].self) { releases, error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let releases = releases {
                    completion(.success(releases))
                }
            }
        }
    }

    /// Fetches a published release with the specified tag.
    /// - Parameters:
    ///   - session: RequestKitURLSession, defaults to URLSession.shared()
    ///   - owner: The user or organization that owns the repositories.
    ///   - repository: The name of the repository.
    ///   - tag: The specified tag
    ///   - completion: Callback for the outcome of the fetch.
    @discardableResult
    func release(_ session: RequestKitURLSession = URLSession.shared,
                 owner: String,
                 repository: String,
                 tag: String,
                 completion: @escaping (_ response: Result<Release, Error>) -> Void) -> URLSessionDataTaskProtocol?
    {
        let router = ReleaseRouter.getReleaseByTag(configuration, owner, repository, tag)
        return router.load(session,
                           dateDecodingStrategy: .formatted(Time.rfc3339DateFormatter),
                           expectedResultType: Release.self)
        { release, error in
            if let error = error {
                completion(.failure(error))
            } else if let release = release {
                completion(.success(release))
            }
        }
    }

    /// Creates a new release.
    /// - Parameters:
    ///   - session: RequestKitURLSession, defaults to URLSession.shared()
    ///   - owner: The user or organization that owns the repositories.
    ///   - repo: The repository on which the release needs to be created.
    ///   - tagName: The name of the tag.
    ///   - targetCommitish: Specifies the commitish value that determines where the Git tag is created from. Can be any branch or commit SHA. Unused if the Git tag already exists. Default: the repository's default branch (usually master).
    ///   - name: The name of the release.
    ///   - body: Text describing the contents of the tag.
    ///   - prerelease: `true` to create a draft (unpublished) release, `false` to create a published one. Default: `false`.
    ///   - draft: `true` to identify the release as a prerelease. `false` to identify the release as a full release. Default: `false`.
    ///   - generateReleaseNotes: Whether to automatically generate the name and body for this release. If name is specified, the specified name will be used; otherwise, a name will be automatically generated. If body is specified, the body will be pre-pended to the automatically generated notes. Default: `false`.
    ///   - completion: Callback for the outcome of the created release.
    @discardableResult
    func postRelease(_ session: RequestKitURLSession = URLSession.shared,
                     owner: String,
                     repository: String,
                     tagName: String,
                     targetCommitish: String? = nil,
                     name: String? = nil,
                     body: String? = nil,
                     prerelease: Bool = false,
                     draft: Bool = false,
                     generateReleaseNotes: Bool = false,
                     completion: @escaping (_ response: Result<Release, Error>) -> Void) -> URLSessionDataTaskProtocol?
    {
        let router = ReleaseRouter.postRelease(configuration, owner, repository, tagName, targetCommitish, name, body, prerelease, draft, generateReleaseNotes)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Time.rfc3339DateFormatter)

        return router.post(session, decoder: decoder, expectedResultType: Release.self) { issue, error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let issue = issue {
                    completion(.success(issue))
                }
            }
        }
    }

    /// Deletes a release.
    /// - Parameters:
    ///   - session: RequestKitURLSession, defaults to URLSession.shared()
    ///   - owner: The user or organization that owns the repositories.
    ///   - repo: The repository on which the release needs to be deleted.
    ///   - releaseId: The ID of the release to delete.
    ///   - completion: Callback for the outcome of the deletion.
    @discardableResult
    func deleteRelease(_ session: RequestKitURLSession = URLSession.shared,
                       owner: String,
                       repository: String,
                       releaseId: Int,
                       completion: @escaping (_ response: Error?) -> Void) -> URLSessionDataTaskProtocol?
    {
        let router = ReleaseRouter.deleteRelease(configuration, owner, repository, releaseId)
        return router.load(session, completion: completion)
    }

    /// Generates release notes.
    /// - Parameters:
    ///   - session: RequestKitURLSession, defaults to URLSession.shared()
    ///   - owner: The user or organization that owns the repositories.
    ///   - repo: The repository on which the release needs to be deleted.
    ///   - releaseId: The ID of the release to delete.
    ///   - completion: Callback for the outcome of the deletion.
    @discardableResult
    /// Generates release notes.
    /// - Parameters:
    ///   - session: RequestKitURLSession, defaults to URLSession.shared()
    ///   - owner: The user or organization that owns the repositories.
    ///   - repo: The repository on which the release needs to be deleted.
    ///   - tagName: The tag name for the release. This can be an existing tag or a new one.
    ///   - targetCommitish: Specifies the commitish value that will be the target for the release's tag. Required if the supplied tag_name does not reference an existing tag. Ignored if the tagName already exists.
    ///   - previousTagName: The name of the previous tag to use as the starting point for the release notes. Use to manually specify the range for the set of changes considered as part this release.
    ///   - completion: Callback for the outcome of the generation.
    func generateReleaseNotes(_ session: RequestKitURLSession = URLSession.shared,
                              owner: String,
                              repository: String,
                              tagName: String,
                              targetCommitish: String,
                              previousTagName: String,
                              completion: @escaping (_ response: Result<ReleaseNotes, Error>) -> Void) -> URLSessionDataTaskProtocol?
    {
        let router = ReleaseRouter.generateNotes(configuration, owner, repository, tagName, targetCommitish, previousTagName)

        return router.post(session, expectedResultType: ReleaseNotes.self) { releaseNotes, error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let releaseNotes = releaseNotes {
                    completion(.success(releaseNotes))
                }
            }
        }
    }
}

// MARK: Router

enum ReleaseRouter: JSONPostRouter {
    case listReleases(Configuration, String, String, Int)
    case getReleaseByTag(Configuration, String, String, String)
    case postRelease(Configuration, String, String, String, String?, String?, String?, Bool, Bool, Bool)
    case deleteRelease(Configuration, String, String, Int)
    case generateNotes(Configuration, String, String, String, String, String)

    var configuration: Configuration {
        switch self {
        case let .listReleases(config, _, _, _): return config
        case let .getReleaseByTag(config, _, _, _): return config
        case let .postRelease(config, _, _, _, _, _, _, _, _, _): return config
        case let .deleteRelease(config, _, _, _): return config
        case let .generateNotes(config, _, _, _, _, _): return config
        }
    }

    var method: HTTPMethod {
        switch self {
        case .listReleases, .getReleaseByTag:
            return .GET
        case .postRelease, .generateNotes:
            return .POST
        case .deleteRelease:
            return .DELETE
        }
    }

    var encoding: HTTPEncoding {
        switch self {
        case .listReleases, .getReleaseByTag:
            return .url
        case .postRelease, .generateNotes:
            return .json
        case .deleteRelease:
            return .url
        }
    }

    var params: [String: Any] {
        switch self {
        case let .listReleases(_, _, _, perPage):
            return ["per_page": "\(perPage)"]
        case .getReleaseByTag:
            return [:]
        case let .postRelease(_, _, _, tagName, targetCommitish, name, body, prerelease, draft, generateReleaseNotes):
            var params: [String: Any] = [
                "tag_name": tagName,
                "prerelease": prerelease,
                "draft": draft,
                "generate_release_notes": generateReleaseNotes
            ]
            if let targetCommitish = targetCommitish {
                params["target_commitish"] = targetCommitish
            }
            if let name = name {
                params["name"] = name
            }
            if let body = body {
                params["body"] = body
            }
            return params
        case .deleteRelease:
            return [:]
        case let .generateNotes(_, _, _, tagName, targetCommitish, previousTagName):
            let params: [String: Any] = [
                "tag_name": tagName,
                "target_commitish": targetCommitish,
                "previous_tag_name": previousTagName
            ]
            return params
        }
    }

    var path: String {
        switch self {
        case let .listReleases(_, owner, repo, _):
            return "repos/\(owner)/\(repo)/releases"
        case let .getReleaseByTag(_, owner, repo, tag):
            return "repos/\(owner)/\(repo)/releases/tags/\(tag)"
        case let .postRelease(_, owner, repo, _, _, _, _, _, _, _):
            return "repos/\(owner)/\(repo)/releases"
        case let .deleteRelease(_, owner, repo, releaseId):
            return "repos/\(owner)/\(repo)/releases/\(releaseId)"
        case let .generateNotes(_, owner, repo, _, _, _):
            return "repos/\(owner)/\(repo)/releases/generate-notes"
        }
    }
}
