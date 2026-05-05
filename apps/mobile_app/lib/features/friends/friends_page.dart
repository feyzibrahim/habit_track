import 'package:ezecute/core/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ezecute/features/auth/auth_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _emailController = TextEditingController();
  List<dynamic> _friends = [];
  List<dynamic> _pendingRequests = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (ApiService.isGuest) return;
    setState(() => _isLoading = true);
    try {
      final friends = await ApiService.getFriends();
      final pending = await ApiService.getPendingRequests();
      if (mounted) {
        setState(() {
          _friends = friends;
          _pendingRequests = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load friends: $e')));
      }
    }
  }

  Future<void> _sendRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await ApiService.sendFriendRequest(email);
      if (mounted) {
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _handleRequest(String requestId, bool accept) async {
    try {
      if (accept) {
        await ApiService.acceptFriendRequest(requestId);
      } else {
        await ApiService.rejectFriendRequest(requestId);
      }
      _fetchData(); // Refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${accept ? 'accept' : 'reject'}: $e'),
          ),
        );
      }
    }
  }

  Widget _buildGuestState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.lock,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 32),
            Text(
              "Account Required",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).animate().fade(delay: 200.ms),
            const SizedBox(height: 16),
            Text(
              "You need to register to see the leaderboard and invite friends.",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ).animate().fade(delay: 400.ms),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    height: MediaQuery.of(context).size.height * 0.9,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: const AuthPage(
                      initialIsLogin: false,
                      disableToggle: true,
                    ),
                  ),
                );
                if (result == true) {
                  _fetchData();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Create Account",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ).animate().fade(delay: 600.ms).scaleY(begin: 0.8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (ApiService.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friends'), centerTitle: true),
        body: _buildGuestState(context, theme),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Friends'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADD FRIEND',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  hintText: 'Friend\'s Email',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _isSending ? null : _sendRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSending
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(LucideIcons.userPlus),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_pendingRequests.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        'PENDING REQUESTS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final req = _pendingRequests[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          child: Icon(
                            LucideIcons.user,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(req['requesterEmail']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                LucideIcons.xCircle,
                                color: Colors.red,
                              ),
                              onPressed: () => _handleRequest(req['id'], false),
                            ),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.checkCircle2,
                                color: Colors.green,
                              ),
                              onPressed: () => _handleRequest(req['id'], true),
                            ),
                          ],
                        ),
                      );
                    }, childCount: _pendingRequests.length),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      'YOUR FRIENDS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_friends.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        "You haven't added any friends yet.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final friend = _friends[index];
                      final name =
                          "${friend['firstName'] ?? ''} ${friend['lastName'] ?? ''}"
                              .trim();
                      final displayName = name.isNotEmpty
                          ? name
                          : (friend['email']?.toString() ?? 'Unknown');
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(friend['email']?.toString() ?? ''),
                      );
                    }, childCount: _friends.length),
                  ),
              ],
            ),
    );
  }
}
