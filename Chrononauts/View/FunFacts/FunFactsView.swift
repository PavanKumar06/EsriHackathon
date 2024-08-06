//
//  FunFactsView.swift
//  Chrononauts
//
//  Created by FredyCamas on 7/28/24.
//

import SwiftUI

struct FanFactsView: View {
    @State private var facts: [String] = []
    @State private var currentFactIndex = 0
    
    let timer = Timer.publish(every: 6, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            if !facts.isEmpty {
                Text(facts[currentFactIndex])
                    .lineLimit(nil) // Allow text to wrap to multiple lines
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.slide)
            }
        }
        .padding()
        .onAppear {
            facts = loadFacts()
        }
        .onReceive(timer) { _ in
            if !facts.isEmpty {
                withAnimation {
                    currentFactIndex = (currentFactIndex + 1) % facts.count
                }
            }
        }
    }

    func loadFacts() -> [String] {
        let jsonString = """
        {
            "esri": {
                "Fact1": "Esri is one of the oldest software companies. It is older than Microsoft, Apple, Oracle and even SAP!",
                "Fact2": "Esri is a private company and the only two shareholders are the two founders — Jack and Laura Dangermond!",
                "Fact3": "Some of the users of ESRI include: 30,000 cities and local governments, all 50 US states, and 12,000 universities!"
            },
            "park":{
                "Fact1": "Truist Park features the largest canopy in baseball, three times bigger than most",
                "Fact2": "The Atlanta Braves are the only existing MLB franchise to have played every season since professional baseball came into existence",
                "Fact3": "Truist Park was originally named SunTrust Park when it opened in 2017. It officially changed names on January 14, 2020"
            }
        }
        """

        let data = Data(jsonString.utf8)
        let decoder = JSONDecoder()
        
        guard let factsModel = try? decoder.decode(FactsModel.self, from: data) else {
            return []
        }

        // Combine all facts into a single array
        return Array(factsModel.esri.values) + Array(factsModel.park.values)
    }
}


struct FactsModel: Codable {
    let esri: [String: String]
    let park: [String: String]
}
