import 'package:flutter/material.dart';
import '../models/admin_reservation_item.dart';
import '../services/admin_reservarions_service.dart';

class AdminReservationsPage extends StatefulWidget {
  const AdminReservationsPage({super.key});

  @override
  State<AdminReservationsPage> createState() => _AdminReservationsPageState();
}

class _AdminReservationsPageState extends State<AdminReservationsPage> {
  final _service = AdminReservationsService();

  bool _loading = false;
  String _error = '';
  List<AdminReservationItem> _items = [];

  int? _statusFilter; // null = svi

  final _statusOptions = const <int?, String>{
    null: 'Svi',
    1: 'Pending',
    2: 'Approved',
    3: 'Rejected',
  };

  // Ujednačen izgled dugmadi
  final ButtonStyle _btnPrimary = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    minimumSize: const Size(0, 38),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  final ButtonStyle _btnOutline = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    minimumSize: const Size(0, 38),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  final ButtonStyle _btnText = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    minimumSize: const Size(0, 38),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final data = await _service.getAll(statusId: _statusFilter);
      setState(() => _items = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _approve(AdminReservationItem item) async {
    final ok = await _confirm(
      title: 'Odobriti rezervaciju?',
      message: 'Odobriti rezervaciju #${item.id} za "${item.listing}"?',
      confirmText: 'Odobri',
    );
    if (!ok) return;

    try {
      await _service.approve(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervacija odobrena.')),
      );
      await _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _reject(AdminReservationItem item) async {
    final ok = await _confirm(
      title: 'Odbiti rezervaciju?',
      message: 'Odbiti rezervaciju #${item.id} za "${item.listing}"?',
      confirmText: 'Odbij',
    );
    if (!ok) return;

    try {
      await _service.reject(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervacija odbijena.')),
      );
      await _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showDetails(AdminReservationItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detalji rezervacije #${item.id}'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Listing', item.listing),
              _kv('User', item.user),
              _kv('Status', '${item.status} (ID: ${item.statusId})'),
              _kv('Check-in', _fmtDate(item.checkIn)),
              _kv('Check-out', _fmtDate(item.checkOut)),
              _kv('Guests', item.guests.toString()),
              _kv('Total', '${item.totalPrice.toStringAsFixed(2)} KM'),
              _kv('Created', _fmtDateTime(item.createdAt)),
              _kv('Note', (item.note == null || item.note!.trim().isEmpty) ? '—' : item.note!),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zatvori')),
          if (item.statusId == 1) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approve(item);
              },
              child: const Text('Odobri'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _reject(item);
              },
              child: const Text('Odbij'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$k:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
  String _fmtDateTime(DateTime d) => '${_fmtDate(d)} ${_two(d.hour)}:${_two(d.minute)}';
  String _two(int n) => n.toString().padLeft(2, '0');

  void _showError(String msg) {
    final clean = msg.replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(clean)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Rezervacije'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter row
            Row(
              children: [
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                DropdownButton<int?>(
                  value: _statusFilter,
                  items: _statusOptions.entries
                      .map((e) => DropdownMenuItem<int?>(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: _loading
                      ? null
                      : (v) async {
                          setState(() => _statusFilter = v);
                          await _load();
                        },
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('Ukupno: ${_items.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_error.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 12),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const Center(child: Text('Nema rezervacija za odabrani filter.'))
                      : Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.black.withOpacity(0.08)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  // minimum širina da tabela “diše”
                                  constraints: const BoxConstraints(minWidth: 1100),
                                  child: DataTable(
                                    headingRowHeight: 52,
                                    dataRowMinHeight: 56,
                                    dataRowMaxHeight: 56,
                                    columnSpacing: 22,
                                    columns: const [
                                      DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Listing', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Check-in', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Check-out', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Akcije', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _items.map((item) {
                                      final pending = item.statusId == 1;

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(item.id.toString())),
                                          DataCell(Text(item.listing)),
                                          DataCell(Text(item.user)),
                                          DataCell(Text(_fmtDate(item.checkIn))),
                                          DataCell(Text(_fmtDate(item.checkOut))),
                                          DataCell(
                                            _StatusPill(text: item.status, statusId: item.statusId),
                                          ),
                                          DataCell(Text('${item.totalPrice.toStringAsFixed(2)} KM')),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                OutlinedButton(
                                                  style: _btnOutline,
                                                  onPressed: () => _showDetails(item),
                                                  child: const Text('Detalji'),
                                                ),
                                                if (pending) ...[
                                                  const SizedBox(width: 10),
                                                  ElevatedButton(
                                                    style: _btnPrimary,
                                                    onPressed: () => _approve(item),
                                                    child: const Text('Odobri'),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  TextButton(
                                                    style: _btnText,
                                                    onPressed: () => _reject(item),
                                                    child: const Text('Odbij'),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final int statusId;

  const _StatusPill({required this.text, required this.statusId});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;

    // Bez ručnih boja u “vizuelnom” smislu? Ovo su samo blage nijanse statusa.
    // Ako želiš totalno neutralno, reci pa ću ostaviti samo text.
    if (statusId == 1) {
      bg = Colors.orange.withOpacity(0.12);
      border = Colors.orange.withOpacity(0.35);
    } else if (statusId == 2) {
      bg = Colors.green.withOpacity(0.12);
      border = Colors.green.withOpacity(0.35);
    } else {
      bg = Colors.red.withOpacity(0.10);
      border = Colors.red.withOpacity(0.30);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
