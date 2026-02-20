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
        "Tap the '+' button on the home screen to start a new entry. You can then add a title, select your mood, write your thoughts, and customize with stickers, images, and background colors.",
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
        "While editing an entry, tap the 'Sticker' button in the bottom toolbar. Choose a sticker from the picker, and it will appear on your entry. You can then drag, resize, or delete it.",
    icon: Icons.emoji_emotions_outlined,
  ),
  FAQItem(
    question: "Can I add photos to my diary entries?",
    answer:
        "Yes! Tap the 'Photo' button in the bottom toolbar to select an image from your gallery. The image will be placed on your entry and can be moved, scaled, or removed.",
    icon: Icons.photo,
  ),
  FAQItem(
    question: "How do I change the background color of an entry?",
    answer:
        "Tap the 'BG Color' button in the bottom toolbar to open a color picker. Choose any color to set as the background for your current entry.",
    icon: Icons.palette,
  ),
  FAQItem(
    question: "Can I use an image as the background?",
    answer:
        "Yes, tap the 'BG Image' button to select an image from your gallery. It will be set as the background for your entry.",
    icon: Icons.image,
  ),
  FAQItem(
    question: "How do I edit or delete an existing entry?",
    answer:
        "On the home screen, tap any entry to open its preview. From there, use the edit (pen) icon to modify the entry, or the delete (trash) icon to remove it permanently.",
    icon: Icons.edit,
  ),
  FAQItem(
    question: "How do I search for specific diary entries?",
    answer:
        "Use the search bar on the home screen to find entries by title, content, or date. You can also filter by mood or date range.",
    icon: Icons.search,
  ),
  FAQItem(
    question: "Is my diary data private and secure?",
    answer:
        "All your diary entries are stored locally on your device. We do not collect or upload any personal data. For additional security, you can enable app lock or biometric authentication in settings.",
    icon: Icons.lock,
  ),
  FAQItem(
    question: "How do I back up my diary entries?",
    answer:
        "Currently, entries are stored locally. You can enable cloud backup in settings (if available) or manually export your entries as a file.",
    icon: Icons.backup,
  ),
  FAQItem(
    question: "Can I set reminders to write in my diary?",
    answer:
        "Yes, you can set daily reminders from the settings screen. Choose a time and you'll receive a notification to write your entry.",
    icon: Icons.notifications,
  ),
  FAQItem(
    question: "How do I change the date of an entry?",
    answer:
        "When creating or editing an entry, tap on the date selector at the top to open a date picker. Select any date you want to associate with the entry.",
    icon: Icons.calendar_today,
  ),
  FAQItem(
    question: "What are stickers and how do I resize them?",
    answer:
        "Stickers are fun emojis or graphics you can place anywhere on your entry. To resize, select the sticker (it will be highlighted) and use pinch‑to‑zoom gestures. You can also tap and hold to open a menu with resize options.",
    icon: Icons.emoji_emotions,
  ),
  FAQItem(
    question: "Can I add bullet points to my diary text?",
    answer:
        "Yes, tap the 'Bullet' button in the bottom toolbar to insert a bullet point at the cursor position. This helps organize your thoughts.",
    icon: Icons.format_list_bulleted,
  ),
  FAQItem(
    question: "How do I view all entries for a specific month?",
    answer:
        "On the home screen, you can switch to calendar view or use the month selector to navigate between months. Tap on a date to see entries for that day.",
    icon: Icons.calendar_month,
  ),
];