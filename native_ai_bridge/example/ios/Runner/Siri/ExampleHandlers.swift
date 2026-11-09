#if SIRI_AI_TOOLS
import Foundation

@available(iOS 27.3, *)
struct ExampleForecastHandler: GetForecastHandler {
  func perform(request: ForecastRequest) async throws -> String {
    let days = min(max(request.days, 1), 7)
    return "The next \(days) days in \(request.city) look sunny, around 24 degrees Celsius."
  }
}

@available(iOS 27.3, *)
enum ExampleHandlers {
  static func register() {
    GetForecast.handler = ExampleForecastHandler()
  }
}
#endif
