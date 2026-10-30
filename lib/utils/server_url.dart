String normalizeServerUrl(String server) {
  final trimmed = server.trim();

  if (trimmed.endsWith('/')) {
    return trimmed.substring(0, trimmed.length - 1);
  }

  return trimmed;
}
