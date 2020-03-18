//
//  PaperListModel.swift
//  Paperful
//
//  Created by Marek Vavrusa on 9/21/19.
//  Copyright © 2019 Marek Vavrusa. All rights reserved.
//

import Foundation
import Combine

final class PaperListModel: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var papers: [Paper] = []

    var searchTerm: String = ""
    private let provider = NcbiProvider.init()

    private let searchTappedSubject = PassthroughSubject<Void, Error>()
    private let fetchAbstractSubject = PassthroughSubject<Int, Error>()
    private var disposeBag = Set<AnyCancellable>()

    init() {
        searchTappedSubject
        .flatMap {
            self.search(searchTerm: self.searchTerm)
                .handleEvents(receiveSubscription: { _ in
                    DispatchQueue.main.async {
                        self.isLoading = true
                    }
                },
                receiveCompletion: { comp in
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                })
                .eraseToAnyPublisher()
        }
        .replaceError(with: [])
        .receive(on: DispatchQueue.main)
        .assign(to: \.papers, on: self)
        .store(in: &disposeBag)
        
        fetchAbstractSubject
        .flatMap { id in
            return self.fetchAbstract(id: id)
        }
        .replaceError(with: (-1, ""))
        .receive(on: DispatchQueue.main)
        .sink { id, result in
            guard let index = self.papers.firstIndex(where: { $0.id == id}) else {
                return
            }
            self.papers[index].abstract = result
        }
        .store(in: &disposeBag)
    }

    func onSearchTapped() {
        searchTappedSubject.send(())
    }
    
    func onDetail(id: Int) {
        fetchAbstractSubject.send(id)
    }

    private func search(searchTerm: String) -> AnyPublisher<[Paper], Error> {
        guard let url = provider.resourceUrl(resource: "esearch", params: ["term": searchTerm]) else {
            return Fail(error: URLError(.badURL))
                .mapError { $0 as Error }
                .eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
               .map { $0.data }
               .mapError { $0 as Error }
            .decode(type: NcbiSearchResponse.self, decoder: JSONDecoder())
               .eraseToAnyPublisher()
            .flatMap { response in
                return self.fetchList(search: response.esearchresult)
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchList(search: PaperSearchResult) -> AnyPublisher<[Paper], Error> {
        let ids = search.idlist.map { String($0) }
        guard let url = provider.resourceUrl(resource: "esummary", params: ["id": ids.joined(separator: ",")]) else {
            return Fail(error: URLError(.badURL))
                .mapError { $0 as Error }
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
               .map { $0.data }
               .mapError { $0 as Error }
            .tryMap { data in
                var papers = [Paper]()
                if let response = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                    let result = response["result"] as? [String: Any]
                    {
                        for id in ids {
                            if let o = result[id] as? [String: Any] {
                                    papers.append(Paper.init(with: o))
                            }
                        }
                }
                return papers
            }
        .eraseToAnyPublisher()
    }
    
    func fetchAbstract(id: Int) -> AnyPublisher<(Int, String), Error> {
        guard let url = provider.resourceUrl(resource: "efetch", params: ["id": String(id)]) else {
            return Fail(error: URLError(.badURL))
                .mapError { $0 as Error }
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
               .map { $0.data }
               .mapError { $0 as Error }
            .tryMap { data in
                switch self.provider.decode(data: data) {
                case .success(let result):
                    return (id, result)
                case .failure(let err):
                    throw err
                }
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

struct NcbiProvider {
    let EMAIL = "marek@vavrusa.com"
    let TOOL = "scienceflix"
    
    func resourceUrl(resource: String, params: [String: String]) -> URL? {
        let args = params.map { "\($0)=\($1)" }.joined(separator: "&")
        let resourceString = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/\(resource).fcgi?\(args)&db=pmc&tool=\(TOOL)&email=\(EMAIL)&retmode=json"
        return URL(string: resourceString)
    }
    
    func decode(data: Data) -> Result<String, PaperSearchError> {
        let decoder = NcbiFetchDecoder()
        let parser = XMLParser.init(data: data)
        parser.delegate = decoder
        if parser.parse() {
            return .success(decoder.abstract!)
        } else {
            return .failure(.decodeError("failed to parse XML response"))
        }
    }
}

struct NcbiSearchResponse: Decodable {
    var esearchresult: PaperSearchResult
}

class NcbiFetchDecoder: NSObject, XMLParserDelegate {
    var abstract: String?
    var parsingAbstract: Bool = false
    var skipElement: Bool = false

    func parserDidStartDocument(_ parser: XMLParser) {
        self.parsingAbstract = false
        self.skipElement = false
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        // Nothing is being captured, check if a new capture should start
        switch elementName {
        case "abstract":
            self.parsingAbstract = true
            self.abstract = ""
        case "title":
            self.skipElement = true
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if self.parsingAbstract && !self.skipElement {
            self.abstract? += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "abstract":
            self.parsingAbstract = false
        default:
            if self.skipElement {
                self.skipElement = false
                return
            }
            // Continue capturing current key
            if self.parsingAbstract {
                self.abstract? += "\n"
            }
            break
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError)
    }
}
