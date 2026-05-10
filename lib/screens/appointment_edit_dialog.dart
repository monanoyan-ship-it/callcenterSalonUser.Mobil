import 'package:callcenter_salonuser_mobil/models/appointment_models.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Mevcut bir randevunun saat/personel/notlarını düzenler. Hizmet seçimi
/// değiştirilmez (yeni randevu akışı P3 sonrasına bırakıldı). Save sonrasında
/// `true` ile pop eder → caller listeyi yenilesin.
class AppointmentEditDialog extends StatefulWidget {
  const AppointmentEditDialog({super.key, required this.appointment});

  final Appointment appointment;

  static Future<bool?> show(BuildContext context, Appointment a) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AppointmentEditDialog(appointment: a),
    );
  }

  @override
  State<AppointmentEditDialog> createState() => _AppointmentEditDialogState();
}

class _AppointmentEditDialogState extends State<AppointmentEditDialog> {
  static final _hourFmt = DateFormat('HH:mm', 'tr_TR');
  static final _dateFmt = DateFormat('d MMMM y EEEE', 'tr_TR');

  late DateTime _start;
  late int _personnelId;
  late TextEditingController _notes;
  List<Map<String, dynamic>> _staff = const [];
  bool _staffLoading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start = widget.appointment.startTime;
    _personnelId = widget.appointment.personnelId;
    _notes = TextEditingController(text: widget.appointment.notes ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStaff();
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() => _staffLoading = true);
    try {
      final list = await context
          .read<SalonApiClient>()
          .getAvailableStaff(widget.appointment.serviceIds);
      if (!mounted) return;
      setState(() {
        _staff = list;
        // Mevcut personel listede yoksa, yine de seçili göstermek için fallback olarak ekle.
        final has = list.any((s) => (s['id'] as num?)?.toInt() == _personnelId);
        if (!has) {
          _staff = [
            ...list,
            {
              'id': widget.appointment.personnelId,
              'name': widget.appointment.personnelName,
            },
          ];
        }
        _staffLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = dioErrorMessage(e);
        _staffLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _start = DateTime(picked.year, picked.month, picked.day,
            _start.hour, _start.minute);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _start.hour, minute: _start.minute),
    );
    if (picked != null) {
      setState(() {
        _start = DateTime(_start.year, _start.month, _start.day,
            picked.hour, picked.minute);
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final dto = AppointmentCreate(
        slnClientId: widget.appointment.slnClientId,
        personnelId: _personnelId,
        serviceIds: widget.appointment.serviceIds,
        startTime: _start,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      await context
          .read<SalonApiClient>()
          .updateAppointment(widget.appointment.id, dto);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = dioErrorMessage(e);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Randevuyu düzenle'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(_dateFmt.format(_start)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(_hourFmt.format(_start)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_staffLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              DropdownButtonFormField<int>(
                initialValue: _personnelId,
                decoration: const InputDecoration(labelText: 'Personel'),
                items: _staff
                    .map((s) {
                      final id = (s['id'] as num?)?.toInt() ?? 0;
                      final name = (s['name'] as String?) ?? 'Personel #$id';
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(name),
                      );
                    })
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _personnelId = v ?? _personnelId),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notlar',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
        ),
      ],
    );
  }
}
