import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/availability_service.dart';
import '../services/reservations_service.dart';

class ReservationCreatePage extends StatefulWidget {
  final int listingId;
  final String listingName;
  final double pricePerNight;
  final int? maxGuests;

  const ReservationCreatePage({
    super.key,
    required this.listingId,
    required this.listingName,
    required this.pricePerNight,
    this.maxGuests,
  });

  @override
  State<ReservationCreatePage> createState() => _ReservationCreatePageState();
}

class _ReservationCreatePageState extends State<ReservationCreatePage> {
  final _availability = AvailabilityService();
  final _reservations = ReservationsService();

  bool _loading = true;
  String _error = '';

  // calendar
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeMode = RangeSelectionMode.toggledOn;

  Set<DateTime> _booked = {};

  final _guestsCtrl = TextEditingController(text: '1');
  final _noteCtrl = TextEditingController();
  final _df = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _loadBooked();
  }

  @override
  void dispose() {
    _guestsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  DateTime _dOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isBooked(DateTime day) => _booked.contains(_dOnly(day));

  bool _isPast(DateTime day) {
    final today = _dOnly(DateTime.now());
    return _dOnly(day).isBefore(today);
  }

  Future<void> _loadBooked() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final from = _dOnly(DateTime.now());
      final to = DateTime(from.year, from.month + 3, from.day);

      final booked = await _availability.getBookedDates(
        propertyId: widget.listingId,
        from: from,
        to: to,
      );

      setState(() {
        _booked = booked;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _rangeCrossesBooked(DateTime start, DateTime endExclusive) {
    for (var d = _dOnly(start); d.isBefore(_dOnly(endExclusive)); d = d.add(const Duration(days: 1))) {
      if (_isBooked(d)) return true;
    }
    return false;
  }

  int _nights() {
    if (_rangeStart == null || _rangeEnd == null) return 0;
    final s = _dOnly(_rangeStart!);
    final e = _dOnly(_rangeEnd!);
    final n = e.difference(s).inDays;
    return n > 0 ? n : 0;
  }

  double _total() => _nights() * widget.pricePerNight;

  Color? _dayColor(DateTime day) {
    if (_isPast(day)) return Colors.grey.shade300;
    if (_isBooked(day)) return Colors.red.shade300;
    return Colors.green.shade200;
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
    });

    if (_rangeStart != null && _rangeEnd != null) {
      final s = _dOnly(_rangeStart!);
      final e = _dOnly(_rangeEnd!);
      if (!e.isAfter(s)) return;

      final endExclusive = e.add(const Duration(days: 1));
      if (_rangeCrossesBooked(s, endExclusive)) {
        setState(() {
          _rangeStart = null;
          _rangeEnd = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Odabrani period sadrži zauzete dane.')),
        );
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _error = '');

    if (_rangeStart == null || _rangeEnd == null) {
      setState(() => _error = 'Odaberi check-in i check-out na kalendaru.');
      return;
    }

    final start = _dOnly(_rangeStart!);
    final end = _dOnly(_rangeEnd!);

    if (!end.isAfter(start)) {
      setState(() => _error = 'Check-out mora biti poslije check-in datuma.');
      return;
    }

    final guests = int.tryParse(_guestsCtrl.text.trim()) ?? 0;
    if (guests <= 0) {
      setState(() => _error = 'Unesi validan broj gostiju.');
      return;
    }
    if (widget.maxGuests != null && guests > widget.maxGuests!) {
      setState(() => _error = 'Maksimalno gostiju: ${widget.maxGuests}.');
      return;
    }

    // backend koristi [checkIn, checkOut) pa šaljemo checkOut = end + 1 dan
    final checkOutExclusive = end.add(const Duration(days: 1));

    if (_rangeCrossesBooked(start, checkOutExclusive)) {
      setState(() => _error = 'Period sadrži zauzete dane.');
      return;
    }

    try {
      setState(() => _loading = true);

      final msg = await _reservations.createReservation(
        ReservationCreateRequest(
          listingId: widget.listingId,
          checkIn: start,
          checkOut: checkOutExclusive,
          guests: guests,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop(true); // true => refresh
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nights = _nights();

    return Scaffold(
      appBar: AppBar(title: Text('Rezerviši • ${widget.listingName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBooked,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(_error, style: TextStyle(color: Colors.red.shade800)),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: const [
                      _Legend(color: Colors.green, text: 'Dostupno'),
                      _Legend(color: Colors.red, text: 'Zauzeto'),
                      _Legend(color: Colors.grey, text: 'Prošlo'),
                      _Legend(color: Colors.blue, text: 'Odabrano'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.now().subtract(const Duration(days: 1)),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,

                      rangeStartDay: _rangeStart,
                      rangeEndDay: _rangeEnd,
                      rangeSelectionMode: _rangeMode,
                      onRangeSelected: _onRangeSelected,
                      onPageChanged: (d) => _focusedDay = d,

                      enabledDayPredicate: (day) {
                        if (_isPast(day)) return false;
                        if (_isBooked(day)) return false;
                        return true;
                      },

                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        rangeHighlightColor: Colors.blue.withOpacity(0.2),
                        rangeStartDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        rangeEndDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        withinRangeDecoration: BoxDecoration(color: Colors.blue.shade200, shape: BoxShape.circle),
                      ),

                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) =>
                            _DayCell(day: day, color: _dayColor(day)),
                        todayBuilder: (context, day, focusedDay) =>
                            _DayCell(day: day, color: _dayColor(day), border: Border.all(color: Colors.black54)),
                        disabledBuilder: (context, day, focusedDay) =>
                            _DayCell(day: day, color: _dayColor(day)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _InfoCard(
                    rows: [
                      ['Check-in', _rangeStart == null ? '—' : _df.format(_dOnly(_rangeStart!))],
                      ['Check-out', _rangeEnd == null ? '—' : _df.format(_dOnly(_rangeEnd!).add(const Duration(days: 1)))],
                      ['Noćenja', nights == 0 ? '—' : nights.toString()],
                      ['Cijena/noć', '${widget.pricePerNight.toStringAsFixed(2)} KM'],
                      ['Ukupno', nights == 0 ? '—' : '${_total().toStringAsFixed(2)} KM'],
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _guestsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Broj gostiju',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Napomena (opcionalno)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: const Text('Kreiraj rezervaciju'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final Color? color;
  final BoxBorder? border;

  const _DayCell({required this.day, this.color, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: border),
      alignment: Alignment.center,
      child: Text('${day.day}', style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<List<String>> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: rows
            .map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(r[0], style: TextStyle(color: Colors.grey.shade700))),
                    Text(r[1], style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
