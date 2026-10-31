# analytics

Steady's usage events (`AnalyticsEvent`) and the `analyticsProvider` features
record them through. The provider does nothing unless the app overrides it,
which `app/` does only on TestFlight builds (`app/lib/usage_sharing.dart`).
Every event and every property Steady can send is in
`lib/src/analytics_event.dart`.
