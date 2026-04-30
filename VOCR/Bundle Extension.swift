//
//  Bundle Extension.swift
//  VOCR
//
//  Created by Chi Kim on 10/15/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import Foundation

extension Bundle {

    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }

    var version: String {
        let release = releaseVersionNumber ?? "0"
        let build = buildVersionNumber ?? "0"
        return "v\(release).\(build)"
    }
}
