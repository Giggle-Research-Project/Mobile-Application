class StringUtils {
  final String value;

  StringUtils(this.value);

  String capitalize() {
    return value.isEmpty
        ? value
        : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }
}
