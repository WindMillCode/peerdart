bool validateId(String id) {
  // Allow empty ids
  return id.isEmpty || RegExp(r'^[A-Za-z0-9]+(?:[ _-][A-Za-z0-9]+)*$').hasMatch(id);
}
