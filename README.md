# App 2 Guitar Note Detector by Okk 🎸

> A comprehensive Flutter application for precise guitar tuning and real-time note detection with advanced audio analysis features.

## 🚀 Features

### 🎯 Dual Interface Modes
- **🔬 Detailed Tuner**: Professional interface with comprehensive audio analysis tools
- **⚡ Simple Tuner**: Clean, minimal interface for quick and easy tuning

### 🎵 Core Functionality
- ✅ Real-time pitch detection using advanced autocorrelation algorithm
- 🎸 Multiple guitar tuning modes (Standard EADGBe, Drop D)
- 📊 Visual pitch deviation indicator with precise cents accuracy
- ⏰ Smart auto-clear: Notes disappear after 5 seconds of silence
- 🔇 Advanced noise reduction and audio filtering
- 🎧 Guitar-specific sound detection and validation

### 📈 Advanced Analysis (Detailed Mode Only)
- **🎸 Interactive Fretboard Visualizer**: See exactly where detected notes appear on the fretboard
- **📊 Real-time Signal Metrics**: Monitor signal strength, pitch stability, and detection confidence
- **🌊 Frequency Spectrum Analyzer**: Visualize frequency content in real-time
- **🎨 Spectrogram Display**: Time-frequency analysis with color-coded intensity
- **🎯 Guitar String Matching**: Individual tuning accuracy for each string with visual feedback
- **📐 Precision Tuning**: Cent-accurate deviation measurement and display

### ⚙️ Customizable Settings
- 🎚️ **Sensitivity Control**: Adjust detection sensitivity for different environments
- 🎛️ **Signal Smoothing**: Balance responsiveness vs. stability
- 🎸 **Tuning Mode Selection**: Standard and Drop D tuning support
- 🔧 **Algorithm Options**: Multiple pitch detection methods


> **Note**: Add actual screenshots of your app here to showcase the interfaces

## 📋 Requirements

### 🔧 Development Environment
- **Flutter**: 3.0.0 or higher
- **Dart**: 3.0.0 or higher
- **IDE**: Android Studio, VS Code, or IntelliJ IDEA

### 📱 Target Platforms
- **iOS**: 12.0+ (iPhone, iPad)
- **Android**: API level 21+ (Android 5.0+)

### 🎤 Device Requirements
- Microphone access (essential for audio input)
- Recommended: Quiet environment for optimal accuracy

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Audio & Permissions
  permission_handler: ^11.0.0  # Handle microphone permissions
  record: ^5.0.0               # Real-time audio recording and streaming
  
  # UI & State Management
  # (Uses built-in Flutter state management)

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### 📚 Key Libraries Used
- **`permission_handler`**: Manages microphone permissions across platforms
- **`record`**: Provides real-time audio streaming capabilities
- **Built-in Flutter**: Uses Flutter's native state management and UI components

## 🚀 Installation 

### **For better usage**
# Just Create New Flutter Project In your computer and copy the code from main.dart and pubspec.xml ( these two are very important ... I have created everything in that two files )

### 1️⃣ **Clone the Repository**
```bash
git clone https://github.com/Okker01/GuitarnotedetectApp
cd GuitarnotedetectApp
```

### 2️⃣ **Install Dependencies**
```bash
flutter pub get
```

### 3️⃣ **Configure Platform Permissions**

#### 🤖 **Android Setup**
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MICROPHONE" />
    
    <application>
        <!-- Your existing application config -->
    </application>
</manifest>
```

#### 🍎 **iOS Setup**
Add to `ios/Runner/Info.plist`:
```xml
<dict>
    <!-- Add this key-value pair -->
    <key>NSMicrophoneUsageDescription</key>
    <string>Guitar Note Detector Pro needs microphone access to analyze your guitar's sound and detect notes for tuning.</string>
    
    <!-- Your existing Info.plist content -->
