import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void showSearchDialog() {
      showSearch(
        context: context,
        delegate: FAQSearchDelegate(faqs: faqs),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FAQ',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => showSearchDialog(),
            icon: Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          itemCount: faqs.length,
          itemBuilder: (context, index) {
            return FAQExpansionTile(faq: faqs[index]);
          },
        ),
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;
  final IconData icon;

  FAQItem({required this.question, required this.answer, required this.icon});
}

class FAQExpansionTile extends StatefulWidget {
  final FAQItem faq;

  const FAQExpansionTile({super.key, required this.faq});

  @override
  State<FAQExpansionTile> createState() => _FAQExpansionTileState();
}

class _FAQExpansionTileState extends State<FAQExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white10
          : null,
      elevation: 1,
      child: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Icon(widget.faq.icon, color: Theme.of(context).primaryColor),
          title: Text(
            widget.faq.question,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Theme.of(context).primaryColor,
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                widget.faq.answer,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQSearchDelegate extends SearchDelegate<String> {
  final List<FAQItem> faqs;

  FAQSearchDelegate({required this.faqs});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final List<FAQItem> results = faqs
        .where(
          (faq) =>
              faq.question.toLowerCase().contains(query.toLowerCase()) ||
              faq.answer.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(results[index].icon),
          title: Text(results[index].question),
          subtitle: Text(
            results[index].answer,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(results[index].question),
                content: Text(results[index].answer),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<FAQItem> suggestions = faqs
        .where(
          (faq) => faq.question.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(suggestions[index].icon),
          title: Text(suggestions[index].question),
          onTap: () {
            query = suggestions[index].question;
            showResults(context);
          },
        );
      },
    );
  }
}

