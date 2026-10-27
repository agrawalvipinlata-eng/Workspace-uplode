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

  /// Source-linked catalogue entries. They are metadata and source references;
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
      'pdfUrl': 'https://www.gutenberg.org/ebooks/11',
      'audioUrl': 'https://librivox.org/search/?q=alice&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/11',
      'readerUrl': "https://www.gutenberg.org/cache/epub/11/pg11.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/11/pg11.cover.medium.jpg",
      'audioUrls': <String>[],
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
      'pdfUrl': 'https://www.gutenberg.org/ebooks/1661',
      'audioUrl':
          'https://librivox.org/search/?q=sherlock+holmes&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/1661',
      'readerUrl': "https://www.gutenberg.org/cache/epub/1661/pg1661.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/1661/pg1661.cover.medium.jpg",
      'audioUrls': <String>[],
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
      'pdfUrl': 'https://www.gutenberg.org/ebooks/1342',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/1342',
      'readerUrl': "https://www.gutenberg.org/cache/epub/1342/pg1342.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_01-03_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_04-05_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_06_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_07_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_08_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_09_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_10-11_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_12-13_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_14-15_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_16-17_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_18-19_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_20_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_21-22_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_23-25_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_26_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_27_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_28-29_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_30_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_31_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_32-33_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_34-35_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_36-37_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_38-39_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_40-41_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_42-43_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_44-45_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_46_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_47-48_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_49_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_50-51_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_52-53f_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_54_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_55_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_56-57_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_58_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_59_austen_64kb.mp3",
        "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_60-61_austen_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/pride_and_prejudice_librivox/prideandprejudice_01-03_austen_64kb.mp3",
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
      'coverUrl': 'https://covers.openlibrary.org/b/title/Frankenstein-M.jpg',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/84',
      'audioUrl':
          'https://librivox.org/search/?q=frankenstein&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/84',
      'readerUrl': "",
      'audioUrls': <String>[],
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
      'coverUrl': 'https://covers.openlibrary.org/b/title/Moby-Dick-M.jpg',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/2701',
      'audioUrl':
          'https://librivox.org/search/?q=moby+dick&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/2701',
      'readerUrl': "",
      'audioUrls': <String>[],
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
      'pdfUrl': 'https://www.gutenberg.org/ebooks/345',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/345',
      'readerUrl': "https://www.gutenberg.org/cache/epub/345/pg345.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/345/pg345.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/dracula_librivox/dracula_01_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_02_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_03_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_04_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_05_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_06_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_07_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_08_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_09_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_10_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_11_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_12_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_13_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_14_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_15_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_16_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_17_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_18_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_19_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_20_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_21_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_22_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_23_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_24_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_25_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_26_stoker_64kb.mp3",
        "https://www.archive.org/download/dracula_librivox/dracula_27_stoker_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/dracula_librivox/dracula_01_stoker_64kb.mp3",
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
      'pdfUrl': 'https://www.gutenberg.org/ebooks/36',
      'audioUrl':
          'https://librivox.org/search/?q=war+of+the+worlds&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/36',
      'readerUrl': "https://www.gutenberg.org/cache/epub/36/pg36.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/36/pg36.cover.medium.jpg",
      'audioUrls': <String>[],
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
      'pdfUrl': 'https://www.gutenberg.org/ebooks/98',
      'audioUrl':
          'https://librivox.org/search/?q=tale+of+two+cities&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/98',
      'readerUrl': "https://www.gutenberg.org/cache/epub/98/pg98.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/98/pg98.cover.medium.jpg",
      'audioUrls': <String>[],
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
      'pdfUrl': 'https://www.gutenberg.org/ebooks/5200',
      'audioUrl':
          'https://librivox.org/search/?q=metamorphosis&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/5200',
      'readerUrl': "https://www.gutenberg.org/cache/epub/5200/pg5200.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/5200/pg5200.cover.medium.jpg",
      'audioUrls': <String>[],
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
      'pdfUrl': 'https://www.gutenberg.org/ebooks/16328',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/16328',
      'readerUrl': "https://www.gutenberg.org/cache/epub/981/pg981.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/981/pg981.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/beowulf/beowulf_01_gummere_64kb.mp3",
        "https://www.archive.org/download/beowulf/beowulf_02_gummere_64kb.mp3",
        "https://www.archive.org/download/beowulf/beowulf_03_gummere_64kb.mp3",
        "https://www.archive.org/download/beowulf/beowulf_04_gummere_64kb.mp3",
        "https://www.archive.org/download/beowulf/beowulf_05_gummere_64kb.mp3",
        "https://www.archive.org/download/beowulf/beowulf_06_gummere_64kb.mp3",
        "https://www.archive.org/download/beowulf/beowulf_07_gummere_64kb.mp3",
        "https://www.archive.org/download/beowulf/beowulf_08_gummere_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/beowulf/beowulf_01_gummere_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-01',
      'title': "Through the Looking-Glass",
      'titleHi': "Through the Looking-Glass",
      'author': "Lewis Carroll",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Through+the+Looking-Glass',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Through+the+Looking-Glass',
      'readerUrl': "https://www.gutenberg.org/cache/epub/12/pg12.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/12/pg12.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/looking-glass_librivox/lookingglass_01_carroll_64kb.mp3",
        "https://www.archive.org/download/looking-glass_librivox/lookingglass_02_carroll_64kb.mp3",
        "https://www.archive.org/download/looking-glass_librivox/lookingglass_03_carroll_64kb.mp3",
        "https://www.archive.org/download/looking-glass_librivox/lookingglass_04_carroll_64kb.mp3",
        "https://www.archive.org/download/looking-glass_librivox/lookingglass_05_carroll_64kb.mp3",
        "https://www.archive.org/download/looking-glass_librivox/lookingglass_06_carroll_64kb.mp3",
        "https://www.archive.org/download/looking-glass_librivox/lookingglass_07_carroll_64kb.mp3",
        "https://www.archive.org/download/looking-glass_librivox/lookingglass_08_carroll_64kb.mp3",
        "https://www.archive.org/download/looking-glass_librivox/lookingglass_09_carroll_64kb.mp3",
        "https://www.archive.org/download/looking-glass_librivox/lookingglass_10_carroll_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/looking-glass_librivox/lookingglass_01_carroll_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-02',
      'title': "Peter Pan",
      'titleHi': "Peter Pan",
      'author': "J. M. Barrie",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Peter+Pan',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Peter+Pan',
      'readerUrl': "https://www.gutenberg.org/cache/epub/16/pg16.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/16/pg16.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_01_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_02_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_03_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_04_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_05_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_06_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_07_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_08_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_09_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_10_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_11_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_12_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_13_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_14_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_15_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_16_barrie_64kb.mp3",
        "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_17_barrie_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/peter_pan_0707_librivox/peterpan_01_barrie_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-03',
      'title': "Paradise Lost",
      'titleHi': "Paradise Lost",
      'author': "John Milton",
      'category': "Epic Literature",
      'language': 'English',
      'description':
          "A public-domain epic literature selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Epic Literature पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Paradise+Lost',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Paradise+Lost',
      'readerUrl': "https://www.gutenberg.org/cache/epub/20/pg20.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/20/pg20.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_01_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_02_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_03_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_04_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_05_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_06_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_07_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_08_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_09_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_10_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_11_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_12_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_13_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_14_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_15_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_16_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_17_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_18_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_19_milton_64kb.mp3",
        "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_20_milton_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/paradise_lost_08083_librivox/paradiselost_01_milton_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-04',
      'title': "The Time Machine",
      'titleHi': "The Time Machine",
      'author': "H. G. Wells",
      'category': "Science Fiction",
      'language': 'English',
      'description':
          "A public-domain science fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Science Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Time+Machine',
      'audioUrl':
          'https://librivox.org/search/?q=The+Time+Machine&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Time+Machine',
      'readerUrl': "https://www.gutenberg.org/cache/epub/35/pg35.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/35/pg35.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-05',
      'title': "The Strange Case of Dr. Jekyll and Mr. Hyde",
      'titleHi': "The Strange Case of Dr. Jekyll and Mr. Hyde",
      'author': "Robert Louis Stevenson",
      'category': "Mystery",
      'language': 'English',
      'description':
          "A public-domain mystery selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Mystery पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Strange+Case+of+Dr.+Jekyll+and+Mr.+Hyde',
      'audioUrl':
          'https://librivox.org/search/?q=The+Strange+Case+of+Dr.+Jekyll+and+Mr.+Hyde&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Strange+Case+of+Dr.+Jekyll+and+Mr.+Hyde',
      'readerUrl': "https://www.gutenberg.org/cache/epub/42/pg42.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/42/pg42.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-06',
      'title': "Anne of Green Gables",
      'titleHi': "Anne of Green Gables",
      'author': "L. M. Montgomery",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Anne+of+Green+Gables',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Anne+of+Green+Gables',
      'readerUrl': "https://www.gutenberg.org/cache/epub/45/pg45.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/45/pg45.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_01_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_02_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_03_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_04_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_05_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_06_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_07_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_08_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_09_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_10_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_11_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_12_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_13_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_14_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_15_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_16_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_17_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_18_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_19_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_20_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_21_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_22_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_23_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_24_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_25_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_26_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_27_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_28_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_29_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_30_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_31_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_32_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_33_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_34_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_35_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_36_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_37_montgomery_64kb.mp3",
        "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_38_montgomery_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/anne_of_green_gables_librivox/anne_of_green_gables_01_montgomery_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-07',
      'title': "A Christmas Carol",
      'titleHi': "A Christmas Carol",
      'author': "Charles Dickens",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=A+Christmas+Carol',
      'audioUrl':
          'https://librivox.org/search/?q=A+Christmas+Carol&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=A+Christmas+Carol',
      'readerUrl': "https://www.gutenberg.org/cache/epub/19337/pg19337.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/19337/pg19337.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-08',
      'title': "The Wonderful Wizard of Oz",
      'titleHi': "The Wonderful Wizard of Oz",
      'author': "L. Frank Baum",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wonderful+Wizard+of+Oz',
      'audioUrl':
          'https://librivox.org/search/?q=The+Wonderful+Wizard+of+Oz&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wonderful+Wizard+of+Oz',
      'readerUrl': "https://www.gutenberg.org/cache/epub/55/pg55.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/55/pg55.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-09',
      'title': "The Complete Works of William Shakespeare",
      'titleHi': "The Complete Works of William Shakespeare",
      'author': "William Shakespeare",
      'category': "Literature",
      'language': 'English',
      'description':
          "A public-domain literature selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Literature पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Complete+Works+of+William+Shakespeare',
      'audioUrl':
          'https://librivox.org/search/?q=The+Complete+Works+of+William+Shakespeare&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Complete+Works+of+William+Shakespeare',
      'readerUrl': "https://www.gutenberg.org/cache/epub/100/pg100.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/100/pg100.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-10',
      'title': "The Count of Monte Cristo",
      'titleHi': "The Count of Monte Cristo",
      'author': "Alexandre Dumas",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Count+of+Monte+Cristo',
      'audioUrl':
          'https://librivox.org/search/?q=The+Count+of+Monte+Cristo&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Count+of+Monte+Cristo',
      'readerUrl': "https://www.gutenberg.org/cache/epub/1184/pg1184.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/1184/pg1184.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-11',
      'title': "Treasure Island",
      'titleHi': "Treasure Island",
      'author': "Robert Louis Stevenson",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Treasure+Island',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Treasure+Island',
      'readerUrl': "https://www.gutenberg.org/cache/epub/120/pg120.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/120/pg120.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_01-02_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_03-04_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_05-06_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_07-08_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_09-10_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_11-12_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_13_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_14_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_15_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_16_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_17_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_18_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_19_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_20_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_21_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_22_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_23-24_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_25-26_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_27_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_28_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_29_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_30_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_31_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_32_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_33_stevenson_64kb.mp3",
        "https://www.archive.org/download/treasureisland_librivox/treasure_island_34_stevenson_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/treasureisland_librivox/treasure_island_01-02_stevenson_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-12',
      'title': "Jane Eyre",
      'titleHi': "Jane Eyre",
      'author': "Charlotte Bronte",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Jane+Eyre',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Jane+Eyre',
      'readerUrl': "https://www.gutenberg.org/cache/epub/79159/pg79159.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/79159/pg79159.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_00_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_01_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_02_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_03_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_04_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_05_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_06_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_07_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_08_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_09_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_10_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_11_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_12_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_13_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_14_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_15_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_16_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_17_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_18_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_19_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_20_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_21_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_22_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_23_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_24_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_25_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_26_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_27_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_28_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_29_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_30_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_31_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_32_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_33_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_34_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_35_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_36_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_37_bronte_64kb.mp3",
        "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_38_bronte_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/jane_eyre_librivox/jane_eyre_00_bronte_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-13',
      'title': "The Jungle Book",
      'titleHi': "The Jungle Book",
      'author': "Rudyard Kipling",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Jungle+Book',
      'audioUrl':
          'https://librivox.org/search/?q=The+Jungle+Book&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Jungle+Book',
      'readerUrl': "https://www.gutenberg.org/cache/epub/236/pg236.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/236/pg236.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-14',
      'title': "The Call of the Wild",
      'titleHi': "The Call of the Wild",
      'author': "Jack London",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Call+of+the+Wild',
      'audioUrl':
          'https://librivox.org/search/?q=The+Call+of+the+Wild&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Call+of+the+Wild',
      'readerUrl': "https://www.gutenberg.org/cache/epub/215/pg215.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/215/pg215.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-15',
      'title': "The Return of Sherlock Holmes",
      'titleHi': "The Return of Sherlock Holmes",
      'author': "Arthur Conan Doyle",
      'category': "Mystery",
      'language': 'English',
      'description':
          "A public-domain mystery selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Mystery पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Return+of+Sherlock+Holmes',
      'audioUrl':
          'https://librivox.org/search/?q=The+Return+of+Sherlock+Holmes&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Return+of+Sherlock+Holmes',
      'readerUrl': "https://www.gutenberg.org/cache/epub/108/pg108.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/108/pg108.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-16',
      'title': "A Study in Scarlet",
      'titleHi': "A Study in Scarlet",
      'author': "Arthur Conan Doyle",
      'category': "Mystery",
      'language': 'English',
      'description':
          "A public-domain mystery selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Mystery पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=A+Study+in+Scarlet',
      'audioUrl':
          'https://librivox.org/search/?q=A+Study+in+Scarlet&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=A+Study+in+Scarlet',
      'readerUrl': "https://www.gutenberg.org/cache/epub/244/pg244.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/244/pg244.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-17',
      'title': "Little Women",
      'titleHi': "Little Women",
      'author': "Louisa May Alcott",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Little+Women',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Little+Women',
      'readerUrl': "https://www.gutenberg.org/cache/epub/514/pg514.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/514/pg514.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_01_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_02_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_03_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_04_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_05_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_06_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_07_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_08_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_09_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_10_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_11_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_12_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_13_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_14_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_15_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_16_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_17_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_18_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_19_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_20_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_21_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_22_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_23_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_24_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_25_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_26_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_27_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_28_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_29_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_30_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_31_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_32_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_33_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_34_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_35_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_36_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_37_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_38_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_39_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_40_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_41_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_42_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_43_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_44_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_45_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_46_alcott_64kb.mp3",
        "https://www.archive.org/download/little_women_0711_librivox/littlewomen_47_alcott_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/little_women_0711_librivox/littlewomen_01_alcott_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-18',
      'title': "Notes from the Underground",
      'titleHi': "Notes from the Underground",
      'author': "Fyodor Dostoevsky",
      'category': "Literature",
      'language': 'English',
      'description':
          "A public-domain literature selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Literature पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Notes+from+the+Underground',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Notes+from+the+Underground',
      'readerUrl': "https://www.gutenberg.org/cache/epub/600/pg600.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/600/pg600.cover.medium.jpg",
      'audioUrls': <String>[
        "https://archive.org/download/notes_from_the_underground/notes_p1_01_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p1_02_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p1_03_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p1_04_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p1_05_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p1_06_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p1_07_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p1_08_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p1_09_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p1_10-11_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p2_01_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p2_02_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p2_03_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p2_04_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p2_05_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p2_06_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p2_07_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p2_08_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p2_09_dostoyevsky_64kb.mp3",
        "https://archive.org/download/notes_from_the_underground/notes_p2_10_dostoyevsky_64kb.mp3"
      ],
      'audioUrl':
          "https://archive.org/download/notes_from_the_underground/notes_p1_01_dostoyevsky_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-19',
      'title': "The Secret Garden",
      'titleHi': "The Secret Garden",
      'author': "Frances Hodgson Burnett",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Secret+Garden',
      'audioUrl':
          'https://librivox.org/search/?q=The+Secret+Garden&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Secret+Garden',
      'readerUrl': "https://www.gutenberg.org/cache/epub/113/pg113.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/113/pg113.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-20',
      'title': "The Wind in the Willows",
      'titleHi': "The Wind in the Willows",
      'author': "Kenneth Grahame",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wind+in+the+Willows',
      'audioUrl':
          'https://librivox.org/search/?q=The+Wind+in+the+Willows&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wind+in+the+Willows',
      'readerUrl': "https://www.gutenberg.org/cache/epub/289/pg289.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/289/pg289.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-21',
      'title': "The Three Musketeers",
      'titleHi': "The Three Musketeers",
      'author': "Alexandre Dumas",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Three+Musketeers',
      'audioUrl':
          'https://librivox.org/search/?q=The+Three+Musketeers&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Three+Musketeers',
      'readerUrl': "https://www.gutenberg.org/cache/epub/1257/pg1257.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/1257/pg1257.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-22',
      'title': "The Odyssey",
      'titleHi': "The Odyssey",
      'author': "Homer",
      'category': "Epic Literature",
      'language': 'English',
      'description':
          "A public-domain epic literature selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Epic Literature पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Odyssey',
      'audioUrl':
          'https://librivox.org/search/?q=The+Odyssey&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Odyssey',
      'readerUrl': "https://www.gutenberg.org/cache/epub/3160/pg3160.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/3160/pg3160.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-23',
      'title': "The Iliad",
      'titleHi': "The Iliad",
      'author': "Homer",
      'category': "Epic Literature",
      'language': 'English',
      'description':
          "A public-domain epic literature selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Epic Literature पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Iliad',
      'audioUrl':
          'https://librivox.org/search/?q=The+Iliad&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Iliad',
      'readerUrl': "https://www.gutenberg.org/cache/epub/2199/pg2199.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/2199/pg2199.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-24',
      'title': "The Republic",
      'titleHi': "The Republic",
      'author': "Plato",
      'category': "Philosophy",
      'language': 'English',
      'description':
          "A public-domain philosophy selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Philosophy पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Republic',
      'audioUrl':
          'https://librivox.org/search/?q=The+Republic&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Republic',
      'readerUrl': "https://www.gutenberg.org/cache/epub/150/pg150.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/150/pg150.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-25',
      'title': "The Art of War",
      'titleHi': "The Art of War",
      'author': "Sun Tzu",
      'category': "Philosophy",
      'language': 'English',
      'description':
          "A public-domain philosophy selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Philosophy पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Art+of+War',
      'audioUrl':
          'https://librivox.org/search/?q=The+Art+of+War&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Art+of+War',
      'readerUrl': "https://www.gutenberg.org/cache/epub/132/pg132.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/132/pg132.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-26',
      'title': "The Prince",
      'titleHi': "The Prince",
      'author': "Niccolo Machiavelli",
      'category': "History & Society",
      'language': 'English',
      'description':
          "A public-domain history & society selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की History & Society पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Prince',
      'audioUrl':
          'https://librivox.org/search/?q=The+Prince&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Prince',
      'readerUrl': "https://www.gutenberg.org/cache/epub/1232/pg1232.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/1232/pg1232.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-27',
      'title': "The Divine Comedy",
      'titleHi': "The Divine Comedy",
      'author': "Dante Alighieri",
      'category': "Epic Literature",
      'language': 'English',
      'description':
          "A public-domain epic literature selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Epic Literature पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Divine+Comedy',
      'audioUrl':
          'https://librivox.org/search/?q=The+Divine+Comedy&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Divine+Comedy',
      'readerUrl': "https://www.gutenberg.org/cache/epub/8800/pg8800.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/8800/pg8800.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-28',
      'title': "Don Quixote",
      'titleHi': "Don Quixote",
      'author': "Miguel de Cervantes",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Don+Quixote',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Don+Quixote',
      'readerUrl': "https://www.gutenberg.org/cache/epub/996/pg996.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/996/pg996.cover.medium.jpg",
      'audioUrls': <String>[
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_alp_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_bms_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_cb_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_clp_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_dl_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_el_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_fs_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_gg_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_jm_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_lah_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_lcw_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_llw_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_mk_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_nb_64kb.mp3",
        "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_wt_64kb.mp3"
      ],
      'audioUrl':
          "https://archive.org/download/don_quixote_1505.poem_librivox/donquixote_cawein_alp_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-29',
      'title': "War and Peace",
      'titleHi': "War and Peace",
      'author': "Leo Tolstoy",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=War+and+Peace',
      'audioUrl':
          'https://librivox.org/search/?q=War+and+Peace&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=War+and+Peace',
      'readerUrl': "https://www.gutenberg.org/cache/epub/2600/pg2600.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/2600/pg2600.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-30',
      'title': "Anna Karenina",
      'titleHi': "Anna Karenina",
      'author': "Leo Tolstoy",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Anna+Karenina',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Anna+Karenina',
      'readerUrl': "https://www.gutenberg.org/cache/epub/1399/pg1399.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/1399/pg1399.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_001_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_002_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_003_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_004_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_005_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_006_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_007_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_008_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_009_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_010_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_011_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_012_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_013_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_014_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_015_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_016_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_017_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_018_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_019_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_020_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_021_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_022_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_023_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_024_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_025_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_026_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_027_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_028_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_029_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_030_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_031_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_032_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_033_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_034_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_035_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_036_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_037_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_038_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_039_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_040_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_041_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_042_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_043_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_044_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_045_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_046_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_047_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_048_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_049_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_050_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_051_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_052_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_053_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_054_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_055_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_056_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_057_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_058_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_059_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_060_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_061_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_062_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_063_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_064_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_065_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_066_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_067_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_068_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_069_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_070_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_071_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_072_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_073_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_074_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_075_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_076_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_077_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_078_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_079_tolstoy_64kb.mp3",
        "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_080_tolstoy_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/annakarenina_dutch_1011_librivox/annakarenina_001_tolstoy_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-31',
      'title': "Crime and Punishment",
      'titleHi': "Crime and Punishment",
      'author': "Fyodor Dostoevsky",
      'category': "Literature",
      'language': 'English',
      'description':
          "A public-domain literature selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Literature पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Crime+and+Punishment',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Crime+and+Punishment',
      'readerUrl': "https://www.gutenberg.org/cache/epub/2554/pg2554.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/2554/pg2554.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_01_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_02_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_03_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_04_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_05_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_06_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_07_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_08_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_09_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_10_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_11_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_12_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_13_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_14_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_15_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_16_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_17_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_18_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_19_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_20_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_21_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_22_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_23_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_24_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_25_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_26_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_27_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_28_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_29_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_30_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_31_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_32_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_33_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_34_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_35_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_36_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_37_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_38_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_39_64kb.mp3",
        "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_40_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/crime_and_punishment_0902_librivox/crime_and_punishment_01_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-32',
      'title': "The Brothers Karamazov",
      'titleHi': "The Brothers Karamazov",
      'author': "Fyodor Dostoevsky",
      'category': "Literature",
      'language': 'English',
      'description':
          "A public-domain literature selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Literature पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Brothers+Karamazov',
      'audioUrl':
          'https://librivox.org/search/?q=The+Brothers+Karamazov&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Brothers+Karamazov',
      'readerUrl': "https://www.gutenberg.org/cache/epub/28054/pg28054.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/28054/pg28054.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-33',
      'title': "The Idiot",
      'titleHi': "The Idiot",
      'author': "Fyodor Dostoevsky",
      'category': "Literature",
      'language': 'English',
      'description':
          "A public-domain literature selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Literature पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Idiot',
      'audioUrl':
          'https://librivox.org/search/?q=The+Idiot&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Idiot',
      'readerUrl': "https://www.gutenberg.org/cache/epub/2638/pg2638.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/2638/pg2638.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-34',
      'title': "Siddhartha",
      'titleHi': "Siddhartha",
      'author': "Hermann Hesse",
      'category': "Philosophy",
      'language': 'English',
      'description':
          "A public-domain philosophy selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Philosophy पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Siddhartha',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Siddhartha',
      'readerUrl': "https://www.gutenberg.org/cache/epub/2500/pg2500.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/2500/pg2500.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_01_hesse_64kb.mp3",
        "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_02_hesse_64kb.mp3",
        "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_03_hesse_64kb.mp3",
        "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_04_hesse_64kb.mp3",
        "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_05_hesse_64kb.mp3",
        "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_06_hesse_64kb.mp3",
        "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_07_hesse_64kb.mp3",
        "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_08_hesse_64kb.mp3",
        "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_09_hesse_64kb.mp3",
        "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_10_hesse_64kb.mp3",
        "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_11_hesse_64kb.mp3",
        "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_12_hesse_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/siddhartha_ap_librivox/siddhartha_01_hesse_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-35',
      'title': "The Prophet",
      'titleHi': "The Prophet",
      'author': "Kahlil Gibran",
      'category': "Philosophy",
      'language': 'English',
      'description':
          "A public-domain philosophy selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Philosophy पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Prophet',
      'audioUrl':
          'https://librivox.org/search/?q=The+Prophet&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Prophet',
      'readerUrl': "https://www.gutenberg.org/cache/epub/58585/pg58585.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/58585/pg58585.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-36',
      'title': "The Little Prince",
      'titleHi': "The Little Prince",
      'author': "Antoine de Saint-Exupery",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Little%20Prince-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Little+Prince',
      'audioUrl':
          'https://librivox.org/search/?q=The+Little+Prince&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Little+Prince',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-37',
      'title': "The Old Man and the Sea",
      'titleHi': "The Old Man and the Sea",
      'author': "Ernest Hemingway",
      'category': "Literature",
      'language': 'English',
      'description':
          "A public-domain literature selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Literature पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Old%20Man%20and%20the%20Sea-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Old+Man+and+the+Sea',
      'audioUrl':
          'https://librivox.org/search/?q=The+Old+Man+and+the+Sea&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Old+Man+and+the+Sea',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-38',
      'title': "The Picture of Dorian Gray",
      'titleHi': "The Picture of Dorian Gray",
      'author': "Oscar Wilde",
      'category': "Literature",
      'language': 'English',
      'description':
          "A public-domain literature selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Literature पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Picture+of+Dorian+Gray',
      'audioUrl':
          'https://librivox.org/search/?q=The+Picture+of+Dorian+Gray&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Picture+of+Dorian+Gray',
      'readerUrl': "https://www.gutenberg.org/cache/epub/174/pg174.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/174/pg174.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-39',
      'title': "The Importance of Being Earnest",
      'titleHi': "The Importance of Being Earnest",
      'author': "Oscar Wilde",
      'category': "Drama",
      'language': 'English',
      'description':
          "A public-domain drama selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Drama पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Importance%20of%20Being%20Earnest-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Importance+of+Being+Earnest',
      'audioUrl':
          'https://librivox.org/search/?q=The+Importance+of+Being+Earnest&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Importance+of+Being+Earnest',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-40',
      'title': "The Happy Prince",
      'titleHi': "The Happy Prince",
      'author': "Oscar Wilde",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Happy%20Prince-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Happy+Prince',
      'audioUrl':
          'https://librivox.org/search/?q=The+Happy+Prince&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Happy+Prince',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-41',
      'title': "The Canterville Ghost",
      'titleHi': "The Canterville Ghost",
      'author': "Oscar Wilde",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Canterville+Ghost',
      'audioUrl':
          'https://librivox.org/search/?q=The+Canterville+Ghost&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Canterville+Ghost',
      'readerUrl': "https://www.gutenberg.org/cache/epub/14522/pg14522.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/14522/pg14522.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-42',
      'title': "Wuthering Heights",
      'titleHi': "Wuthering Heights",
      'author': "Emily Bronte",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Wuthering+Heights',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Wuthering+Heights',
      'readerUrl': "https://www.gutenberg.org/cache/epub/768/pg768.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/768/pg768.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_01_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_02_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_03_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_04_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_05_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_06_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_07_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_08_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_09_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_10_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_11_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_12_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_13_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_14_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_15_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_16_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_17_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_18_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_19_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_20_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_21_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_22_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_23_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_24_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_25_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_26_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_27_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_28_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_29_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_30_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_31_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_32_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_33_bronte_64kb.mp3",
        "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_34_bronte_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/wuthering_heights_0801_librivox/wutheringheights_01_bronte_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-43',
      'title': "The Tenant of Wildfell Hall",
      'titleHi': "The Tenant of Wildfell Hall",
      'author': "Anne Bronte",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Tenant+of+Wildfell+Hall',
      'audioUrl':
          'https://librivox.org/search/?q=The+Tenant+of+Wildfell+Hall&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Tenant+of+Wildfell+Hall',
      'readerUrl': "https://www.gutenberg.org/cache/epub/969/pg969.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/969/pg969.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-44',
      'title': "Middlemarch",
      'titleHi': "Middlemarch",
      'author': "George Eliot",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Middlemarch',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Middlemarch',
      'readerUrl': "https://www.gutenberg.org/cache/epub/145/pg145.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/145/pg145.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_01_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_02_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_03_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_04_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_05_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_06_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_07_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_08_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_09_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_10_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_11_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_12_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_13_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_14_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_15_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_16_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_17_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_18_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_19_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_20_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_21_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_22_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_23_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_24_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_25_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_26_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_27_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_28_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_29_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_30_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_31_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_32_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_33_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_34_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_35_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_36_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_37_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_38_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_39_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_40_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_41_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_42_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_43_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_44_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_45_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_46_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_47_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_48_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_49_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_50_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_51_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_52_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_53_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_54_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_55_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_56_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_57_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_58_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_59_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_60_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_61_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_62_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_63_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_64_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_65_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_66_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_67_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_68_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_69_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_70_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_71_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_72_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_73_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_74_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_75_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_76_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_77_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_78_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_79_eliot_64kb.mp3",
        "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_80_eliot_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/middlemarch_0810_librivox/middlemarch_01_eliot_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-45',
      'title': "Silas Marner",
      'titleHi': "Silas Marner",
      'author': "George Eliot",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Silas+Marner',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Silas+Marner',
      'readerUrl': "https://www.gutenberg.org/cache/epub/550/pg550.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/550/pg550.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_01_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_02_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_03_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_04_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_05_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_06_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_07_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_08_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_09_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_10_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_11_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_12_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_13_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_14_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_15_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_16_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_17_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_18_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_19_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_20_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_21_eliot_64kb.mp3",
        "https://www.archive.org/download/silas_marner_librivox/silas_marner_22_eliot_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/silas_marner_librivox/silas_marner_01_eliot_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-46',
      'title': "The Mill on the Floss",
      'titleHi': "The Mill on the Floss",
      'author': "George Eliot",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Mill+on+the+Floss',
      'audioUrl':
          'https://librivox.org/search/?q=The+Mill+on+the+Floss&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Mill+on+the+Floss',
      'readerUrl': "https://www.gutenberg.org/cache/epub/6688/pg6688.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/6688/pg6688.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-47',
      'title': "Northanger Abbey",
      'titleHi': "Northanger Abbey",
      'author': "Jane Austen",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Northanger+Abbey',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Northanger+Abbey',
      'readerUrl': "https://www.gutenberg.org/cache/epub/121/pg121.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/121/pg121.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_01_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_02_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_03_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_04_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_05_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_06_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_07_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_08_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_09_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_10_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_11_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_12_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_13_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_14_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_15_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_16_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_17_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_18_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_19_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_20_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_21_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_22_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_23_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_24_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_25_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_26_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_27_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_28_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_29_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_30_austen_64kb.mp3",
        "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_31_austen_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/northanger_abbey_librivox/northangerabbey_01_austen_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-48',
      'title': "Sense and Sensibility",
      'titleHi': "Sense and Sensibility",
      'author': "Jane Austen",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Sense+and+Sensibility',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Sense+and+Sensibility',
      'readerUrl': "https://www.gutenberg.org/cache/epub/161/pg161.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/161/pg161.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_01_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_02_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_03_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_04_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_05_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_06_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_07_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_08_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_09_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_10_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_11_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_12_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_13_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_14_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_15_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_16_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_17_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_18_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_19_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_20_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_21_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_22_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_23_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_24_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_25_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_26_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_27_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_28_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_29_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_30_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_31_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_32_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_33_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_34_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_35_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_36_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_37_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_38_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_39_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_40_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_41_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_42_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_43_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_44_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_45_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_46_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_47_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_48_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_49_austen_64kb.mp3",
        "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_50_austen_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/0_sense_and_sensibility_librivox/senseandsensibility_01_austen_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-49',
      'title': "Emma",
      'titleHi': "Emma",
      'author': "Jane Austen",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Emma',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Emma',
      'readerUrl': "https://www.gutenberg.org/cache/epub/158/pg158.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/158/pg158.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/emma_solo_librivox/emma_01_01_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_02_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_03_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_04_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_05_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_06_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_07_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_08_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_09_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_10_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_11_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_12_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_13_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_14_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_15_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_16_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_17_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_01_18_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_01_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_02_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_03_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_04_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_05_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_06_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_07_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_08_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_09_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_10_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_11_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_12_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_13_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_14_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_15_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_16_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_17_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_02_18_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_01_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_02_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_03_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_04_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_05_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_06_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_07_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_08_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_09_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_10_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_11_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_12_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_13_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_14_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_15_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_16_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_17_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_18_austen_64kb.mp3",
        "https://www.archive.org/download/emma_solo_librivox/emma_03_19_austen_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/emma_solo_librivox/emma_01_01_austen_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-50',
      'title': "Mansfield Park",
      'titleHi': "Mansfield Park",
      'author': "Jane Austen",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Mansfield+Park',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Mansfield+Park',
      'readerUrl': "https://www.gutenberg.org/cache/epub/141/pg141.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/141/pg141.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_01_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_02_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_03_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_04_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_05_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_06_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_07_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_08_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_09_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_10_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_11_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_12_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_13_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_14_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_15_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_16_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_17_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_18_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_19_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_20_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_21_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_22_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_23_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_24_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_25_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_26_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_27_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_28_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_29_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_30_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_31_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_32_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_33_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_34_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_35_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_36_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_37_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_38_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_39_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_40_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_41_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_42_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_43_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_44_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_45_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_46_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_47_austen_64kb.mp3",
        "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_48_austen_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/mansfield_park_librivox/mansfieldpark_01_austen_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-51',
      'title': "Persuasion",
      'titleHi': "Persuasion",
      'author': "Jane Austen",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Persuasion',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Persuasion',
      'readerUrl': "https://www.gutenberg.org/cache/epub/105/pg105.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/105/pg105.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_01_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_02_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_03_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_04_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_05_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_06_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_07_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_08_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_09_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_10_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_11_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_12_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_13_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_14_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_15_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_16_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_17_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_18_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_19_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_20_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_21_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_22_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_23_austen_64kb.mp3",
        "https://www.archive.org/download/persuasion_0708_librivox/persuasion_24_austen_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/persuasion_0708_librivox/persuasion_01_austen_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-52',
      'title': "The Mayor of Casterbridge",
      'titleHi': "The Mayor of Casterbridge",
      'author': "Thomas Hardy",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Mayor+of+Casterbridge',
      'audioUrl':
          'https://librivox.org/search/?q=The+Mayor+of+Casterbridge&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Mayor+of+Casterbridge',
      'readerUrl': "https://www.gutenberg.org/cache/epub/143/pg143.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/143/pg143.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-53',
      'title': "Tess of the d’Urbervilles",
      'titleHi': "Tess of the d’Urbervilles",
      'author': "Thomas Hardy",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/Tess%20of%20the%20d%E2%80%99Urbervilles-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Tess+of+the+d%27Urbervilles',
      'audioUrl':
          'https://librivox.org/search/?q=Tess+of+the+d%27Urbervilles&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Tess+of+the+d%27Urbervilles',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-54',
      'title': "Far from the Madding Crowd",
      'titleHi': "Far from the Madding Crowd",
      'author': "Thomas Hardy",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Far+from+the+Madding+Crowd',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Far+from+the+Madding+Crowd',
      'readerUrl': "https://www.gutenberg.org/cache/epub/27/pg27.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/27/pg27.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_01_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_02_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_03_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_04_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_05_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_06_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_07_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_08_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_09_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_10_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_11_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_12_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_13_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_14_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_15_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_16_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_17_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_18_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_19_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_20_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_21_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_22_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_23_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_24_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_25_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_26_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_27_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_28_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_29_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_30_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_31_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_32_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_33_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_34_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_35_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_36_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_37_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_38_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_39_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_40_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_41_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_42_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_43_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_44_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_45_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_46_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_47_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_48_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_49_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_50_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_51_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_52_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_53_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_54_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_55_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_56_hardy_64kb.mp3",
        "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_57_hardy_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/madding_crowd_0807_librivox/farfrommaddingcrowd_01_hardy_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-55',
      'title': "The Scarlet Letter",
      'titleHi': "The Scarlet Letter",
      'author': "Nathaniel Hawthorne",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Scarlet+Letter',
      'audioUrl':
          'https://librivox.org/search/?q=The+Scarlet+Letter&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Scarlet+Letter',
      'readerUrl': "https://www.gutenberg.org/cache/epub/33/pg33.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/33/pg33.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-56',
      'title': "The House of the Seven Gables",
      'titleHi': "The House of the Seven Gables",
      'author': "Nathaniel Hawthorne",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+House+of+the+Seven+Gables',
      'audioUrl':
          'https://librivox.org/search/?q=The+House+of+the+Seven+Gables&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+House+of+the+Seven+Gables',
      'readerUrl': "https://www.gutenberg.org/cache/epub/77/pg77.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/77/pg77.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-57',
      'title': "The Last of the Mohicans",
      'titleHi': "The Last of the Mohicans",
      'author': "James Fenimore Cooper",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Last%20of%20the%20Mohicans-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Last+of+the+Mohicans',
      'audioUrl':
          'https://librivox.org/search/?q=The+Last+of+the+Mohicans&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Last+of+the+Mohicans',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-58',
      'title': "The Deerslayer",
      'titleHi': "The Deerslayer",
      'author': "James Fenimore Cooper",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Deerslayer',
      'audioUrl':
          'https://librivox.org/search/?q=The+Deerslayer&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Deerslayer',
      'readerUrl': "https://www.gutenberg.org/cache/epub/3285/pg3285.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/3285/pg3285.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-59',
      'title': "Robinson Crusoe",
      'titleHi': "Robinson Crusoe",
      'author': "Daniel Defoe",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Robinson+Crusoe',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Robinson+Crusoe',
      'readerUrl': "https://www.gutenberg.org/cache/epub/48387/pg48387.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/48387/pg48387.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_01_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_02_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_03_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_04_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_05_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_06_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_07_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_08_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_09_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_10_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_11_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_12_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_13_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_14_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_15_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_16_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_17_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_18_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_19_defoe_64kb.mp3",
        "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_20_defoe_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/robinson_crusoe_librivox/robinson_crusoe_01_defoe_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-60',
      'title': "Gulliver’s Travels",
      'titleHi': "Gulliver’s Travels",
      'author': "Jonathan Swift",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Gulliver%27s+Travels',
      'audioUrl':
          'https://librivox.org/search/?q=Gulliver%27s+Travels&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Gulliver%27s+Travels',
      'readerUrl': "https://www.gutenberg.org/cache/epub/65473/pg65473.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/65473/pg65473.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-61',
      'title': "The Pilgrim’s Progress",
      'titleHi': "The Pilgrim’s Progress",
      'author': "John Bunyan",
      'category': "Epic Literature",
      'language': 'English',
      'description':
          "A public-domain epic literature selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Epic Literature पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Pilgrim%E2%80%99s%20Progress-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Pilgrim%27s+Progress',
      'audioUrl':
          'https://librivox.org/search/?q=The+Pilgrim%27s+Progress&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Pilgrim%27s+Progress',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-62',
      'title': "The Invisible Man",
      'titleHi': "The Invisible Man",
      'author': "H. G. Wells",
      'category': "Science Fiction",
      'language': 'English',
      'description':
          "A public-domain science fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Science Fiction पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Invisible%20Man-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Invisible+Man',
      'audioUrl':
          'https://librivox.org/search/?q=The+Invisible+Man&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Invisible+Man',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-63',
      'title': "The First Men in the Moon",
      'titleHi': "The First Men in the Moon",
      'author': "H. G. Wells",
      'category': "Science Fiction",
      'language': 'English',
      'description':
          "A public-domain science fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Science Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+First+Men+in+the+Moon',
      'audioUrl':
          'https://librivox.org/search/?q=The+First+Men+in+the+Moon&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+First+Men+in+the+Moon',
      'readerUrl': "https://www.gutenberg.org/cache/epub/1013/pg1013.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/1013/pg1013.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-64',
      'title': "The Island of Doctor Moreau",
      'titleHi': "The Island of Doctor Moreau",
      'author': "H. G. Wells",
      'category': "Science Fiction",
      'language': 'English',
      'description':
          "A public-domain science fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Science Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Island+of+Doctor+Moreau',
      'audioUrl':
          'https://librivox.org/search/?q=The+Island+of+Doctor+Moreau&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Island+of+Doctor+Moreau',
      'readerUrl': "https://www.gutenberg.org/cache/epub/159/pg159.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/159/pg159.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-65',
      'title': "The Lost World",
      'titleHi': "The Lost World",
      'author': "Arthur Conan Doyle",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Lost+World',
      'audioUrl':
          'https://librivox.org/search/?q=The+Lost+World&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Lost+World',
      'readerUrl': "https://www.gutenberg.org/cache/epub/139/pg139.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/139/pg139.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-66',
      'title': "The Moonstone",
      'titleHi': "The Moonstone",
      'author': "Wilkie Collins",
      'category': "Mystery",
      'language': 'English',
      'description':
          "A public-domain mystery selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Mystery पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Moonstone',
      'audioUrl':
          'https://librivox.org/search/?q=The+Moonstone&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Moonstone',
      'readerUrl': "https://www.gutenberg.org/cache/epub/155/pg155.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/155/pg155.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-67',
      'title': "The Woman in White",
      'titleHi': "The Woman in White",
      'author': "Wilkie Collins",
      'category': "Mystery",
      'language': 'English',
      'description':
          "A public-domain mystery selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Mystery पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Woman+in+White',
      'audioUrl':
          'https://librivox.org/search/?q=The+Woman+in+White&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Woman+in+White',
      'readerUrl': "https://www.gutenberg.org/cache/epub/583/pg583.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/583/pg583.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-68',
      'title': "The Thirty-Nine Steps",
      'titleHi': "The Thirty-Nine Steps",
      'author': "John Buchan",
      'category': "Mystery",
      'language': 'English',
      'description':
          "A public-domain mystery selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Mystery पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Thirty-Nine+Steps',
      'audioUrl':
          'https://librivox.org/search/?q=The+Thirty-Nine+Steps&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Thirty-Nine+Steps',
      'readerUrl': "https://www.gutenberg.org/cache/epub/558/pg558.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/558/pg558.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-69',
      'title': "The Hound of the Baskervilles",
      'titleHi': "The Hound of the Baskervilles",
      'author': "Arthur Conan Doyle",
      'category': "Mystery",
      'language': 'English',
      'description':
          "A public-domain mystery selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Mystery पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Hound+of+the+Baskervilles',
      'audioUrl':
          'https://librivox.org/search/?q=The+Hound+of+the+Baskervilles&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Hound+of+the+Baskervilles',
      'readerUrl': "https://www.gutenberg.org/cache/epub/2852/pg2852.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/2852/pg2852.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-70',
      'title': "The Sign of the Four",
      'titleHi': "The Sign of the Four",
      'author': "Arthur Conan Doyle",
      'category': "Mystery",
      'language': 'English',
      'description':
          "A public-domain mystery selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Mystery पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Sign+of+the+Four',
      'audioUrl':
          'https://librivox.org/search/?q=The+Sign+of+the+Four&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Sign+of+the+Four',
      'readerUrl': "https://www.gutenberg.org/cache/epub/2097/pg2097.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/2097/pg2097.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-71',
      'title': "The Moon",
      'titleHi': "The Moon",
      'author': "H. G. Wells",
      'category': "Science Fiction",
      'language': 'English',
      'description':
          "A public-domain science fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Science Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Moon',
      'audioUrl':
          'https://librivox.org/search/?q=The+Moon&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Moon',
      'readerUrl': "https://www.gutenberg.org/cache/epub/17712/pg17712.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/17712/pg17712.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-72',
      'title': "The Last Man",
      'titleHi': "The Last Man",
      'author': "Mary Shelley",
      'category': "Science Fiction",
      'language': 'English',
      'description':
          "A public-domain science fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Science Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Last+Man',
      'audioUrl':
          'https://librivox.org/search/?q=The+Last+Man&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Last+Man',
      'readerUrl': "https://www.gutenberg.org/cache/epub/18247/pg18247.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/18247/pg18247.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-73',
      'title': "The Scarlet Pimpernel",
      'titleHi': "The Scarlet Pimpernel",
      'author': "Baroness Orczy",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Scarlet+Pimpernel',
      'audioUrl':
          'https://librivox.org/search/?q=The+Scarlet+Pimpernel&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Scarlet+Pimpernel',
      'readerUrl': "https://www.gutenberg.org/cache/epub/60/pg60.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/60/pg60.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-74',
      'title': "The Prisoner of Zenda",
      'titleHi': "The Prisoner of Zenda",
      'author': "Anthony Hope",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Prisoner+of+Zenda',
      'audioUrl':
          'https://librivox.org/search/?q=The+Prisoner+of+Zenda&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Prisoner+of+Zenda',
      'readerUrl': "https://www.gutenberg.org/cache/epub/95/pg95.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/95/pg95.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-75',
      'title': "The Three Men in a Boat",
      'titleHi': "The Three Men in a Boat",
      'author': "Jerome K. Jerome",
      'category': "Humour",
      'language': 'English',
      'description':
          "A public-domain humour selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Humour पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Three%20Men%20in%20a%20Boat-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Three+Men+in+a+Boat',
      'audioUrl':
          'https://librivox.org/search/?q=The+Three+Men+in+a+Boat&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Three+Men+in+a+Boat',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-76',
      'title': "The Pickwick Papers",
      'titleHi': "The Pickwick Papers",
      'author': "Charles Dickens",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Pickwick+Papers',
      'audioUrl':
          'https://librivox.org/search/?q=The+Pickwick+Papers&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Pickwick+Papers',
      'readerUrl': "https://www.gutenberg.org/cache/epub/580/pg580.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/580/pg580.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-77',
      'title': "David Copperfield",
      'titleHi': "David Copperfield",
      'author': "Charles Dickens",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=David+Copperfield',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=David+Copperfield',
      'readerUrl': "https://www.gutenberg.org/cache/epub/766/pg766.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/766/pg766.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_00_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_01_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_02_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_03_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_04_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_05_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_06_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_07_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_08_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_09_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_10_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_11_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_12_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_13_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_14_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_15_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_16_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_17_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_18_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_19_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_20_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_21_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_22_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_23_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_24_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_25_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_26_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_27_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_28_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_29_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_30_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_31_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_32_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_33_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_34_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_35_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_36_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_37_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_38_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_39_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_40_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_41_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_42_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_43_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_44_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_45_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_46_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_47_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_48_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_49_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_50_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_51_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_52_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_53_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_54_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_55_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_56_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_57_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_58_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_59_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_60_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_61_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_62_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_63_dickens_64kb.mp3",
        "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_64_dickens_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/David_Copperfield_0805_librivox2/davidcopperfield_00_dickens_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-78',
      'title': "Great Expectations",
      'titleHi': "Great Expectations",
      'author': "Charles Dickens",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Great+Expectations',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Great+Expectations',
      'readerUrl': "https://www.gutenberg.org/cache/epub/1400/pg1400.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/1400/pg1400.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_01_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_02_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_03_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_04_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_05_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_06_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_07_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_08_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_09_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_10_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_11_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_12_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_13_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_14_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_15_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_16_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_17_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_18_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_19_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_20_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_21_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_22_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_23_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_24_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_25_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_26_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_27_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_28_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_29_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_30_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_31_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_32_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_33_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_34_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_35_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_36_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_37_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_38_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_39_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_40_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_41_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_42_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_43_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_44_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_45_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_46_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_47_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_48_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_49_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_50_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_51_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_52_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_53_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_54_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_55_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_56_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_57_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_58_dickens_64kb.mp3",
        "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_59_dickens_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/great_expectations_mfs_0812_librivox/greatexpectations_01_dickens_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-79',
      'title': "Oliver Twist",
      'titleHi': "Oliver Twist",
      'author': "Charles Dickens",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Oliver+Twist',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Oliver+Twist',
      'readerUrl': "https://www.gutenberg.org/cache/epub/730/pg730.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/730/pg730.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_01_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_02_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_03_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_04_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_05_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_06_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_07_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_08_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_09_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_10_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_11_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_12_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_13_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_14_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_15_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_16_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_17_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_18_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_19_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_20_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_21_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_22_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_23_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_24_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_25_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_26_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_27_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_28_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_29_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_30_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_31_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_32_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_33_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_34_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_35_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_36_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_37_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_38_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_39_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_40_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_41_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_42_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_43_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_44_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_45_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_46_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_47_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_48_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_49_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_50_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_51_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_52_64kb.mp3",
        "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_53_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/oliver_twist_librivox/dickens_oliver_twist_01_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-80',
      'title': "Hard Times",
      'titleHi': "Hard Times",
      'author': "Charles Dickens",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Hard+Times',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Hard+Times',
      'readerUrl': "https://www.gutenberg.org/cache/epub/786/pg786.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/786/pg786.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_01_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_02_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_03_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_04_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_05_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_06_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_07_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_08_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_09_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_10_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_11_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_12_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_13_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_14_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_15_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_16_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_17_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_18_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_19_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_20_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_21_dickens_64kb.mp3",
        "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_22_dickens_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/hard_times_dickens_0709_librivox/hardtimes_01_dickens_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-81',
      'title': "The Old Curiosity Shop",
      'titleHi': "The Old Curiosity Shop",
      'author': "Charles Dickens",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain classic fiction selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Classic Fiction पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Old+Curiosity+Shop',
      'audioUrl':
          'https://librivox.org/search/?q=The+Old+Curiosity+Shop&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Old+Curiosity+Shop',
      'readerUrl': "https://www.gutenberg.org/cache/epub/700/pg700.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/700/pg700.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-82',
      'title': "Aesop’s Fables",
      'titleHi': "Aesop’s Fables",
      'author': "Aesop",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/Aesop%E2%80%99s%20Fables-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Aesop%27s+Fables',
      'audioUrl':
          'https://librivox.org/search/?q=Aesop%27s+Fables&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Aesop%27s+Fables',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-83',
      'title': "Grimm’s Fairy Tales",
      'titleHi': "Grimm’s Fairy Tales",
      'author': "Brothers Grimm",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Grimm%27s+Fairy+Tales',
      'audioUrl':
          'https://librivox.org/search/?q=Grimm%27s+Fairy+Tales&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Grimm%27s+Fairy+Tales',
      'readerUrl': "https://www.gutenberg.org/cache/epub/52521/pg52521.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/52521/pg52521.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-84',
      'title': "The Arabian Nights",
      'titleHi': "The Arabian Nights",
      'author': "Anonymous",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Arabian%20Nights-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Arabian+Nights',
      'audioUrl':
          'https://librivox.org/search/?q=The+Arabian+Nights&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Arabian+Nights',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-85',
      'title': "The Adventures of Tom Sawyer",
      'titleHi': "The Adventures of Tom Sawyer",
      'author': "Mark Twain",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Adventures+of+Tom+Sawyer',
      'audioUrl':
          'https://librivox.org/search/?q=The+Adventures+of+Tom+Sawyer&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Adventures+of+Tom+Sawyer',
      'readerUrl': "https://www.gutenberg.org/cache/epub/74/pg74.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/74/pg74.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-86',
      'title': "Adventures of Huckleberry Finn",
      'titleHi': "Adventures of Huckleberry Finn",
      'author': "Mark Twain",
      'category': "Adventure",
      'language': 'English',
      'description':
          "A public-domain adventure selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Adventure पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Adventures+of+Huckleberry+Finn',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Adventures+of+Huckleberry+Finn',
      'readerUrl': "https://www.gutenberg.org/cache/epub/76/pg76.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/76/pg76.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_01_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_02_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_03_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_04_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_05_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_06_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_07_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_08_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_09_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_10_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_11_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_12_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_13_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_14_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_15_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_16_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_17_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_18_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_19_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_20_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_21_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_22_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_23_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_24_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_25_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_26_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_27_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_28_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_29_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_30_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_31_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_32_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_33_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_34_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_35_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_36_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_37_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_38_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_39_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_40_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_41_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_42_twain_apc_64kb.mp3",
        "https://www.archive.org/download/huck_finn_librivox/huckfinn_43_twain_apc_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/huck_finn_librivox/huckfinn_01_twain_apc_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-87',
      'title': "The Prince and the Pauper",
      'titleHi': "The Prince and the Pauper",
      'author': "Mark Twain",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Prince+and+the+Pauper',
      'audioUrl':
          'https://librivox.org/search/?q=The+Prince+and+the+Pauper&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Prince+and+the+Pauper',
      'readerUrl': "https://www.gutenberg.org/cache/epub/1837/pg1837.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/1837/pg1837.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-88',
      'title': "The Adventures of Pinocchio",
      'titleHi': "The Adventures of Pinocchio",
      'author': "Carlo Collodi",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Adventures+of+Pinocchio',
      'audioUrl':
          'https://librivox.org/search/?q=The+Adventures+of+Pinocchio&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Adventures+of+Pinocchio',
      'readerUrl': "https://www.gutenberg.org/cache/epub/500/pg500.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/500/pg500.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-89',
      'title': "The Wonderful Adventures of Nils",
      'titleHi': "The Wonderful Adventures of Nils",
      'author': "Selma Lagerlof",
      'category': "Children",
      'language': 'English',
      'description':
          "A public-domain children selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Children पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wonderful+Adventures+of+Nils',
      'audioUrl':
          'https://librivox.org/search/?q=The+Wonderful+Adventures+of+Nils&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wonderful+Adventures+of+Nils',
      'readerUrl': "https://www.gutenberg.org/cache/epub/10935/pg10935.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/10935/pg10935.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-90-90',
      'title': "The Secret Agent",
      'titleHi': "The Secret Agent",
      'author': "Joseph Conrad",
      'category': "Mystery",
      'language': 'English',
      'description':
          "A public-domain mystery selection for reading, listening and extra learning.",
      'descriptionHi':
          "पढ़ने, सुनने और अतिरिक्त ज्ञान के लिए सार्वजनिक डोमेन की Mystery पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Secret%20Agent-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Secret+Agent',
      'audioUrl':
          'https://librivox.org/search/?q=The+Secret+Agent&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Secret+Agent',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-01',
      'title': "The Red Badge of Courage",
      'titleHi': "The Red Badge of Courage",
      'author': "Stephen Crane",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Red%20Badge%20of%20Courage-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Red+Badge+of+Courage',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Red+Badge+of+Courage',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-02',
      'title': "The Awakening",
      'titleHi': "The Awakening",
      'author': "Kate Chopin",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Awakening',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Awakening',
      'readerUrl': "https://www.gutenberg.org/cache/epub/50834/pg50834.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/50834/pg50834.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-03',
      'title': "The Age of Innocence",
      'titleHi': "The Age of Innocence",
      'author': "Edith Wharton",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Age+of+Innocence',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Age+of+Innocence',
      'readerUrl': "https://www.gutenberg.org/cache/epub/541/pg541.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/541/pg541.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-04',
      'title': "The House of Mirth",
      'titleHi': "The House of Mirth",
      'author': "Edith Wharton",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+House+of+Mirth',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+House+of+Mirth',
      'readerUrl': "https://www.gutenberg.org/cache/epub/284/pg284.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/284/pg284.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-05',
      'title': "The Turn of the Screw",
      'titleHi': "The Turn of the Screw",
      'author': "Henry James",
      'category': "Mystery",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Turn+of+the+Screw',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Turn+of+the+Screw',
      'readerUrl': "https://www.gutenberg.org/cache/epub/209/pg209.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/209/pg209.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-06',
      'title': "The Portrait of a Lady",
      'titleHi': "The Portrait of a Lady",
      'author': "Henry James",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Portrait%20of%20a%20Lady-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Portrait+of+a+Lady',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Portrait+of+a+Lady',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-07',
      'title': "The Ambassadors",
      'titleHi': "The Ambassadors",
      'author': "Henry James",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Ambassadors',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Ambassadors',
      'readerUrl': "https://www.gutenberg.org/cache/epub/432/pg432.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/432/pg432.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-08',
      'title': "The Golden Bowl",
      'titleHi': "The Golden Bowl",
      'author': "Henry James",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Golden%20Bowl-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Golden+Bowl',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Golden+Bowl',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-09',
      'title': "The Wings of the Dove",
      'titleHi': "The Wings of the Dove",
      'author': "Henry James",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Wings%20of%20the%20Dove-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wings+of+the+Dove',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wings+of+the+Dove',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-10',
      'title': "The Bostonians",
      'titleHi': "The Bostonians",
      'author': "Henry James",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Bostonians-M.jpg',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Bostonians',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Bostonians',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-11',
      'title': "The Europeans",
      'titleHi': "The Europeans",
      'author': "Henry James",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Europeans',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Europeans',
      'readerUrl': "https://www.gutenberg.org/cache/epub/179/pg179.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/179/pg179.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-12',
      'title': "The American",
      'titleHi': "The American",
      'author': "Henry James",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+American',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+American',
      'readerUrl': "https://www.gutenberg.org/cache/epub/177/pg177.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/177/pg177.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-13',
      'title': "The Aspern Papers",
      'titleHi': "The Aspern Papers",
      'author': "Henry James",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Aspern+Papers',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Aspern+Papers',
      'readerUrl': "https://www.gutenberg.org/cache/epub/211/pg211.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/211/pg211.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-14',
      'title': "The Beast in the Jungle",
      'titleHi': "The Beast in the Jungle",
      'author': "Henry James",
      'category': "Literature",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Beast+in+the+Jungle',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Beast+in+the+Jungle',
      'readerUrl': "https://www.gutenberg.org/cache/epub/1093/pg1093.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/1093/pg1093.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-15',
      'title': "The Open Boat",
      'titleHi': "The Open Boat",
      'author': "Stephen Crane",
      'category': "Literature",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Open%20Boat-M.jpg',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Open+Boat',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Open+Boat',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-16',
      'title': "The Wonderful Visit",
      'titleHi': "The Wonderful Visit",
      'author': "H. G. Wells",
      'category': "Science Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wonderful+Visit',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wonderful+Visit',
      'readerUrl': "https://www.gutenberg.org/cache/epub/33913/pg33913.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/33913/pg33913.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-17',
      'title': "The Food of the Gods and How It Came to Earth",
      'titleHi': "The Food of the Gods and How It Came to Earth",
      'author': "H. G. Wells",
      'category': "Science Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Food+of+the+Gods+and+How+It+Came+to+Earth',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Food+of+the+Gods+and+How+It+Came+to+Earth',
      'readerUrl': "https://www.gutenberg.org/cache/epub/11696/pg11696.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/11696/pg11696.cover.medium.jpg",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-18',
      'title': "The Sleeper Awakes",
      'titleHi': "The Sleeper Awakes",
      'author': "H. G. Wells",
      'category': "Science Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'coverUrl':
          'https://covers.openlibrary.org/b/title/The%20Sleeper%20Awakes-M.jpg',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Sleeper+Awakes',
      'audioUrl': '',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Sleeper+Awakes',
      'readerUrl': "",
      'audioUrls': <String>[],
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-19',
      'title': "Kipps",
      'titleHi': "Kipps",
      'author': "H. G. Wells",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'coverUrl': 'https://covers.openlibrary.org/b/title/Kipps-M.jpg',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Kipps',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Kipps',
      'readerUrl': "",
      'audioUrls': <String>[
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_01_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_02_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_03_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_04_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_05_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_06_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_07_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_08_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_09_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_10_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_11_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_12_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_13_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_14_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_15_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_16_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_17_wells_64kb.mp3",
        "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_18_wells_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/kipps_1211_ao_librivox/kipps_01_wells_64kb.mp3",
      'isPublished': true,
    },
    <String, dynamic>{
      'id': 'demo-readonly-20',
      'title': "Love and Mr Lewisham",
      'titleHi': "Love and Mr Lewisham",
      'author': "H. G. Wells",
      'category': "Classic Fiction",
      'language': 'English',
      'description':
          "A public-domain read-only selection for extra learning and reading practice.",
      'descriptionHi':
          "अतिरिक्त ज्ञान और पढ़ने के अभ्यास के लिए सार्वजनिक डोमेन की पुस्तक।",
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Love+and+Mr+Lewisham',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Love+and+Mr+Lewisham',
      'readerUrl': "https://www.gutenberg.org/cache/epub/11640/pg11640.txt",
      'coverUrl':
          "https://www.gutenberg.org/cache/epub/11640/pg11640.cover.medium.jpg",
      'audioUrls': <String>[
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_01_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_02_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_03_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_04_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_05_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_06_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_07_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_08_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_09_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_10_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_11_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_12_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_13_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_14_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_15_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_16_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_17_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_18_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_19_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_20_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_21_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_22_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_23_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_24_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_25_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_26_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_27_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_28_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_29_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_30_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_31_wells_64kb.mp3",
        "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_32_wells_64kb.mp3"
      ],
      'audioUrl':
          "https://www.archive.org/download/love_and_mr_lewisham_ao_1410_librivox/loveandmrlewisham_01_wells_64kb.mp3",
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