</dict>
```

### 4️⃣ **Verify Installation**
```bash
flutter doctor
```
Ensure all checkmarks are green for your target platforms.

### 5️⃣ **Run the Application**
```bash
# For development
flutter run

# For release build
flutter build apk    # Android
flutter build ios    # iOS
```

> 💡 **Tip**: Use `flutter run --release` for better performance during testing

## 🎯 Usage Guide

### 🏁 **Getting Started**
1. **Launch** the app and **grant microphone permissions** when prompted
2. **Choose your interface**:
    - 🎸 **"Detailed Tuner"** - Full analysis suite (recommended for precision tuning)
    - ⚡ **"Simple Tuner"** - Clean interface (perfect for quick tune-ups)
3. **Tap "Start Listening"** to begin real-time note detection
4. **Play your guitar** - notes appear instantly with visual feedback!

### 🎸 **Tuning Your Guitar**

#### 🎯 **Perfect Tuning Process**:
1. **Play a single string** clearly (avoid pressing frets initially)
2. **Watch the pitch deviation indicator**:
    - 🟢 **Green center**: Perfect tuning ✅
    - 🔴 **Left side**: Tune UP (tighten string) ⬆️
    - 🔴 **Right side**: Tune DOWN (loosen string) ⬇️
3. **Adjust tuning pegs** gradually until indicator centers
4. **Repeat** for all six strings

> 💡 **Pro Tip**: For best results, tune in a quiet room and play strings one at a time

### 🔬 **Advanced Features (Detailed Mode)**

#### 🎸 **Interactive Fretboard**
- **Visual note mapping**: See exactly where detected notes appear on the virtual fretboard
- **Real-time highlighting**: Active notes illuminate on the fretboard
- **Fret position reference**: Understand note relationships across the neck

#### 📊 **Live Audio Analysis**
- **Signal Metrics**: Monitor input quality and detection confidence
- **Frequency Spectrum**: Visualize the harmonic content of your guitar
- **Spectrogram**: Time-based frequency analysis with color intensity
- **Expandable Panels**: Tap section headers to show/hide analysis tools

#### 🎯 **String-by-String Matching**
- **Individual string status**: See tuning accuracy for each guitar string
- **Visual progress bars**: Instant feedback on tuning progress
- **Target frequency display**: Know exactly what frequency to aim for

### ⚙️ **Settings & Customization**

#### 🎛️ **Accessing Settings**
1. Tap the **⚙️ settings icon** in the top-right corner
2. Adjust parameters in the sliding panel:

#### 🎚️ **Sensitivity Slider** (0.0 - 1.0)
- **Low (0.0-0.3)**: Best for **quiet environments**, less sensitive to noise
- **Medium (0.4-0.7)**: **Balanced** for most situations
- **High (0.8-1.0)**: **Noisy environments**, maximum sensitivity

#### 📊 **Smoothing Control** (0.0 - 1.0)
- **Low (0.0-0.3)**: **Highly responsive**, updates quickly but may fluctuate
- **Medium (0.4-0.7)**: **Balanced** responsiveness and stability
- **High (0.8-1.0)**: **Very stable** readings, slower to respond

#### 🎸 **Tuning Modes**
- **Standard Tuning**: E-A-D-G-B-E (most common)
- **Drop D Tuning**: D-A-D-G-B-E (popular for rock/metal)

### 🎵 **Usage Tips**

#### ✅ **Best Practices**:
- 🔇 **Quiet environment** for optimal accuracy
- 🎸 **Play single notes** (avoid chords during tuning)
- 🎯 **Hold notes steadily** for 2-3 seconds
- 📱 **Keep device close** to your guitar (1-3 feet ideal)

#### ⚠️ **Avoid**:
- 🔊 **Background music** or TV noise
- 🎵 **Playing multiple strings** simultaneously while tuning
- 📱 **Moving device** excessively during detection

## 🔧 Technical Specifications

### 🎤 **Audio Processing Pipeline**
| Parameter | Value | Description |
|-----------|-------|-------------|
| **Sample Rate** | 44.1 kHz | CD-quality audio sampling |
| **Buffer Size** | 4,096 samples | ~93ms latency for real-time processing |
| **Bit Depth** | 16-bit PCM | Standard audio bit depth |
| **Channels** | Mono | Single-channel audio input |
| **Update Rate** | 10 Hz | 100ms refresh intervals |

### 🎯 **Pitch Detection Engine**
- **Primary Algorithm**: Enhanced Autocorrelation with confidence weighting
- **Frequency Range**: 70-800 Hz (optimized for 6-string guitar fundamentals)
- **Accuracy**: ±1 cent (1/100th of a semitone)
- **Detection Threshold**: Adaptive based on signal quality
- **Confidence Calculation**: Multi-factor analysis including pitch stability and harmonic content

### 🔄 **Real-time Signal Processing**
1. **📥 Audio Capture**: Continuous PCM audio streaming via `record` package
2. **🔇 Noise Reduction**:
    - High-pass filter (80 Hz cutoff) - removes low-frequency noise
    - Low-pass filter (2000 Hz cutoff) - removes high-frequency interference
    - Adaptive noise gate - dynamic noise suppression
3. **🎯 Pitch Detection**: Autocorrelation algorithm with guitar-optimized parameters
4. **📊 Smoothing**: Exponential smoothing for stable, responsive readings
5. **🎵 Note Mapping**: Frequency-to-note conversion with cent-accurate deviation calculation

### 🎸 **Guitar-Specific Optimizations**
- **String Frequency Detection**: Tuned for standard guitar string fundamentals
- **Harmonic Analysis**: Recognizes guitar harmonic patterns
- **Playing Style Adaptation**: Optimized for both fingerpicking and strumming
- **Fret Position Calculation**: Real-time fretboard position mapping

### 📊 **Analysis Features**
- **Frequency Spectrum**: 256-bin FFT analysis for harmonic visualization
- **Spectrogram**: 50-frame history with color-coded intensity mapping
- **Signal Quality Metrics**: RMS, SNR, and stability calculations
- **Multi-string Recognition**: Simultaneous analysis of multiple guitar strings

## 🔧 Troubleshooting

### 🎤 **Audio Detection Issues**

#### ❌ **"App doesn't detect any sound"**
- ✅ **Check microphone permissions**: Go to Settings > Privacy > Microphone
- ✅ **Test device microphone**: Try recording a voice memo
- ✅ **Increase sensitivity**: Use Settings panel to boost sensitivity (0.7-1.0)
- ✅ **Check distance**: Keep device within 1-3 feet of your guitar
- ✅ **Volume check**: Ensure device volume is up (affects some microphone circuits)

#### ❌ **"Readings are inaccurate or jumpy"**
- ✅ **Reduce background noise**: Find a quieter environment
- ✅ **Play single notes**: Avoid chords and multiple strings
- ✅ **Increase smoothing**: Adjust smoothing slider to 0.6-0.8 for stability
- ✅ **Check guitar intonation**: Ensure your guitar is generally in tune with itself
- ✅ **Play closer to pickup**: If using electric guitar, play near the pickup area

#### ❌ **"Detection is too slow/fast"**
- 🐌 **Too slow**: Decrease smoothing (0.2-0.4) for faster response
- 🐰 **Too fast/jumpy**: Increase smoothing (0.6-0.9) for more stable readings

### 📱 **App Performance Issues**

#### ❌ **"App crashes on startup"**
```bash
# Try these solutions:
flutter clean
flutter pub get
flutter run
```
- ✅ **Check Flutter version**: Ensure Flutter 3.0+ is installed
- ✅ **Verify permissions**: Ensure microphone permissions are properly configured
- ✅ **Restart device**: Sometimes audio drivers need a reset
- ✅ **Check available storage**: Ensure sufficient device storage


### 🛠️ **Advanced Troubleshooting**

#### 🔍 **Debug Mode**
1. Enable **Detailed Tuner** mode
2. Check **Signal Metrics** panel:
    - **Signal Strength**: Should be green when playing
    - **Confidence**: Should be >60% for accurate readings
    - **Noise Level**: Should be low (<0.05)

#### 📊 **Performance Monitoring**
- **Good Signal**: Green indicators, confidence >70%
- **Marginal Signal**: Orange indicators, confidence 40-70%
- **Poor Signal**: Red indicators, confidence <40%

```

