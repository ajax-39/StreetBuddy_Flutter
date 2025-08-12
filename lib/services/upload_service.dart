import 'package:street_buddy/globals.dart';
import 'package:street_buddy/widgets/uploading_snackbar.dart';

class UploadService {
  static void start() {
    uploadsnackbarKey.currentState?.showSnackBar(UploadingSnackbar.start());
  }

  static void stop() {
    uploadsnackbarKey.currentState?.removeCurrentSnackBar();
    uploadsnackbarKey.currentState?.showSnackBar(UploadingSnackbar.stop());
  }

  static void error() {
    uploadsnackbarKey.currentState?.removeCurrentSnackBar();
    uploadsnackbarKey.currentState?.showSnackBar(UploadingSnackbar.error());
  }
}
