import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolServicesService {
  SchoolServicesService(this._db);
  final FirebaseFirestore _db;

  Stream<List<Map<String, dynamic>>> watchSocialLinks() => _db
      .collection('schoolSocialLinks')
      .where('isPublished', isEqualTo: true)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              <String, dynamic>{
                'id': doc.id,
                ...doc.data(),
              })
          .toList());

  Stream<List<Map<String, dynamic>>> watchDressItems() => _db
      .collection('dressShopItems')
      .where('isPublished', isEqualTo: true)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              <String, dynamic>{
                'id': doc.id,
                ...doc.data(),
              })
          .toList());

  Future<void> submitFeedback({
    required String uid,
    required String name,
    required String message,
    required int rating,
    String category = 'General',
  }) async {
    await _db.collection('feedback').add(<String, dynamic>{
      'uid': uid,
      'name': name,
      'message': message,
      'rating': rating,
      'category': category,
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> placeDressOrder({
    required String uid,
    required String name,
    required String itemId,
    required String itemName,
    required String size,
    required int quantity,
    required double unitPrice,
    String? classSection,
    String? note,
  }) async {
    await _db.collection('dressShopOrders').add(<String, dynamic>{
      'uid': uid,
      'name': name,
      'itemId': itemId,
      'itemName': itemName,
      'size': size,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': unitPrice * quantity,
      'classSection': classSection,
      'note': note ?? '',
      'status': 'requested',
      'paymentStatus': 'not_required_yet',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static const List<Map<String, dynamic>> demoSocialLinks =
      <Map<String, dynamic>>[
    <String, dynamic>{
      'title': 'School Website',
      'platform': 'website',
      'url': ''
    },
    <String, dynamic>{'title': 'Instagram', 'platform': 'instagram', 'url': ''},
    <String, dynamic>{'title': 'Facebook', 'platform': 'facebook', 'url': ''},
    <String, dynamic>{'title': 'YouTube', 'platform': 'youtube', 'url': ''},
  ];

  static const List<Map<String, dynamic>> demoDressItems =
      <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'demo-summer-shirt',
      'name': 'School Summer Shirt',
      'description': 'Official daily-wear school shirt.',
      'price': 650,
      'sizes': <String>['24', '26', '28', '30', '32', '34', '36'],
      'stock': 50,
    },
    <String, dynamic>{
      'id': 'demo-trouser',
      'name': 'School Trousers',
      'description': 'Official school trousers for regular uniform.',
      'price': 850,
      'sizes': <String>['26', '28', '30', '32', '34', '36'],
      'stock': 50,
    },
    <String, dynamic>{
      'id': 'demo-tie-belt',
      'name': 'Tie and Belt Set',
      'description': 'School tie with matching belt.',
      'price': 300,
      'sizes': <String>['Standard'],
      'stock': 50,
    },
  ];
}