### 🧩 **Core Components**

#### 🎛️ **State Management**
- **`AppSettings`**: Global configuration state using `ChangeNotifier`
    - Tuning mode selection (Standard/Drop D)
    - Algorithm preferences (Autocorrelation/YIN)
    - Sensitivity and smoothing parameters
    - Cross-screen setting synchronization

#### 🎤 **Audio Processing Pipeline**
- **`AudioRecorder`**: Real-time audio capture using `record` package
- **`PitchDetector`**: Core frequency analysis with autocorrelation
- **`SignalProcessor`**: Noise reduction and filtering chain
- **`NoiseGate`**: Adaptive background noise suppression

#### 🎨 **Custom UI Components**
- **`PitchDeviationPainter`**: Custom canvas drawing for tuning needle
- **`SpectrumPainter`**: Real-time frequency spectrum visualization
- **`SpectrogramPainter`**: Time-frequency heatmap display
- **`FretboardVisualizer`**: Interactive guitar neck with note highlighting

#### 🔄 **Data Flow Architecture**
```
🎤 Audio Input → 🔧 Signal Processing → 🎯 Pitch Detection → 🎵 Note Conversion → 🎨 UI Update
↓                    ↓                     ↓                    ↓              ↓
📊 Raw PCM        🔇 Noise Filtered    📈 Frequency       🎼 Note Name    📱 Visual Display
Samples           Audio Samples       Analysis           & Deviation      & Feedback
```

