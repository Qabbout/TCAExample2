//
//  SearchView.swift
//  TCAExample2
//
//  Created by Abdulrahman Qabbout on 18/04/2024.
//
import ComposableArchitecture
import SwiftUI

@Reducer
struct Search {
  @ObservableState
  struct State: Equatable {
    var results: [GeocodingSearch.Result] = []
    var resultForecastRequestInFlight: GeocodingSearch.Result?
    var searchQuery = ""
    var weather: Weather?

    struct Weather: Equatable {
      var id: GeocodingSearch.Result.ID
      var days: [Day]

      struct Day: Equatable {
        var date: Date
        var temperatureMax: Double
        var temperatureMaxUnit: String
        var temperatureMin: Double
        var temperatureMinUnit: String
      }
    }
  }

  enum Action {
    case forecastResponse(GeocodingSearch.Result.ID, Result<Forecast, Error>)
    case searchQueryChanged(String)
    case searchQueryChangeDebounced
    case searchResponse(Result<GeocodingSearch, Error>)
    case searchResultTapped(GeocodingSearch.Result)
  }

  @Dependency(\.weatherClient) var weatherClient
  private enum CancelID { case location, weather }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .forecastResponse(_, .failure):
        state.weather = nil
        state.resultForecastRequestInFlight = nil
        return .none

      case let .forecastResponse(id, .success(forecast)):
        state.weather = State.Weather(
          id: id,
          days: forecast.daily.time.indices.map {
            State.Weather.Day(
              date: forecast.daily.time[$0],
              temperatureMax: forecast.daily.temperatureMax[$0],
              temperatureMaxUnit: forecast.dailyUnits.temperatureMax,
              temperatureMin: forecast.daily.temperatureMin[$0],
              temperatureMinUnit: forecast.dailyUnits.temperatureMin
            )
          }
        )
        state.resultForecastRequestInFlight = nil
        return .none

      case let .searchQueryChanged(query):
        state.searchQuery = query

        // When the query is cleared we can clear the search results, but we have to make sure to
        // cancel any in-flight search requests too, otherwise we may get data coming in later.
        guard !state.searchQuery.isEmpty else {
          state.results = []
          state.weather = nil
          return .cancel(id: CancelID.location)
        }
        return .none

      case .searchQueryChangeDebounced:
        guard !state.searchQuery.isEmpty else {
          return .none
        }
        return .run { [query = state.searchQuery] send in
          await send(.searchResponse(Result { try await self.weatherClient.search(query: query) }))
        }
        .cancellable(id: CancelID.location)

      case .searchResponse(.failure):
        state.results = []
        return .none

      case let .searchResponse(.success(response)):
        state.results = response.results
        return .none

      case let .searchResultTapped(location):
        state.resultForecastRequestInFlight = location

        return .run { send in
          await send(
            .forecastResponse(
              location.id,
              Result { try await self.weatherClient.forecast(location: location) }
            )
          )
        }
        .cancellable(id: CancelID.weather, cancelInFlight: true)
      }
    }
  }
}
