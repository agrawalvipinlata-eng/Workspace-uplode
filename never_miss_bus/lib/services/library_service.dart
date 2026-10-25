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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Through+the+Looking-Glass',
      'audioUrl':
          'https://librivox.org/search/?q=Through+the+Looking-Glass&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Through+the+Looking-Glass',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Peter+Pan',
      'audioUrl':
          'https://librivox.org/search/?q=Peter+Pan&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Peter+Pan',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Paradise+Lost',
      'audioUrl':
          'https://librivox.org/search/?q=Paradise+Lost&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Paradise+Lost',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Time+Machine',
      'audioUrl':
          'https://librivox.org/search/?q=The+Time+Machine&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Time+Machine',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Strange+Case+of+Dr.+Jekyll+and+Mr.+Hyde',
      'audioUrl':
          'https://librivox.org/search/?q=The+Strange+Case+of+Dr.+Jekyll+and+Mr.+Hyde&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Strange+Case+of+Dr.+Jekyll+and+Mr.+Hyde',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Anne+of+Green+Gables',
      'audioUrl':
          'https://librivox.org/search/?q=Anne+of+Green+Gables&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Anne+of+Green+Gables',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=A+Christmas+Carol',
      'audioUrl':
          'https://librivox.org/search/?q=A+Christmas+Carol&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=A+Christmas+Carol',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wonderful+Wizard+of+Oz',
      'audioUrl':
          'https://librivox.org/search/?q=The+Wonderful+Wizard+of+Oz&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wonderful+Wizard+of+Oz',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Complete+Works+of+William+Shakespeare',
      'audioUrl':
          'https://librivox.org/search/?q=The+Complete+Works+of+William+Shakespeare&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Complete+Works+of+William+Shakespeare',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Count+of+Monte+Cristo',
      'audioUrl':
          'https://librivox.org/search/?q=The+Count+of+Monte+Cristo&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Count+of+Monte+Cristo',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Treasure+Island',
      'audioUrl':
          'https://librivox.org/search/?q=Treasure+Island&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Treasure+Island',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Jane+Eyre',
      'audioUrl':
          'https://librivox.org/search/?q=Jane+Eyre&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Jane+Eyre',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Jungle+Book',
      'audioUrl':
          'https://librivox.org/search/?q=The+Jungle+Book&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Jungle+Book',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Call+of+the+Wild',
      'audioUrl':
          'https://librivox.org/search/?q=The+Call+of+the+Wild&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Call+of+the+Wild',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Return+of+Sherlock+Holmes',
      'audioUrl':
          'https://librivox.org/search/?q=The+Return+of+Sherlock+Holmes&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Return+of+Sherlock+Holmes',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=A+Study+in+Scarlet',
      'audioUrl':
          'https://librivox.org/search/?q=A+Study+in+Scarlet&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=A+Study+in+Scarlet',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Little+Women',
      'audioUrl':
          'https://librivox.org/search/?q=Little+Women&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Little+Women',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Notes+from+the+Underground',
      'audioUrl':
          'https://librivox.org/search/?q=Notes+from+the+Underground&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Notes+from+the+Underground',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Secret+Garden',
      'audioUrl':
          'https://librivox.org/search/?q=The+Secret+Garden&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Secret+Garden',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wind+in+the+Willows',
      'audioUrl':
          'https://librivox.org/search/?q=The+Wind+in+the+Willows&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wind+in+the+Willows',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Three+Musketeers',
      'audioUrl':
          'https://librivox.org/search/?q=The+Three+Musketeers&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Three+Musketeers',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Odyssey',
      'audioUrl':
          'https://librivox.org/search/?q=The+Odyssey&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Odyssey',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Iliad',
      'audioUrl':
          'https://librivox.org/search/?q=The+Iliad&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Iliad',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Republic',
      'audioUrl':
          'https://librivox.org/search/?q=The+Republic&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Republic',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Art+of+War',
      'audioUrl':
          'https://librivox.org/search/?q=The+Art+of+War&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Art+of+War',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Prince',
      'audioUrl':
          'https://librivox.org/search/?q=The+Prince&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Prince',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Divine+Comedy',
      'audioUrl':
          'https://librivox.org/search/?q=The+Divine+Comedy&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Divine+Comedy',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Don+Quixote',
      'audioUrl':
          'https://librivox.org/search/?q=Don+Quixote&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Don+Quixote',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=War+and+Peace',
      'audioUrl':
          'https://librivox.org/search/?q=War+and+Peace&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=War+and+Peace',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Anna+Karenina',
      'audioUrl':
          'https://librivox.org/search/?q=Anna+Karenina&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Anna+Karenina',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Crime+and+Punishment',
      'audioUrl':
          'https://librivox.org/search/?q=Crime+and+Punishment&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Crime+and+Punishment',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Brothers+Karamazov',
      'audioUrl':
          'https://librivox.org/search/?q=The+Brothers+Karamazov&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Brothers+Karamazov',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Idiot',
      'audioUrl':
          'https://librivox.org/search/?q=The+Idiot&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Idiot',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Siddhartha',
      'audioUrl':
          'https://librivox.org/search/?q=Siddhartha&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Siddhartha',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Prophet',
      'audioUrl':
          'https://librivox.org/search/?q=The+Prophet&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Prophet',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Little+Prince',
      'audioUrl':
          'https://librivox.org/search/?q=The+Little+Prince&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Little+Prince',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Old+Man+and+the+Sea',
      'audioUrl':
          'https://librivox.org/search/?q=The+Old+Man+and+the+Sea&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Old+Man+and+the+Sea',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Picture+of+Dorian+Gray',
      'audioUrl':
          'https://librivox.org/search/?q=The+Picture+of+Dorian+Gray&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Picture+of+Dorian+Gray',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Importance+of+Being+Earnest',
      'audioUrl':
          'https://librivox.org/search/?q=The+Importance+of+Being+Earnest&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Importance+of+Being+Earnest',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Happy+Prince',
      'audioUrl':
          'https://librivox.org/search/?q=The+Happy+Prince&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Happy+Prince',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Canterville+Ghost',
      'audioUrl':
          'https://librivox.org/search/?q=The+Canterville+Ghost&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Canterville+Ghost',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Wuthering+Heights',
      'audioUrl':
          'https://librivox.org/search/?q=Wuthering+Heights&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Wuthering+Heights',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Tenant+of+Wildfell+Hall',
      'audioUrl':
          'https://librivox.org/search/?q=The+Tenant+of+Wildfell+Hall&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Tenant+of+Wildfell+Hall',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Middlemarch',
      'audioUrl':
          'https://librivox.org/search/?q=Middlemarch&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Middlemarch',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Silas+Marner',
      'audioUrl':
          'https://librivox.org/search/?q=Silas+Marner&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Silas+Marner',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Mill+on+the+Floss',
      'audioUrl':
          'https://librivox.org/search/?q=The+Mill+on+the+Floss&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Mill+on+the+Floss',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Northanger+Abbey',
      'audioUrl':
          'https://librivox.org/search/?q=Northanger+Abbey&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Northanger+Abbey',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Sense+and+Sensibility',
      'audioUrl':
          'https://librivox.org/search/?q=Sense+and+Sensibility&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Sense+and+Sensibility',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Emma',
      'audioUrl': 'https://librivox.org/search/?q=Emma&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Emma',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Mansfield+Park',
      'audioUrl':
          'https://librivox.org/search/?q=Mansfield+Park&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Mansfield+Park',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Persuasion',
      'audioUrl':
          'https://librivox.org/search/?q=Persuasion&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Persuasion',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Mayor+of+Casterbridge',
      'audioUrl':
          'https://librivox.org/search/?q=The+Mayor+of+Casterbridge&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Mayor+of+Casterbridge',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Tess+of+the+d%27Urbervilles',
      'audioUrl':
          'https://librivox.org/search/?q=Tess+of+the+d%27Urbervilles&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Tess+of+the+d%27Urbervilles',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Far+from+the+Madding+Crowd',
      'audioUrl':
          'https://librivox.org/search/?q=Far+from+the+Madding+Crowd&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Far+from+the+Madding+Crowd',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Scarlet+Letter',
      'audioUrl':
          'https://librivox.org/search/?q=The+Scarlet+Letter&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Scarlet+Letter',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+House+of+the+Seven+Gables',
      'audioUrl':
          'https://librivox.org/search/?q=The+House+of+the+Seven+Gables&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+House+of+the+Seven+Gables',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Last+of+the+Mohicans',
      'audioUrl':
          'https://librivox.org/search/?q=The+Last+of+the+Mohicans&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Last+of+the+Mohicans',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Deerslayer',
      'audioUrl':
          'https://librivox.org/search/?q=The+Deerslayer&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Deerslayer',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Robinson+Crusoe',
      'audioUrl':
          'https://librivox.org/search/?q=Robinson+Crusoe&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Robinson+Crusoe',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Gulliver%27s+Travels',
      'audioUrl':
          'https://librivox.org/search/?q=Gulliver%27s+Travels&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Gulliver%27s+Travels',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Pilgrim%27s+Progress',
      'audioUrl':
          'https://librivox.org/search/?q=The+Pilgrim%27s+Progress&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Pilgrim%27s+Progress',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Invisible+Man',
      'audioUrl':
          'https://librivox.org/search/?q=The+Invisible+Man&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Invisible+Man',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+First+Men+in+the+Moon',
      'audioUrl':
          'https://librivox.org/search/?q=The+First+Men+in+the+Moon&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+First+Men+in+the+Moon',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Island+of+Doctor+Moreau',
      'audioUrl':
          'https://librivox.org/search/?q=The+Island+of+Doctor+Moreau&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Island+of+Doctor+Moreau',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Lost+World',
      'audioUrl':
          'https://librivox.org/search/?q=The+Lost+World&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Lost+World',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Moonstone',
      'audioUrl':
          'https://librivox.org/search/?q=The+Moonstone&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Moonstone',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Woman+in+White',
      'audioUrl':
          'https://librivox.org/search/?q=The+Woman+in+White&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Woman+in+White',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Thirty-Nine+Steps',
      'audioUrl':
          'https://librivox.org/search/?q=The+Thirty-Nine+Steps&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Thirty-Nine+Steps',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Hound+of+the+Baskervilles',
      'audioUrl':
          'https://librivox.org/search/?q=The+Hound+of+the+Baskervilles&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Hound+of+the+Baskervilles',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Sign+of+the+Four',
      'audioUrl':
          'https://librivox.org/search/?q=The+Sign+of+the+Four&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Sign+of+the+Four',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Moon',
      'audioUrl':
          'https://librivox.org/search/?q=The+Moon&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Moon',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=The+Last+Man',
      'audioUrl':
          'https://librivox.org/search/?q=The+Last+Man&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Last+Man',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Scarlet+Pimpernel',
      'audioUrl':
          'https://librivox.org/search/?q=The+Scarlet+Pimpernel&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Scarlet+Pimpernel',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Prisoner+of+Zenda',
      'audioUrl':
          'https://librivox.org/search/?q=The+Prisoner+of+Zenda&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Prisoner+of+Zenda',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Three+Men+in+a+Boat',
      'audioUrl':
          'https://librivox.org/search/?q=The+Three+Men+in+a+Boat&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Three+Men+in+a+Boat',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Pickwick+Papers',
      'audioUrl':
          'https://librivox.org/search/?q=The+Pickwick+Papers&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Pickwick+Papers',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=David+Copperfield',
      'audioUrl':
          'https://librivox.org/search/?q=David+Copperfield&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=David+Copperfield',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Great+Expectations',
      'audioUrl':
          'https://librivox.org/search/?q=Great+Expectations&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Great+Expectations',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Oliver+Twist',
      'audioUrl':
          'https://librivox.org/search/?q=Oliver+Twist&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Oliver+Twist',
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
      'coverUrl': '',
      'pdfUrl': 'https://www.gutenberg.org/ebooks/search/?query=Hard+Times',
      'audioUrl':
          'https://librivox.org/search/?q=Hard+Times&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl': 'https://www.gutenberg.org/ebooks/search/?query=Hard+Times',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Old+Curiosity+Shop',
      'audioUrl':
          'https://librivox.org/search/?q=The+Old+Curiosity+Shop&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Old+Curiosity+Shop',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Aesop%27s+Fables',
      'audioUrl':
          'https://librivox.org/search/?q=Aesop%27s+Fables&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Aesop%27s+Fables',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Grimm%27s+Fairy+Tales',
      'audioUrl':
          'https://librivox.org/search/?q=Grimm%27s+Fairy+Tales&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Grimm%27s+Fairy+Tales',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Arabian+Nights',
      'audioUrl':
          'https://librivox.org/search/?q=The+Arabian+Nights&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Arabian+Nights',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Adventures+of+Tom+Sawyer',
      'audioUrl':
          'https://librivox.org/search/?q=The+Adventures+of+Tom+Sawyer&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Adventures+of+Tom+Sawyer',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Adventures+of+Huckleberry+Finn',
      'audioUrl':
          'https://librivox.org/search/?q=Adventures+of+Huckleberry+Finn&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=Adventures+of+Huckleberry+Finn',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Prince+and+the+Pauper',
      'audioUrl':
          'https://librivox.org/search/?q=The+Prince+and+the+Pauper&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Prince+and+the+Pauper',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Adventures+of+Pinocchio',
      'audioUrl':
          'https://librivox.org/search/?q=The+Adventures+of+Pinocchio&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Adventures+of+Pinocchio',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wonderful+Adventures+of+Nils',
      'audioUrl':
          'https://librivox.org/search/?q=The+Wonderful+Adventures+of+Nils&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Wonderful+Adventures+of+Nils',
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
      'coverUrl': '',
      'pdfUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Secret+Agent',
      'audioUrl':
          'https://librivox.org/search/?q=The+Secret+Agent&search_form=advanced',
      'licenseType': 'PUBLIC_DOMAIN_DEMO',
      'licenseUrl': 'https://www.gutenberg.org/policy/terms_of_use.html',
      'sourceUrl':
          'https://www.gutenberg.org/ebooks/search/?query=The+Secret+Agent',
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
