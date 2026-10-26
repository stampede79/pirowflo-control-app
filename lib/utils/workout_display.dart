String workoutDisplayName(String name) {
  return name.replaceFirst(
    RegExp(r'^Rudern\s*[–—-]\s*', caseSensitive: false),
    '',
  );
}
