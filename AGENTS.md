# Workspace Rules for Mithai Wale

## Testing Guidelines
- **Do Not Write Tests**: Do not generate, add, or create unit tests, widget tests, integration tests, or test files unless explicitly requested by the user.
- **Do Not Run Tests**: Do not execute `flutter test` or test commands automatically unless explicitly requested by the user.
- Prioritize clean implementation, feature delivery, and design aesthetics according to user requests.

## Button Elevation & Affordance
- **All Buttons Must Have Elevation or Shadows**: Every button in the application (FilledButton, ElevatedButton, OutlinedButton, action buttons) must feature visible elevation or shadows so users immediately have the intuition that an element on screen is an interactive button.

## Internationalization (i18n) Guidelines
- **Support English and Gujarati**: The app supports English (`en`) and Gujarati (`gu`).
- **No Hardcoded Strings**: All user-facing titles, labels, buttons, dialogs, and messages must use `context.l10n.<key>`. Never hardcode raw user-facing strings in UI components.
- **Symmetric ARB Files**: Every string must exist in both `lib/l10n/app_en.arb` and `lib/l10n/app_gu.arb`. Use descriptive naming prefixes (`nav`, `action`, `status`) and ICU placeholders for dynamic parameters and plurals.

