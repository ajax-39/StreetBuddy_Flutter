import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart';
import 'package:intl/intl.dart';

enum SortOption {
  mostLikes,
  mostGuides, 
  mostPosts,
  ambassadorEligible
}

class UserManagementFeatureFlags {
  static const bool canEditUsername = true;
  static const bool canEditName = true;
  static const bool canEditBio = true;
  static const bool canEditGender = true;
  static const bool canEditPhone = false;
  static const bool canEditEmail = false;
  static const bool canEditVIPStatus = true;
  static const bool canEditDevStatus = true;
  static const bool canEditPrivacy = true;
  static const bool canEditBirthdate = true;
  static const bool canEditInterests = true;
}

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  SortOption? _currentSort;
  bool _showOnlyAmbassadorEligible = false;

  List<UserModel> _sortUsers(List<UserModel> users) {
    switch (_currentSort) {
      case SortOption.mostLikes:
        return users..sort((a, b) => b.totalLikes.compareTo(a.totalLikes));
      case SortOption.mostGuides:
        return users..sort((a, b) => b.guideCount.compareTo(a.guideCount));
      case SortOption.mostPosts:
        return users..sort((a, b) => b.postCount.compareTo(a.postCount));
      default:
        return users;
    }
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    if (_showOnlyAmbassadorEligible) {
      return users.where((user) =>
        user.guideCount >= 50 &&
        user.followersCount >= 500 &&
        user.totalLikes >= 1000 &&
        user.avgGuideReview >= 4.0 &&
        user.guideCountMnt >= 5
      ).toList();
    }
    return users;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          PopupMenuButton<SortOption>(
            onSelected: (SortOption value) {
              setState(() => _currentSort = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.mostLikes,
                child: Text('Sort by Most Likes'),
              ),
              const PopupMenuItem(
                value: SortOption.mostGuides,
                child: Text('Sort by Most Guides'),
              ),
              const PopupMenuItem(
                value: SortOption.mostPosts,
                child: Text('Sort by Most Posts'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.verified_user,
              color: _showOnlyAmbassadorEligible ? Colors.amber : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showOnlyAmbassadorEligible = !_showOnlyAmbassadorEligible;
              });
            },
            tooltip: 'Show Ambassador Eligible',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return UserModel.fromMap(doc.id, data);
          }).toList();

          users = _sortUsers(_filterUsers(users));

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) => _buildUserCard(context, users[index]),
          );
        },
      ),
    );
  }

  // Update _buildUserCard method:

  Widget _buildUserCard(BuildContext context, UserModel user) {
    final isAmbassadorEligible = user.guideCount >= 50 &&
        user.followersCount >= 500 &&
        user.totalLikes >= 1000 &&
        user.avgGuideReview >= 4.0 &&
        user.guideCountMnt >= 5;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(user.username[0].toUpperCase())
                  : null,
            ),
            if (isAmbassadorEligible)
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(Icons.verified, color: Colors.amber, size: 16),
              ),
          ],
        ),
        title: Text(user.username),
        subtitle: Text(user.email ?? 'No email'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditDialog(context, user),
        ),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(user),
                  const SizedBox(height: 16),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Field')),
                      DataColumn(label: Text('Value')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: [
                      _buildDataRow('Username', user.username,
                          UserManagementFeatureFlags.canEditUsername),
                      _buildDataRow('Name', user.name,
                          UserManagementFeatureFlags.canEditName),
                      _buildDataRow('Email', user.email ?? 'Not set',
                          UserManagementFeatureFlags.canEditEmail),
                      _buildDataRow('Phone', user.phoneNumber ?? 'Not set',
                          UserManagementFeatureFlags.canEditPhone),
                      _buildDataRow('Gender', user.genderString,
                          UserManagementFeatureFlags.canEditGender),
                      _buildDataRow('Bio', user.bio ?? 'Not set',
                          UserManagementFeatureFlags.canEditBio),
                      _buildDataRow(
                          'Birthdate',
                          user.birthdate != null
                              ? DateFormat('yyyy-MM-dd').format(user.birthdate!)
                              : 'Not set',
                          UserManagementFeatureFlags.canEditBirthdate),
                      _buildDataRow('VIP Status', user.isVIP ? 'Yes' : 'No',
                          UserManagementFeatureFlags.canEditVIPStatus),
                      _buildDataRow('Developer', user.isDev ? 'Yes' : 'No',
                          UserManagementFeatureFlags.canEditDevStatus),
                      _buildDataRow(
                          'Private Account',
                          user.isPrivate ? 'Yes' : 'No',
                          UserManagementFeatureFlags.canEditPrivacy),
                      _buildDataRow('Email Verified',
                          user.isEmailVerified ? 'Yes' : 'No', false),
                      _buildDataRow('Phone Verified',
                          user.isPhoneVerified ? 'Yes' : 'No', false),
                      _buildDataRow('Interests', user.interests.join(', '),
                          UserManagementFeatureFlags.canEditInterests),
                      _buildDataRow('Guide Count', '${user.guideCount}', false),
                      _buildDataRow('Monthly Guides', '${user.guideCountMnt}', false),
                      _buildDataRow('Total Likes', '${user.totalLikes}', false),
                      _buildDataRow('Avg Review', '${user.avgGuideReview}', false),
                      _buildDataRow('Bookmarks', '${user.bookmarkedPlaces.length}', false),
                      _buildDataRow('Ambassador Eligible', 
                        isAmbassadorEligible ? 'Yes' : 'No', false),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard('Posts', user.postCount),
        _buildStatCard('Followers', user.followersCount),
        _buildStatCard('Following', user.followingCount),
      ],
    );
  }

  Widget _buildStatCard(String label, int value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(String field, String value, bool isEditable) {
    return DataRow(
      cells: [
        DataCell(Text(
          field,
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
        DataCell(Text(value)),
        DataCell(
          Icon(
            isEditable ? Icons.edit : Icons.lock,
            size: 16,
            color: isEditable ? Colors.blue : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    );
  }
}

class EditUserDialog extends StatefulWidget {
  final UserModel user;

  const EditUserDialog({super.key, required this.user});

  @override
  _EditUserDialogState createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController _usernameController;
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late bool _isVIP;
  late bool _isDev;
  late bool _isPrivate;
  late Gender _gender;
  late DateTime? _birthdate;
  late List<String> _interests;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _phoneController =
        TextEditingController(text: widget.user.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _isVIP = widget.user.isVIP;
    _isDev = widget.user.isDev;
    _isPrivate = widget.user.isPrivate;
    _gender = widget.user.gender;
    _birthdate = widget.user.birthdate;
    _interests = List.from(widget.user.interests);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    try {
      final updates = {
        if (UserManagementFeatureFlags.canEditUsername)
          'username': _usernameController.text,
        if (UserManagementFeatureFlags.canEditName)
          'name': _nameController.text,
        if (UserManagementFeatureFlags.canEditBio) 'bio': _bioController.text,
        if (UserManagementFeatureFlags.canEditPhone)
          'phoneNumber': _phoneController.text,
        if (UserManagementFeatureFlags.canEditEmail)
          'email': _emailController.text,
        if (UserManagementFeatureFlags.canEditVIPStatus) 'isVIP': _isVIP,
        if (UserManagementFeatureFlags.canEditDevStatus) 'isDev': _isDev,
        if (UserManagementFeatureFlags.canEditPrivacy) 'isPrivate': _isPrivate,
        if (UserManagementFeatureFlags.canEditGender)
          'gender': _gender.toString().split('.').last,
        if (UserManagementFeatureFlags.canEditBirthdate)
          'birthdate': _birthdate,
        if (UserManagementFeatureFlags.canEditInterests)
          'interests': _interests,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update(updates);

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit User: ${widget.user.username}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (UserManagementFeatureFlags.canEditUsername)
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
            if (UserManagementFeatureFlags.canEditName)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            if (UserManagementFeatureFlags.canEditBio)
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
            if (UserManagementFeatureFlags.canEditPhone)
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
            if (UserManagementFeatureFlags.canEditEmail)
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            if (UserManagementFeatureFlags.canEditGender)
              DropdownButtonFormField<Gender>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: Gender.values.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _gender = value);
                },
              ),
            if (UserManagementFeatureFlags.canEditBirthdate)
              ListTile(
                title: const Text('Birthdate'),
                subtitle: Text(_birthdate == null
                    ? 'Not set'
                    : DateFormat('yyyy-MM-dd').format(_birthdate!)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _birthdate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _birthdate = date);
                  },
                ),
              ),
            if (UserManagementFeatureFlags.canEditVIPStatus)
              SwitchListTile(
                title: const Text('VIP Status'),
                value: _isVIP,
                onChanged: (value) => setState(() => _isVIP = value),
              ),
            if (UserManagementFeatureFlags.canEditDevStatus)
              SwitchListTile(
                title: const Text('Developer Status'),
                value: _isDev,
                onChanged: (value) => setState(() => _isDev = value),
              ),
            if (UserManagementFeatureFlags.canEditPrivacy)
              SwitchListTile(
                title: const Text('Private Account'),
                value: _isPrivate,
                onChanged: (value) => setState(() => _isPrivate = value),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateUser,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
