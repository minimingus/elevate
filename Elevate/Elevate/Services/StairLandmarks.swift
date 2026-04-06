import Foundation

// Extracted from SessionSummaryView so both SessionSummaryView and SessionDetailView can use it.

struct Landmark {
    let name: String
    let emoji: String
    let steps: Int
}

let stairLandmarks: [Landmark] = [
    Landmark(name: "Leaning Tower of Pisa",  emoji: "🗼", steps: 294),
    Landmark(name: "Statue of Liberty",       emoji: "🗽", steps: 354),
    Landmark(name: "Big Ben",                 emoji: "🕰️", steps: 334),
    Landmark(name: "Sydney Opera House",      emoji: "🎭", steps: 200),
    Landmark(name: "Eiffel Tower",            emoji: "🗼", steps: 1665),
    Landmark(name: "Empire State Building",   emoji: "🏙️", steps: 1860),
    Landmark(name: "CN Tower",                emoji: "📡", steps: 1776),
    Landmark(name: "Burj Khalifa",            emoji: "🏗️", steps: 2909),
]

func landmarkComparison(for steps: Int) -> String? {
    guard steps > 0 else { return nil }
    let best = stairLandmarks
        .filter { steps >= $0.steps }
        .max(by: { $0.steps < $1.steps })
    guard let best else {
        if let closest = stairLandmarks.min(by: { $0.steps < $1.steps }) {
            let pct = Int(Double(steps) / Double(closest.steps) * 100)
            return "\(pct)% of the way up \(closest.name) \(closest.emoji)"
        }
        return nil
    }
    let times = steps / best.steps
    let remainder = steps % best.steps
    let fraction = Double(remainder) / Double(best.steps)
    if times == 1 && fraction < 0.15 {
        return "That's like climbing \(best.name)! \(best.emoji)"
    } else if times >= 2 {
        return "Like climbing \(best.name) \(times)× \(best.emoji)"
    } else {
        let pct = Int((Double(times) + fraction) * 100)
        return "\(pct)% of \(best.name) \(best.emoji)"
    }
}
