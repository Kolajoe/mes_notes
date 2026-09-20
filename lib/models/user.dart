class User {
  final int? id;
  final String fullName;
  final String phone;
  final String username;
  final String password;

  User({
    this.id,
    required this.fullName,
    required this.phone,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'username': username,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
    );
  }
}
