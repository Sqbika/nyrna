part of 'app_cubit.dart';

class AppState extends Equatable {
  final String runningVersion;
  final String updateVersion;
  final bool updateAvailable;

  /// The index of the currently active virtual desktop.
  final int currentDesktop;

  final Map<String, Window> windows;

  const AppState({
    required this.runningVersion,
    required this.updateVersion,
    required this.updateAvailable,
    required this.currentDesktop,
    required this.windows,
  });

  factory AppState.initial() {
    return AppState(
      runningVersion: '',
      updateVersion: '',
      updateAvailable: false,
      currentDesktop: 0,
      windows: <String, Window>{},
    );
  }

  @override
  List<Object> get props {
    return [
      runningVersion,
      updateVersion,
      updateAvailable,
      currentDesktop,
      windows,
    ];
  }

  AppState copyWith({
    String? runningVersion,
    String? updateVersion,
    bool? updateAvailable,
    int? currentDesktop,
    Map<String, Window>? windows,
  }) {
    return AppState(
      runningVersion: runningVersion ?? this.runningVersion,
      updateVersion: updateVersion ?? this.updateVersion,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      currentDesktop: currentDesktop ?? this.currentDesktop,
      windows: windows ?? this.windows,
    );
  }
}
