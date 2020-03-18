//
//  ContentView.swift
//  Paperful
//
//  Created by Marek Vavrusa on 9/21/19.
//  Copyright © 2019 Marek Vavrusa. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: PaperListModel

    var body: some View {
        NavigationView {
            List {
                SearchBar(searchText: $viewModel.searchTerm, onCommit: viewModel.onSearchTapped)
                ForEach(viewModel.papers.indexed(), id: \.1.id) { index, paper in
                    NavigationLink(destination: PaperDetail(paper: self.$viewModel.papers[index])) {
                        PaperRow(paper: paper)
                    }
                }
            }
            .navigationBarTitle(Text("Search"))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(PaperListModel())
    }
}


struct SearchBar : View {
    @Binding var searchText: String
    var onCommit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search",
                text: $searchText,
                onCommit: onCommit
            )
        }.padding(.horizontal)
    }
}
