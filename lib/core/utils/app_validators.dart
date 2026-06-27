class AppValidators {
  static String? Function(String?) required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  static String? Function(String?) price({
    String empty = 'Please enter a price',
    String invalid = 'Please enter a valid number',
    String negative = 'Price cannot be negative',
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return empty;
      if (double.tryParse(value) == null) return invalid;
      if (double.parse(value) < 0) return negative;
      return null;
    };
  }
}
