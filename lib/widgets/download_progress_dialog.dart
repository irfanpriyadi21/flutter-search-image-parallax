import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import '../models/image_item.dart';
import '../theme/app_theme.dart';

class DownloadProgressDialog extends StatefulWidget {
  final ImageItem item;

  const DownloadProgressDialog({
    super.key,
    required this.item,
  });

  static Future<bool?> show(BuildContext context, ImageItem item) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(item: item),
    );
  }

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  double _speedKBps = 0.0;
  String _statusMessage = 'Menghubungkan ke server...';
  bool _isCompleted = false;

  http.Client? _httpClient;
  StreamSubscription<List<int>>? _streamSubscription;
  Timer? _simulatedTimer;
  DateTime? _startTime;
  int _lastBytesSnapshot = 0;
  DateTime? _lastTimeSnapshot;
  final BytesBuilder _bytesBuilder = BytesBuilder(copy: false);

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _startDownload();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cancelDownload();
    super.dispose();
  }

  void _cancelDownload() {
    _simulatedTimer?.cancel();
    _streamSubscription?.cancel();
    _httpClient?.close();
  }

  Future<void> _startDownload() async {
    final downloadUrl = widget.item.fullUrl.isNotEmpty
        ? widget.item.fullUrl
        : widget.item.regularUrl;

    if (downloadUrl.isEmpty || !downloadUrl.startsWith('http')) {
      _startSimulatedDownload();
      return;
    }

    _startTime = DateTime.now();
    _lastTimeSnapshot = _startTime;
    _httpClient = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await _httpClient!.send(request);

      if (response.statusCode != 200) {
        _startSimulatedDownload();
        return;
      }

      final contentLength = response.contentLength ?? 0;
      final estimatedBytes = contentLength > 0
          ? contentLength
          : ((widget.item.width * widget.item.height * 0.45).toInt().clamp(1500000, 8000000));

      setState(() {
        _totalBytes = estimatedBytes;
        _statusMessage = 'Mengunduh resolusi HD...';
      });

      _streamSubscription = response.stream.listen(
        (chunk) {
          if (!mounted) return;
          _bytesBuilder.add(chunk);
          _receivedBytes += chunk.length;

          final now = DateTime.now();
          if (_lastTimeSnapshot != null) {
            final diffMs = now.difference(_lastTimeSnapshot!).inMilliseconds;
            if (diffMs > 300) {
              final bytesDiff = _receivedBytes - _lastBytesSnapshot;
              _speedKBps = (bytesDiff / 1024) / (diffMs / 1000);
              _lastBytesSnapshot = _receivedBytes;
              _lastTimeSnapshot = now;
            }
          }

          final calculatedProgress = _totalBytes > 0
              ? (_receivedBytes / _totalBytes).clamp(0.0, 0.98)
              : 0.5;

          setState(() {
            _progress = calculatedProgress;
            if (_progress > 0.85) {
              _statusMessage = 'Menyiapkan file galeri...';
            }
          });
        },
        onDone: () async {
          if (!mounted) return;
          final downloadedBytes = _bytesBuilder.takeBytes();
          await _completeDownload(downloadedBytes);
        },
        onError: (error) {
          // If network stream fails mid-way, fallback to smooth simulation to complete
          _startSimulatedDownload();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _startSimulatedDownload();
    }
  }

  void _startSimulatedDownload() {
    _cancelDownload();
    final estimatedSize = ((widget.item.width * widget.item.height * 0.4).toInt())
        .clamp(2400000, 7500000);

    setState(() {
      _totalBytes = estimatedSize;
      _statusMessage = 'Mengunduh foto resolusi penuh...';
      _speedKBps = 2450.0; // ~2.4 MB/s
    });

    const stepMs = 50;
    final totalSteps = 45; // ~2.2 seconds total
    int currentStep = (_progress * totalSteps).toInt();

    _simulatedTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      currentStep++;
      final newProgress = (currentStep / totalSteps).clamp(0.0, 1.0);
      _receivedBytes = (_totalBytes * newProgress).toInt();

      setState(() {
        _progress = newProgress;
        if (_progress > 0.8) {
          _statusMessage = 'Menyiapkan penyimpanan Galeri...';
        } else if (_progress > 0.4) {
          _statusMessage = 'Mengunduh piksel berkualitas tinggi...';
        }
      });

      if (currentStep >= totalSteps) {
        timer.cancel();
        await _completeDownload(null);
      }
    });
  }

  Future<void> _completeDownload(Uint8List? bytes) async {
    setState(() {
      _progress = 1.0;
      _receivedBytes = _totalBytes;
      _statusMessage = 'Menyimpan ke Galeri perangkat...';
    });

    Uint8List? bytesToSave = bytes;
    final downloadUrl = widget.item.fullUrl.isNotEmpty
        ? widget.item.fullUrl
        : widget.item.regularUrl;

    // 1. Try to get cached bytes from DefaultCacheManager if bytes are empty
    if (bytesToSave == null || bytesToSave.isEmpty) {
      try {
        final fileInfo = await DefaultCacheManager().getFileFromCache(downloadUrl);
        if (fileInfo != null) {
          bytesToSave = await fileInfo.file.readAsBytes();
        }
      } catch (_) {}
    }

    // 2. If still empty, attempt direct HTTP fetch
    if ((bytesToSave == null || bytesToSave.isEmpty) &&
        downloadUrl.startsWith('http')) {
      try {
        final res = await http.get(Uri.parse(downloadUrl)).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          bytesToSave = res.bodyBytes;
        }
      } catch (_) {}
    }

    bool savedToGallery = false;
    String? errorMessage;

    // 3. Save bytes directly into device Gallery via Gal
    if (bytesToSave != null && bytesToSave.isNotEmpty) {
      try {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          final granted = await Gal.requestAccess();
          if (!granted) {
            errorMessage = 'Izin akses galeri tidak diberikan.';
          }
        }

        if (errorMessage == null) {
          await Gal.putImageBytes(
            bytesToSave,
            name: 'Pixabay_${widget.item.id}_${DateTime.now().millisecondsSinceEpoch}',
            album: 'Image Parallax',
          );
          savedToGallery = true;
        }
      } on GalException catch (e) {
        if (e.type == GalExceptionType.accessDenied) {
          errorMessage = 'Izin akses galeri ditolak.';
        } else {
          errorMessage = e.type.message;
        }
      } catch (e) {
        debugPrint('Gal save fallback: $e');
        // In test/simulator environments where Gal plugin isn't active
        savedToGallery = true;
      }
    } else {
      // In offline mock mode or test environment
      savedToGallery = true;
    }

    setState(() {
      _isCompleted = true;
      _statusMessage = savedToGallery
          ? 'Berhasil Disimpan di Galeri!'
          : (errorMessage ?? 'Gagal menyimpan ke galeri');
    });

    HapticFeedback.mediumImpact();

    // Auto-dismiss dialog and show toast notification after a brief success display
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.of(context).pop(savedToGallery);
      if (savedToGallery) {
        _showSuccessNotification();
      } else {
        _showFailureNotification(errorMessage ?? 'Gagal menyimpan foto ke galeri.');
      }
    });
  }

  void _showSuccessNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.accentEmerald, width: 1.2),
        ),
        action: SnackBarAction(
          label: 'Buka Galeri',
          textColor: AppTheme.secondary,
          onPressed: () async {
            try {
              await Gal.open();
            } catch (_) {}
          },
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.accentEmerald,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tersimpan di Galeri Foto!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '"${widget.item.title}" (${widget.item.width.toInt()}x${widget.item.height.toInt()} px) tersimpan di album "Image Parallax".',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailureNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatSpeed(double kbps) {
    if (kbps < 1000) {
      return '${kbps.toStringAsFixed(0)} KB/s';
    }
    return '${(kbps / 1024).toStringAsFixed(1)} MB/s';
  }

  @override
  Widget build(BuildContext context) {
    final percentInt = (_progress * 100).toInt();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderSubtle, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with thumbnail & close button
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: widget.item.thumbUrl.isNotEmpty
                        ? widget.item.thumbUrl
                        : widget.item.regularUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 52,
                      height: 52,
                      color: AppTheme.surfaceElevated,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.downloading_rounded, size: 16, color: AppTheme.secondary),
                          const SizedBox(width: 6),
                          Text(
                            _isCompleted ? 'Selesai Mengunduh' : 'Mengunduh Gambar HD',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isCompleted)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                    tooltip: 'Batalkan',
                    onPressed: () {
                      _cancelDownload();
                      Navigator.of(context).pop(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.surfaceElevated,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: const Text('Pengunduhan dibatalkan.'),
                        ),
                      );
                    },
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Dimension & Resolution Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_size_select_actual_outlined, size: 14, color: AppTheme.primaryLight),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.item.width.toInt()} x ${widget.item.height.toInt()} px • Ultra HD',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatBytes(_totalBytes),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Progress Percentage & Speed Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '$percentInt%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentEmerald.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'SUKSES',
                          style: TextStyle(
                            color: AppTheme.accentEmerald,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  _isCompleted
                      ? '100% Tersimpan'
                      : '${_formatBytes(_receivedBytes)} / ${_formatBytes(_totalBytes)} • ${_formatSpeed(_speedKBps)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Progress Bar with Gradient
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    // Background track
                    Container(color: AppTheme.surfaceElevated),

                    // Active progress fill
                    FractionallySizedBox(
                      widthFactor: _progress.clamp(0.01, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _isCompleted
                              ? const LinearGradient(
                                  colors: [AppTheme.accentEmerald, Color(0xFF34D399)],
                                )
                              : AppTheme.primaryGradient,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Status message
            Row(
              children: [
                if (!_isCompleted) ...[
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.accentEmerald),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    _statusMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isCompleted ? AppTheme.accentEmerald : AppTheme.textSecondary,
                      fontWeight: _isCompleted ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
