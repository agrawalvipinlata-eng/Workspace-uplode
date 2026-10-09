import 'package:flutter/material.dart';

import '../../core/constants/app_language.dart';
import '../../core/constants/nmb_constants.dart';
import '../../core/theme/nmb_colors.dart';
import '../../core/theme/nmb_typography.dart';
import '../../core/widgets/nmb_card.dart';

/// 🛡️ PRIVACY POLICY — Play Store requirement. In-app version;
/// web version bhi hosted honi chahiye (Play Console me URL dena hota hai).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Privacy Policy', 'गोपनीयता नीति')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          NmbCard(
            color: NmbColors.infoSoft,
            child: Row(
              children: <Widget>[
                const Icon(Icons.verified_user_rounded,
                    color: NmbColors.info,),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr(
                      'Your data is safe. This app is made only for '
                      '${NmbConstants.schoolName} students, parents and staff.',
                      'आपका डेटा सुरक्षित है। यह ऐप केवल '
                      '${NmbConstants.schoolName} के छात्रों, अभिभावकों '
                      'और स्टाफ के लिए है।',
                    ),
                    style: NmbTypography.bodySecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _section(
            tr('1. What data we collect', '1. हम कौन सा डेटा लेते हैं'),
            tr(
              '• Student name, class, section, roll number (given by school)\n'
              '• Parent contact number and address (school records)\n'
              '• Profile photo (only if you choose to add one)\n'
              '• Bus location (ONLY the driver\'s phone shares GPS, '
              'and ONLY during an active trip)\n'
              '• Attendance and fee records (managed by school)',
              '• छात्र का नाम, कक्षा, सेक्शन, रोल नंबर (स्कूल द्वारा)\n'
              '• अभिभावक का फोन नंबर और पता (स्कूल रिकॉर्ड)\n'
              '• प्रोफ़ाइल फोटो (केवल अगर आप जोड़ें)\n'
              '• बस की लोकेशन (केवल ड्राइवर का फोन, केवल ट्रिप के दौरान)\n'
              '• उपस्थिति और फीस रिकॉर्ड (स्कूल द्वारा प्रबंधित)',
            ),
          ),
          _section(
            tr('2. What we DO NOT do', '2. हम क्या नहीं करते'),
            tr(
              '• We never sell or share your data with anyone\n'
              '• No advertisements in this app\n'
              '• Student phones are NEVER tracked — only the school '
              'bus is tracked\n'
              '• No data is sent outside the school\'s own Firebase '
              'account',
              '• हम आपका डेटा कभी नहीं बेचते या साझा नहीं करते\n'
              '• इस ऐप में कोई विज्ञापन नहीं है\n'
              '• छात्रों के फोन कभी ट्रैक नहीं होते — केवल स्कूल बस\n'
              '• डेटा स्कूल के अपने Firebase अकाउंट से बाहर नहीं जाता',
            ),
          ),
          _section(
            tr('3. Who can see your data', '3. आपका डेटा कौन देख सकता है'),
            tr(
              '• You: your own profile, attendance, fees, bus\n'
              '• Your class teacher: your class\'s attendance and details\n'
              '• School admin: all records (for school management)\n'
              '• Other students CANNOT see your personal details',
              '• आप: अपनी प्रोफ़ाइल, उपस्थिति, फीस, बस\n'
              '• क्लास टीचर: अपनी कक्षा की उपस्थिति और विवरण\n'
              '• स्कूल एडमिन: सभी रिकॉर्ड (स्कूल प्रबंधन हेतु)\n'
              '• दूसरे छात्र आपकी निजी जानकारी नहीं देख सकते',
            ),
          ),
          _section(
            tr('4. Security', '4. सुरक्षा'),
            tr(
              '• Every login is protected by password\n'
              '• Only one device can be logged in at a time\n'
              '• All data is protected by Firebase security rules\n'
              '• School can instantly block any account',
              '• हर लॉगिन पासवर्ड से सुरक्षित है\n'
              '• एक समय में केवल एक डिवाइस लॉगिन हो सकता है\n'
              '• सारा डेटा Firebase सुरक्षा नियमों से सुरक्षित है\n'
              '• स्कूल किसी भी अकाउंट को तुरंत ब्लॉक कर सकता है',
            ),
          ),
          _section(
            tr('5. Data deletion', '5. डेटा हटाना'),
            tr(
              'To delete your account and data, contact the school '
              'office. When a student leaves the school, the admin '
              'permanently deletes the account and all its data.',
              'अपना अकाउंट और डेटा हटाने के लिए स्कूल ऑफिस से संपर्क '
              'करें। छात्र के स्कूल छोड़ने पर एडमिन अकाउंट और पूरा डेटा '
              'स्थायी रूप से हटा देता है।',
            ),
          ),
          _section(
            tr('6. Children\'s privacy', '6. बच्चों की गोपनीयता'),
            tr(
              'This app is used by school students under teacher and '
              'parent supervision. Accounts are created ONLY by the '
              'school — children cannot sign up themselves. Parents '
              'can ask the school office to see or delete their '
              'child\'s data anytime.',
              'यह ऐप शिक्षक और अभिभावक की निगरानी में उपयोग होता है। '
              'अकाउंट केवल स्कूल बनाता है — बच्चे खुद साइन-अप नहीं कर '
              'सकते। अभिभावक कभी भी स्कूल ऑफिस से अपने बच्चे का डेटा '
              'देखने या हटाने को कह सकते हैं।',
            ),
          ),
          _section(
            tr('7. Contact', '7. संपर्क'),
            '${NmbConstants.schoolName}\nNauhjheel, Mathura (U.P.), India',
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              tr('Last updated: September 2026',
                  'अंतिम अपडेट: सितंबर 2026',),
              style: NmbTypography.caption,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NmbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: NmbTypography.sectionTitle),
            const SizedBox(height: 8),
            Text(body, style: NmbTypography.bodySecondary),
          ],
        ),
      ),
    );
  }
}
