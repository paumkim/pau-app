# Pau App — Autonomous Evolution Backlog

## 🔴 Critical (system integrity)

- [ ] Secure HF API token (move to env/config, never in source)
- [ ] Add Hive database — replace SharedPreferences for chat/translation history
- [ ] Wrap all SharedPreferences reads in error boundaries (they throw on corrupted data)
- [ ] Add compute isolates for EPUB parsing (blocks UI thread)
- [ ] Fix: "Pau Zomi (Soon)" model selection crashes chat — guard against non-functional models

## 🟠 High (core UX broken or absent)

- [ ] Make Ollama endpoint configurable (Settings > server IP) instead of hardcoded 192.168.12.189
- [ ] Add `connectivity_plus` for offline awareness — disable chat/translate when offline
- [ ] Translation: wire actual working pipeline (cloud endpoint doesn't exist yet). Fallback to Ollama-based translation
- [ ] Add retry logic with exponential backoff to ChatService and TranslationService
- [ ] Add proper error UI: ErrorWidget + retry button pattern for every screen
- [ ] Add loading skeletons to all screens (not just spinners)
- [ ] Fix haptic toggle in Settings — currently hardcoded to `true`, never reads SharedPreferences
- [ ] Chat: add connection status indicator (green dot / red dot for Ollama reachability)
- [ ] Library: "Recent Activity" items are raw JSON keys — fix deserialization
- [ ] Home screen quick cards: all three navigate to "Coming soon" placeholder — wire to TranslateScreen with preset languages

## 🟡 Medium (architecture & UX debt)

- [ ] Reader: add bookmark persistence + resume reading
- [ ] Reader: add font size / line spacing controls
- [ ] Reader: add text selection + highlight + note capability
- [ ] Reader: add reading progress bar
- [ ] Reader: add table of contents side drawer
- [ ] Onboarding: first-launch flow explaining Pau, language selection, plugin intro
- [ ] Plugin system: make plugins loadable from external config/JSON (not hardcoded in plugin.dart)
- [ ] Plugin system: add plugin store concept (downloadable plugins from a repo)
- [ ] State management: migrate from setState to a proper solution (Riverpod)
- [ ] Routing: add go_router with named routes + deep linking + route guards
- [ ] History: add search/filter, bulk delete, export to text
- [ ] History: store structured data (not raw JSON blobs)
- [ ] Chat: add streaming response (currently waits for full response, bad UX)
- [ ] Settings: reorganize — separate "working" features from "coming soon"
- [ ] Settings: add "Reset to Defaults" button
- [ ] Add i18n/localization infrastructure (at minimum Zomi + English)
- [ ] Add unit tests for all services
- [ ] Add widget tests for all screens
- [ ] EPUB parsing: add progress indicator (currently UI hangs with no feedback)

## 🔵 Low (polish & v1.1)

- [ ] Accessibility: add Semantics widgets throughout
- [ ] Accessibility: support font scaling (MediaQuery.textScaleFactor)
- [ ] Accessibility: ensure all touch targets are >= 48dp
- [ ] Crash reporting: add Sentry or similar
- [ ] Logging: add structured logging
- [ ] Brand consistency audit: ensure #1877F2 and #D4A843 are used everywhere
- [ ] Splash screen: use brand colors (currently white)
- [ ] Add "What's New" dialog after app update
- [ ] Add privacy-respecting feature usage analytics
- [ ] Add share functionality for translations
- [ ] Add Android home screen widget (quick translate)
- [ ] Add notification scheduling for daily verse
- [ ] Implement speech-to-text (package already declared, never used)
- [ ] Implement text-to-speech (package already declared, never used)
- [ ] Add keyboard dismissal on tap-outside for all screens

## 🟣 Future / Deep

- [ ] Build community feedback loop: thumbs up/down on translations → feedback to training pipeline
- [ ] Add Pau Cin Hau script support (Unicode U+11D00-U+11D5F)
- [ ] Add Zomi keyboard / input method
- [ ] Training progress indicator in app (show Phase 1 / Phase 2 status)
- [ ] Allow switching to fine-tuned model checkpoint from within app
- [ ] Add trending Zomi phrases / community-contributed content section
- [ ] iOS version (blocked on Mac)
- [ ] Google Play publishing (API 35 build-tools issue)
- [ ] Model quantization pipeline → 4-bit GGUF for offline use
