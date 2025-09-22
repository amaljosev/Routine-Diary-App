import 'package:consist/core/components/neumorphic_card.dart';
import 'package:consist/features/onboarding/domain/entities/user_analytics_model.dart';
import 'package:consist/features/onboarding/presentation/blocs/user_bloc/user_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  @override
  void initState() {
    context.read<UserBloc>().add(FetchUserProfileEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220.0,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProfileHeader(context, state),
                ),
                pinned: true,
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
                backgroundColor: const Color(0xFF7C3AED),
              ),
              SliverToBoxAdapter(child: _buildContent(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserState state) {
    if (state is FetchUserProfileLoadingState) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is FetchUserProfileErrorState) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.msg,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<UserBloc>().add(FetchUserProfileEvent());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is FetchUserProfileSuccessState) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildStreakStatsSection(context, state.user),
            const SizedBox(height: 24),
            // _buildWeeklyProgressChart(context, state.user),
            // const SizedBox(height: 24),
            // _buildAchievementsSection(context, state.user),
            // const SizedBox(height: 24),
            // _buildActivityHistorySection(context, state.user),
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserState state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (state is FetchUserProfileSuccessState)
            _buildProfileContent(context, state.user)
          else if (state is FetchUserProfileLoadingState)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (state is FetchUserProfileErrorState)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load profile',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium!.copyWith(color: Colors.white),
                  ),
                ],
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserAnalytics userData) {
    return Padding(
      padding: const EdgeInsets.only(top: 70.0, left: 16.0, right: 16.0),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: Image.asset(
                userData.avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person,
                  size: 40,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userData.username,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${userData.totalDaysActive} Active Days',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined ${userData.installedDate}',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          _buildStarBadge(context, userData),
        ],
      ),
    );
  }

  Widget _buildStarBadge(BuildContext context, UserAnalytics userData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            userData.stars.toString(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStatsSection(
    BuildContext context,
    UserAnalytics userData,
  ) {
    return Row(
      children: [
        Expanded(
          child: NeumorphicCard(
            child: Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                Text(
                  userData.currentStreak.toString(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current Streak',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NeumorphicCard(
            child: Column(
              children: [
                const Text('👑', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                Text(
                  userData.bestStreak.toString(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Best Streak',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NeumorphicCard(
            child: Column(
              children: [
                const Text('📊', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                Text(
                  '${((userData.totalDaysActive / 365) * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consistency',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildWeeklyProgressChart(
  //   BuildContext context,
  //   UserAnalytics userData,
  // ) {
  //   return NeumorphicCard(
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'Weekly Progress',
  //           style: Theme.of(context).textTheme.titleMedium!.copyWith(
  //             fontSize: 18,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         SizedBox(
  //           height: 200,
  //           child: BarChart(
  //             BarChartData(
  //               alignment: BarChartAlignment.spaceAround,
  //               borderData: FlBorderData(show: false),
  //               gridData: const FlGridData(show: false),
  //               titlesData: FlTitlesData(
  //                 bottomTitles: AxisTitles(
  //                   sideTitles: SideTitles(
  //                     showTitles: true,
  //                     getTitlesWidget: (value, meta) {
  //                       const days = [
  //                         'Mon',
  //                         'Tue',
  //                         'Wed',
  //                         'Thu',
  //                         'Fri',
  //                         'Sat',
  //                         'Sun',
  //                       ];
  //                       return Padding(
  //                         padding: const EdgeInsets.only(top: 8.0),
  //                         child: Text(
  //                           days[value.toInt()],
  //                           style: Theme.of(
  //                             context,
  //                           ).textTheme.titleMedium!.copyWith(fontSize: 10),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //                 leftTitles: const AxisTitles(
  //                   sideTitles: SideTitles(showTitles: false),
  //                 ),
  //                 topTitles: const AxisTitles(
  //                   sideTitles: SideTitles(showTitles: false),
  //                 ),
  //                 rightTitles: const AxisTitles(
  //                   sideTitles: SideTitles(showTitles: false),
  //                 ),
  //               ),
  //               barGroups: [
  //                 BarChartGroupData(
  //                   x: 0,
  //                   barRods: [
  //                     BarChartRodData(
  //                       toY: 3,
  //                       color: const Color(0xFF6366F1),
  //                       width: 16,
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                   ],
  //                 ),
  //                 BarChartGroupData(
  //                   x: 1,
  //                   barRods: [
  //                     BarChartRodData(
  //                       toY: 5,
  //                       color: const Color(0xFF6366F1),
  //                       width: 16,
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                   ],
  //                 ),
  //                 BarChartGroupData(
  //                   x: 2,
  //                   barRods: [
  //                     BarChartRodData(
  //                       toY: 4,
  //                       color: const Color(0xFF6366F1),
  //                       width: 16,
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                   ],
  //                 ),
  //                 BarChartGroupData(
  //                   x: 3,
  //                   barRods: [
  //                     BarChartRodData(
  //                       toY: 7,
  //                       color: const Color(0xFF10B981),
  //                       width: 16,
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                   ],
  //                 ),
  //                 BarChartGroupData(
  //                   x: 4,
  //                   barRods: [
  //                     BarChartRodData(
  //                       toY: 2,
  //                       color: const Color(0xFF6366F1),
  //                       width: 16,
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                   ],
  //                 ),
  //                 BarChartGroupData(
  //                   x: 5,
  //                   barRods: [
  //                     BarChartRodData(
  //                       toY: 4,
  //                       color: const Color(0xFF6366F1),
  //                       width: 16,
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                   ],
  //                 ),
  //                 BarChartGroupData(
  //                   x: 6,
  //                   barRods: [
  //                     BarChartRodData(
  //                       toY: 6,
  //                       color: const Color(0xFFF59E0B),
  //                       width: 16,
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildAchievementsSection(
  //   BuildContext context,
  //   UserAnalytics userData,
  // ) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Achievements',
  //         style: Theme.of(context).textTheme.titleMedium!.copyWith(
  //           fontSize: 18,
  //           fontWeight: FontWeight.w600,
  //         ),
  //       ),
  //       const SizedBox(height: 12),
  //       GestureDetector(
  //         onTap: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) =>  AchievementsScreen(),
  //             ),
  //           );
  //         },
  //         child: SizedBox(
  //           height: 100,
  //           child: NeumorphicCard(
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(
  //                   Icons.fitness_center,
  //                   size: 28,
  //                   color: const Color(0xFFF59E0B),
  //                 ),
  //                 const SizedBox(height: 6),
  //                 Text(
  //                   'Achievements',
  //                   style: Theme.of(context).textTheme.titleMedium!.copyWith(
  //                     fontSize: 10,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildActivityHistorySection(
  //   BuildContext context,
  //   UserAnalytics userData,
  // ) {
  //   return NeumorphicCard(
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'Recent Activity',
  //           style: Theme.of(context).textTheme.titleMedium!.copyWith(
  //             fontSize: 18,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         _buildActivityItem(
  //           'Morning Run',
  //           'Completed',
  //           'Today, 7:30 AM',
  //           Icons.directions_run,
  //           context,
  //         ),
  //         _buildActivityItem(
  //           'Meditation',
  //           'Completed',
  //           'Today, 8:15 AM',
  //           Icons.self_improvement,
  //           context,
  //         ),
  //         _buildActivityItem(
  //           'Read Book',
  //           'Completed',
  //           'Yesterday, 9:20 PM',
  //           Icons.menu_book,
  //           context,
  //         ),
  //         _buildActivityItem(
  //           'Water Intake',
  //           'Missed',
  //           'Oct 26',
  //           Icons.water_drop,
  //           context,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildActivityItem(
  //   String title,
  //   String status,
  //   String time,
  //   IconData icon,
  //   BuildContext context,
  // ) {
  //   return ListTile(
  //     contentPadding: EdgeInsets.zero,
  //     leading: Container(
  //       width: 40,
  //       height: 40,
  //       decoration: BoxDecoration(
  //         color: const Color(0xFF7C3AED).withValues(alpha:  0.1),
  //         shape: BoxShape.circle,
  //       ),
  //       child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
  //     ),
  //     title: Text(
  //       title,
  //       style: Theme.of(
  //         context,
  //       ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500),
  //     ),
  //     subtitle: Text(
  //       time,
  //       style: Theme.of(
  //         context,
  //       ).textTheme.titleMedium!.copyWith(fontSize: 12, color: Colors.grey),
  //     ),
  //     trailing: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //       decoration: BoxDecoration(
  //         color: status == 'Completed'
  //             ? const Color(0xFF10B981).withValues(alpha:  0.2)
  //             : Colors.grey.withValues(alpha:  0.2),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: Text(
  //         status,
  //         style: Theme.of(context).textTheme.titleMedium!.copyWith(
  //           fontSize: 12,
  //           color: status == 'Completed'
  //               ? const Color(0xFF10B981)
  //               : Colors.grey,
  //         ),
  //       ),
  //     ),
  //   );
  // }
}



// class MeScreen extends StatelessWidget {
//   const MeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     return Scaffold(
//       backgroundColor: Colors.indigo.shade100,
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         forceMaterialTransparency: true,
//       ),
//       endDrawer: DrawerHome(),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             spacing: 20,
//             children: [
//               Card(
//                 elevation: 0,
//                 child: SizedBox(
//                   height: size.height * 0.1,
//                   width: size.width,
//                   child: Padding(
//                     padding: const EdgeInsets.all(10),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           'Username',
//                           style: Theme.of(context).textTheme.headlineMedium,
//                         ),
//                         Row(
//                           spacing: 5,
//                           children: [
//                             Text(
//                               'S7LD7FH5E5OTY9W56348',
//                               style: Theme.of(context).textTheme.bodyMedium!
//                                   .copyWith(color: Colors.grey),
//                             ),
//                             Icon(
//                               Icons.copy,
//                               color: Colors.grey,
//                               size: size.width * 0.04,
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               UserAchievementWidget(),
//               Expanded(
//                 child: GridView.builder(
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     childAspectRatio: 2.5,
//                   ),

//                   itemBuilder: (context, index) => meCategories(
//                     icon: Icons.today_outlined,
//                     title: 'My Goals',
//                   ),
//                   itemCount: 4,
//                 ),
//               ),
//               // ClipRSuperellipse(
//               //   borderRadius: BorderRadiusGeometry.all(Radius.circular(20)),
//               //   child: CalenderWidget(isHome: false),
//               // ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget meCategories({required IconData icon, required String title}) {
//     return Card(
//       elevation: 0,
//       child: Padding(
//         padding: const EdgeInsets.all(10),
//         child: Row(
//           spacing: 10,
//           children: [
//             Icon(icon),
//             Expanded(child: Text(title)),
//           ],
//         ),
//       ),
//     );
//   }
// }
