import 'package:caller/pages/addcontact.dart';
import 'package:caller/pages/allairtimes.dart';
import 'package:caller/pages/dail.dart';
import 'package:caller/pages/incomingcall.dart';
import 'package:caller/pages/ougoingcall.dart';
import 'package:caller/pages/profile.dart';
import 'package:caller/pages/register.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:caller/utils/types.dart';
import 'package:caller/services/auth.services.dart';
import 'package:caller/pages/login.dart';
import 'package:caller/pages/home.dart';
import 'package:caller/pages/call.dart';
import 'package:caller/services/socket.services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

// Define a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Stripe.publishableKey =
      'pk_test_51QEWwyQ0hrJRXizc8YasnirXr1LESnWmWbK73NiUl4ldsRFyZgyW25OA8hujLBOJegL9OwfcNw93va66WTPOUMQY00fAehnAg7';
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // final FlutterSoundPlayer _player = FlutterSoundPlayer();
  User? user;

  @override
  void initState() {
    super.initState();
    _initializeSignalingService();
  }

  Future<void> _initializeSignalingService() async {
    user = await authService.getCurrentUser();

    if (user != null) {
      SignallingService.instance.init(
        websocketUrl: 'https://caller-server.onrender.com',
        selfCallerID: user?.callerId ?? "1232",
      );

      SignallingService.instance.socket!.on('newCall', (data) {
        print("New call received: $data");
        navigatorKey.currentState?.pushNamed('/incoming', arguments: {
          'callerId': data['callerId'],
          'channelId': data["channelId"],
          'token': data["token"],
          'appId': data["appId"],
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Use the global navigator key
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthenticationWrapper(),
        '/home': (context) => Home(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterPage(),
        '/dial': (context) => DialNumberPage(),
        '/allairtimes': (context) => AirtimePurchasePage(),
        '/profile': (context) => ProfileEditPage(),
        '/incoming': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return IncomingCallPage(
            callerId: args?['callerId'] ?? '',
            channelId: args?['channelId'],
            appId: args?['appId'],
            token: args?['token'],
          );
        },
        '/outgoing': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return OutgoingCallPage(
            calleeId: args?['calleeId'] ?? '',
          );
        },
        '/call': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return CallScreen(
              appId: args?["appId"],
              channelId: args?["channelId"],
              token: args?["token"],
               callerId: args?['callerId'] ?? '',
                calleeId: args?['calleeId'] ?? '',);
        },
        '/addcontact': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return AddContactPage(
            callerId: args?['callerId'] ?? '',
          );
        },
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: authService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/home');
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
