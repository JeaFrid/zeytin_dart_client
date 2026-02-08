class ZeytinValidators {
  static bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
