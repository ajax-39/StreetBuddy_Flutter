import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/utils/styles.dart';

showReportPopup(BuildContext context, {String? postId, String? userId}) =>
    showDialog(
      context: context,
      builder: (context) => ReportPopup(postId: postId, userId: userId),
    );

class ReportPopup extends StatefulWidget {
  final String? postId;
  final String? userId;

  const ReportPopup({super.key, this.postId, this.userId});

  @override
  State<ReportPopup> createState() => _ReportPopupState();
}

class _ReportPopupState extends State<ReportPopup> {
  String? _selectedReason = 'Hate speech or symbols';
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  final _supabase = Supabase.instance.client;

  final List<String> _reportReasons = [
    'Nudity or sexual content',
    'Hate speech or symbols',
    'Spam or misleading',
    'Violence or harm',
    'Inappropriate language',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    if (globalUser == null) {
      _showSnackBar('Please log in to submit a report', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Determine the issue text based on selected reason
      String? issueText;
      if (_selectedReason == 'Other') {
        issueText = _descriptionController.text.trim();
        if (issueText.isEmpty) {
          _showSnackBar('Please describe the issue when selecting "Other"',
              isError: true);
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      } else {
        // For other reasons, include description if provided
        final description = _descriptionController.text.trim();
        if (description.isNotEmpty) {
          issueText = description;
        }
      }

      final reportData = {
        'user_id': globalUser!.uid,
        'username': globalUser!.username,
        'reason': _selectedReason,
        'issue': issueText,
        'type': widget.postId != null ? 'post' : 'user',
        'reported_post': widget.postId,
        'reported_user': widget.userId,
      };

      await _supabase.from('reports').insert(reportData);

      if (mounted) {
        _showSnackBar('Report submitted successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to submit report. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Why are you reporting this?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Radio options
            ...List.generate(_reportReasons.length, (index) {
              final reason = _reportReasons[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedReason == reason
                                ? const Color(0xFFE67E22)
                                : Colors.black,
                            width: 2,
                          ),
                        ),
                        child: _selectedReason == reason
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFE67E22),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        reason,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: fontregular,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 10),

            // Text field
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Please describe the issue (optional)...',
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 10),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
