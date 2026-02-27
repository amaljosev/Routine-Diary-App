// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:routine/features/app_lock/domain/entities/lock_type.dart';
// import 'package:routine/features/app_lock/presentation/bloc/lock_bloc.dart';
// import '../pages/lock_page.dart';
// import '../pages/security_question_page.dart';

// class AppLockWrapper extends StatefulWidget {
//   final Widget child;

//   const AppLockWrapper({super.key, required this.child});

//   @override
//   State<AppLockWrapper> createState() => _AppLockWrapperState();
// }

// class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     context.read<AppLockBloc>().add(LoadAppLockSettings());
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       context.read<AppLockBloc>().add(LockApp());
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AppLockBloc, AppLockState>(
//       listenWhen: (previous, current) => previous.isLocked != current.isLocked,
//       listener: (context, state) {
//         if (state.isLocked) {
//           _showLockScreen(context);
//         }
//       },
//       child: widget.child,
//     );
//   }

//   Future<void> _showLockScreen(BuildContext context) async {
//     final bloc = context.read<AppLockBloc>();
//     final lockType = bloc.state.lockType;

//     Widget lockWidget;
//     if (lockType == LockType.biometric) {
//       lockWidget = const _BiometricLockScreen();
//     } else if (lockType == LockType.pin) {
//       lockWidget = const LockPage(mode: LockMode.verify);
//     } else if (lockType == LockType.securityQuestion) {
//       lockWidget = const SecurityQuestionPage(isVerification: true);
//     } else {
//       return;
//     }

//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => WillPopScope(
//         onWillPop: () async => false,
//         child: lockWidget,
//       ),
//     );
//   }
// }

// class _BiometricLockScreen extends StatefulWidget {
//   const _BiometricLockScreen();

//   @override
//   State<_BiometricLockScreen> createState() => __BiometricLockScreenState();
// }

// class __BiometricLockScreenState extends State<_BiometricLockScreen> {
//   StreamSubscription<AppLockState>? _subscription;

//   @override
//   void initState() {
//     super.initState();
//     _authenticate();
//   }

//   @override
//   void dispose() {
//     _subscription?.cancel();
//     super.dispose();
//   }

//   Future<void> _authenticate() async {
//     final bloc = context.read<AppLockBloc>();
//     _subscription = bloc.stream.listen((state) {
//       if (!state.isLocked) {
//         Navigator.of(context).pop();
//       }
//     });
//     bloc.add(const VerifyAppBiometric());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: const [
//             CircularProgressIndicator(color: Colors.white),
//             SizedBox(height: 20),
//             Text('Authenticating...', style: TextStyle(color: Colors.white)),
//           ],
//         ),
//       ),
//     );
//   }
// }