// Diary‑specific FAQ items
final List<FAQItem> faqs = [
  FAQItem(
    question: "What is a Diary Entry?",
    answer:
        "A diary entry is a personal record of your thoughts, feelings, and experiences for a specific day. You can add a title, mood, description, stickers, and images to make each entry unique.",
    icon: Icons.menu_book,
  ),
  FAQItem(
    question: "How do I create a new diary entry?",
    answer:
        "Tap the '+' button on the home screen or in the calendar view to start a new entry. You can then add a title, select your mood, write your thoughts, and customize with stickers, images, and background colors.",
    icon: Icons.add_circle,
  ),
  FAQItem(
    question: "How can I add my mood to an entry?",
    answer:
        "On the entry screen, tap the mood emoji (default is 😊) to open an emoji picker. Select the emoji that best represents your mood for that day.",
    icon: Icons.emoji_emotions,
  ),
  FAQItem(
    question: "How do I add stickers to my diary entry?",
    answer:
        "While editing an entry, tap the 'Add Sticker' button (✨ icon) in the bottom toolbar. Choose a sticker from the picker, and it will appear on your entry. You can add up to 10 stickers per entry. You can then drag, resize with pinch gestures, or delete it by tapping and using the remove button.",
    icon: Icons.auto_awesome_outlined,
  ),
  FAQItem(
    question: "Can I add photos to my diary entries?",
    answer:
        "Yes! Tap the 'Add Sticker photo' button (📷 icon) in the bottom toolbar to select an image from your gallery. The image will be placed on your entry and can be moved, scaled, or removed. You can add up to 5 images per entry.",
    icon: Icons.photo_outlined,
  ),
  FAQItem(
    question: "How do I change the background color of an entry?",
    answer:
        "Tap the 'Background Color' button (🎨 icon) in the bottom toolbar to open a color picker. Choose any color to set as the background for your current entry.",
    icon: Icons.palette_outlined,
  ),
  FAQItem(
    question: "How do I change the background image?",
    answer:
        "Tap the 'Change Background' button (layers icon) in the bottom toolbar. You can choose from preset backgrounds (downloadable online) or select an image from your gallery. The 'Clear Background' button removes any background color or image.",
    icon: Icons.layers_outlined,
  ),
  FAQItem(
    question: "How do I edit or delete an existing entry?",
    answer:
        "On the home screen or calendar view, tap any entry to open its preview. From there, use the edit (pen) icon to modify the entry, or the delete (trash) icon to remove it permanently.",
    icon: Icons.edit,
  ),
  FAQItem(
    question: "How do I search for specific diary entries?",
    answer:
        "Use the search bar on the home screen to find entries by title, content, or date. You can also use the calendar view to browse entries by date.",
    icon: Icons.search,
  ),
  FAQItem(
    question: "Is my diary data private and secure?",
    answer:
        "All your diary entries are stored locally on your device. We do not collect or upload any personal data. You can also enable app lock with PIN, device lock, or security question for additional security.",
    icon: Icons.lock,
  ),
  FAQItem(
    question: "How do I change the date of an entry?",
    answer:
        "When creating or editing an entry, tap on the date selector at the top (showing day, month, year) to open a date picker. Select any date you want to associate with the entry.",
    icon: Icons.calendar_today,
  ),
  FAQItem(
    question: "What are stickers and how do I resize them?",
    answer:
        "Stickers are fun graphics you can place anywhere on your entry. To resize, select the sticker (it will show a dashed border) and use pinch‑to‑zoom gestures. A remove button (red X) appears on selected stickers for easy deletion.",
    icon: Icons.auto_awesome_outlined,
  ),
  FAQItem(
    question: "Can I add bullet points to my diary text?",
    answer:
        "Yes, tap the 'Add Bullet' button (📋 icon) in the bottom toolbar to insert a bullet point at the cursor position. This helps organize your thoughts and create lists.",
    icon: Icons.format_list_bulleted,
  ),
  FAQItem(
    question: "How do I view all entries using the calendar?",
    answer:
        "Tap the calendar icon from the home screen to open the Memory Timeline view. You'll see a monthly calendar with dots indicating days that have entries. Tap any date to view entries for that day.",
    icon: Icons.calendar_month,
  ),
  
  // APP LOCK FEATURES (Based on your actual implementation)
  FAQItem(
    question: "How do I lock my diary with a PIN?",
    answer:
        "Go to Settings → Diary Lock. Select 'PIN Lock' and create a 4-digit PIN. You'll need to confirm it by entering it twice. Once enabled, you'll be asked to enter this PIN every time you open the app.",
    icon: Icons.pin_outlined,
  ),
  FAQItem(
    question: "Can I use my device's screen lock (fingerprint/face) to secure the app?",
    answer:
        "Yes! In Settings → Diary Lock, select 'Mobile Lock'. This will use your device's existing biometric authentication (fingerprint, face unlock) or pattern/password to secure the app. This option only appears if your device already has a screen lock set up.",
    icon: Icons.fingerprint,
  ),
  FAQItem(
    question: "How do I set up a security question lock?",
    answer:
        "Go to Settings → Diary Lock and select 'Security Question Lock'. You'll create a custom question (e.g., 'What is your favorite color?') and provide an answer. This serves as an alternative way to unlock your app.",
    icon: Icons.question_answer_outlined,
  ),
  FAQItem(
    question: "What if I forget my PIN?",
    answer:
        "On the PIN entry screen, tap the 'Forgot?' button. If your device supports biometric authentication, you'll be prompted to use your device's screen lock (fingerprint/face/pattern) to verify your identity and can then set a new PIN.",
    icon: Icons.help_outline,
  ),
  FAQItem(
    question: "What if I forget my security question answer?",
    answer:
        "On the security question verification screen, tap the 'Forgot?' button. If your device supports biometric authentication, you'll be prompted to use your device's screen lock to verify your identity and can then set up a new security question.",
    icon: Icons.security_update_warning,
  ),
  FAQItem(
    question: "Why can't I enable Mobile Lock?",
    answer:
        "Mobile Lock requires your device to have a screen lock (pattern, PIN, password, or biometrics) already set up. Please go to your device Settings → Security → Screen Lock to set one up first, then return to the app to enable this feature.",
    icon: Icons.smartphone,
  ),
  FAQItem(
    question: "Can I change my lock type after setting it?",
    answer:
        "Yes! Go to Settings → Diary Lock and simply select a different lock option. You'll be guided through setting up the new lock type. The previous lock settings will be replaced.",
    icon: Icons.switch_access_shortcut,
  ),
  FAQItem(
    question: "How do I disable the app lock completely?",
    answer:
        "Go to Settings → Diary Lock and select 'No Lock'. The app will immediately disable all lock protection.",
    icon: Icons.lock_open_outlined,
  ),
  
  // INTERNET & DOWNLOAD FEATURES
  FAQItem(
    question: "Does the app need internet connection?",
    answer:
        "An internet connection is required only when downloading new background presets and sticker packs from our online collection. You can browse and download these from the sticker picker or background image picker. Once downloaded, they are stored locally and can be used offline. Your diary entries always remain on your device.",
    icon: Icons.wifi,
  ),
  FAQItem(
    question: "How do I download new background presets?",
    answer:
        "Tap the 'Change Background' button in the bottom toolbar, then select from the available preset backgrounds. If a preset isn't downloaded yet, it will download automatically when selected. Downloaded presets are saved locally for offline use.",
    icon: Icons.layers_outlined,
  ),
  FAQItem(
    question: "How do I download new sticker packs?",
    answer:
        "Tap the 'Add Sticker' button (✨ icon) in the bottom toolbar to open the sticker picker. Browse available stickers - they will download automatically when you select them. Downloaded stickers are cached locally for future use without internet.",
    icon: Icons.auto_awesome_outlined,
  ),
  FAQItem(
    question: "Are my downloaded stickers and backgrounds stored online?",
    answer:
        "No. All downloaded content is stored locally on your device. Your diary entries, downloaded stickers, and background presets remain on your device and are not uploaded to any server. The online content is only for downloading new items.",
    icon: Icons.sd_storage,
  ),
  FAQItem(
    question: "What happens if I select a sticker or background without internet?",
    answer:
        "If you've previously downloaded a sticker or background preset, it will work offline. For new items you haven't downloaded before, you'll need an internet connection to download them first. After download, they're available offline.",
    icon: Icons.offline_bolt,
  ),
  
  // CALENDAR/TIMELINE FEATURES (Based on your DiaryCalendarScreen)
  FAQItem(
    question: "What is the Memory Timeline?",
    answer:
        "The Memory Timeline is a calendar view that helps you visually browse your diary entries by date. Days with entries are marked with a dot. You can navigate between months and tap any date to see all entries for that day.",
    icon: Icons.timeline,
  ),
  FAQItem(
    question: "How do I access the calendar view?",
    answer:
        "Tap the calendar icon on the home screen to open the Memory Timeline. From there you can see a full monthly calendar with your entry history.",
    icon: Icons.calendar_view_month,
  ),
  FAQItem(
    question: "How can I tell which days have entries?",
    answer:
        "In the calendar view, days that have diary entries are marked with a small colored dot below the date. The dot color matches your app's theme color.",
    icon: Icons.circle,
  ),
  FAQItem(
    question: "Can I see all entries for a specific date?",
    answer:
        "Yes! Tap any date in the calendar view. Below the calendar, you'll see a list of all entries for that selected date, showing their title, mood, and preview.",
    icon: Icons.list_alt,
  ),
  FAQItem(
    question: "How do I navigate between months in the calendar?",
    answer:
        "Use the left and right chevron arrows (‹ ›) at the top of the calendar to move between months. The current month and year are displayed in the center.",
    icon: Icons.chevron_left,
  ),
  FAQItem(
    question: "Can I create a new entry directly from the calendar?",
    answer:
        "Yes! The floating action button (+) in the calendar view lets you create a new entry from any screen.",
    icon: Icons.add,
  ),
  
  // SETTINGS & THEME FEATURES
  FAQItem(
    question: "How do I change the app theme?",
    answer:
        "Go to Settings → Theme. You can choose between Light mode, Dark mode, or follow your system settings. The app also supports various font options for your diary entries.",
    icon: Icons.brightness_medium,
  ),
  FAQItem(
    question: "How do I change the font in my diary?",
    answer:
        "While editing an entry, tap the 'Change Font' button (Aa icon with sparkles) in the bottom toolbar. You can choose from several available fonts including Quicksand, Caveat, Cormorant Garamond, Dancing Script, Playfair Display, AmaticSC, Goldman, and ShadowsIntoLight.",
    icon: Icons.text_fields_rounded,
  ),
  FAQItem(
    question: "Where can I find all lock settings?",
    answer:
        "All security and lock settings are located in Settings → Diary Lock. From there you can enable PIN lock, Mobile Lock (biometric/device), or Security Question lock.",
    icon: Icons.lock,
  ),
  
  // SUPPORT FEATURES
  FAQItem(
    question: "How do I contact the developer for support?",
    answer:
        "If you encounter any issues or have suggestions, go to Settings → Support. You can connect with the developer directly from there for assistance, bug reports, or feature requests.",
    icon: Icons.support_agent,
  ),
  FAQItem(
    question: "I found a bug. How do I report it?",
    answer:
        "We're sorry you're experiencing issues! Please go to Settings → Support and use the contact option to report the bug. Include details about what happened, and if possible, steps to reproduce the issue. This helps us fix it faster.",
    icon: Icons.bug_report,
  ),
  FAQItem(
    question: "Can I request new features or sticker packs?",
    answer:
        "Absolutely! We love hearing from our users. Visit Settings → Support to send us your ideas for new stickers, backgrounds, fonts, or app improvements.",
    icon: Icons.lightbulb,
  ),
  
  // ADDITIONAL LIMITS & FEATURES
  FAQItem(
    question: "How many stickers can I add to an entry?",
    answer:
        "You can add up to 10 stickers per diary entry. If you try to add more, you'll see a notification letting you know you've reached the limit.",
    icon: Icons.auto_awesome_outlined,
  ),
  FAQItem(
    question: "How many images can I add to an entry?",
    answer:
        "You can add up to 5 images per diary entry. The app will notify you if you try to exceed this limit.",
    icon: Icons.photo_outlined,
  ),
  FAQItem(
    question: "How do I resize images in my entry?",
    answer:
        "Select an image (it will show a dashed border), then use pinch-to-zoom gestures to resize. A remove button (red X) appears on selected images for easy deletion.",
    icon: Icons.photo_size_select_actual,
  ),
  FAQItem(
    question: "What happens if I delete a background image from my gallery?",
    answer:
        "If you've used a gallery image as a background and later delete it from your device, the app will automatically clear that background to prevent errors. You can always set a new background afterward.",
    icon: Icons.warning_amber,
  ),
  FAQItem(
    question: "What is the maximum title length?",
    answer:
        "Diary entry titles are limited to 50 characters to keep them concise and readable.",
    icon: Icons.title,
  ),
];

// FAQItem(
  //   question: "How do I back up my diary entries?",
  //   answer:
  //       "Currently, entries are stored locally. You can enable cloud backup in settings (if available) or manually export your entries as a file.",
  //   icon: Icons.backup,
  // ),
  // FAQItem(
  //   question: "Can I set reminders to write in my diary?",
  //   answer:
  //       "Yes, you can set daily reminders from the settings screen. Choose a time and you'll receive a notification to write your entry.",
  //   icon: Icons.notifications,
  // ),