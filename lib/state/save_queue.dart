/// Runs saves one after another, so a slow earlier save can never finish
/// after (and overwrite) a newer one. A failed save doesn't block the next.
class SaveQueue {
  Future<void> _last = Future.value();

  Future<void> add(Future<void> Function() save) =>
      _last = _last.catchError((Object _) {}).then((_) => save());
}
