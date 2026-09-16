import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../widgets/empty_state.dart';
import '../../models/notification_app.dart';
import '../../services/notification_service_api.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationApiService();

  List<NotificationApp> _notifications = [];
  bool _charge = false;
  int _nbNonLues = 0;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      final resultat = await _service.getNotifications();
      setState(() {
        _notifications = resultat.notifications;
        _nbNonLues = resultat.nonLues;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _toutMarquerLu() async {
    try {
      await _service.toutMarquerLu();
      await _charger();
    } catch (_) {}
  }

  Future<void> _marquerLue(NotificationApp n) async {
    if (n.lue) return;
    try {
      await _service.marquerLue(n.id);
      await _charger();
    } catch (_) {}
  }

  static const _icones = {
    'homework':     Icons.assignment_outlined,
    'attendance':   Icons.event_busy_outlined,
    'conversation': Icons.forum_outlined,
    'announcement': Icons.campaign_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (_nbNonLues > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(10)),
                child: Text('$_nbNonLues', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white)),
              ),
            ],
          ],
        ),
        actions: [
          if (_nbNonLues > 0)
            TextButton(
              onPressed: _toutMarquerLu,
              child: Text('Tout lire', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontSize: 13)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _charge
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? const EmptyState(
                    message: 'Aucune notification',
                    sousTitre: 'Vous serez notifié des nouveaux devoirs, messages et annonces.',
                    icone: Icons.notifications_none_outlined,
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      DateTime? date;
                      try { date = DateTime.parse(n.createdAt); } catch (_) {}

                      return ListTile(
                        tileColor: n.lue ? null : AppColors.blue.withOpacity(0.04),
                        leading: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: (n.lue ? AppColors.muted : AppColors.navy).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _icones[n.type] ?? Icons.notifications_outlined,
                            color: n.lue ? AppColors.muted : AppColors.navy,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          n.titre ?? '—',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: n.lue ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.navy,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (n.corps != null)
                              Text(n.corps!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.body), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (date != null)
                              Text(
                                DateFormat('d MMM, HH:mm', 'fr_FR').format(date),
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted),
                              ),
                          ],
                        ),
                        isThreeLine: n.corps != null,
                        onTap: n.lue ? null : () => _marquerLue(n),
                      );
                    },
                  ),
      ),
    );
  }
}
