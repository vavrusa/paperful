//
//  PaperRow.swift
//  Paperful
//
//  Created by Marek Vavrusa on 9/21/19.
//  Copyright © 2019 Marek Vavrusa. All rights reserved.
//

import SwiftUI

struct PaperRow: View {
    var paper: Paper

    var body: some View {
        VStack {
            Text(paper.info.title)
                .font(.headline)
            Text(paper.info.authors.map { $0.name }.joined(separator: ","))
                .font(.footnote)
        }
    }
}

struct PaperRow_Previews: PreviewProvider {
    static var previews: some View {
        PaperRow(paper: paperData[0])
    }
}
