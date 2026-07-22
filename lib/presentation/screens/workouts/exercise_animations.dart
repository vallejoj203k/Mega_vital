// lib/presentation/screens/workouts/exercise_animations.dart

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// ── Cloudflare R2 (egress gratis) ─────────────────────────────────
// Bucket público: megavital-media
// Estructura: exercise-animations/{folder}/{id}.mp4  (videos)
//             exercise-images/{folder}/{id}.jpg       (fotos)
const _kStorageBase =
    'https://pub-8ff0ad1a7d05499e9161f5d3198bd0e1.r2.dev/exercise-animations';

const _kImageBase =
    'https://pub-8ff0ad1a7d05499e9161f5d3198bd0e1.r2.dev/exercise-images';

const _kPrefixToFolder = <String, String>{
  'pec': 'pectoral',
  'hom': 'hombros',
  'bic': 'biceps',
  'tri': 'triceps',
  'esp': 'espalda',
  'dor': 'espalda',
  'lum': 'espalda',
  'abs': 'abdominales',
  'cua': 'cuadriceps',
  'gem': 'gemelos',
  'glu': 'gluteos',
  'isq': 'isquiotibiales',
};

String? _videoUrl(String exerciseId) {
  final prefix = exerciseId.replaceAll(RegExp(r'[0-9]'), '');
  final folder  = _kPrefixToFolder[prefix];
  if (folder == null) return null;
  return '$_kStorageBase/$folder/$exerciseId.mp4';
}

String? _imageUrl(String exerciseId) {
  final prefix = exerciseId.replaceAll(RegExp(r'[0-9]'), '');
  final folder  = _kPrefixToFolder[prefix];
  if (folder == null) return null;
  return '$_kImageBase/$folder/$exerciseId.jpg';
}

// ── Widget principal ──────────────────────────────────────────────
// Muestra el primer frame del video como miniatura estática.
// El usuario toca para reproducir; tocar otro video pausa el actual.
// activeVideoNotifier: notifier compartido entre todas las tarjetas
// del mismo panel para garantizar que solo uno reproduzca a la vez.
class ExerciseAnimationWidget extends StatefulWidget {
  final String               exerciseId;
  final Color                color;
  final double               size;
  final ValueNotifier<String?>? activeVideoNotifier;

  const ExerciseAnimationWidget({
    super.key,
    required this.exerciseId,
    required this.color,
    this.size = 120,
    this.activeVideoNotifier,
  });

  @override
  State<ExerciseAnimationWidget> createState() => _ExerciseAnimationWidgetState();
}

class _ExerciseAnimationWidgetState extends State<ExerciseAnimationWidget> {
  VideoPlayerController? _controller;
  bool _hasVideoError = false;
  bool _isPlaying     = false;

  @override
  void initState() {
    super.initState();
    widget.activeVideoNotifier?.addListener(_onActiveChanged);
    _initVideo();
  }

  @override
  void didUpdateWidget(ExerciseAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseId != widget.exerciseId) {
      widget.activeVideoNotifier?.removeListener(_onActiveChanged);
      widget.activeVideoNotifier?.addListener(_onActiveChanged);
      _controller?.dispose();
      _controller = null;
      _hasVideoError = false;
      _isPlaying = false;
      _initVideo();
    }
  }

  @override
  void dispose() {
    widget.activeVideoNotifier?.removeListener(_onActiveChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _onActiveChanged() {
    if (widget.activeVideoNotifier?.value != widget.exerciseId && _isPlaying) {
      _controller?.pause();
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _initVideo() async {
    final url = _videoUrl(widget.exerciseId);
    if (url == null) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.setLooping(true);
      controller.setVolume(0);
      await controller.seekTo(Duration.zero);
      setState(() => _controller = controller);
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _hasVideoError = true);
    }
  }

  void _togglePlay() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (_isPlaying) {
      ctrl.pause();
      setState(() => _isPlaying = false);
    } else {
      widget.activeVideoNotifier?.value = widget.exerciseId;
      ctrl.play();
      setState(() => _isPlaying = true);
    }
  }

  Widget _placeholder() => SizedBox(
    width:  widget.size,
    height: widget.size * 1.15,
    child: Container(
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.color.withOpacity(0.18)),
      ),
      child: Icon(Icons.fitness_center_rounded,
          color: widget.color.withOpacity(0.35), size: widget.size * 0.4),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // 1️⃣ Video inicializado → reproducir
    final ctrl = _controller;
    if (ctrl != null && ctrl.value.isInitialized) {
      return GestureDetector(
        onTap: _togglePlay,
        child: SizedBox(
          width:  widget.size,
          height: widget.size * 1.15,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width:  ctrl.value.size.width,
                    height: ctrl.value.size.height,
                    child:  VideoPlayer(ctrl),
                  ),
                ),
              ),
              if (!_isPlaying)
                Container(
                  width:  widget.size * 0.38,
                  height: widget.size * 0.38,
                  decoration: BoxDecoration(
                    color:  Colors.black.withOpacity(0.55),
                    shape:  BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow_rounded,
                      color: widget.color, size: widget.size * 0.24),
                ),
            ],
          ),
        ),
      );
    }

    // 2️⃣ Sin video → imagen de la máquina
    final imgUrl = _imageUrl(widget.exerciseId);
    if (imgUrl != null) {
      return SizedBox(
        width:  widget.size,
        height: widget.size * 1.15,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imgUrl,
            fit: BoxFit.cover,
            errorBuilder:   (_, __, ___) => _placeholder(),
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _placeholder(),
          ),
        ),
      );
    }

    // 3️⃣ Sin imagen → ícono placeholder
    return _placeholder();
  }
}

