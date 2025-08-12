import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:street_buddy/services/search_service.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/buttons/custom_leading_button.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:street_buddy/globals.dart';

class SearchHistory extends StatefulWidget {
  const SearchHistory({super.key});

  @override
  State<SearchHistory> createState() => _SearchHistoryState();
}

class _SearchHistoryState extends State<SearchHistory> {
  List<Map<String, dynamic>> searchHistory = [];
  List<Map<String, dynamic>> filteredSearchHistory = [];
  int selectedIndex = 0;
  List<String> filters = ['All', 'Last 24h', 'This Week', 'This Month'];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSearchHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchSearchHistory() async {
    setState(() {
      isLoading = true;
    });
    try {
      final currentUser = globalUser;
      if (currentUser?.uid == null || currentUser?.username == null) {
        searchHistory = [];
        filteredSearchHistory = [];
        setState(() {
          isLoading = false;
        });
        return;
      }
      final username = currentUser!.username;
      List<Map<String, dynamic>> allHistory =
          await SearchService.getUserSearchHistory(username: username);
      searchHistory = _filterHistory(allHistory, selectedIndex);
      _applySearchBarFilter();
    } catch (e) {
      debugPrint('Error fetching search history: $e');
      searchHistory = [];
      filteredSearchHistory = [];
    }
    setState(() {
      isLoading = false;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _applySearchBarFilter();
    });
  }

  void _applySearchBarFilter() {
    String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredSearchHistory = List<Map<String, dynamic>>.from(searchHistory);
    } else {
      filteredSearchHistory = searchHistory.where((item) {
        final text = (item['query_text'] ?? '').toString().toLowerCase();
        return text.contains(query);
      }).toList();
    }
  }

  List<Map<String, dynamic>> _filterHistory(
      List<Map<String, dynamic>> allHistory, int filterIndex) {
    if (filterIndex == 0) return allHistory;
    final now = DateTime.now();
    DateTime from;
    switch (filterIndex) {
      case 1: // Last 24h
        from = now.subtract(const Duration(hours: 24));
        break;
      case 2: // This Week
        from = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 3: // This Month
        from = DateTime(now.year, now.month, 1);
        break;
      default:
        from = DateTime(2000);
    }
    return allHistory.where((item) {
      final executedAt =
          DateTime.tryParse(item['executed_at'] ?? '') ?? DateTime(2000);
      return executedAt.isAfter(from);
    }).toList();
  }

  Future<void> clearAllHistory() async {
    // Not implemented: Deleting all history from Supabase is not supported in SearchService
    // You may implement a delete endpoint if needed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Clear All is not supported for server history.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search History',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: const CustomLeadingButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search terms...',
                      contentPadding: EdgeInsets.zero,
                      hintStyle: AppTypography.searchBar16,
                      prefixIconConstraints: const BoxConstraints(
                        maxHeight: 24,
                        maxWidth: 44,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Image.asset(
                          'assets/icon/search.png',
                          color: const Color(0xffD9D9D9),
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Color(0xffD9D9D9)),
                              onPressed: () {
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xffD9D9D9), width: 1),
                          borderRadius: BorderRadius.all(Radius.circular(50))),
                      enabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xffD9D9D9), width: 1),
                          borderRadius: BorderRadius.all(Radius.circular(50))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              _buildFilterChips(),
              const SizedBox(height: 25),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Recent Searches',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredSearchHistory.length,
                      itemBuilder: (context, index) {
                        var searchTerm = filteredSearchHistory[index];
                        return ListTile(
                          leading: Image.asset(
                            'assets/icon/search.png',
                            height: 25,
                            width: 25,
                            color: Colors.black.withOpacity(0.5),
                          ),
                          titleTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          title: Text(searchTerm['query_text'] ?? ''),
                          subtitle: Text(
                            timeago.format(
                              DateTime.tryParse(
                                      searchTerm['executed_at'] ?? '') ??
                                  DateTime.now(),
                            ),
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 5),
            ListView.builder(
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: FilterChip(
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color:
                          selectedIndex == index ? Colors.white : Colors.black,
                    ),
                    label: Text(filters[index]),
                    selected: selectedIndex == index,
                    onSelected: (bool selected) async {
                      if (selectedIndex != index) {
                        setState(() {
                          selectedIndex = index;
                        });
                        await fetchSearchHistory();
                      }
                    },
                  ),
                );
              },
              itemCount: filters.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }
}
