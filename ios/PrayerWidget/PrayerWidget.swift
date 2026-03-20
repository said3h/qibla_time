// ios/PrayerWidget/PrayerWidget.swift
//
// Widget de pantalla de inicio para iOS usando WidgetKit.
// Lee los datos que WidgetSyncService guarda via UserDefaults
// con el App Group compartido entre la app y la extensión.

import WidgetKit
import SwiftUI

// ── Modelo de datos ──────────────────────────────────────────

struct PrayerEntry: TimelineEntry {
    let date: Date
    let prayerName: String
    let prayerTime: String
    let countdown: String
}

// ── Provider: decide cuándo y qué mostrar ────────────────────

struct PrayerProvider: TimelineProvider {

    // App Group ID — debe coincidir con el configurado en Xcode
    // y con el que uses en WidgetSyncService de Flutter
    private let appGroupId = "group.com.qiblatime.qibla_time"

    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(
            date: Date(),
            prayerName: "Asr",
            prayerTime: "17:14",
            countdown: "2h 33min"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let entry = readEntry()

        // Actualizar cada 30 minutos
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // Leer datos guardados por Flutter (WidgetSyncService)
    private func readEntry() -> PrayerEntry {
        let defaults = UserDefaults(suiteName: appGroupId)

        let prayerName = defaults?.string(forKey: "next_prayer_name")    ?? "—"
        let prayerTime = defaults?.string(forKey: "next_prayer_time")    ?? "—"
        let countdown  = defaults?.string(forKey: "next_prayer_countdown") ?? "—"

        return PrayerEntry(
            date: Date(),
            prayerName: prayerName,
            prayerTime: prayerTime,
            countdown: countdown
        )
    }
}

// ── Vista del widget ─────────────────────────────────────────

struct PrayerWidgetView: View {
    var entry: PrayerEntry

    // Colores QiblaTime
    let bgColor     = Color(red: 0.051, green: 0.067, blue: 0.090) // #0D1117
    let surfaceColor= Color(red: 0.086, green: 0.106, blue: 0.133) // #161B22
    let goldColor   = Color(red: 0.831, green: 0.686, blue: 0.216) // #D4AF37
    let textColor   = Color(red: 0.941, green: 0.965, blue: 0.988) // #F0F6FC
    let mutedColor  = Color(red: 0.545, green: 0.580, blue: 0.620) // #8B949E

    var body: some View {
        ZStack {
            // Fondo
            RoundedRectangle(cornerRadius: 16)
                .fill(surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {

                // Etiqueta
                Text("PRÓXIMA ORACIÓN")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(mutedColor)
                    .kerning(1.2)

                // Nombre de la oración
                Text(entry.prayerName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(goldColor)

                // Hora
                Text(entry.prayerTime)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textColor)

                Divider()
                    .background(Color.white.opacity(0.12))
                    .padding(.vertical, 4)

                // Cuenta atrás
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(mutedColor)
                    Text("En \(entry.countdown)")
                        .font(.system(size: 12))
                        .foregroundColor(mutedColor)
                }

                Spacer()

                // Botón abrir app
                HStack {
                    Spacer()
                    Text("Abrir →")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(goldColor)
                }
            }
            .padding(14)
        }
    }
}

// ── Widget principal ─────────────────────────────────────────

@main
struct PrayerWidget: Widget {
    let kind: String = "PrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            PrayerWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("QiblaTime")
        .description("Próxima oración y tiempo restante")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// ── Preview ──────────────────────────────────────────────────

#Preview(as: .systemSmall) {
    PrayerWidget()
} timeline: {
    PrayerEntry(
        date: .now,
        prayerName: "Asr · عصر",
        prayerTime: "17:14",
        countdown: "2h 33min"
    )
}
