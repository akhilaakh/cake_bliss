class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? imageUrl;
  final String? password;

  UserModel(
      {required this.id,
      required this.name,
      required this.email,
      required this.phone,
      required this.address,
      this.imageUrl,
      required this.password});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'imageUrl': imageUrl,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      imageUrl: map['imageUrl'],
      password: map['password'] ?? '',
    );
  }

  // Add the copyWith method
  UserModel copyWith(
      {String? id,
      String? name,
      String? email,
      String? phone,
      String? address,
      String? imageUrl,
      String? password}) {
    return UserModel(
      password: password ?? this.password,
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