### 🎯 **Key Design Patterns**

#### 🔧 **Provider Pattern**
- Custom `ChangeNotifierProvider` implementation for settings
- Reactive UI updates across all screens
- Efficient state sharing without external dependencies

#### 🎨 **Custom Painter Pattern**
- Hardware-accelerated canvas drawing for real-time visualizations
- Smooth 60fps animations for pitch deviation and spectrum displays
- Memory-efficient rendering of complex audio data

#### ⚡ **Stream Processing**
- Real-time audio stream handling with `StreamSubscription`
- Buffered audio processing with configurable window sizes
- Timer-based analysis loops for consistent update rates

### 🔧 **Performance Optimizations**

#### 🚀 **Audio Processing**
- **Fixed-size buffers**: Prevents memory leaks during long sessions
- **Efficient FFT**: Optimized frequency analysis with minimal CPU usage
- **Adaptive thresholds**: Dynamic noise gates based on environment
- **Signal validation**: Guitar-specific audio detection to avoid false positives

#### 📱 **UI Rendering**
- **Canvas-based drawing**: Hardware acceleration for smooth animations
- **Selective repaints**: Only redraw changed components
- **Memory management**: Proper disposal of audio streams and timers
- **Responsive design**: Adaptive layouts for different screen sizes

### 🎸 **Domain-Specific Features**

#### 🎵 **Music Theory Integration**
- **Chromatic scale mapping**: Complete note frequency database (C0-B8)
- **Cent calculation**: Precise deviation measurement in musical cents
- **Tuning system support**: Multiple guitar tuning configurations
- **Fretboard mathematics**: Real-time fret position calculations

#### 🎯 **Guitar-Centric Design**
- **String-specific analysis**: Individual tuning accuracy per string
- **Playing technique adaptation**: Optimized for both picking and strumming
- **Harmonic recognition**: Enhanced detection of guitar-specific overtones
- **Visual feedback**: Musician-friendly interface with familiar guitar metaphors



