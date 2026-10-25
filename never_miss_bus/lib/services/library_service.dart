import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/result.dart';

class LibraryService {
  LibraryService(this._db);
  final FirebaseFirestore _db;

  Stream<List<Map<String, dynamic>>> watchPublished() => _db
      .collection('libraryBooks')
      .where('isPublished', isEqualTo: true)
      .snapshots()
      .map(_rowsAndSort)
      .map(_withDemoBooks);

  Stream<List<Map<String, dynamic>>> watchAll() =>
      _db.collection('libraryBooks').snapshots().map(_rowsAndSort);

  List<Map<String, dynamic>> _rows(
          QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              <String, dynamic>{
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

  List<Map<String, dynamic>> _rowsAndSort(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    final List<Map<String, dynamic>> rows = _rows(snapshot);
    rows.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
        '${a['title'] ?? ''}'.toLowerCase().compareTo(
              '${b['title'] ?? ''}'.toLowerCase(),
            ));
    return rows;
  }

  List<Map<String, dynamic>> _withDemoBooks(
      List<Map<String, dynamic>> firestoreBooks) {
    final Set<String> titles = firestoreBooks
        .map((Map<String, dynamic> book) =>
            '${book['title'] ?? ''}'.trim().toLowerCase())
        .toSet();
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[
      ...firestoreBooks,
      ...demoBooks.where((Map<String, dynamic> book) =>
          !titles.contains('${book['title']}'.trim().toLowerCase())),
    ];
    all.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
        '${a['title']}'.toLowerCase().compareTo('${b['title']}'.toLowerCase()));
    return all;
  }

