import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // Corrected import path
import 'package:record/record.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:async';

void main() {
  runApp(const GuitarNoteDetectorApp());
}

// Enum for Pitch Detection Algorithms
enum PitchAlgorithm { autocorrelation, yin }

// Enum for Guitar Tuning Modes
enum TuningMode { standard, dropD }

// Global settings class to be passed down the widget tree
class AppSettings extends ChangeNotifier {
  PitchAlgorithm _pitchAlgorithm = PitchAlgorithm.autocorrelation;
  TuningMode _tuningMode = TuningMode.standard;
  double _sensitivity = 0.5; // 0.0 to 1.0
  double _smoothing = 0.5; // 0.0 to 1.0

  PitchAlgorithm get pitchAlgorithm => _pitchAlgorithm;
  TuningMode get tuningMode => _tuningMode;
  double get sensitivity => _sensitivity;
  double get smoothing => _smoothing;

  void setPitchAlgorithm(PitchAlgorithm algorithm) {
    if (_pitchAlgorithm != algorithm) {
      _pitchAlgorithm = algorithm;
      notifyListeners();
    }
  }

  void setTuningMode(TuningMode mode) {
    if (_tuningMode != mode) {
      _tuningMode = mode;
      notifyListeners();
    }
  }

  void setSensitivity(double value) {
    if (_sensitivity != value) {
      _sensitivity = value;
      notifyListeners();
    }
  }

  void setSmoothing(double value) {
    if (_smoothing != value) {
      _smoothing = value;
      notifyListeners();
    }
  }
}

class GuitarNoteDetectorApp extends StatefulWidget {
  const GuitarNoteDetectorApp({super.key});

  @override
  State<GuitarNoteDetectorApp> createState() => _GuitarNoteDetectorAppState();
}

