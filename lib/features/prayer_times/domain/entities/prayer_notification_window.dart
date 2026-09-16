// Reserve space below iOS's 64 pending notifications for hourly hadiths,
// daily inspiration, Ramadan reminders and the weekly summary.
const prayerNotificationDays = 6;
const prayerNotificationsPerDay = 5;

Iterable<int> get prayerNotificationIds =>
    Iterable<int>.generate(prayerNotificationDays * prayerNotificationsPerDay);