  /// Ten source-linked public-domain demo entries. They are metadata only;
  /// the app does not copy or store these books in Firebase Storage.
  static const List<Map<String, dynamic>> demoBooks = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'demo-alice',
      'title': 'Alice’s Adventures in Wonderland',
      'titleHi': 'एलिस एडवेंचर्स इन वंडरलैंड',
      'author': 'Lewis Carroll',
      'category': 'Classic Fiction',
      'language': 'English',
      'description':
          'A curious girl follows a white rabbit into a world of imagination and discovery.',
      'descriptionHi':
          'एक जिज्ञासु लड़की सफेद खरगोश के पीछे कल्पना और खोज की अद्भुत दुनिया में पहुंचती है।',
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/11',
      'audioUrl': 'https://librivox.org/search/?q=alice&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/11',
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-sherlock',
      'title': 'The Adventures of Sherlock Holmes',
      'titleHi': 'द एडवेंचर्स ऑफ शरलॉक होम्स',
      'author': 'Arthur Conan Doyle',
      'category': 'Mystery',
      'language': 'English',
      'description':
          'Brilliant detective stories that develop observation, logic and problem-solving skills.',
      'descriptionHi':
          'अवलोकन, तर्क और समस्या-समाधान कौशल विकसित करने वाली जासूसी कहानियां।',
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/1661',
      'audioUrl':
          'https://librivox.org/search/?q=sherlock+holmes&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/1661',
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-pride',
      'title': 'Pride and Prejudice',
      'titleHi': 'प्राइड एंड प्रेजुडिस',
      'author': 'Jane Austen',
      'category': 'Classic Fiction',
      'language': 'English',
      'description':
          'A classic story about relationships, first impressions and social understanding.',
      'descriptionHi':
          'रिश्तों, पहली मुलाकात और सामाजिक समझ पर आधारित प्रसिद्ध क्लासिक कहानी।',
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/1342',
      'audioUrl':
          'https://librivox.org/search/?q=pride+prejudice&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/1342',
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-frankenstein',
      'title': 'Frankenstein',
      'titleHi': 'फ्रैंकनस्टाइन',
      'author': 'Mary Shelley',
      'category': 'Science Fiction',
      'language': 'English',
      'description':
          'A thoughtful novel about scientific ambition, responsibility and human choices.',
      'descriptionHi':
          'वैज्ञानिक महत्वाकांक्षा, जिम्मेदारी और मानवीय फैसलों पर विचार करने वाला उपन्यास।',
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/84',
      'audioUrl':
          'https://librivox.org/search/?q=frankenstein&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/84',
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-moby',
      'title': 'Moby-Dick',
      'titleHi': 'मोबी-डिक',
      'author': 'Herman Melville',
      'category': 'Adventure',
      'language': 'English',
      'description':
          'A sea adventure that explores courage, leadership, nature and determination.',
      'descriptionHi':
          'साहस, नेतृत्व, प्रकृति और दृढ़ संकल्प को समझने वाला समुद्री रोमांच।',
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/2701',
      'audioUrl':
          'https://librivox.org/search/?q=moby+dick&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/2701',
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-dracula',
      'title': 'Dracula',
      'titleHi': 'ड्रैकुला',
      'author': 'Bram Stoker',
      'category': 'Gothic Fiction',
      'language': 'English',
      'description':
          'A famous suspense novel that builds atmosphere through letters, diaries and reports.',
      'descriptionHi':
          'पत्रों, डायरी और रिपोर्ट के माध्यम से suspense बनाने वाला प्रसिद्ध उपन्यास।',
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/345',
      'audioUrl': 'https://librivox.org/search/?q=dracula&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/345',
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-war-worlds',
      'title': 'The War of the Worlds',
      'titleHi': 'द वॉर ऑफ द वर्ल्ड्स',
      'author': 'H. G. Wells',
      'category': 'Science Fiction',
      'language': 'English',
      'description':
          'A classic science-fiction story that invites readers to think about technology and society.',
      'descriptionHi':
          'तकनीक और समाज पर सोचने के लिए प्रेरित करने वाली क्लासिक विज्ञान-कथा।',
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/36',
      'audioUrl':
          'https://librivox.org/search/?q=war+of+the+worlds&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/36',
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-tale-two-cities',
      'title': 'A Tale of Two Cities',
      'titleHi': 'ए टेल ऑफ टू सिटीज',
      'author': 'Charles Dickens',
      'category': 'History & Society',
      'language': 'English',
      'description':
          'A powerful historical story about sacrifice, justice and transformation.',
      'descriptionHi':
          'त्याग, न्याय और बदलाव पर आधारित प्रभावशाली ऐतिहासिक कहानी।',
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/98',
      'audioUrl':
          'https://librivox.org/search/?q=tale+of+two+cities&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/98',
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-metamorphosis',
      'title': 'The Metamorphosis',
      'titleHi': 'द मेटामॉर्फोसिस',
      'author': 'Franz Kafka',
      'category': 'Literature',
      'language': 'English',
      'description':
          'A short literary work that encourages reflection on identity, family and belonging.',
      'descriptionHi':
          'पहचान, परिवार और अपनापन पर विचार करने वाली छोटी साहित्यिक रचना।',
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/5200',
      'audioUrl':
          'https://librivox.org/search/?q=metamorphosis&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/5200',
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-beowulf',
      'title': 'Beowulf',
      'titleHi': 'बियोवुल्फ',
      'author': 'Anonymous',
      'category': 'Epic Literature',
      'language': 'English',
      'description':
          'An ancient epic about bravery, loyalty and the responsibility of a leader.',
      'descriptionHi':
          'बहादुरी, निष्ठा और एक नेता की जिम्मेदारी पर आधारित प्राचीन महाकाव्य।',
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/16328',
      'audioUrl': 'https://librivox.org/search/?q=beowulf&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/16328',
      'isPublished': true,
    },
  ];

  Future<Result<void>> create({
    required String title,
    required String titleHi,
    required String author,
    required String category,
    required String language,
    required String description,
    required String descriptionHi,
    required String coverUrl,
    required String pdfUrl,
    required String audioUrl,
    required String licenseType,
    required String licenseUrl,
    required String sourceUrl,
    required bool isPublished,
    required String createdBy,
  }) async {
    try {
      await _db.collection('libraryBooks').add(<String, dynamic>{
        'title': title.trim(),
        'titleHi': titleHi.trim(),
        'author': author.trim(),
        'category': category.trim(),
        'language': language.trim(),
        'description': description.trim(),
        'descriptionHi': descriptionHi.trim(),
        'coverUrl': coverUrl.trim(),
        'pdfUrl': pdfUrl.trim(),
        'audioUrl': audioUrl.trim(),
        'licenseType': licenseType.trim(),
        'licenseUrl': licenseUrl.trim(),
        'sourceUrl': sourceUrl.trim(),
        'isPublished': isPublished,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(AppFailure(e.code, 'Library save failed: ${e.message}'));
    } catch (e) {
      return Err<void>(AppFailure('library-save', 'Library save failed: $e'));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      await _db.collection('libraryBooks').doc(id).delete();
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
          AppFailure(e.code, 'Library delete failed: ${e.message}'));
    } catch (e) {
      return Err<void>(
          AppFailure('library-delete', 'Library delete failed: $e'));
    }
  }
}
