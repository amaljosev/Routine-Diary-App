import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:routine/core/version/app_version.dart';
import 'package:routine/features/settings/presentation/pages/contact_us.dart';
import 'package:routine/features/settings/presentation/pages/help_screen.dart';
import 'package:routine/features/settings/presentation/pages/home_bg_update.dart';
import 'package:routine/features/settings/presentation/pages/theme/theme_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            /// Top Logo + Title
            SliverToBoxAdapter(
              child: Column(
                spacing: 20,
                children: [
                  Image.asset(
                    'assets/icons/routine_icon.png',
                    height: 80,
                    width: 80,
                  ),

                  Text(
                    'Routine: Diary App',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            /// Main List Section
            SliverList(
              delegate: SliverChildListDelegate([
                CupertinoListSection.insetGrouped(
                  header: const Text('Settings'),
                  children: [
                    ListTile(
                      leading: const Icon(CupertinoIcons.photo),
                      title: const Text('Update Home Background'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      onTap: ()  => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HomeBgUpdate(),
                        ),
                      ),
                    ),
                     ListTile(
                      leading: const Icon(Icons.color_lens_outlined),
                      title: const Text('Theme'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      onTap: ()  => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>  ThemeSwitcherScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                /// APP INFORMATION
                CupertinoListSection.insetGrouped(
                  header: const Text('App'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.support_agent),
                      title: const Text('Help'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => HelpScreen()),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.shield_outlined),
                      title: const Text('Privacy Policy'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      // onTap: () async => await _lunchPrivacyPolicy(context),
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        splashFactory: NoSplash.splashFactory,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(
                          'About this app',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        trailing: const CupertinoListTileChevron(),
                        childrenPadding: const EdgeInsets.all(12),
                        children: [_buildAboutContent(context)],
                      ),
                    ),
                  ],
                ),

                /// ENGAGEMENT
                // CupertinoListSection.insetGrouped(
                //   header: const Text('Engagement'),
                //   children: [
                //     ListTile(
                //       leading: const Icon(Icons.share_outlined),
                //       title: const Text('Share'),
                //       titleTextStyle: Theme.of(context).textTheme.titleSmall,
                //       trailing: const CupertinoListTileChevron(),
                //       onTap: () async {
                //         await ShareUtils.shareApp();
                //       },
                //     ),
                //     ListTile(
                //       leading: const Icon(Icons.star_border),
                //       title: const Text('Rate app'),
                //       titleTextStyle: Theme.of(context).textTheme.titleSmall,
                //       trailing: const CupertinoListTileChevron(),
                //       onTap: () async => await _rateApp(context),
                //     ),
                //   ],
                // ),

                /// SUPPORT
                CupertinoListSection.insetGrouped(
                  header: const Text('Support'),
                  children: [
                    ListTile(
                      leading: const Icon(CupertinoIcons.mail),
                      title: const Text('Contact us'),
                      titleTextStyle: Theme.of(context).textTheme.titleSmall,
                      trailing: const CupertinoListTileChevron(),
                      onTap: () async => showModernSupportSheet(context),
                    ),
                  ],
                ),
              ]),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Routine: Diary App',
          style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Text('''
Routine is a simple and private diary application designed to help you capture your daily thoughts, experiences, and reflections in one secure place.

With a clean and distraction-free interface, Routine makes journaling easy and consistent. Whether you want to record memories, track personal growth, or simply express your thoughts, Routine helps you build a meaningful daily writing habit.

Write daily. Reflect deeply. Grow consistently.
''', style: textTheme.bodyMedium),

        const SizedBox(height: 16),

        Text('Version: ${AppVersion.version}', style: textTheme.bodyMedium),

        const SizedBox(height: 12),

        Text('Developed by Amal Jose', style: textTheme.bodyMedium),
      ],
    );
  }

  // Future<void> _lunchPrivacyPolicy(BuildContext context) async {
  //   final Uri _url = Uri.parse(
  //     'https://amaljosev.github.io/Pursuit-Privacy-Policy/',
  //   );
  //   if (!await launchUrl(_url, mode: LaunchMode.inAppBrowserView)) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Sorry we are facing an issue')));
  //   }
  // }

  // Future<void> _rateApp(BuildContext context) async {
  //   final Uri _url = Uri.parse(AppConstants.playStoreUrl);
  //   if (!await launchUrl(_url, mode: LaunchMode.platformDefault)) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Sorry we are facing an issue')));
  //   }
  // }

  void showModernSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return const ContactUsSheet();
      },
    );
  }
}
