import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/user_service.dart';
import '../services/reservations_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/login_page.dart';
import '../services/reviews_service.dart';
import '../models/review_create_request.dart';
import '../services/payments_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  final _users = UserService();
  final _resv = ReservationsService();
  final _auth = AuthService();
  final _reviews = ReviewsService();
  final _payments = PaymentsService();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  bool _isHandlingPayPalReturn = false;
  String? _lastHandledPayPalLink;

  bool _loading = true;
  String _error = '';

  UserProfileDto? _me;
  List<MyReservationDto> _myReservations = [];

  bool _editing = false;
  bool _creatingPayment = false;

  final _profileFormKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  String? _profileGeneralError;
  String? _firstNameServerError;
  String? _lastNameServerError;
  String? _phoneServerError;
  String? _addressServerError;

  final RegExp _phoneRegex = RegExp(r'^(\+?\d{8,15})$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForPayPalReturn();
    _handleInitialPayPalLink();
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();

    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleInitialPayPalLink();
    }
  }

  void _listenForPayPalReturn() {
    _linkSub = _appLinks.uriLinkStream.listen((Uri uri) async {
      await _handlePayPalReturn(uri);
    });
  }

  Future<void> _handleInitialPayPalLink() async {
    try {
      final Uri? uri = await _appLinks.getInitialLink();
      if (uri != null) {
        await _handlePayPalReturn(uri);
      }
    } catch (_) {}
  }

  Future<void> _handlePayPalReturn(Uri uri) async {
    final uriString = uri.toString();

    if (_isHandlingPayPalReturn) return;
    if (_lastHandledPayPalLink == uriString) return;

    if (uri.scheme != 'rentloop') return;
    if (uri.host != 'paypal-return') return;

    final orderId = uri.queryParameters['token'];
    if (orderId == null || orderId.isEmpty) return;

    final storage = TokenStorage();
    final reservationIdRaw = await storage.read('pending_reservation_id');

    if (reservationIdRaw == null || reservationIdRaw.isEmpty) return;

    final reservationId = int.tryParse(reservationIdRaw);
    if (reservationId == null) return;

    _isHandlingPayPalReturn = true;
    _lastHandledPayPalLink = uriString;

    try {
      final result = await _payments.capturePayPalOrder(
        reservationId: reservationId,
        orderId: orderId,
      );

      await storage.delete('pending_reservation_id');
      await _load();

      if (!mounted) return;

      final status = result.status.toUpperCase();

      if (status == 'COMPLETED' || status == 'ALREADY_CAPTURED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plaćanje uspješno završeno ✅')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PayPal status: $status')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri završavanju plaćanja: $msg')),
      );
    } finally {
      _isHandlingPayPalReturn = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final me = await _users.me();
      final reservations = await _resv.myReservations();

      _me = me;
      _myReservations = reservations;

      _firstName.text = me.firstName ?? '';
      _lastName.text = me.lastName ?? '';
      _phone.text = me.phone ?? '';
      _address.text = me.address ?? '';

      _clearProfileMappedErrors();

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
      });
    }
  }

  void _clearProfileMappedErrors() {
    _profileGeneralError = null;
    _firstNameServerError = null;
    _lastNameServerError = null;
    _phoneServerError = null;
    _addressServerError = null;
  }

  void _mapProfileServerError(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('first name') || msg.contains('firstname') || msg.contains('ime')) {
      _firstNameServerError = message;
      return;
    }

    if (msg.contains('last name') || msg.contains('lastname') || msg.contains('prezime')) {
      _lastNameServerError = message;
      return;
    }

    if (msg.contains('phone') || msg.contains('telefon')) {
      _phoneServerError = message;
      return;
    }

    if (msg.contains('address') || msg.contains('adresa')) {
      _addressServerError = message;
      return;
    }

    _profileGeneralError = message;
  }

  void _clearProfileFieldError(String field) {
    setState(() {
      _profileGeneralError = null;

      switch (field) {
        case 'firstName':
          _firstNameServerError = null;
          break;
        case 'lastName':
          _lastNameServerError = null;
          break;
        case 'phone':
          _phoneServerError = null;
          break;
        case 'address':
          _addressServerError = null;
          break;
      }
    });
  }

  String? _validateFirstName(String? value) {
    final v = value?.trim() ?? '';

    if (v.isNotEmpty && v.length > 50) {
      return 'Ime može imati najviše 50 karaktera';
    }

    if (_firstNameServerError != null) return _firstNameServerError;
    return null;
  }

  String? _validateLastName(String? value) {
    final v = value?.trim() ?? '';

    if (v.isNotEmpty && v.length > 50) {
      return 'Prezime može imati najviše 50 karaktera';
    }

    if (_lastNameServerError != null) return _lastNameServerError;
    return null;
  }

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';

    if (v.isNotEmpty) {
      if (v.length > 30) return 'Telefon može imati najviše 30 karaktera';
      if (!_phoneRegex.hasMatch(v)) return 'Telefon nije u ispravnom formatu';
    }

    if (_phoneServerError != null) return _phoneServerError;
    return null;
  }

  String? _validateAddress(String? value) {
    final v = value?.trim() ?? '';

    if (v.length > 200) return 'Adresa može imati najviše 200 karaktera';

    if (_addressServerError != null) return _addressServerError;
    return null;
  }

  Future<void> _save() async {
    if (_me == null) return;

    setState(_clearProfileMappedErrors);

    final ok = _profileFormKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final req = UpdateMeRequest(
        firstName: _firstName.text.trim().isEmpty ? null : _firstName.text.trim(),
        lastName: _lastName.text.trim().isEmpty ? null : _lastName.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      );

      final updated = await _users.updateMe(req);

      _me = updated;
      _editing = false;

      _firstName.text = updated.firstName ?? '';
      _lastName.text = updated.lastName ?? '';
      _phone.text = updated.phone ?? '';
      _address.text = updated.address ?? '';

      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil uspješno sačuvan ✅')),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();

      setState(() {
        _loading = false;
        _mapProfileServerError(msg);
      });

      _profileFormKey.currentState?.validate();
    }
  }

  Future<void> _payReservation(MyReservationDto r) async {
    if (_creatingPayment) return;

    setState(() => _creatingPayment = true);

    try {
      final created = await _payments.createPayPalOrder(r.id);

      final storage = TokenStorage();
      await storage.save('pending_reservation_id', r.id.toString());

      if (!mounted) return;

      final uri = Uri.parse(created.approveUrl);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ne mogu otvoriti PayPal link.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PayPal greška: $msg')),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingPayment = false);
      }
    }
  }

  Future<void> _cancelReservation(MyReservationDto r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Otkaži rezervaciju'),
        content: Text(
          'Da li sigurno želiš otkazati rezervaciju "${r.listingTitle.isEmpty ? '#${r.id}' : r.listingTitle}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Otkaži rezervaciju'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _resv.cancelReservation(r.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervacija uspješno otkazana.')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Odjava'),
        content: const Text('Da li ste sigurni da se želite odjaviti?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Odjavi se')),
        ],
      ),
    );

    if (ok != true) return;

    await _auth.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _openChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();

    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    bool loading = false;
    String? generalError;
    String? currentServerError;
    String? newServerError;
    String? confirmServerError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            void clearMappedErrors() {
              generalError = null;
              currentServerError = null;
              newServerError = null;
              confirmServerError = null;
            }

            void mapServerError(String message) {
              final msg = message.toLowerCase();

              if (msg.contains('current password') || msg.contains('trenutna lozinka')) {
                currentServerError = message;
                return;
              }

              if (msg.contains('new password') || msg.contains('nova lozinka')) {
                newServerError = message;
                return;
              }

              if (msg.contains('confirm') || msg.contains('potvrdi')) {
                confirmServerError = message;
                return;
              }

              generalError = message;
            }

            String? validateCurrent(String? value) {
              final v = value ?? '';
              if (v.isEmpty) return 'Trenutna lozinka je obavezna';
              if (currentServerError != null) return currentServerError;
              return null;
            }

            String? validateNew(String? value) {
              final v = value ?? '';
              if (v.isEmpty) return 'Nova lozinka je obavezna';
              if (v.length < 6) return 'Nova lozinka mora imati najmanje 6 karaktera';
              if (v.length > 100) return 'Nova lozinka može imati najviše 100 karaktera';
              if (newServerError != null) return newServerError;
              return null;
            }

            String? validateConfirm(String? value) {
              final v = value ?? '';
              if (v.isEmpty) return 'Potvrda lozinke je obavezna';
              if (v != newCtrl.text) return 'Lozinke se ne podudaraju';
              if (confirmServerError != null) return confirmServerError;
              return null;
            }

            void clearFieldError(String field) {
              setStateDialog(() {
                generalError = null;

                switch (field) {
                  case 'current':
                    currentServerError = null;
                    break;
                  case 'new':
                    newServerError = null;
                    break;
                  case 'confirm':
                    confirmServerError = null;
                    break;
                }
              });
            }

            Future<void> submit() async {
              setStateDialog(clearMappedErrors);

              final ok = formKey.currentState?.validate() ?? false;
              if (!ok) return;

              setStateDialog(() {
                loading = true;
              });

              try {
                await _auth.changePassword(
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );

                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lozinka uspješno promijenjena 🔐')),
                );
              } catch (e) {
                final msg = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();

                setStateDialog(() {
                  loading = false;
                  mapServerError(msg);
                });

                formKey.currentState?.validate();
              }
            }

            return AlertDialog(
              title: const Text('Promjena lozinke'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (generalError != null && generalError!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            generalError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      TextFormField(
                        controller: currentCtrl,
                        obscureText: true,
                        validator: validateCurrent,
                        onChanged: (_) => clearFieldError('current'),
                        decoration: const InputDecoration(
                          labelText: 'Trenutna lozinka',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: newCtrl,
                        obscureText: true,
                        validator: validateNew,
                        onChanged: (_) {
                          clearFieldError('new');
                          formKey.currentState?.validate();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Nova lozinka',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: confirmCtrl,
                        obscureText: true,
                        validator: validateConfirm,
                        onChanged: (_) {
                          clearFieldError('confirm');
                          formKey.currentState?.validate();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Potvrdi novu lozinku',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          currentCtrl.dispose();
                          newCtrl.dispose();
                          confirmCtrl.dispose();
                          Navigator.pop(ctx);
                        },
                  child: const Text('Odustani'),
                ),
                ElevatedButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Sačuvaj'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openReservationActions(MyReservationDto r) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                r.listingTitle.isEmpty ? 'Rezervacija #${r.id}' : r.listingTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                '${_fmtDate(r.from)} → ${_fmtDate(r.to)}',
                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (r.statusId == 1) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _cancelReservation(r);
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Otkaži rezervaciju'),
                  ),
                ),
              ] else if (r.statusId == 2 && r.isPaid == false) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _creatingPayment
                        ? null
                        : () {
                            Navigator.pop(context);
                            _payReservation(r);
                          },
                    icon: const Icon(Icons.payments),
                    label: Text(_creatingPayment ? 'Učitavanje...' : 'Plati (PayPal)'),
                  ),
                ),
              ] else if (r.statusId == 2 && r.isPaid == true) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFAF0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFB7E4C7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Plaćeno',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (r.paidAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Vrijeme plaćanja: ${_fmtDate(r.paidAt)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _openReviewDialog(r);
                          },
                          icon: const Icon(Icons.star_rate),
                          label: const Text('Ocijeni boravak'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Text(
                    r.statusId == 3
                        ? 'Rezervacija je odbijena (Rejected).'
                        : r.statusId == 4
                            ? 'Rezervacija je otkazana (Cancelled).'
                            : 'Rezervacija nije dostupna za akcije.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Zatvori'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openReviewDialog(MyReservationDto r) {
    int rating = 5;
    final commentCtrl = TextEditingController();
    bool loading = false;
    String error = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            Future<void> submit() async {
              final comment = commentCtrl.text.trim();

              if (comment.isEmpty) {
                setStateDialog(() => error = 'Komentar je obavezan.');
                return;
              }
              if (rating < 1 || rating > 5) {
                setStateDialog(() => error = 'Ocjena mora biti između 1 i 5.');
                return;
              }

              setStateDialog(() {
                loading = true;
                error = '';
              });

              try {
                final msg = await _reviews.createReview(
                  ReviewCreateRequest(
                    reservationId: r.id,
                    rating: rating,
                    comment: comment,
                  ),
                );

                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

                await _load();
              } catch (e) {
                setStateDialog(() {
                  loading = false;
                  error = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
                });
              }
            }

            return AlertDialog(
              title: const Text('Ocijeni boravak'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(error, style: const TextStyle(color: Colors.red)),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        final filled = star <= rating;
                        return IconButton(
                          onPressed: loading ? null : () => setStateDialog(() => rating = star),
                          icon: Icon(
                            filled ? Icons.star : Icons.star_border,
                            size: 30,
                            color: filled ? Colors.amber : Colors.black45,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentCtrl,
                      enabled: !loading,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Komentar',
                        border: OutlineInputBorder(),
                        hintText: 'Npr. čisto, lokacija super, sve preporuke…',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          commentCtrl.dispose();
                          Navigator.pop(ctx);
                        },
                  child: const Text('Odustani'),
                ),
                ElevatedButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Pošalji'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _roleName(int role) {
    if (role == 1) return 'Admin';
    if (role == 2) return 'Korisnik';
    return 'Nepoznato';
  }

  String _statusLabel(int statusId, String fallback) {
    if (statusId == 1) return 'Pending';
    if (statusId == 2) return 'Approved';
    if (statusId == 3) return 'Rejected';
    if (statusId == 4) return 'Cancelled';
    return fallback.isNotEmpty ? fallback : 'Status $statusId';
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2F5BFF);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('Moj profil'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _error.isNotEmpty
          ? _ErrorBox(message: _error, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfileHeader(
                    username: _me!.username,
                    email: _me!.email,
                    role: _roleName(_me!.role),
                    active: _me!.isActive,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _openChangePasswordDialog,
                    icon: const Icon(Icons.lock),
                    label: const Text('Promijeni lozinku'),
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    title: 'Podaci',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_editing)
                          TextButton.icon(
                            onPressed: () => setState(() => _editing = true),
                            icon: const Icon(Icons.edit, color: blue),
                            label: const Text('Edit', style: TextStyle(color: blue)),
                          )
                        else ...[
                          TextButton(
                            onPressed: () {
                              final me = _me!;
                              _firstName.text = me.firstName ?? '';
                              _lastName.text = me.lastName ?? '';
                              _phone.text = me.phone ?? '';
                              _address.text = me.address ?? '';
                              _clearProfileMappedErrors();
                              setState(() => _editing = false);
                            },
                            child: const Text('Odustani'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save),
                            label: const Text('Sačuvaj'),
                          ),
                        ],
                      ],
                    ),
                    child: Form(
                      key: _profileFormKey,
                      autovalidateMode: _editing
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        children: [
                          if (_profileGeneralError != null &&
                              _profileGeneralError!.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _profileGeneralError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          _Field(
                            label: 'Ime',
                            controller: _firstName,
                            enabled: _editing,
                            validator: _validateFirstName,
                            onChanged: (_) => _clearProfileFieldError('firstName'),
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            label: 'Prezime',
                            controller: _lastName,
                            enabled: _editing,
                            validator: _validateLastName,
                            onChanged: (_) => _clearProfileFieldError('lastName'),
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            label: 'Telefon',
                            controller: _phone,
                            enabled: _editing,
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
                            onChanged: (_) => _clearProfileFieldError('phone'),
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            label: 'Adresa',
                            controller: _address,
                            enabled: _editing,
                            validator: _validateAddress,
                            onChanged: (_) => _clearProfileFieldError('address'),
                          ),
                          const SizedBox(height: 10),
                          _ReadOnlyRow(label: 'Email', value: _me!.email),
                          const SizedBox(height: 6),
                          _ReadOnlyRow(label: 'Username', value: _me!.username),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    title: 'Moje rezervacije',
                    trailing: Text(
                      '${_myReservations.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    child: _myReservations.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Nema rezervacija još uvijek.'),
                          )
                        : Column(
                            children: _myReservations
                                .map(
                                  (r) => _ReservationTile(
                                    title: r.listingTitle.isEmpty ? 'Rezervacija #${r.id}' : r.listingTitle,
                                    dateRange: '${_fmtDate(r.from)} → ${_fmtDate(r.to)}',
                                    status: r.isPaid ? 'Plaćeno' : _statusLabel(r.statusId, r.statusName),
                                    price: r.totalPrice,
                                    onTap: () => _openReservationActions(r),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '?';
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String username;
  final String email;
  final String role;
  final bool active;

  const _ProfileHeader({
    required this.username,
    required this.email,
    required this.role,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2F5BFF);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E6E6)),
        boxShadow: const [
          BoxShadow(blurRadius: 10, offset: Offset(0, 4), color: Color(0x11000000)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person, color: blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Chip(text: role),
                    const SizedBox(width: 8),
                    _Chip(text: active ? 'Aktivan' : 'Neaktivan'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Card({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E6E6)),
        boxShadow: const [
          BoxShadow(blurRadius: 10, offset: Offset(0, 4), color: Color(0x11000000)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.label,
    required this.controller,
    required this.enabled,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF6F6F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final String title;
  final String dateRange;
  final String status;
  final double price;
  final VoidCallback? onTap;

  const _ReservationTile({
    required this.title,
    required this.dateRange,
    required this.status,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_note),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(dateRange, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(status, style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${price.toStringAsFixed(2)} KM',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}