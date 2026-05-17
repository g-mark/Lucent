//
//  CounterScreenStore.swift
//  LucentExample
//
//  Created by Steven Grosmark on 5/7/26.
//

import Foundation
import Lucent

final class CounterScreenStore: Store<CounterScreen> {

    override func handleAction(action: Action, state: inout State, store: StoreAccess) {
        switch action {

        case .decrementButtonTapped:
            state.count -= 1
            state.fact = nil

        case .incrementButtonTapped:
            state.count += 1
            state.fact = nil

        case .factButtonTapped:
            let count = state.count
            state.fact = nil
            state.factIsLoading = true

            store.runSideEffect { actions in
                await Self.loadFact(for: count, with: actions)
            }

        case .factLoaded(let fact):
            state.fact = fact
            state.factIsLoading = false
        }
    }

    private static func loadFact(for count: Int, with actions: ActionAccess) async {
        do {
            try await Task.sleep(for: .seconds(1))
            let pageName = "\(count)_(number)"
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
            let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(pageName)")!
            let data = try await URLSession.shared.data(from: url).0
            let summary = try JSONDecoder().decode(WikipediaSummary.self, from: data)
            await actions.send(.factLoaded(summary.extract))
        }
        catch {
            await actions.send(.factLoaded("Could not load a fact for \(count)."))
        }
    }

    private struct WikipediaSummary: Decodable {
        let extract: String
    }
}
