import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/MainScreen/message_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class ShareService {
  // when website host name changes:
  // 1. change http intent host in androidManifest
  // 2. change this host variable

  String host = 'streetbuddy-bd84d.web.app';
  String hostalt = 'streetbuddy-bd.netlify.app';

  sharePost(BuildContext context, String uid, PostModel post) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return _MultiUserShareModal(
            host: host,
            post: post,
            uid: uid,
          );
        },
      );

// Modal widget for multi-user selection and sending

  shareGuide(BuildContext context, String uid, PostModel post) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return _MultiUserShareGuideModal(
            host: host,
            post: post,
            uid: uid,
          );
        },
      );

  shareProfile(BuildContext context, String uid, UserModel user) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return _MultiUserShareProfileModal(
            host: host,
            user: user,
            uid: uid,
          );
        },
      );
}

class _MultiUserShareModal extends StatefulWidget {
  final String host;
  final PostModel post;
  final String uid;
  const _MultiUserShareModal({
    required this.host,
    required this.post,
    required this.uid,
  });

  @override
  State<_MultiUserShareModal> createState() => _MultiUserShareModalState();
}

class _MultiUserShareModalState extends State<_MultiUserShareModal> {
  final Set<UserModel> _selectedUsers = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 525),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareSquareButton(
                  color: Colors.white,
                  icon: Icons.link,
                  label: 'Copy link',
                  iconColor: const Color(0xFF0059FF),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(
                        text:
                            'https://${widget.host}/post?id=${widget.post.id}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Link copied to clipboard!')),
                    );
                  },
                ),
                _ShareSquareButton(
                  color: Colors.white,
                  icon: Icons.share,
                  label: 'Share',
                  iconColor: const Color(0xFF4CD964),
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(
                        'https://${widget.host}/post?id=${widget.post.id}');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 41,
              child: TextField(
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  hintText: 'Search followers',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: ProfileProvider().streamFollowing(widget.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading following',
                        style: AppTypography.body.copyWith(color: Colors.red),
                      ),
                    );
                  }
                  final users = snapshot.data ?? [];
                  final filteredUsers = _searchQuery.isEmpty
                      ? users
                      : users
                          .where((user) =>
                              user.username
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              user.name.toLowerCase().contains(_searchQuery))
                          .toList();
                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Text(
                        users.isEmpty
                            ? 'Not following anyone'
                            : 'No users found',
                        style: AppTypography.body.copyWith(color: Colors.grey),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    itemCount: filteredUsers.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 2,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isSelected = _selectedUsers.contains(user);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUsers.remove(user);
                              debugPrint('🟠 Deselected: ${user.username}');
                            } else {
                              _selectedUsers.add(user);
                              debugPrint('🟢 Selected: ${user.username}');
                            }
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 51,
                              height: 51,
                              child: CircleAvatar(
                                radius: 25.5,
                                backgroundImage: NetworkImage(
                                    user.profileImageUrl.toString()),
                                backgroundColor: isSelected
                                    ? Colors.orange.withOpacity(0.2)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected)
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    margin: const EdgeInsets.only(right: 4),
                                    child: const Icon(Icons.check,
                                        size: 14, color: Colors.white),
                                  ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    user.username,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedUsers.isEmpty
                    ? null
                    : () {
                        for (final user in _selectedUsers) {
                          MessageProvider.sendMessage(
                            user,
                            '/post?id=${widget.post.id} ${widget.post.thumbnailUrl!.isNotEmpty ? widget.post.thumbnailUrl : widget.post.mediaUrls.first} ${widget.post.username}',
                            'post',
                          );
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Post sent to ${_selectedUsers.length} user(s)')),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED7014),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Send',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiUserShareGuideModal extends StatefulWidget {
  final String host;
  final PostModel post;
  final String uid;
  const _MultiUserShareGuideModal({
    required this.host,
    required this.post,
    required this.uid,
  });

  @override
  State<_MultiUserShareGuideModal> createState() =>
      _MultiUserShareGuideModalState();
}

class _MultiUserShareGuideModalState extends State<_MultiUserShareGuideModal> {
  final Set<UserModel> _selectedUsers = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 525),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareSquareButton(
                  color: const Color(0xFF0059FF),
                  icon: Icons.link,
                  label: 'Copy link',
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(
                        text:
                            'https://${widget.host}/guide?id=${widget.post.id}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Link copied to clipboard!')),
                    );
                  },
                ),
                _ShareSquareButton(
                  color: const Color(0xFF4CD964),
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(
                        'https://${widget.host}/guide?id=${widget.post.id}');
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 41,
              child: TextField(
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  hintText: 'Search followers',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 14),
                readOnly: true,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: ProfileProvider().streamFollowing(widget.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading following',
                        style: AppTypography.body.copyWith(color: Colors.red),
                      ),
                    );
                  }
                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return Center(
                      child: Text(
                        'Not following anyone',
                        style: AppTypography.body.copyWith(color: Colors.grey),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    itemCount: users.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelected = _selectedUsers.contains(user);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUsers.remove(user);
                            } else {
                              _selectedUsers.add(user);
                            }
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 25.5,
                                  backgroundImage: NetworkImage(
                                      user.profileImageUrl.toString()),
                                  backgroundColor: isSelected
                                      ? Colors.orange.withOpacity(0.2)
                                      : null,
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(3),
                                      child: const Icon(Icons.check,
                                          size: 12, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              user.username,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedUsers.isEmpty
                    ? null
                    : () {
                        for (final user in _selectedUsers) {
                          MessageProvider.sendMessage(
                            user,
                            '/guide?id=${widget.post.id} ${widget.post.thumbnailUrl!.isNotEmpty ? widget.post.thumbnailUrl : null} ${widget.post.username}',
                            'guide',
                          );
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Guide sent to ${_selectedUsers.length} user(s)')),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED7014),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Send',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiUserShareProfileModal extends StatefulWidget {
  final String host;
  final UserModel user;
  final String uid;
  const _MultiUserShareProfileModal({
    required this.host,
    required this.user,
    required this.uid,
  });

  @override
  State<_MultiUserShareProfileModal> createState() =>
      _MultiUserShareProfileModalState();
}

class _MultiUserShareProfileModalState
    extends State<_MultiUserShareProfileModal> {
  final Set<UserModel> _selectedUsers = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 525),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareSquareButton(
                  color: Colors.white,
                  icon: Icons.link,
                  label: 'Copy link',
                  iconColor: const Color(0xFF0059FF),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(
                        ClipboardData(text: 'https://${widget.host}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Link copied to clipboard!')),
                    );
                  },
                ),
                _ShareSquareButton(
                  color: Colors.white,
                  icon: Icons.share,
                  label: 'Share',
                  iconColor: const Color(0xFF4CD964),
                  onTap: () {
                    Navigator.pop(context);
                    Share.share('https://${widget.host}');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 41,
              child: TextField(
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  hintText: 'Search followers',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: ProfileProvider().streamFollowing(widget.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading following',
                        style: AppTypography.body.copyWith(color: Colors.red),
                      ),
                    );
                  }
                  final users = snapshot.data ?? [];
                  final filteredUsers = _searchQuery.isEmpty
                      ? users
                      : users
                          .where((user) =>
                              user.username
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              user.name.toLowerCase().contains(_searchQuery))
                          .toList();
                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Text(
                        users.isEmpty
                            ? 'Not following anyone'
                            : 'No users found',
                        style: AppTypography.body.copyWith(color: Colors.grey),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    itemCount: filteredUsers.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 2,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isSelected = _selectedUsers.contains(user);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUsers.remove(user);
                              debugPrint('🟠 Deselected: ${user.username}');
                            } else {
                              _selectedUsers.add(user);
                              debugPrint('🟢 Selected: ${user.username}');
                            }
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 51,
                              height: 51,
                              child: CircleAvatar(
                                radius: 25.5,
                                backgroundImage: NetworkImage(
                                    user.profileImageUrl.toString()),
                                backgroundColor: isSelected
                                    ? const Color(0xFFED7014).withOpacity(0.2)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFED7014),
                                    size: 16,
                                  ),
                                SizedBox(
                                  width: isSelected ? 60 : 70,
                                  child: Text(
                                    user.username,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedUsers.isEmpty
                    ? null
                    : () {
                        for (final user in _selectedUsers) {
                          MessageProvider.sendMessage(
                            user,
                            'https://${widget.host} ${widget.user.profileImageUrl ?? ''} ${widget.user.username}',
                            'profile',
                          );
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Profile sent to ${_selectedUsers.length} user(s)')),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED7014),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Send',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for square share buttons
class _ShareSquareButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  const _ShareSquareButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: iconColor ?? Colors.black, size: 28),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