class _GuitarNoteDetectorAppState extends State<GuitarNoteDetectorApp> {
  int _selectedIndex = 0;
  final AppSettings _appSettings = AppSettings();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the sheet to be full height if needed
      builder: (context) {
        return ChangeNotifierProvider<AppSettings>(
          value: _appSettings, // Provide the same instance
          child: const SettingsScreen(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppSettings>(
      value: _appSettings, // Provide AppSettings to the entire app
      child: MaterialApp(
        title: 'Guitar Note Detector Pro',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
            secondary: Colors.amber, // Example secondary color
          ),
        ),
        home: Scaffold(
          body: Builder( // Use Builder to get a context for the Scaffold
            builder: (context) {
              return _selectedIndex == 0
                  ? AudioRecorderScreen(openSettings: () => _openSettings(context))
                  : TunerModeScreen(openSettings: () => _openSettings(context));
            },
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Detailed Tuner',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.music_note),
                label: 'Simple Tuner',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}

// --- Provider for AppSettings (similar to how you might use provider package) ---
// This is a simplified version for demonstration within a single file.
// In a real app, you'd use the 'provider' package.
class ChangeNotifierProvider<T extends ChangeNotifier> extends InheritedNotifier<T> {
  const ChangeNotifierProvider({
    super.key,
    required T value,
    required super.child,
  }) : super(notifier: value);

  static T of<T extends ChangeNotifier>(BuildContext context, {bool listen = true}) {
    final provider = listen
        ? context.dependOnInheritedWidgetOfExactType<ChangeNotifierProvider<T>>()
        : context.findAncestorWidgetOfExactType<ChangeNotifierProvider<T>>();
    assert(provider != null, 'No ChangeNotifierProvider found for type $T');
    return provider!.notifier!;
  }
}


// --- AudioRecorderScreen (Detailed Tuner) ---
class AudioRecorderScreen extends StatefulWidget {
  final VoidCallback openSettings;
  const AudioRecorderScreen({super.key, required this.openSettings});

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isInitialized = false;
  bool _isLoading = true;
  String _detectedNote = '';
  double _frequency = 0.0;
  double _confidence = 0.0;
  List<double> _audioSamplesBuffer = [];
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  Timer? _analysisTimer;
  double _lastDetectedFrequency = 0.0; // For smoothing
  Timer? _noteClearTimer; // New: Timer for clearing the displayed note

  List<double> _frequencySpectrum = [];
  double _signalStrength = 0.0;
  double _noiseLevel = 0.0;
  List<double> _pitchStabilityHistory = [];
  double _pitchStability = 0.0;
  double _pitchDeviation = 0.0;
  String _closestNoteName = '';
  double _closestNoteFreq = 0.0;
  bool _isSignalTooQuiet = false;
  bool _isSignalTooLoud = false;
  bool _hasExcessiveNoise = false;
  bool _isGuitarSoundPresent = false; // New flag for guitar sound detection

  double _minSignalThreshold = 0.01;
  double _maxSignalThreshold = 0.8;
  double _noiseThreshold = 0.05;

  // Panel expansion states
  bool _isGuitarStringMatchExpanded = true;
  bool _isFretboardExpanded = true;
  bool _isSignalMetricsExpanded = true;
  bool _isFrequencySpectrumExpanded = true;
  bool _isSpectrogramExpanded = true;

  List<List<double>> _spectrogramData = [];
  static const int _spectrogramBins = 256;
  static const int _spectrogramHistory = 50;

  static const int _sampleRate = 44100;
  static const int _bufferSize = 4096;

  // Note frequencies for different tunings
  late Map<String, double> _currentGuitarNotes;

  final Map<String, double> _standardTuningNotes = {
    'E2': 82.41, // Low E
    'A2': 110.0, // A
    'D3': 146.8, // D
    'G3': 196.0, // G
    'B3': 246.9, // B
    'E4': 329.6, // High E
  };

  final Map<String, double> _dropDTuningNotes = {
    'D2': 73.42, // Drop D
    'A2': 110.0,
    'D3': 146.8,
    'G3': 196.0,
    'B3': 246.9,
    'E4': 329.6,
  };

  final Map<String, double> _allNoteFrequencies = {
    'C0': 16.35, 'C#0': 17.32, 'D0': 18.35, 'D#0': 19.45, 'E0': 20.60, 'F0': 21.83,
    'F#0': 23.12, 'G0': 24.50, 'G#0': 25.96, 'A0': 27.50, 'A#0': 29.14, 'B0': 30.87,
    'C1': 32.70, 'C#1': 34.65, 'D1': 36.71, 'D#1': 38.89, 'E1': 41.20, 'F1': 43.65,
    'F#1': 46.25, 'G1': 49.00, 'G#1': 51.91, 'A1': 55.00, 'A#1': 58.27, 'B1': 61.74,
    'C2': 65.41, 'C#2': 69.30, 'D2': 73.42, 'D#2': 77.78, 'E2': 82.41, 'F2': 87.31,
    'F#2': 92.50, 'G2': 98.00, 'G#2': 103.8, 'A2': 110.0, 'A#2': 116.5, 'B2': 123.5,
    'C3': 130.8, 'C#3': 138.6, 'D3': 146.8, 'D#3': 155.6, 'E3': 164.8, 'F3': 174.6,
    'F#3': 185.0, 'G3': 196.0, 'G#3': 207.7, 'A3': 220.0, 'A#3': 233.1, 'B3': 246.9,
    'C4': 261.6, 'C#4': 277.2, 'D4': 293.7, 'D#4': 311.1, 'E4': 329.6, 'F4': 349.2,
    'F#4': 370.0, 'G4': 392.0, 'G#4': 415.3, 'A4': 440.0, 'A#4': 466.2, 'B4': 493.9,
    'C5': 523.3, 'C#5': 554.4, 'D5': 587.3, 'D#5': 622.3, 'E5': 659.3, 'F5': 698.5,
    'F#5': 740.0, 'G5': 784.0, 'G#5': 830.6, 'A5': 880.0, 'A#5': 932.3, 'B5': 987.8,
    'C6': 1047, 'C#6': 1109, 'D6': 1175, 'D#6': 1245, 'E6': 1319, 'F6': 1397,
    'F#6': 1480, 'G6': 1568, 'G#6': 1661, 'A6': 1760, 'A#6': 1865, 'B6': 1976,
    'C7': 2093, 'C#7': 2217, 'D7': 2349, 'D#7': 2489, 'E7': 2637, 'F7': 2794,
    'F#7': 2960, 'G7': 3136, 'G#7': 3322, 'A7': 3520, 'A#7': 3729, 'B7': 3951,
    'C8': 4186, 'C#8': 4435, 'D8': 4699, 'D#8': 4978, 'E8': 5274, 'F8': 5588,
    'F#8': 5920, 'G8': 6272, 'G#8': 6645, 'A8': 7040, 'A#8': 7459, 'B8': 7902,
  };

  @override
  void initState() {
    super.initState();
    _currentGuitarNotes = _standardTuningNotes; // Default
    _initializeRecorder();
    _initializeVisualData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to changes in AppSettings
    ChangeNotifierProvider.of<AppSettings>(context).addListener(_onSettingsChanged);
    _onSettingsChanged(); // Apply initial settings
  }

  @override
  void dispose() {
    ChangeNotifierProvider.of<AppSettings>(context).removeListener(_onSettingsChanged);
    _audioStreamSubscription?.cancel();
    _analysisTimer?.cancel();
    _noteClearTimer?.cancel(); // Dispose the new timer
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    final settings = ChangeNotifierProvider.of<AppSettings>(context, listen: false);
    setState(() {
      _currentGuitarNotes = settings.tuningMode == TuningMode.standard
          ? _standardTuningNotes
          : _dropDTuningNotes;
      // Update thresholds based on sensitivity setting
      _minSignalThreshold = 0.01 * (1.0 - settings.sensitivity * 0.8);
      _maxSignalThreshold = 0.8 * (1.0 + settings.sensitivity * 0.2);
      _noiseThreshold = 0.05 * (1.0 - settings.sensitivity * 0.5);
    });
  }

  void _initializeVisualData() {
    _frequencySpectrum = List.filled(_spectrogramBins, 0.0);
    _spectrogramData = List.generate(
        _spectrogramHistory, (index) => List.filled(_spectrogramBins, 0.0));
    _pitchStabilityHistory = [];
  }

  Future<void> _initializeRecorder() async {
    setState(() { _isLoading = true; });
    try {
      // Use Permission and PermissionStatus directly from the correct import
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission denied');
      }
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        throw Exception('Audio recorder permission not granted');
      }
      setState(() { _isInitialized = true; _isLoading = false; });
    } catch (e) {
      _showError('Failed to initialize recorder: $e');
      setState(() { _isInitialized = false; _isLoading = false; });
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized) {
      _showError('Recorder not initialized. Please wait or grant permissions.');
      return;
    }
    try {
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
      );
      _audioStreamSubscription = (await _audioRecorder.startStream(config)).listen((chunk) {
        final newSamples = _convertToSamples(chunk);
        _audioSamplesBuffer.addAll(newSamples);
        if (_audioSamplesBuffer.length > _bufferSize) {
          _audioSamplesBuffer = _audioSamplesBuffer.sublist(
              _audioSamplesBuffer.length - _bufferSize);
        }
      });
      setState(() {
        _isRecording = true;
        _detectedNote = '';
        _frequency = 0.0;
        _confidence = 0.0;
        _pitchDeviation = 0.0;
        _closestNoteName = '';
        _closestNoteFreq = 0.0;
        _audioSamplesBuffer.clear();
        _pitchStabilityHistory.clear();
        _lastDetectedFrequency = 0.0; // Reset smoothing on new recording
        _isGuitarSoundPresent = false; // Reset on start
      });
      _startRealTimeAnalysis();
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      await _audioRecorder.stop();
      _audioStreamSubscription?.cancel();
      _analysisTimer?.cancel();
      _noteClearTimer?.cancel(); // Cancel timer on stop
      setState(() {
        _isRecording = false;
        _detectedNote = '';
        _frequency = 0.0;
        _confidence = 0.0;
        _pitchDeviation = 0.0;
        _closestNoteName = '';
        _closestNoteFreq = 0.0;
        _lastDetectedFrequency = 0.0; // Reset smoothing on stop
        _isGuitarSoundPresent = false; // Reset on stop
      });
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  void _startRealTimeAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      await _analyzeCurrentAudioBuffer(_audioSamplesBuffer);
    });
  }

  Future<void> _analyzeCurrentAudioBuffer(List<double> samples) async {
    final settings = ChangeNotifierProvider.of<AppSettings>(context, listen: false);

    // Adjust thresholds based on sensitivity setting
    final currentMinSignalThreshold = _minSignalThreshold;
    final currentMaxSignalThreshold = _maxSignalThreshold;
    final currentNoiseThreshold = _noiseThreshold;

    if (samples.length < _bufferSize) {
      setState(() {
        _detectedNote = 'No signal';
        _frequency = 0.0;
        _confidence = 0.0;
        _pitchDeviation = 0.0;
        _closestNoteName = '';
        _closestNoteFreq = 0.0;
        _isGuitarSoundPresent = false;
      });
      _noteClearTimer?.cancel(); // Cancel any active timer if signal is lost
      return;
    }
    try {
      final samplesToAnalyze = List<double>.from(samples);
      _updateSignalAnalysis(samplesToAnalyze, currentMinSignalThreshold, currentMaxSignalThreshold, currentNoiseThreshold);

      if (!_isGuitarSoundPresent) {
        if (_noteClearTimer == null || !_noteClearTimer!.isActive) { // Only update if no active timer
          setState(() {
            _detectedNote = 'Waiting for guitar...';
            _frequency = 0.0;
            _confidence = 0.0;
            _pitchDeviation = 0.0;
            _closestNoteName = '';
            _closestNoteFreq = 0.0;
            _lastDetectedFrequency = 0.0;
          });
        }
        return;
      }

      final filteredSamples = _applyAdvancedNoiseReduction(samplesToAnalyze);

      double detectedFrequency;
      if (settings.pitchAlgorithm == PitchAlgorithm.autocorrelation) {
        detectedFrequency = _autocorrelationPitchDetection(filteredSamples);
      } else {
        detectedFrequency = _autocorrelationPitchDetection(filteredSamples);
      }

      final smoothedFrequency = _exponentialSmoothing(detectedFrequency, settings.smoothing);

      if (smoothedFrequency > 0) {
        _noteClearTimer?.cancel(); // Cancel any pending clear operation
        final note = _frequencyToNote(smoothedFrequency);
        double currentPitchDeviation = 0.0;
        if (_closestNoteFreq > 0) {
          currentPitchDeviation = (smoothedFrequency - _closestNoteFreq) / _closestNoteFreq;
          currentPitchDeviation = math.max(-0.05, math.min(0.05, currentPitchDeviation));
          currentPitchDeviation = currentPitchDeviation / 0.05;
        }
        final confidence = _calculateAdvancedConfidence(smoothedFrequency, filteredSamples);
        _updatePitchStability(smoothedFrequency);
        setState(() {
          _frequency = smoothedFrequency;
          _detectedNote = note;
          _confidence = confidence;
          _pitchDeviation = currentPitchDeviation;
          _lastDetectedFrequency = smoothedFrequency;
        });

        // Start a new timer to clear the note after 5 seconds
        _noteClearTimer = Timer(const Duration(seconds: 5), () {
          setState(() {
            _detectedNote = 'Waiting for guitar...';
            _frequency = 0.0;
            _confidence = 0.0;
            _pitchDeviation = 0.0;
            _closestNoteName = '';
            _closestNoteFreq = 0.0;
          });
        });

      } else {
        if (_noteClearTimer == null || !_noteClearTimer!.isActive) { // Only update if no active timer
          setState(() {
            _detectedNote = 'No guitar sound';
            _frequency = 0.0;
            _confidence = 0.0;
            _pitchDeviation = 0.0;
            _closestNoteName = '';
            _closestNoteFreq = 0.0;
            _lastDetectedFrequency = 0.0;
          });
        }
      }
    } catch (e) {
      // Silently handle errors during real-time analysis
    }
  }

  double _exponentialSmoothing(double currentFrequency, double smoothingFactor) {
    if (_lastDetectedFrequency == 0.0 || currentFrequency == 0.0) {
      return currentFrequency;
    }
    // Alpha closer to 1 means less smoothing (more responsive)
    // Alpha closer to 0 means more smoothing (less responsive)
    final alpha = 1.0 - smoothingFactor; // Invert smoothing factor for intuitive slider
    return alpha * currentFrequency + (1.0 - alpha) * _lastDetectedFrequency;
  }


  void _updateSignalAnalysis(List<double> samples, double minThreshold, double maxThreshold, double noiseThreshold) {
    if (samples.isEmpty) {
      _signalStrength = 0.0;
      _noiseLevel = 0.0;
      _isSignalTooQuiet = true;
      _isSignalTooLoud = false;
      _hasExcessiveNoise = false;
      _isGuitarSoundPresent = false; // New flag
      return;
    }

    final rms = math.sqrt(samples.map((s) => s * s).reduce((a, b) => a + b) / samples.length);
    _signalStrength = rms;

    double highFreqEnergy = 0.0;
    for (int i = 1; i < samples.length; i++) {
      final diff = samples[i] - samples[i - 1];
      highFreqEnergy += diff * diff;
    }
    _noiseLevel = math.sqrt(highFreqEnergy / samples.length);

    _isSignalTooQuiet = rms < minThreshold;
    _isSignalTooLoud = rms > maxThreshold;
    _hasExcessiveNoise = _noiseLevel > noiseThreshold;

    // Ensure frequency spectrum is updated before checking for dominant frequency
    _updateFrequencySpectrum(samples);

    // New logic for guitar sound presence: check for dominant frequency in guitar range
    final dominantFreq = _detectDominantFrequencyInRange(_frequencySpectrum, 70.0, 800.0); // Guitar fundamental range
    _isGuitarSoundPresent = !_isSignalTooQuiet && !_isSignalTooLoud && !_hasExcessiveNoise && dominantFreq > 0;
  }

  // New method to detect dominant frequency within a specific range
  double _detectDominantFrequencyInRange(List<double> spectrum, double minFreq, double maxFreq) {
    if (spectrum.isEmpty) return 0.0;

    double maxMagnitude = 0.0;
    int maxMagnitudeBin = -1;

    // Calculate frequency per bin
    final double freqPerBin = (_sampleRate / 2) / _spectrogramBins;

    // Determine the bin indices corresponding to minFreq and maxFreq
    final int minBin = (minFreq / freqPerBin).floor();
    final int maxBin = (maxFreq / freqPerBin).ceil();

    for (int i = 0; i < spectrum.length; i++) {
      // Only consider bins within the specified frequency range
      if (i >= minBin && i <= maxBin) {
        if (spectrum[i] > maxMagnitude) {
          maxMagnitude = spectrum[i];
          maxMagnitudeBin = i;
        }
      }
    }

    // A threshold for meaningful peak magnitude (e.g., 5% of max possible normalized magnitude)
    if (maxMagnitudeBin != -1 && maxMagnitude > 0.05) {
      return maxMagnitudeBin * freqPerBin;
    }
    return 0.0;
  }


  void _updateFrequencySpectrum(List<double> samples) {
    if (samples.length < _spectrogramBins) return;
    final spectrum = List.filled(_spectrogramBins, 0.0);
    final windowSize = samples.length ~/ _spectrogramBins;
    for (int i = 0; i < _spectrogramBins; i++) {
      double magnitude = 0.0;
      final startIdx = i * windowSize;
      final endIdx = math.min(startIdx + windowSize, samples.length);
      for (int j = startIdx; j < endIdx; j++) {
        magnitude += samples[j].abs();
      }
      spectrum[i] = magnitude / windowSize;
    }
    _frequencySpectrum = spectrum;
    _spectrogramData.removeAt(0);
    _spectrogramData.add(List.from(spectrum));
  }

  void _updatePitchStability(double frequency) {
    _pitchStabilityHistory.add(frequency);
    if (_pitchStabilityHistory.length > 20) {
      _pitchStabilityHistory.removeAt(0);
    }
    if (_pitchStabilityHistory.length > 5) {
      final mean =
          _pitchStabilityHistory.reduce((a, b) => a + b) / _pitchStabilityHistory.length;
      final variance = _pitchStabilityHistory
          .map((f) => math.pow(f - mean, 2))
          .reduce((a, b) => a + b) /
          _pitchStabilityHistory.length;
      final standardDeviation = math.sqrt(variance);
      _pitchStability = math.max(0.0, 1.0 - (standardDeviation / 50.0));
    }
  }

  List<double> _convertToSamples(Uint8List bytes) {
    const headerSize = 0;
    if (bytes.length < 2) return [];
    final samples = <double>[];
    for (int i = headerSize; i < bytes.length - 1; i += 2) {
      final sample = (bytes[i] | (bytes[i + 1] << 8));
      final normalizedSample = (sample > 32767 ? sample - 65536 : sample) / 32768.0;
      samples.add(normalizedSample);
    }
    return samples;
  }

  List<double> _applyAdvancedNoiseReduction(List<double> samples) {
    if (samples.isEmpty) return samples;
    var filtered = samples;
    filtered = _highPassFilter(filtered, 80.0, _sampleRate);
    filtered = _lowPassFilter(filtered, 2000.0, _sampleRate);
    filtered = _adaptiveNoiseGate(filtered);
    return filtered;
  }

  List<double> _highPassFilter(
      List<double> samples, double cutoffFreq, int sampleRate) {
    final filtered = <double>[];
    final rc = 1.0 / (2 * math.pi * cutoffFreq);
    final dt = 1.0 / sampleRate;
    final alpha = rc / (rc + dt);
    double prevInput = 0.0;
    double prevOutput = 0.0;
    for (final sample in samples) {
      final output = alpha * (prevOutput + sample - prevInput);
      filtered.add(output);
      prevInput = sample;
      prevOutput = output;
    }
    return filtered;
  }

  List<double> _lowPassFilter(
      List<double> samples, double cutoffFreq, int sampleRate) {
    final filtered = <double>[];
    final rc = 1.0 / (2 * math.pi * cutoffFreq);
    final dt = 1.0 / sampleRate;
    final alpha = dt / (rc + dt);
    double prevOutput = 0.0;
    for (final sample in samples) {
      final output = prevOutput + alpha * (sample - prevOutput);
      filtered.add(output);
      prevOutput = output;
    }
    return filtered;
  }

  List<double> _adaptiveNoiseGate(List<double> samples) {
    if (samples.isEmpty) return samples;
    final rms = math.sqrt(samples.map((s) => s * s).reduce((a, b) => a + b) / samples.length);
    final threshold = rms * 0.1;
    return samples.map((sample) => sample.abs() > threshold ? sample : 0.0).toList();
  }

  double _autocorrelationPitchDetection(List<double> samples) {
    final n = samples.length;
    final minPeriod = (_sampleRate / 800).round();
    final maxPeriod = (_sampleRate / 80).round();
    double maxCorrelation = 0.0;
    int bestPeriod = 0;
    for (int period = minPeriod; period < maxPeriod && period < n ~/ 2; period++) {
      double correlation = 0.0;
      double energy = 0.0;
      for (int i = 0; i < n - period; i++) {
        correlation += samples[i] * samples[i + period];
        energy += samples[i] * samples[i];
      }
      if (energy > 0) {
        correlation /= energy;
        if (correlation > maxCorrelation) {
          maxCorrelation = correlation;
          bestPeriod = period;
        }
      }
    }
    return bestPeriod > 0 && maxCorrelation > 0.3
        ? _sampleRate / bestPeriod
        : 0.0;
  }

  String _frequencyToNote(double frequency) {
    if (frequency < 70) {
      _closestNoteName = '';
      _closestNoteFreq = 0.0;
      return 'No signal';
    }
    double minDiff = double.infinity;
    String tempClosestNote = 'Unknown';
    double tempClosestFreq = 0.0;
    _allNoteFrequencies.forEach((note, freq) {
      final diff = (frequency - freq).abs();
      if (diff < minDiff) {
        minDiff = diff;
        tempClosestNote = note;
        tempClosestFreq = freq;
      }
    });
    _closestNoteName = tempClosestNote;
    _closestNoteFreq = tempClosestFreq;
    if (minDiff > 15) {
      return 'Between notes';
    }
    return tempClosestNote;
  }

  double _calculateAdvancedConfidence(double frequency, List<double> samples) {
    if (frequency < 80) return 0.0;
    double totalConfidence = 0.0;
    int factors = 0;
    double minDiff = double.infinity;
    _allNoteFrequencies.forEach((note, freq) {
      final diff = (frequency - freq).abs();
      if (diff < minDiff) {
        minDiff = diff;
      }
    });
    final freqConfidence = math.max(0.0, 1.0 - (minDiff / 10.0));
    totalConfidence += freqConfidence;
    factors++;
    if (samples.isNotEmpty) {
      final rms = math.sqrt(samples.map((s) => s * s).reduce((a, b) => a + b) / samples.length);
      final strengthConfidence = math.min(1.0, rms * 10);
      totalConfidence += strengthConfidence;
      factors++;
    }
    final period = _sampleRate / frequency;
    if (period > 0 && samples.length > period * 2) {
      double harmonicStability = 0.0;
      final periodInt = period.round();
      for (int i = 0; i < samples.length - periodInt * 2; i += periodInt) {
        final corr = samples[i] * samples[i + periodInt];
        harmonicStability += corr.abs();
      }
      harmonicStability /= (samples.length / periodInt);
      totalConfidence += math.min(1.0, harmonicStability);
      factors++;
    }
    return factors > 0 ? totalConfidence / factors : 0.0;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildCollapsiblePanel({
    required String title,
    required Widget content,
    required bool isExpanded,
    required ValueChanged<bool> onToggle,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => onToggle(!isExpanded),
            ),
            onTap: () => onToggle(!isExpanded), // Tap anywhere on tile to toggle
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildSignalStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Signal Strength', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: math.min(1.0, _signalStrength * 5),
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            _isSignalTooQuiet
                ? Colors.red
                : _isSignalTooLoud
                ? Colors.orange
                : Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (_isSignalTooQuiet)
              const Text('Too quiet', style: TextStyle(color: Colors.red, fontSize: 12)),
            if (_isSignalTooLoud)
              const Text('Too loud', style: TextStyle(color: Colors.orange, fontSize: 12)),
            if (_hasExcessiveNoise)
              const Text(' • Noisy', style: TextStyle(color: Colors.red, fontSize: 12)),
            if (!_isSignalTooQuiet && !_isSignalTooLoud && !_hasExcessiveNoise)
              const Text('Good signal', style: TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildPitchStabilityIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pitch Stability', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: _pitchStability,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            _pitchStability > 0.8
                ? Colors.green
                : _pitchStability > 0.5
                ? Colors.orange
                : Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(_pitchStability * 100).toStringAsFixed(0)}% stable',
          style: TextStyle(
            color: _pitchStability > 0.8
                ? Colors.green
                : _pitchStability > 0.5
                ? Colors.orange
                : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPitchDeviationIndicator() {
    return Column(
      children: [
        const Text('Pitch Deviation', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        CustomPaint(
          size: const Size(double.infinity, 50),
          painter: PitchDeviationPainter(_pitchDeviation),
        ),
        const SizedBox(height: 8),
        Text(
          _pitchDeviation == 0.0
              ? 'Perfect'
              : _pitchDeviation > 0
              ? '+${(_pitchDeviation * 100).toStringAsFixed(1)} cents'
              : '${(_pitchDeviation * 100).toStringAsFixed(1)} cents',
          style: TextStyle(
            color: _pitchDeviation.abs() < 0.01 ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGuitarStringMatchPanel() {
    return Column(
      children: _currentGuitarNotes.entries.map((entry) {
        final noteName = entry.key;
        final noteFreq = entry.value;
        final isClosest = _closestNoteName == noteName;
        final isDetected = isClosest && _frequency > 0;
        final diff = isDetected ? (_frequency - noteFreq).abs() : double.infinity;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  noteName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isClosest ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  '${noteFreq.toStringAsFixed(1)} Hz',
                  style: TextStyle(
                    fontSize: 16,
                    color: isClosest ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: isDetected
                    ? LinearProgressIndicator(
                  value: 1.0 - (diff / noteFreq).abs() * 10, // Scale difference to 0-1
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _pitchDeviation.abs() < 0.01 ? Colors.green : Colors.orange,
                  ),
                )
                    : LinearProgressIndicator(
                  value: 0,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.transparent),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isClosest && _pitchDeviation.abs() < 0.01 ? Icons.check_circle : Icons.circle_outlined,
                color: isClosest && _pitchDeviation.abs() < 0.01 ? Colors.green : Colors.grey,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guitar Note Detector Pro (Detailed)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: widget.openSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRecording
                        ? Icons.mic
                        : _isLoading
                        ? Icons.hourglass_empty
                        : Icons.mic_off,
                    color: _isRecording ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isRecording
                        ? 'Listening for guitar...'
                        : _isLoading
                        ? 'Initializing recorder...'
                        : 'Ready to record',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isRecording ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Detected Note',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _detectedNote.isNotEmpty ? _detectedNote : 'N/A',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: _detectedNote.isNotEmpty ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                    ),
                    Text(
                      _frequency > 0 ? '${_frequency.toStringAsFixed(2)} Hz' : '',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPitchDeviationIndicator(),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : _isRecording
                          ? _stopRecording
                          : _startRecording,
                      icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
                      label: Text(_isRecording ? 'Stop Listening' : 'Start Listening'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildCollapsiblePanel(
              title: 'Guitar String Match',
              isExpanded: _isGuitarStringMatchExpanded,
              onToggle: (bool value) {
                setState(() {
                  _isGuitarStringMatchExpanded = value;
                });
              },
              content: _buildGuitarStringMatchPanel(),
            ),

            _buildCollapsiblePanel(
              title: 'Fretboard Visualizer',
              isExpanded: _isFretboardExpanded,
              onToggle: (bool value) {
                setState(() {
                  _isFretboardExpanded = value;
                });
              },
              content: FretboardVisualizer(
                detectedNoteName: _closestNoteName,
                detectedFrequency: _frequency,
                allNoteFrequencies: _allNoteFrequencies,
                tuningNotes: _currentGuitarNotes,
              ),
            ),

            _buildCollapsiblePanel(
              title: 'Signal Metrics',
              isExpanded: _isSignalMetricsExpanded,
              onToggle: (bool value) {
                setState(() {
                  _isSignalMetricsExpanded = value;
                });
              },
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSignalStrengthIndicator(),
                  const SizedBox(height: 16),
                  _buildPitchStabilityIndicator(),
                  const SizedBox(height: 16),
                  Text('Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  LinearProgressIndicator(
                    value: _confidence,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _confidence > 0.7 ? Colors.green : _confidence > 0.4 ? Colors.orange : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Noise Level: ${_noiseLevel.toStringAsFixed(3)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Min Signal Threshold: ${_minSignalThreshold.toStringAsFixed(3)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Max Signal Threshold: ${_maxSignalThreshold.toStringAsFixed(3)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Noise Threshold: ${_noiseThreshold.toStringAsFixed(3)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            _buildCollapsiblePanel(
              title: 'Frequency Spectrum',
              isExpanded: _isFrequencySpectrumExpanded,
              onToggle: (bool value) {
                setState(() {
                  _isFrequencySpectrumExpanded = value;
                });
              },
              content: FrequencySpectrumVisualizer(spectrumData: _frequencySpectrum),
            ),

            _buildCollapsiblePanel(
              title: 'Spectrogram',
              isExpanded: _isSpectrogramExpanded,
              onToggle: (bool value) {
                setState(() {
                  _isSpectrogramExpanded = value;
                });
              },
              content: SpectrogramVisualizer(spectrogramData: _spectrogramData),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Pitch Deviation Indicator
class PitchDeviationPainter extends CustomPainter {
  final double deviation; // -1.0 to 1.0

  PitchDeviationPainter(this.deviation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    // Background bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2),
        const Radius.circular(5),
      ),
      paint,
    );

    // Center line
    paint.color = Colors.grey.shade500;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.49, size.height * 0.3, size.width * 0.02, size.height * 0.4),
      paint,
    );

    // Needle
    final needleX = size.width * 0.5 + deviation * (size.width * 0.4);
    paint.color = deviation.abs() < 0.01 ? Colors.green : Colors.red;
    canvas.drawCircle(Offset(needleX, size.height * 0.5), size.height * 0.25, paint);
  }

  @override
  bool shouldRepaint(covariant PitchDeviationPainter oldDelegate) {
    return oldDelegate.deviation != deviation;
  }
}

// Fretboard Visualizer Widget
class FretboardVisualizer extends StatelessWidget {
  final String detectedNoteName;
  final double detectedFrequency;
  final Map<String, double> allNoteFrequencies;
  final Map<String, double> tuningNotes; // E.g., E2, A2, D3, G3, B3, E4

  const FretboardVisualizer({
    super.key,
    required this.detectedNoteName,
    required this.detectedFrequency,
    required this.allNoteFrequencies,
    required this.tuningNotes,
  });

  @override
  Widget build(BuildContext context) {
    // Sort tuning notes by frequency to ensure correct string order (low to high)
    final sortedTuningNotes = tuningNotes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Column(
      children: [
        // Display the detected note prominently at the top
        if (detectedNoteName.isNotEmpty && detectedFrequency > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Currently Playing: $detectedNoteName',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.brown.shade700,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Column(
            children: sortedTuningNotes.map((tuningEntry) {
              final openNoteName = tuningEntry.key;
              final openNoteFreq = tuningEntry.value;

              return _buildGuitarString(
                context,
                openNoteName,
                openNoteFreq,
                detectedNoteName,
                detectedFrequency,
                allNoteFrequencies,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGuitarString(
      BuildContext context,
      String openNoteName,
      double openNoteFreq,
      String detectedNoteName,
      double detectedFrequency,
      Map<String, double> allNoteFrequencies,
      ) {
    final List<Widget> frets = [];
    // Add open string (fret 0)
    frets.add(_buildFretCell(
      context,
      '0',
      openNoteName,
      openNoteFreq,
      detectedNoteName,
      detectedFrequency,
      isFretZero: true,
    ));

    // Add frets 1-12
    for (int i = 1; i <= 12; i++) {
      final fretNote = _getNoteAtFret(openNoteName, i, allNoteFrequencies);
      frets.add(_buildFretCell(
        context,
        '$i',
        fretNote['name']!,
        fretNote['frequency']!,
        detectedNoteName,
        detectedFrequency,
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: frets,
      ),
    );
  }

  Map<String, dynamic> _getNoteAtFret(
      String openNoteName, int fretNumber, Map<String, double> allNoteFrequencies) {
    final List<String> chromaticScale = [
      'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
    ];

    // Find the index of the open note in the chromatic scale
    int openNoteIndex = -1;
    int openNoteOctave = 0;
    for (int i = 0; i < chromaticScale.length; i++) {
      if (openNoteName.startsWith(chromaticScale[i])) {
        openNoteIndex = i;
        openNoteOctave = int.parse(openNoteName.substring(chromaticScale[i].length));
        break;
      }
    }

    if (openNoteIndex == -1) {
      return {'name': 'N/A', 'frequency': 0.0};
    }

    int targetNoteIndex = (openNoteIndex + fretNumber) % chromaticScale.length;
    int targetOctaveShift = (openNoteIndex + fretNumber) ~/ chromaticScale.length;
    int targetOctave = openNoteOctave + targetOctaveShift;

    final targetNoteName = '${chromaticScale[targetNoteIndex]}$targetOctave';
    final targetFrequency = allNoteFrequencies[targetNoteName] ?? 0.0;

    return {'name': targetNoteName, 'frequency': targetFrequency};
  }

  Widget _buildFretCell(
      BuildContext context,
      String fretNumber,
      String noteName,
      double noteFrequency,
      String detectedNoteName,
      double detectedFrequency, {
        bool isFretZero = false,
      }) {
    final isTargetNote = noteName == detectedNoteName;
    final isPerfectMatch = isTargetNote && (detectedFrequency - noteFrequency).abs() < 0.5; // Within 0.5 Hz for perfect match

    Color backgroundColor = Colors.brown.shade800;
    Color textColor = Colors.white;
    if (isTargetNote) {
      backgroundColor = isPerfectMatch ? Colors.green.shade700 : Colors.orange.shade700;
      textColor = Colors.white;
    } else if (isFretZero) {
      backgroundColor = Colors.brown.shade600;
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              fretNumber,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 10,
              ),
            ),
            Text(
              noteName,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (isTargetNote && detectedFrequency > 0)
              Text(
                '${detectedFrequency.toStringAsFixed(1)} Hz',
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Frequency Spectrum Visualizer Widget
class FrequencySpectrumVisualizer extends StatelessWidget {
  final List<double> spectrumData; // Normalized 0.0 to 1.0

  const FrequencySpectrumVisualizer({super.key, required this.spectrumData});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: CustomPaint(
        painter: SpectrumPainter(spectrumData),
      ),
    );
  }
}

// Custom Painter for Frequency Spectrum
class SpectrumPainter extends CustomPainter {
  final List<double> spectrumData;

  SpectrumPainter(this.spectrumData);

  @override
  void paint(Canvas canvas, Size size) {
    if (spectrumData.isEmpty) return;

    final barWidth = size.width / spectrumData.length;
    final paint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    for (int i = 0; i < spectrumData.length; i++) {
      final barHeight = spectrumData[i] * size.height;
      canvas.drawRect(
        Rect.fromLTWH(i * barWidth, size.height - barHeight, barWidth, barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpectrumPainter oldDelegate) {
    return oldDelegate.spectrumData != spectrumData;
  }
}

// Spectrogram Visualizer Widget
class SpectrogramVisualizer extends StatelessWidget {
  final List<List<double>> spectrogramData; // List of spectrums, each 0.0 to 1.0

  const SpectrogramVisualizer({super.key, required this.spectrogramData});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: CustomPaint(
        painter: SpectrogramPainter(spectrogramData),
      ),
    );
  }
}

// Custom Painter for Spectrogram
class SpectrogramPainter extends CustomPainter {
  final List<List<double>> spectrogramData;

  SpectrogramPainter(this.spectrogramData);

  @override
  void paint(Canvas canvas, Size size) {
    if (spectrogramData.isEmpty || spectrogramData[0].isEmpty) return;

    final historyLength = spectrogramData.length;
    final binCount = spectrogramData[0].length;

    final pixelWidth = size.width / historyLength;
    final pixelHeight = size.height / binCount;

    for (int x = 0; x < historyLength; x++) {
      for (int y = 0; y < binCount; y++) {
        final value = spectrogramData[x][y]; // Value from 0.0 to 1.0
        final color = Color.lerp(Colors.black, Colors.blue.shade700, value);
        if (color != null) {
          final paint = Paint()..color = color;
          canvas.drawRect(
            Rect.fromLTWH(
              x * pixelWidth,
              size.height - (y + 1) * pixelHeight, // Invert y-axis for frequency display
              pixelWidth,
              pixelHeight,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpectrogramPainter oldDelegate) {
    return oldDelegate.spectrogramData != spectrogramData;
  }
}


// --- TunerModeScreen (Simple Tuner) ---
class TunerModeScreen extends StatefulWidget {
  final VoidCallback openSettings;
  const TunerModeScreen({super.key, required this.openSettings});

  @override
  State<TunerModeScreen> createState() => _TunerModeScreenState();
}

class _TunerModeScreenState extends State<TunerModeScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isInitialized = false;
  bool _isLoading = true;
  String _detectedNote = '';
  double _frequency = 0.0;
  double _confidence = 0.0;
  List<double> _audioSamplesBuffer = [];
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  Timer? _analysisTimer;
  double _lastDetectedFrequency = 0.0; // For smoothing
  Timer? _noteClearTimer; // New: Timer for clearing the displayed note

  double _pitchDeviation = 0.0;
  String _closestNoteName = '';
  double _closestNoteFreq = 0.0;
  bool _isGuitarSoundPresent = false; // New flag for guitar sound detection
  List<double> _frequencySpectrum = []; // Needed for dominant frequency detection

  double _minSignalThreshold = 0.01;
  double _maxSignalThreshold = 0.8;
  double _noiseThreshold = 0.05;

  // Added missing state variables for TunerModeScreen
  double _signalStrength = 0.0;
  double _noiseLevel = 0.0;
  List<double> _pitchStabilityHistory = [];
  double _pitchStability = 0.0;
  bool _isSignalTooQuiet = false;
  bool _isSignalTooLoud = false;
  bool _hasExcessiveNoise = false;
  late Map<String, double> _currentGuitarNotes; // Needed for settings

  // Note frequencies for different tunings (added to TunerModeScreenState)
  final Map<String, double> _standardTuningNotes = {
    'E2': 82.41, // Low E
    'A2': 110.0, // A
    'D3': 146.8, // D
    'G3': 196.0, // G
    'B3': 246.9, // B
    'E4': 329.6, // High E
  };

  final Map<String, double> _dropDTuningNotes = {
    'D2': 73.42, // Drop D
    'A2': 110.0,
    'D3': 146.8,
    'G3': 196.0,
    'B3': 246.9,
    'E4': 329.6,
  };

  static const int _sampleRate = 44100;
  static const int _bufferSize = 4096;
  static const int _spectrogramBins = 256; // Needed for dominant frequency detection

  final Map<String, double> _allNoteFrequencies = {
    'C0': 16.35, 'C#0': 17.32, 'D0': 18.35, 'D#0': 19.45, 'E0': 20.60, 'F0': 21.83,
    'F#0': 23.12, 'G0': 24.50, 'G#0': 25.96, 'A0': 27.50, 'A#0': 29.14, 'B0': 30.87,
    'C1': 32.70, 'C#1': 34.65, 'D1': 36.71, 'D#1': 38.89, 'E1': 41.20, 'F1': 43.65,
    'F#1': 46.25, 'G1': 49.00, 'G#1': 51.91, 'A1': 55.00, 'A#1': 58.27, 'B1': 61.74,
    'C2': 65.41, 'C#2': 69.30, 'D2': 73.42, 'D#2': 77.78, 'E2': 82.41, 'F2': 87.31,
    'F#2': 92.50, 'G2': 98.00, 'G#2': 103.8, 'A2': 110.0, 'A#2': 116.5, 'B2': 123.5,
    'C3': 130.8, 'C#3': 138.6, 'D3': 146.8, 'D#3': 155.6, 'E3': 164.8, 'F3': 174.6,
    'F#3': 185.0, 'G3': 196.0, 'G#3': 207.7, 'A3': 220.0, 'A#3': 233.1, 'B3': 246.9,
    'C4': 261.6, 'C#4': 277.2, 'D4': 293.7, 'D#4': 311.1, 'E4': 329.6, 'F4': 349.2,
    'F#4': 370.0, 'G4': 392.0, 'G#4': 415.3, 'A4': 440.0, 'A#4': 466.2, 'B4': 493.9,
    'C5': 523.3, 'C#5': 554.4, 'D5': 587.3, 'D#5': 622.3, 'E5': 659.3, 'F5': 698.5,
    'F#5': 740.0, 'G5': 784.0, 'G#5': 830.6, 'A5': 880.0, 'A#5': 932.3, 'B5': 987.8,
    'C6': 1047, 'C#6': 1109, 'D6': 1175, 'D#6': 1245, 'E6': 1319, 'F6': 1397,
    'F#6': 1480, 'G6': 1568, 'G#6': 1661, 'A6': 1760, 'A#6': 1865, 'B6': 1976,
    'C7': 2093, 'C#7': 2217, 'D7': 2349, 'D#7': 2489, 'E7': 2637, 'F7': 2794,
    'F#7': 2960, 'G7': 3136, 'G#7': 3322, 'A7': 3520, 'A#7': 3729, 'B7': 3951,
    'C8': 4186, 'C#8': 4435, 'D8': 4699, 'D#8': 4978, 'E8': 5274, 'F8': 5588,
    'F#8': 5920, 'G8': 6272, 'G#8': 6645, 'A8': 7040, 'A#8': 7459, 'B8': 7902,
  };

  @override
  void initState() {
    super.initState();
    _currentGuitarNotes = _standardTuningNotes; // Initialize here as well
    _initializeRecorder();
    _frequencySpectrum = List.filled(_spectrogramBins, 0.0); // Initialize spectrum
    _pitchStabilityHistory = []; // Initialize pitch stability history
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ChangeNotifierProvider.of<AppSettings>(context).addListener(_onSettingsChanged);
    _onSettingsChanged(); // Apply initial settings
  }

  @override
  void dispose() {
    ChangeNotifierProvider.of<AppSettings>(context).removeListener(_onSettingsChanged);
    _audioStreamSubscription?.cancel();
    _analysisTimer?.cancel();
    _noteClearTimer?.cancel(); // Dispose the new timer
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    final settings = ChangeNotifierProvider.of<AppSettings>(context, listen: false);
    setState(() {
      // TunerModeScreen doesn't directly use _currentGuitarNotes for display,
      // but it's good practice to keep it updated if settings affect underlying logic.
      _currentGuitarNotes = settings.tuningMode == TuningMode.standard
          ? _standardTuningNotes
          : _dropDTuningNotes;
      _minSignalThreshold = 0.01 * (1.0 - settings.sensitivity * 0.8);
      _maxSignalThreshold = 0.8 * (1.0 + settings.sensitivity * 0.2);
      _noiseThreshold = 0.05 * (1.0 - settings.sensitivity * 0.5);
    });
  }

  Future<void> _initializeRecorder() async {
    setState(() { _isLoading = true; });
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission denied');
      }
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        throw Exception('Audio recorder permission not granted');
      }
      setState(() { _isInitialized = true; _isLoading = false; });
    } catch (e) {
      _showError('Failed to initialize recorder: $e');
      setState(() { _isInitialized = false; _isLoading = false; });
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized) {
      _showError('Recorder not initialized. Please wait or grant permissions.');
      return;
    }
    try {
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
      );
      _audioStreamSubscription = (await _audioRecorder.startStream(config)).listen((chunk) {
        final newSamples = _convertToSamples(chunk);
        _audioSamplesBuffer.addAll(newSamples);
        if (_audioSamplesBuffer.length > _bufferSize) {
          _audioSamplesBuffer = _audioSamplesBuffer.sublist(
              _audioSamplesBuffer.length - _bufferSize);
        }
      });
      setState(() {
        _isRecording = true;
        _detectedNote = '';
        _frequency = 0.0;
        _confidence = 0.0;
        _pitchDeviation = 0.0;
        _closestNoteName = '';
        _closestNoteFreq = 0.0;
        _audioSamplesBuffer.clear();
        _lastDetectedFrequency = 0.0;
        _isGuitarSoundPresent = false; // Reset on start
        _pitchStabilityHistory.clear(); // Clear history on start
        _signalStrength = 0.0; // Reset signal strength
        _noiseLevel = 0.0; // Reset noise level
        _pitchStability = 0.0; // Reset pitch stability
        _isSignalTooQuiet = false;
        _isSignalTooLoud = false;
        _hasExcessiveNoise = false;
      });
      _startRealTimeAnalysis();
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      await _audioRecorder.stop();
      _audioStreamSubscription?.cancel();
      _analysisTimer?.cancel();
      _noteClearTimer?.cancel(); // Cancel timer on stop
      setState(() {
        _isRecording = false;
        _detectedNote = '';
        _frequency = 0.0;
        _confidence = 0.0;
        _pitchDeviation = 0.0;
        _closestNoteName = '';
        _closestNoteFreq = 0.0;
        _lastDetectedFrequency = 0.0;
        _isGuitarSoundPresent = false; // Reset on stop
      });
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  void _startRealTimeAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      await _analyzeCurrentAudioBuffer(_audioSamplesBuffer);
    });
  }

  Future<void> _analyzeCurrentAudioBuffer(List<double> samples) async {
    final settings = ChangeNotifierProvider.of<AppSettings>(context, listen: false);

    // Adjust thresholds based on sensitivity setting
    final currentMinSignalThreshold = _minSignalThreshold;
    final currentMaxSignalThreshold = _maxSignalThreshold;
    final currentNoiseThreshold = _noiseThreshold;

    if (samples.length < _bufferSize) {
      setState(() {
        _detectedNote = 'No signal';
        _frequency = 0.0;
        _confidence = 0.0;
        _pitchDeviation = 0.0;
        _closestNoteName = '';
        _closestNoteFreq = 0.0;
        _isGuitarSoundPresent = false;
      });
      _noteClearTimer?.cancel(); // Cancel any active timer if signal is lost
      return;
    }
    try {
      final samplesToAnalyze = List<double>.from(samples);
      _updateSignalAnalysis(samplesToAnalyze, currentMinSignalThreshold, currentMaxSignalThreshold, currentNoiseThreshold);

      if (!_isGuitarSoundPresent) {
        if (_noteClearTimer == null || !_noteClearTimer!.isActive) { // Only update if no active timer
          setState(() {
            _detectedNote = 'Waiting for guitar...';
            _frequency = 0.0;
            _confidence = 0.0;
            _pitchDeviation = 0.0;
            _closestNoteName = '';
            _closestNoteFreq = 0.0;
            _lastDetectedFrequency = 0.0;
          });
        }
        return;
      }

      final filteredSamples = _applyAdvancedNoiseReduction(samplesToAnalyze);

      double detectedFrequency;
      if (settings.pitchAlgorithm == PitchAlgorithm.autocorrelation) {
        detectedFrequency = _autocorrelationPitchDetection(filteredSamples);
      } else {
        detectedFrequency = _autocorrelationPitchDetection(filteredSamples); // Placeholder for YIN
      }

      final smoothedFrequency = _exponentialSmoothing(detectedFrequency, settings.smoothing);

      if (smoothedFrequency > 0) {
        _noteClearTimer?.cancel(); // Cancel any pending clear operation
        final note = _frequencyToNote(smoothedFrequency);
        double currentPitchDeviation = 0.0;
        if (_closestNoteFreq > 0) {
          currentPitchDeviation = (smoothedFrequency - _closestNoteFreq) / _closestNoteFreq;
          currentPitchDeviation = math.max(-0.05, math.min(0.05, currentPitchDeviation));
          currentPitchDeviation = currentPitchDeviation / 0.05;
        }
        final confidence = _calculateAdvancedConfidence(smoothedFrequency, filteredSamples);
        _updatePitchStability(smoothedFrequency);
        setState(() {
          _frequency = smoothedFrequency;
          _detectedNote = note;
          _confidence = confidence;
          _pitchDeviation = currentPitchDeviation;
          _lastDetectedFrequency = smoothedFrequency;
        });

        // Start a new timer to clear the note after 5 seconds
        _noteClearTimer = Timer(const Duration(seconds: 5), () {
          setState(() {
            _detectedNote = 'Waiting for guitar...';
            _frequency = 0.0;
            _confidence = 0.0;
            _pitchDeviation = 0.0;
            _closestNoteName = '';
            _closestNoteFreq = 0.0;
          });
        });

      } else {
        if (_noteClearTimer == null || !_noteClearTimer!.isActive) { // Only update if no active timer
          setState(() {
            _detectedNote = 'No guitar sound';
            _frequency = 0.0;
            _confidence = 0.0;
            _pitchDeviation = 0.0;
            _closestNoteName = '';
            _closestNoteFreq = 0.0;
            _lastDetectedFrequency = 0.0;
          });
        }
      }
    } catch (e) {
      // Silently handle errors during real-time analysis
    }
  }

  double _exponentialSmoothing(double currentFrequency, double smoothingFactor) {
    if (_lastDetectedFrequency == 0.0 || currentFrequency == 0.0) {
      return currentFrequency;
    }
    final alpha = 1.0 - smoothingFactor;
    return alpha * currentFrequency + (1.0 - alpha) * _lastDetectedFrequency;
  }

  void _updateSignalAnalysis(List<double> samples, double minThreshold, double maxThreshold, double noiseThreshold) {
    if (samples.isEmpty) {
      _signalStrength = 0.0;
      _noiseLevel = 0.0;
      _isSignalTooQuiet = true;
      _isSignalTooLoud = false;
      _hasExcessiveNoise = false;
      _isGuitarSoundPresent = false;
      return;
    }

    final rms = math.sqrt(samples.map((s) => s * s).reduce((a, b) => a + b) / samples.length);
    _signalStrength = rms;

    double highFreqEnergy = 0.0;
    for (int i = 1; i < samples.length; i++) {
      final diff = samples[i] - samples[i - 1];
      highFreqEnergy += diff * diff;
    }
    _noiseLevel = math.sqrt(highFreqEnergy / samples.length);

    _isSignalTooQuiet = rms < minThreshold;
    _isSignalTooLoud = rms > maxThreshold;
    _hasExcessiveNoise = _noiseLevel > noiseThreshold;

    _updateFrequencySpectrum(samples);

    final dominantFreq = _detectDominantFrequencyInRange(_frequencySpectrum, 70.0, 800.0);
    _isGuitarSoundPresent = !_isSignalTooQuiet && !_isSignalTooLoud && !_hasExcessiveNoise && dominantFreq > 0;
  }

  double _detectDominantFrequencyInRange(List<double> spectrum, double minFreq, double maxFreq) {
    if (spectrum.isEmpty) return 0.0;

    double maxMagnitude = 0.0;
    int maxMagnitudeBin = -1;

    final double freqPerBin = (_sampleRate / 2) / _spectrogramBins;

    final int minBin = (minFreq / freqPerBin).floor();
    final int maxBin = (maxFreq / freqPerBin).ceil();

    for (int i = 0; i < spectrum.length; i++) {
      if (i >= minBin && i <= maxBin) {
        if (spectrum[i] > maxMagnitude) {
          maxMagnitude = spectrum[i];
          maxMagnitudeBin = i;
        }
      }
    }

    if (maxMagnitudeBin != -1 && maxMagnitude > 0.05) {
      return maxMagnitudeBin * freqPerBin;
    }
    return 0.0;
  }

  void _updateFrequencySpectrum(List<double> samples) {
    if (samples.length < _spectrogramBins) return;
    final spectrum = List.filled(_spectrogramBins, 0.0);
    final windowSize = samples.length ~/ _spectrogramBins;
    for (int i = 0; i < _spectrogramBins; i++) {
      double magnitude = 0.0;
      final startIdx = i * windowSize;
      final endIdx = math.min(startIdx + windowSize, samples.length);
      for (int j = startIdx; j < endIdx; j++) {
        magnitude += samples[j].abs();
      }
      spectrum[i] = magnitude / windowSize;
    }
    _frequencySpectrum = spectrum;
    // Note: Spectrogram data is not used in the simple tuner, so no need to update _spectrogramData here.
  }

  void _updatePitchStability(double frequency) {
    _pitchStabilityHistory.add(frequency);
    if (_pitchStabilityHistory.length > 20) {
      _pitchStabilityHistory.removeAt(0);
    }
    if (_pitchStabilityHistory.length > 5) {
      final mean =
          _pitchStabilityHistory.reduce((a, b) => a + b) / _pitchStabilityHistory.length;
      final variance = _pitchStabilityHistory
          .map((f) => math.pow(f - mean, 2))
          .reduce((a, b) => a + b) /
          _pitchStabilityHistory.length;
      final standardDeviation = math.sqrt(variance);
      _pitchStability = math.max(0.0, 1.0 - (standardDeviation / 50.0));
    }
  }

  List<double> _convertToSamples(Uint8List bytes) {
    const headerSize = 0;
    if (bytes.length < 2) return [];
    final samples = <double>[];
    for (int i = headerSize; i < bytes.length - 1; i += 2) {
      final sample = (bytes[i] | (bytes[i + 1] << 8));
      final normalizedSample = (sample > 32767 ? sample - 65536 : sample) / 32768.0;
      samples.add(normalizedSample);
    }
    return samples;
  }

  List<double> _applyAdvancedNoiseReduction(List<double> samples) {
    if (samples.isEmpty) return samples;
    var filtered = samples;
    filtered = _highPassFilter(filtered, 80.0, _sampleRate);
    filtered = _lowPassFilter(filtered, 2000.0, _sampleRate);
    filtered = _adaptiveNoiseGate(filtered);
    return filtered;
  }

  List<double> _highPassFilter(
      List<double> samples, double cutoffFreq, int sampleRate) {
    final filtered = <double>[];
    final rc = 1.0 / (2 * math.pi * cutoffFreq);
    final dt = 1.0 / sampleRate;
    final alpha = rc / (rc + dt);
    double prevInput = 0.0;
    double prevOutput = 0.0;
    for (final sample in samples) {
      final output = alpha * (prevOutput + sample - prevInput);
      filtered.add(output);
      prevInput = sample;
      prevOutput = output;
    }
    return filtered;
  }

  List<double> _lowPassFilter(
      List<double> samples, double cutoffFreq, int sampleRate) {
    final filtered = <double>[];
    final rc = 1.0 / (2 * math.pi * cutoffFreq);
    final dt = 1.0 / sampleRate;
    final alpha = dt / (rc + dt);
    double prevOutput = 0.0;
    for (final sample in samples) {
      final output = prevOutput + alpha * (sample - prevOutput);
      filtered.add(output);
      prevOutput = output;
    }
    return filtered;
  }

  List<double> _adaptiveNoiseGate(List<double> samples) {
    if (samples.isEmpty) return samples;
    final rms = math.sqrt(samples.map((s) => s * s).reduce((a, b) => a + b) / samples.length);
    final threshold = rms * 0.1;
    return samples.map((sample) => sample.abs() > threshold ? sample : 0.0).toList();
  }

  double _autocorrelationPitchDetection(List<double> samples) {
    final n = samples.length;
    final minPeriod = (_sampleRate / 800).round();
    final maxPeriod = (_sampleRate / 80).round();
    double maxCorrelation = 0.0;
    int bestPeriod = 0;
    for (int period = minPeriod; period < maxPeriod && period < n ~/ 2; period++) {
      double correlation = 0.0;
      double energy = 0.0;
      for (int i = 0; i < n - period; i++) {
        correlation += samples[i] * samples[i + period];
        energy += samples[i] * samples[i];
      }
      if (energy > 0) {
        correlation /= energy;
        if (correlation > maxCorrelation) {
          maxCorrelation = correlation;
          bestPeriod = period;
        }
      }
    }
    return bestPeriod > 0 && maxCorrelation > 0.3
        ? _sampleRate / bestPeriod
        : 0.0;
  }

  String _frequencyToNote(double frequency) {
    if (frequency < 70) {
      _closestNoteName = '';
      _closestNoteFreq = 0.0;
      return 'No signal';
    }
    double minDiff = double.infinity;
    String tempClosestNote = 'Unknown';
    double tempClosestFreq = 0.0;
    _allNoteFrequencies.forEach((note, freq) {
      final diff = (frequency - freq).abs();
      if (diff < minDiff) {
        minDiff = diff;
        tempClosestNote = note;
        tempClosestFreq = freq;
      }
    });
    _closestNoteName = tempClosestNote;
    _closestNoteFreq = tempClosestFreq;
    if (minDiff > 15) {
      return 'Between notes';
    }
    return tempClosestNote;
  }

  double _calculateAdvancedConfidence(double frequency, List<double> samples) {
    if (frequency < 80) return 0.0;
    double totalConfidence = 0.0;
    int factors = 0;
    double minDiff = double.infinity;
    _allNoteFrequencies.forEach((note, freq) {
      final diff = (frequency - freq).abs();
      if (diff < minDiff) {
        minDiff = diff;
      }
    });
    final freqConfidence = math.max(0.0, 1.0 - (minDiff / 10.0));
    totalConfidence += freqConfidence;
    factors++;
    if (samples.isNotEmpty) {
      final rms = math.sqrt(samples.map((s) => s * s).reduce((a, b) => a + b) / samples.length);
      final strengthConfidence = math.min(1.0, rms * 10);
      totalConfidence += strengthConfidence;
      factors++;
    }
    final period = _sampleRate / frequency;
    if (period > 0 && samples.length > period * 2) {
      double harmonicStability = 0.0;
      final periodInt = period.round();
      for (int i = 0; i < samples.length - periodInt * 2; i += periodInt) {
        final corr = samples[i] * samples[i + periodInt];
        harmonicStability += corr.abs();
      }
      harmonicStability /= (samples.length / periodInt);
      totalConfidence += math.min(1.0, harmonicStability);
      factors++;
    }
    return factors > 0 ? totalConfidence / factors : 0.0;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guitar Note Detector Pro (Simple)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: widget.openSettings,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isRecording
                          ? Icons.mic
                          : _isLoading
                          ? Icons.hourglass_empty
                          : Icons.mic_off,
                      color: _isRecording ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isRecording
                          ? 'Listening...'
                          : _isLoading
                          ? 'Initializing...'
                          : 'Ready',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isRecording ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Detected Note',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                _detectedNote.isNotEmpty ? _detectedNote : 'N/A',
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  color: _detectedNote.isNotEmpty ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
              ),
              Text(
                _frequency > 0 ? '${_frequency.toStringAsFixed(2)} Hz' : '',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 30),
              CustomPaint(
                size: const Size(double.infinity, 60),
                painter: PitchDeviationPainter(_pitchDeviation),
              ),
              const SizedBox(height: 16),
              Text(
                _pitchDeviation == 0.0
                    ? 'Perfect'
                    : _pitchDeviation > 0
                    ? '+${(_pitchDeviation * 100).toStringAsFixed(1)} cents'
                    : '${(_pitchDeviation * 100).toStringAsFixed(1)} cents',
                style: TextStyle(
                  fontSize: 20,
                  color: _pitchDeviation.abs() < 0.01 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : _isRecording
                    ? _stopRecording
                    : _startRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
                label: Text(_isRecording ? 'Stop Listening' : 'Start Listening'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SettingsScreen ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = ChangeNotifierProvider.of<AppSettings>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8, // 80% of screen height
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 30),
          Expanded(
            child: ListView(
              children: [
                _buildSettingSection(
                  context,
                  'Pitch Detection Algorithm',
                  Column(
                    children: [
                      RadioListTile<PitchAlgorithm>(
                        title: const Text('Autocorrelation'),
                        value: PitchAlgorithm.autocorrelation,
                        groupValue: appSettings.pitchAlgorithm,
                        onChanged: (value) {
                          if (value != null) {
                            appSettings.setPitchAlgorithm(value);
                          }
                        },
                      ),
                      RadioListTile<PitchAlgorithm>(
                        title: const Text('YIN (Currently uses Autocorrelation)'),
                        value: PitchAlgorithm.yin,
                        groupValue: appSettings.pitchAlgorithm,
                        onChanged: (value) {
                          if (value != null) {
                            appSettings.setPitchAlgorithm(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                _buildSettingSection(
                  context,
                  'Guitar Tuning Mode',
                  Column(
                    children: [
                      RadioListTile<TuningMode>(
                        title: const Text('Standard Tuning (EADGBe)'),
                        value: TuningMode.standard,
                        groupValue: appSettings.tuningMode,
                        onChanged: (value) {
                          if (value != null) {
                            appSettings.setTuningMode(value);
                          }
                        },
                      ),
                      RadioListTile<TuningMode>(
                        title: const Text('Drop D Tuning (DADGBe)'),
                        value: TuningMode.dropD,
                        groupValue: appSettings.tuningMode,
                        onChanged: (value) {
                          if (value != null) {
                            appSettings.setTuningMode(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                _buildSettingSection(
                  context,
                  'Sensitivity',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: appSettings.sensitivity,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: appSettings.sensitivity.toStringAsFixed(1),
                        onChanged: (value) {
                          appSettings.setSensitivity(value);
                        },
                      ),
                      const Text(
                        'Adjusts how sensitive the detector is to quiet/loud signals and noise.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildSettingSection(
                  context,
                  'Smoothing',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: appSettings.smoothing,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: appSettings.smoothing.toStringAsFixed(1),
                        onChanged: (value) {
                          appSettings.setSmoothing(value);
                        },
                      ),
                      const Text(
                        'Controls the responsiveness vs. stability of the detected pitch. Higher values mean more smoothing (less responsive).',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection(BuildContext context, String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          content,
          const Divider(height: 20),
        ],
      ),
    );
  }
}