### 📋 **Development Guidelines**

#### 🎨 **Code Style**
- ✅ Follow [Flutter/Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- ✅ Use meaningful variable names and comments
- ✅ Keep functions focused and concise
- ✅ Document complex audio processing logic

#### 🧪 **Testing Requirements**
- ✅ **Unit tests** for core algorithms (pitch detection, note conversion)
- ✅ **Widget tests** for UI components
- ✅ **Integration tests** for audio processing pipeline
- ✅ **Cross-platform testing** on both iOS and Android devices

#### 📚 **Documentation**
- ✅ Update README for new features
- ✅ Add inline code documentation
- ✅ Include usage examples for new APIs
- ✅ Update changelog with your contributions

#### 🎯 **Pull Request Checklist**
- [ ] Code follows project style guidelines
- [ ] All tests pass (`flutter test`)
- [ ] No performance regressions in audio processing
- [ ] UI changes tested on multiple screen sizes
- [ ] Documentation updated if needed
- [ ] No breaking changes to existing APIs



### ⚡ **Performance & Technical Improvements**

#### 🔋 **Battery Optimization**
- [ ] **Smart Processing**: Reduce CPU usage during idle periods
- [ ] **Background Management**: Efficient handling when app is backgrounded
- [ ] **Adaptive Quality**: Automatically adjust processing based on battery level

#### 🚀 **Speed Enhancements**
- [ ] **WebRTC Integration**: Professional audio processing libraries
- [ ] **GPU Acceleration**: Hardware-accelerated spectrum analysis
- [ ] **Multi-threading**: Parallel processing for complex algorithms
- [ ] **Caching**: Smart caching of analysis results

#### 🛡️ **Reliability Improvements**
- [ ] **Error Recovery**: Automatic recovery from audio system failures
- [ ] **Crash Prevention**: Better handling of edge cases and invalid inputs
- [ ] **Memory Management**: Advanced memory optimization for long sessions
- [ ] **Network Resilience**: Robust handling of connectivity issues



### 🎵 **Audio Processing Resources**
- **Digital Signal Processing**: Techniques from academic and industry research
- **Music Information Retrieval**: Algorithms for musical audio analysis
- **Real-time Audio**: Low-latency processing techniques for mobile devices


### ⏰ **Response Times**
- 🐛 **Critical bugs**: 24-48 hours
- ❓ **General support**: 3-5 business days
- 💡 **Feature requests**: Acknowledged within 1 week
- 📧 **Email inquiries**: 2-3 business days

---

## 📈 Changelog

### 🎉 **Version 1.0.0** - *Initial Release*
**🚀 New Features:**
- ✨ **Dual Interface Modes**: Detailed analyzer and simple tuner
- 🎸 **Real-time Pitch Detection**: Autocorrelation-based note detection
- 🎵 **Multiple Tuning Modes**: Standard and Drop D guitar tunings
- 📊 **Advanced Audio Analysis**: Spectrum, spectrogram, and signal metrics
- 🎯 **Interactive Fretboard**: Visual note mapping on guitar neck
- ⚙️ **Customizable Settings**: Sensitivity and smoothing controls
- 🎨 **Professional UI**: Material Design 3 with smooth animations
- 📱 **Cross-platform**: iOS and Android support

**🔧 Technical:**
- 🎤 **44.1kHz Audio Processing**: CD-quality real-time analysis
- 📐 **±1 Cent Accuracy**: Professional-grade tuning precision
- 🔇 **Advanced Noise Reduction**: Multi-stage audio filtering
- ⚡ **10Hz Update Rate**: Smooth, responsive interface updates
- 🛡️ **Robust Error Handling**: Graceful recovery from audio issues

---


*Last updated: July 2025 • Version 1.0.0*
