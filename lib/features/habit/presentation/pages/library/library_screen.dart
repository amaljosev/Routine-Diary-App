// import 'package:consist/core/app_colors.dart';
// import 'package:consist/core/constants/habits_items.dart';
// import 'package:consist/features/habit/presentation/pages/create_habit/create_habit_screen.dart';
// import 'package:consist/features/habit/presentation/widgets/tab_slider.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// class LibraryScreen extends StatefulWidget {
//   const LibraryScreen({super.key});

//   @override
//   State<LibraryScreen> createState() => _LibraryScreenState();
// }

// class _LibraryScreenState extends State<LibraryScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final develop = HabitsItems.habitList
//         .where((h) => h['categoryId'] == '1')
//         .toList();
//     final quit = HabitsItems.habitList
//         .where((h) => h['categoryId'] == '2')
//         .toList();
//     final task = HabitsItems.habitList
//         .where((h) => h['categoryId'] == '3')
//         .toList();
//     return DefaultTabController(
//       length: 3,
//       child: NestedScrollView(
//         headerSliverBuilder: (context, innerBoxIsScrolled) => [
//           SliverAppBar(
//             expandedHeight: size.height * 0.25,
//             backgroundColor: Theme.of(context).colorScheme.surface,
//             flexibleSpace: FlexibleSpaceBar(
//               background: Stack(
//                 fit: StackFit.expand,
//                 alignment: Alignment.topCenter,
//                 children: [
//                   Image.asset(
//                     isDark
//                         ? 'assets/img/library_night.png'
//                         : 'assets/img/library.png',
//                     fit: BoxFit.cover,
//                   ),
//                   SafeArea(
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Library',
//                           style: Theme.of(context).textTheme.headlineLarge,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               expandedTitleScale: 1.0,
//               stretchModes: [StretchMode.zoomBackground],
//               title: TabSliderWidget(
//                 controller: _tabController,
//                 isDark: isDark,
//                 tab1: 'Develop',
//                 tab2: 'Quit',
//                 tab3: 'One-time',
//               ),
//             ),
//             pinned: true,
//             automaticallyImplyLeading: false,
//             elevation: 0,
//           ),
//         ],
//         body: TabBarView(
//           controller: _tabController,
//           children: [
//             HabitItemsList(habitList: develop),
//             HabitItemsList(habitList: quit),
//             HabitItemsList(habitList: task),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class HabitItemsList extends StatelessWidget {
//   const HabitItemsList({super.key, required this.habitList});
//   final List habitList;
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       padding: const EdgeInsets.all(5),
//       itemBuilder: (context, index) {
//         final habit = habitList[index];
//         final color = AppColors.myColorsDarker[index];
//         return ListTile(
//           leading: Icon(habit['icon'], color: color['color']),
//           title: Text(habit['name']),
//           trailing: CupertinoListTileChevron(),
//           onTap: () => Navigator.of(context).push(
//             MaterialPageRoute(
//               builder: (context) => CreateHabitScreen(
//                 habit: habit,
//                 category: habit['categoryId'],
//                 name: habit['name'],
//                 icon: habit['id'],
               

//               ),
//             ),
//           ),
//         );
//       },
//       itemCount: habitList.length,
//     );
//   }
// }
