import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/provider/Auth/auth_provider.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/services/upload_service.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/file_video_player.dart';

class AddDetailsScreen extends StatelessWidget {
  const AddDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    int maxVideoDuration = 60;
    return WillPopScope(
      onWillPop: () async {
        // Clear the selected media when navigating back
        Provider.of<UploadProvider>(context, listen: false).reset();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Clear the selected media before popping
              Provider.of<UploadProvider>(context, listen: false).reset();
              context.pop();
            },
          ),
          title: const Text('New Post'),
          actions: [
            Consumer2<UploadProvider, AuthenticationProvider>(
              builder: (context, uploadState, authProvider, child) {
                return TextButton(
                  onPressed: uploadState.isValid && !uploadState.isUploading
                      ? () async {
                          try {
                            if (uploadState.duration > maxVideoDuration) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Video duration is too long')),
                              );
                              return;
                            }
                            uploadState.setUploading(true);

                            context.pop();
                            await uploadState.createPost(
                              user: authProvider.userModel!,
                            );

                            // Refresh posts across the app
                            if (context.mounted) {
                              final postProvider = Provider.of<PostProvider>(
                                  context,
                                  listen: false);
                              postProvider.refreshPosts();
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Post uploaded successfully!')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Upload failed: $e')),
                            );
                            UploadService.error();
                          }
                        }
                      : null,
                  child: uploadState.isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Upload'),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Consumer<UploadProvider>(
            builder: (context, state, child) {
              return Column(
                children: [
                  if (state.mediaType == PostType.image)
                    Image.file(
                      state.selectedMedia!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  else if (state.mediaType == PostType.video)
                    SizedBox(
                      height: 300,
                      child: FileVideoPlayer(
                        videoFile: state.selectedMedia!,
                      ),
                    ),
                  Visibility(
                    visible: state.thumbnail != null,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 100,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: state.thumbnail != null
                                    ? Image.file(
                                        state.thumbnail!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              const Text(
                                'Thumbnail',
                                style: AppTypography.subtitle,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${state.duration} seconds',
                                style: AppTypography.body.copyWith(
                                  color: state.duration > maxVideoDuration
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Title*',
                      hintText: 'Enter a title for your post',
                    ),
                    onChanged: state.setTitle,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Description*',
                      hintText: 'Write a description...',
                    ),
                    maxLines: 3,
                    onChanged: state.setDescription,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Location (Optional)',
                      hintText: 'Add a location',
                    ),
                    onChanged: state.setLocation,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  // Visibility(
                  //   visible: state.audio != null,
                  //   child: MusicPlayer(file: state.audio),
                  // ),
                  const SizedBox(
                    height: 30,
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// class MusicPlayer extends StatefulWidget {
//   final File? file;
//   const MusicPlayer({super.key, required this.file});

//   @override
//   State<MusicPlayer> createState() => _MusicPlayerState();
// }

// class _MusicPlayerState extends State<MusicPlayer> {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   bool _isPlaying = false;
//   void togglePlayPause() async {
//     if (_isPlaying) {
//       await _audioPlayer.pause();
//     } else {
//       await _audioPlayer.setSourceDeviceFile(widget.file!.path);
//       await _audioPlayer.resume();
//     }

//     setState(() {
//       _isPlaying = !_isPlaying;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       shape: RoundedRectangleBorder(side: BorderSide(color: Colors.purple)),
//       leading: Image.asset(
//         'assets/music.png',
//         height: 40,
//       ),
//       title: Text("Original audio"),
//       subtitle: Text(widget.file!.lengthSync().toString() + " bytes"),
//       trailing: IconButton(
//         icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
//         onPressed: togglePlayPause,
//       ),
//     );
//   }
// }
