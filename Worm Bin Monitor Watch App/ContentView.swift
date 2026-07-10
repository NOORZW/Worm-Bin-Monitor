import SwiftUI

struct ContentView: View {
    @State private var tempC: Double = 0
    @State private var tempF: Double = 0
    @State private var humidity: Double = 0
    @State private var status = "Connecting..."
    @State private var isLive = false
    @State private var useFahrenheit = true
    @State private var timer: Timer?

    let picoIP = "10.0.0.75"
    let tmin = 15.0; let tmax = 25.0
    let hmin = 70.0; let hmax = 90.0

    var tempColor: Color {
        if tempC < tmin || tempC > tmax { return .red }
        if tempC < tmin + 2 || tempC > tmax - 2 { return .yellow }
        return .green
    }
    var humColor: Color {
        if humidity < hmin || humidity > hmax { return .red }
        if humidity < hmin + 5 || humidity > hmax - 5 { return .yellow }
        return .green
    }
    var tempDisplay: String {
        useFahrenheit ? String(format: "%.1f°F", tempF) : String(format: "%.1f°C", tempC)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    Text("🪱 Worm Bin")
                        .font(.headline)
                    Spacer()
                    Circle()
                        .fill(isLive ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                }

                if !isLive {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                HStack(spacing: 8) {
                    VStack(spacing: 4) {
                        Text("TEMP")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(isLive ? tempDisplay : "--")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(tempColor)
                        Text(statusLabel(tempC, min: tmin, max: tmax))
                            .font(.system(size: 10))
                            .foregroundColor(tempColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)

                    VStack(spacing: 4) {
                        Text("HUMIDITY")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(isLive ? String(format: "%.1f%%", humidity) : "--")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(humColor)
                        Text(statusLabel(humidity, min: hmin, max: hmax))
                            .font(.system(size: 10))
                            .foregroundColor(humColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
                }

                if isLive && (tempC < tmin || tempC > tmax || humidity < hmin || humidity > hmax) {
                    Text("⚠️ Check worm bin!")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(6)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(8)
                }

                Button(action: { useFahrenheit.toggle() }) {
                    Text(useFahrenheit ? "Switch to °C" : "Switch to °F")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
        .onAppear { startFetching() }
        .onDisappear { timer?.invalidate() }
    }

    func statusLabel(_ v: Double, min: Double, max: Double) -> String {
        if v < min { return "Too low" }
        if v > max { return "Too high" }
        if v < min + 2 || v > max - 2 { return "Borderline" }
        return "Perfect ✓"
    }

    func startFetching() {
        fetchData()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            fetchData()
        }
    }

    func fetchData() {
        guard let url = URL(string: "http://\(picoIP)/data") else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Double],
                   let tc = json["temp_c"],
                   let tf = json["temp_f"],
                   let h = json["humidity"] {
                    tempC = tc
                    tempF = tf
                    humidity = h
                    isLive = true
                    status = "Live"
                } else {
                    isLive = false
                    status = "Reconnecting..."
                }
            }
        }.resume()
    }
}
