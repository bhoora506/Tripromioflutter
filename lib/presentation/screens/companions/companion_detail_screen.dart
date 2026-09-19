import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/companion_model.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/services/connection_service.dart';
import '../connections/conversation_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CompanionDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Displays detailed information about a companion from the discovery feed
/// and provides the ability to send a connection request.
class CompanionDetailScreen extends StatefulWidget {
  const CompanionDetailScreen({super.key});

  @override
  State<CompanionDetailScreen> createState() => _CompanionDetailScreenState();
}

class _CompanionDetailScreenState extends State<CompanionDetailScreen> {
  final _connectionService = ConnectionService();
  final _chatService = ChatService();

  bool _isSending = false;
  bool _isSent = false;
  bool _isStartingChat = false;

  static const Map<String, String> _styleLabels = {
    'adventure': '🏔️ Adventure',
    'backpacking': '🎒 Backpacking',
    'budget': '💰 Budget',
    'luxury': '✨ Luxury',
    'relaxed': '🌴 Relaxed',
    'road_trip': '🚗 Road Trip',
    'nature': '🌿 Nature',
    'cultural': '🏛️ Cultural',
  };

  @override
  void dispose() {
    _connectionService.dispose();
    _chatService.dispose();
    super.dispose();
  }

  CompanionModel get _companion {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is CompanionDetailArgs) return args.companion;
    if (args is! CompanionModel) {
      throw StateError('CompanionDetailScreen requires a CompanionModel argument');
    }
    return args;
  }

  bool get _isAcceptedConnection {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is CompanionDetailArgs) return args.isAcceptedConnection;
    return false;
  }

  Future<void> _sendRequest() async {
    if (_isSending || _isSent) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _connectionService.sendConnectionRequest(_companion.id);
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _isSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection request sent!'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ConflictException catch (e) {
      // A request already exists (pending or accepted)
      if (!mounted) return;
      setState(() {
        _isSending = false;
        // Treat it as already handled/sent in the UI to prevent spamming
        _isSent = true; 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _startChat() async {
    if (_isStartingChat) return;
    setState(() => _isStartingChat = true);
    try {
      final conversation = await _chatService.createConversation(
        recipientId: _companion.id,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationDetailScreen(conversation: conversation),
        ),
      );
    } on ConflictException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection must be accepted before messaging.'),
          backgroundColor: AppColors.warning,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start conversation. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final companion = _companion;
    final photoUrl = _resolvePhotoUrl(companion.profilePhotoUrl);
    final styleLabel = _styleLabels[companion.travelStyle] ?? companion.travelStyle;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surfaceLight,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroHeader(
                photoUrl: photoUrl,
                name: companion.name,
              ),
            ),
          ),

          // ── Details ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.screenPaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Location
                  Text(
                    companion.name,
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (companion.location != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            companion.location!,
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (styleLabel != null) ...[
                    const SizedBox(height: 16),
                    _StyleChip(label: styleLabel),
                  ],

                  const SizedBox(height: 24),
                  const Divider(color: AppColors.borderLight, height: 1),
                  const SizedBox(height: 24),

                  // About (Bio)
                  if (companion.bio != null && companion.bio!.isNotEmpty) ...[
                    _SectionTitle('About Me'),
                    const SizedBox(height: 8),
                    Text(
                      companion.bio!,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        color: AppColors.textSecondaryLight,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Languages
                  if (companion.languages.isNotEmpty) ...[
                    _SectionTitle('Languages'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: companion.languages
                          .map((l) => _LanguageChip(name: l))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Interests
                  if (companion.interests.isNotEmpty) ...[
                    _SectionTitle('Interests'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: companion.interests
                          .map((i) => _InterestChip(name: i.name))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Preferred Destinations
                  if (companion.preferredDestinations.isNotEmpty) ...[
                    _SectionTitle('Preferred Destinations'),
                    const SizedBox(height: 12),
                    ...companion.preferredDestinations.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.place_outlined,
                                size: 18, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d.destination,
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  color: AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Bottom padding for button
                  SizedBox(height: 80 + bottomPad),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // ── Fixed Bottom Button ─────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppConstants.screenPaddingH,
          16,
          AppConstants.screenPaddingH,
          bottomPad == 0 ? 16 : bottomPad,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _isAcceptedConnection
            ? _ChatBtn(
                isLoading: _isStartingChat,
                onTap: _startChat,
              )
            : _ConnectBtn(
                isSending: _isSending,
                isSent: _isSent,
                onTap: _sendRequest,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Components
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.photoUrl, required this.name});
  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _FallbackHeader(name: name),
      );
    }
    return _FallbackHeader(name: name);
  }
}

class _FallbackHeader extends StatelessWidget {
  const _FallbackHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.nunito(
            fontSize: 72,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimaryLight,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        name,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.translate_rounded, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            name,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectBtn extends StatelessWidget {
  const _ConnectBtn({
    required this.isSending,
    required this.isSent,
    required this.onTap,
  });

  final bool isSending;
  final bool isSent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isSent) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
          const SizedBox(width: AppConstants.spacingSm),
          Text('Request Sent',
              style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                  letterSpacing: 0.2)),
        ]),
      );
    }

    return GestureDetector(
      onTap: isSending ? null : onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: isSending 
                  ? [Colors.grey.shade400, Colors.grey.shade500] 
                  : AppColors.primaryGradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          boxShadow: isSending ? [] : [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isSending)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            )
          else
            const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
          const SizedBox(width: AppConstants.spacingSm),
          Text(isSending ? 'Sending...' : 'Send Connection Request',
              style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2)),
        ]),
      ),
    );
  }
}

String? _resolvePhotoUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation argument object for CompanionDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Typed navigation argument for [CompanionDetailScreen].
///
/// Use [CompanionDetailArgs] instead of a plain [CompanionModel] when
/// you need to communicate additional context (e.g., accepted connection).
class CompanionDetailArgs {
  const CompanionDetailArgs({
    required this.companion,
    this.isAcceptedConnection = false,
  });

  final CompanionModel companion;

  /// True when this companion is an accepted connection — shows the
  /// "Message" button instead of "Send Connection Request".
  final bool isAcceptedConnection;
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Button
// ─────────────────────────────────────────────────────────────────────────────

class _ChatBtn extends StatelessWidget {
  const _ChatBtn({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : AppColors.primaryGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            else
              const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppConstants.spacingSm),
            Text(
              isLoading ? 'Opening chat…' : 'Message',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
