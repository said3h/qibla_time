import SwiftUI
import WidgetKit

private struct PrayerEntry: TimelineEntry {
    let date: Date
    let name: String
    let timeLabel: String
    let countdown: String
    let themeKey: String
}

private struct PrayerProvider: TimelineProvider {
    private let suite = UserDefaults(suiteName: "group.com.qiblatime.shared")

    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(date: Date(), name: "ASR", timeLabel: "17:14", countdown: "2h 10m", themeKey: "asr")
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let entry = loadEntry()
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func loadEntry() -> PrayerEntry {
        PrayerEntry(
            date: Date(),
            name: suite?.string(forKey: "next_prayer_name") ?? "FAJR",
            timeLabel: suite?.string(forKey: "next_prayer_time") ?? "--:--",
            countdown: suite?.string(forKey: "next_prayer_countdown") ?? "--",
            themeKey: suite?.string(forKey: "next_prayer_theme") ?? "fajr"
        )
    }
}

private struct PrayerWidgetView: View {
    let entry: PrayerEntry

    private var gradient: LinearGradient {
        switch entry.themeKey {
        case "fajr":
            return LinearGradient(colors: [Color(red: 0.08, green: 0.18, blue: 0.33), Color(red: 0.18, green: 0.40, blue: 0.73)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "dhuhr":
            return LinearGradient(colors: [Color(red: 0.09, green: 0.32, blue: 0.21), Color(red: 0.25, green: 0.62, blue: 0.31)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "asr":
            return LinearGradient(colors: [Color(red: 0.34, green: 0.21, blue: 0.10), Color(red: 0.74, green: 0.46, blue: 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "maghrib":
            return LinearGradient(colors: [Color(red: 0.33, green: 0.08, blue: 0.11), Color(red: 0.73, green: 0.25, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color(red: 0.05, green: 0.07, blue: 0.14), Color(red: 0.21, green: 0.18, blue: 0.36)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            gradient
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("QiblaTime")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Image(systemName: entry.themeKey == "isha" ? "moon.stars.fill" : "sparkles")
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Text(entry.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(entry.timeLabel)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.95))
                Text(entry.countdown)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding()
        }
    }
}

struct QiblaTimeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QiblaTimeWidget", provider: PrayerProvider()) { entry in
            PrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("Proxima oracion")
        .description("Muestra la siguiente oracion y su cuenta atras.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QiblaTimeLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QiblaTimeLockScreenWidget", provider: PrayerProvider()) { entry in
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.headline)
                Text(entry.countdown)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .configurationDisplayName("QiblaTime Lock Screen")
        .description("Cuenta atras de la proxima oracion.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}
