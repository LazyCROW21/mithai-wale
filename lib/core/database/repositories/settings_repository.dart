/// Abstract interface for reading and writing application settings.
///
/// Concrete implementations are provided per DB backend:
/// - [DriftSettingsRepository] — backed by drift (SQLite / WASM)
///
/// Consumers should depend on this interface, never on a concrete class,
/// ensuring that swapping the underlying storage has zero impact on
/// business logic or UI code.
library;

/// A single persisted setting entry.
class SettingEntry {
  const SettingEntry({required this.key, required this.value});

  /// Unique identifier for the setting (e.g. `theme_mode`).
  final String key;

  /// String-serialised value. Convert to the required type in the consumer.
  final String value;
}

/// Contract for persisting and retrieving application settings.
abstract interface class ISettingsRepository {
  /// Returns the value for [key], or `null` if not found.
  Future<String?> get(String key);

  /// Persists [value] under [key], inserting or replacing an existing entry.
  Future<void> set(String key, String value);

  /// Removes the entry for [key]. No-ops if the key does not exist.
  Future<void> remove(String key);

  /// Returns all stored settings as a list of [SettingEntry].
  Future<List<SettingEntry>> getAll();

  /// Emits the value for [key] whenever it changes.
  Stream<String?> watch(String key);

  /// Removes every stored setting. Use with caution.
  Future<void> clear();
}
