import 'dart:async';
import 'package:flutter/material.dart';

class UploadProgressNotifier extends ChangeNotifier {
  static final UploadProgressNotifier _instance = UploadProgressNotifier._internal();
  factory UploadProgressNotifier() => _instance;
  UploadProgressNotifier._internal();

  bool isUploading = false;
  String currentFileName = '';
  double progress = 0.0;
  String statusMessage = '';
  bool isSuccess = false;
  String? uploadedUrl;
  Timer? _dismissTimer;

  void startUpload(String fileName) {
    _dismissTimer?.cancel();
    isUploading = true;
    currentFileName = fileName;
    progress = 0.08;
    statusMessage = 'Uploading $fileName to Cloudflare R2...';
    isSuccess = false;
    uploadedUrl = null;
    notifyListeners();
  }

  void updateProgress(double value, {String? customStatus}) {
    progress = value;
    if (customStatus != null) statusMessage = customStatus;
    notifyListeners();
  }

  void completeUpload(String publicUrl) {
    isUploading = false;
    progress = 1.0;
    isSuccess = true;
    uploadedUrl = publicUrl;
    statusMessage = 'Uploaded Successfully ✓ Synced with Firestore';
    notifyListeners();

    _dismissTimer = Timer(const Duration(milliseconds: 3500), () {
      isSuccess = false;
      notifyListeners();
    });
  }

  void failUpload(String error) {
    isUploading = false;
    isSuccess = false;
    statusMessage = 'Upload Failed: $error';
    notifyListeners();

    _dismissTimer = Timer(const Duration(milliseconds: 4000), () {
      statusMessage = '';
      notifyListeners();
    });
  }
}

class BottomRightUploadOverlay extends StatelessWidget {
  const BottomRightUploadOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UploadProgressNotifier(),
      builder: (context, _) {
        final notifier = UploadProgressNotifier();
        final shouldShow = notifier.isUploading || notifier.isSuccess;

        if (!shouldShow) return const SizedBox.shrink();

        return Positioned(
          bottom: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, val, child) {
                return Transform.scale(
                  scale: val,
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: notifier.isSuccess
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1).withOpacity(0.7),
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (notifier.isSuccess
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6366F1))
                              .withOpacity(0.38),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: notifier.isSuccess
                                ? const Color(0xFF10B981).withOpacity(0.2)
                                : const Color(0xFF6366F1).withOpacity(0.2),
                          ),
                          child: Center(
                            child: notifier.isSuccess
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF10B981),
                                    size: 26,
                                  )
                                : const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF818CF8),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    notifier.isSuccess
                                        ? 'Cloudflare R2 Synced'
                                        : 'Uploading Media...',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      color: notifier.isSuccess
                                          ? const Color(0xFF10B981)
                                          : Colors.white,
                                    ),
                                  ),
                                  if (!notifier.isSuccess)
                                    Text(
                                      '${(notifier.progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notifier.statusMessage,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!notifier.isSuccess) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: notifier.progress,
                                    minHeight: 4,
                                    backgroundColor: const Color(0xFF1E293B),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
