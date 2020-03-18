//
//  PaperDetail.swift
//  Paperful
//
//  Created by Marek Vavrusa on 9/22/19.
//  Copyright © 2019 Marek Vavrusa. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import AVFoundation

struct PaperDetail: View {
    @EnvironmentObject var viewModel: PaperListModel
    @Binding var paper: Paper
    @State var synthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer.init()
    @State var isSpeaking: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text(paper.info.title)
                .font(.headline)
            Text(paper.info.authors.map { $0.name }.joined(separator: ","))
                .font(.caption)
            HStack {
                Image(systemName: !self.isSpeaking ? "play.circle" : "pause.circle")
                    .imageScale(.large)
                    .onTapGesture {
                        if self.synthesizer.isPaused {
                            self.synthesizer.continueSpeaking()
                            self.isSpeaking = true
                            return
                        }
                        if self.synthesizer.isSpeaking {
                            self.synthesizer.pauseSpeaking(at: .word)
                            self.isSpeaking = false
                            return
                        }
                        guard let text = self.paper.abstract else {
                            return
                        }
                        let utterance = AVSpeechUtterance.init(string: text)
                         utterance.voice = AVSpeechSynthesisVoice.init(language: "en-GB")!
                         utterance.rate = 0.40
                         utterance.postUtteranceDelay = 5
                        self.synthesizer.speak(utterance)
                        self.isSpeaking = true
                }
                .onDisappear(perform: {
                    print("Disappearing")
                    self.synthesizer.pauseSpeaking(at: .immediate)
                    self.synthesizer.stopSpeaking(at: .immediate)
                })
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
            }
            ScrollView {
                Text(self.paper.abstract ?? "")
                    .lineLimit(100)
                    .font(.body)
            }
            
        }
        .navigationBarTitle(Text("Preview paper"), displayMode: .inline)
        .onAppear {
            // Fetch paper abstract if it's not yet cached
            if self.paper.abstract == nil {
                self.viewModel.onDetail(id: self.paper.id)
            }
        }
    }
}

struct PaperDetail_Previews: PreviewProvider {
    static var previews: some View {
        PaperRow(paper: paperData[0])
        .environmentObject(PaperListModel())
    }
}
