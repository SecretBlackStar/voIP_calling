class User {
  String uid;
  String email;
  String name;
  String phone;
  String? password;
  String role;
  int airtime;
  String callerId; 

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    this.password,
    required this.role,
    required this.airtime,
    required this.callerId, 
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'password': password,
      'role': role,
      'airtime': airtime,
      'callerId': callerId, // Add callerId to the map
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'],
      email: map['email'],
      name: map['name'],
      phone: map['phone'],
      password: map['password'],
      role: map['role'],
      airtime: map['airtime'],
      callerId: map['callerId'], // Retrieve callerId from map
    );
  }

  factory User.fromFirestore(Map<String, dynamic> data) {
    return User(
      uid: data['uid'],
      email: data['email'],
      name: data['name'],
      phone: data['phone'],
      password: data['password'],
      role: data['role'],
      airtime: data['airtime'],
      callerId: data['callerId'], // Retrieve callerId from Firestore data
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      password: json['password'],
      role: json['role'],
      airtime: json['airtime'],
      callerId: json['callerId'], // Retrieve callerId from JSON
    );
  }

  User copyWith(Map<String, dynamic> updates) {
    return User(
      uid: updates['uid'] ?? this.uid,
      email: updates['email'] ?? this.email,
      name: updates['name'] ?? this.name,
      phone: updates['phone'] ?? this.phone,
      password: updates['password'] ?? this.password,
      role: updates['role'] ?? this.role,
      airtime: updates['airtime'] ?? this.airtime,
      callerId: updates['callerId'] ?? this.callerId, // Allow callerId to be updated
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'airtime': airtime,
      'callerId': callerId, // Add callerId to the JSON output
    };
  }
}




class Contact {
  final String name;
  final String phoneNumber;
  final String owner;
  String? id;

  Contact({
    required this.name,
    required this.phoneNumber,
    required this.owner,
    this.id,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'owner': owner,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      owner: map['owner'],
      id: map['id'],
    );
  }

  factory Contact.fromFirestore(Map<String, dynamic> data) {
    return Contact(
      name: data['name'],
      phoneNumber: data['phoneNumber'],
      owner: data['owner'],
    )..id = data['id'];
  }
}


class AirtimeBundle {
  final String id; // Unique identifier for the airtime bundle
  final String name; // Name of the airtime bundle
  final double price; // Price of the airtime bundle
  final int time; // Duration or amount of airtime in minutes or units
  final String? description; // Description of the airtime bundle

  AirtimeBundle({
    required this.id,
    required this.name,
    required this.price,
    required this.time,
    this.description, // Description can be optional
  });

  // Method to convert AirtimeBundle to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'time': time,
      'description': description, // Include description in JSON
    };
  }

  // Factory method to create AirtimeBundle from JSON
  factory AirtimeBundle.fromJson(Map<String, dynamic> json) {
    return AirtimeBundle(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(), // Ensure price is double
      time: json['time'] as int,
      description: json['description'] as String?, // Parse description from JSON
    );
  }
}
