//
//  SearchView.swift
//  TCAExample2
//
//  Created by Abdulrahman Qabbout on 18/04/2024.
//

import SwiftUI
import ComposableArchitecture

struct SearchView: View {
    @Bindable var store: StoreOf<Search>
    
    private let readMe = """
      This application demonstrates live-searching with the Composable Architecture. As you type the \
      events are debounced for 300 milliseconds, and when you stop typing an API request is made to \
      load locations. Then tapping on a location will load weather.
      """
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text(readMe)
                    .padding()
                
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField(
                        "New York, San Francisco, ...", text: $store.searchQuery.sending(\.searchQueryChanged)
                    )
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                
                List {
                    ForEach(store.results) { location in
                        VStack(alignment: .leading) {
                            Button {
                                store.send(.searchResultTapped(location))
                            } label: {
                                HStack {
                                    Text(location.name)
                                    
                                    if store.resultForecastRequestInFlight?.id == location.id {
                                        ProgressView()
                                            .padding(.leading, 5)
                                    }
                                }
                            }
                            
                            if location.id == store.weather?.id {
                                weatherView(locationWeather: store.weather)
                            }
                        }
                    }
                }
//                .animation(.smooth, value: store.results)
                
                Button("Weather API provided by Open-Meteo") {
                    UIApplication.shared.open(URL(string: "https://open-meteo.com/en")!)
                }
                .foregroundColor(.gray)
                .padding(.all, 16)
            }
            .navigationTitle("Search")
        }
        // run task on every store.searchQuery change
        .task(id: store.searchQuery) {
            
            do {
                try await Task.sleep(for: .milliseconds(300))
                await store.send(.searchQueryChangeDebounced).finish()
            } catch {
                dump("Task Cancelled sending .searchQueryChangeDebounced")
            }
        }
    }
    
    @ViewBuilder
    func weatherView(locationWeather: Search.State.Weather?) -> some View {
        if let locationWeather {
            let days = locationWeather.days
                .enumerated()
                .map { idx, weather in formattedWeather(day: weather, isToday: idx == 0) }
            
            VStack(alignment: .leading) {
                ForEach(days, id: \.self) { day in
                    Text(day)
                }
            }
            .padding(.leading, 16)
        }
    }
    
    
    private func formattedWeather(day: Search.State.Weather.Day, isToday: Bool) -> String {
        let date =
        isToday
        ? "Today"
        : dateFormatter.string(from: day.date).capitalized
        let min = "\(day.temperatureMin)\(day.temperatureMinUnit)"
        let max = "\(day.temperatureMax)\(day.temperatureMaxUnit)"
        
        return "\(date), \(min) – \(max)"
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}

#Preview {
    SearchView(
        store: Store(initialState: Search.State()) {
            Search()
        }
    )
}
