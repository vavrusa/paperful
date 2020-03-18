//
//  PaperProvider.swift
//  Paperful
//
//  Created by Marek Vavrusa on 9/21/19.
//  Copyright © 2019 Marek Vavrusa. All rights reserved.
//

import Foundation

enum PaperSearchError: Error {
    case unknown
    case decodeError(String)
}

class PaperProvider {
    
}

struct PaperSearchResult: Decodable {
    var count: Int
    var retmax: Int
    var retstart: Int
    var idlist: [Int]
    
    enum CodingKeys: String, CodingKey {
        case count
        case retmax
        case retstart
        case idlist
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = Int(try container.decode(String.self, forKey: .count))!
        retmax = Int(try container.decode(String.self, forKey: .retmax))!
        retstart = Int(try container.decode(String.self, forKey: .retstart))!
        idlist = try container.decode([String].self, forKey: .idlist).map { Int($0)! }
    }
}
