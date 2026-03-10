import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'core/storage/token_storage.dart';
import 'features/auth/login_page.dart';
import 'features/user/pages/profile_page.dart';
import 'features/user/services/payments_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RentLoopApp());
}

class RentLoopApp extends StatefulWidget {
  const RentLoopApp({super.key});

  @override
  State<RentLoopApp> createState() => _RentLoopAppState();
}

class _RentLoopAppState extends State<RentLoopApp> {
  final AppLinks _appLinks = AppLinks();
  final PaymentsService _payments = PaymentsService();
  final TokenStorage _storage = TokenStorage();

  StreamSubscription<Uri>? _linkSub;
  bool _isHandlingLink = false;
  String? _lastHandledLink;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleIncomingUri(initialUri);
      }
    } catch (_) {}

    _linkSub = _appLinks.uriLinkStream.listen((uri) async {
      await _handleIncomingUri(uri);
    });
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    if (uri.scheme != 'rentloop') return;

    final raw = uri.toString();
    if (_lastHandledLink == raw) return;
    _lastHandledLink = raw;

    if (_isHandlingLink) return;
    _isHandlingLink = true;

    try {
      if (uri.host == 'paypal-return') {
        final orderId = uri.queryParameters['token'];
        if (orderId == null || orderId.isEmpty) return;

        final reservationIdRaw = await _storage.read('pending_reservation_id');
        if (reservationIdRaw == null || reservationIdRaw.isEmpty) return;

        final reservationId = int.tryParse(reservationIdRaw);
        if (reservationId == null) return;

        final status = await _payments.capturePayPal(reservationId, orderId);

        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                status == 'COMPLETED'
                    ? 'Plaćanje uspješno ✅'
                    : 'PayPal status: $status',
              ),
            ),
          );
        }

        if (status == 'COMPLETED' || status == 'ALREADY_CAPTURED') {
          await _storage.delete('pending_reservation_id');

          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ProfilePage()),
            (_) => false,
          );
        }
      }

      if (uri.host == 'paypal-cancel') {
        await _storage.delete('pending_reservation_id');

        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Plaćanje otkazano.')),
          );
        }
      }
    } catch (e) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        final msg = e.toString()
            .replaceFirst('Exception: ', '')
            .replaceAll('"', '')
            .trim();

        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Capture greška: $msg')),
        );
      }
    } finally {
      _isHandlingLink = false;
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'RentLoop',
      home: const LoginPage(),
    );
  }
}