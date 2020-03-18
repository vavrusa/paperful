//
//  Paper.swift
//  Paperful
//
//  Created by Marek Vavrusa on 9/21/19.
//  Copyright © 2019 Marek Vavrusa. All rights reserved.
//

import SwiftUI

struct Paper: Hashable, Codable, Identifiable {
    var id: Int
    var info: PaperInfo
    var category: Category
    var abstract: String?

    enum Category: String, CaseIterable, Codable, Hashable {
        case pubmed = "PubMed"
    }
    
    init(with dictionary: [String: Any]) {
        self.id = Int(dictionary["uid"] as? String ?? "") ?? 0
        self.info = PaperInfo(with: dictionary)
        self.category = .pubmed
    }
}

struct Author: Hashable, Codable {
    var name: String
    var authtype: String
    
    init(name: String, authtype: String) {
        self.name = name
        self.authtype = authtype
    }
}

struct PaperInfo: Hashable, Codable {
    var title: String
    var authors: [Author]

    init(with dictionary: [String: Any]) {
        self.title = dictionary["title"] as? String ?? ""
        self.authors = [Author]()

        guard let authors = dictionary["authors"] as? [[String: String]] else { return }
        for item in authors {
            guard let name = item["name"] else { continue }
            guard let authtype = item["authtype"] else { continue }
            self.authors.append(Author.init(name: name, authtype: authtype))
        }
    }
}

//class Paper: NSObject {
//    var title: Title
//    var abstract: String?
//    var parsingAbstract: Bool = false
//    var skipElement: Bool = false
//
//    init(summary: ArticleSummary) {
//        self.summary = summary
//    }
//}
//
//extension ArticleDetail: XMLParserDelegate {
//    func parserDidStartDocument(_ parser: XMLParser) {
//        self.parsingAbstract = false
//        self.skipElement = false
//    }
//
//    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
//        // Nothing is being captured, check if a new capture should start
//        switch elementName {
//        case "abstract":
//            self.parsingAbstract = true
//            self.abstract = ""
//        case "title":
//            self.skipElement = true
//        default:
//            // Continue capturing current key
//            if self.parsingAbstract {
//                self.abstract? += "<" + elementName + ">"
//            }
//            break
//        }
//    }
//
//    func parser(_ parser: XMLParser, foundCharacters string: String) {
//        if self.parsingAbstract && !self.skipElement {
//            self.abstract? += string
//        }
//    }
//
//    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
//        switch elementName {
//        case "abstract":
//            self.parsingAbstract = false
//        default:
//            if self.skipElement {
//                self.skipElement = false
//                return
//            }
//            // Continue capturing current key
//            if self.parsingAbstract {
//                self.abstract? += "<" + elementName + ">"
//            }
//            break
//        }
//    }
//
//    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
//        print(parseError)
//    }
//}
