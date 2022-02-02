import 'package:flutter/material.dart';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:native_platform/native_platform.dart';
import 'package:nyrna/application/app/app.dart';
import 'package:nyrna/application/preferences/cubit/preferences_cubit.dart';
import 'package:nyrna/infrastructure/preferences/preferences.dart';
import 'package:nyrna/infrastructure/versions/versions.dart';

class MockPreferences extends Mock implements Preferences {}

class MockPreferencesCubit extends Mock implements PreferencesCubit {
  MockPreferencesCubit()
      : _state = PreferencesState(
          autoRefresh: false,
          autoStartHotkey: false,
          refreshInterval: 5,
          showHiddenWindows: false,
          trayIconColor: Colors.amber,
        );

  final PreferencesState _state;

  @override
  PreferencesState get state => _state;
}

class MockPrefsCubitState extends Mock implements PreferencesState {}

class MockNativePlatform extends Mock implements NativePlatform {
  @override
  Future<int> currentDesktop() async => 0;
}

class MockVersions implements Versions {
  @override
  Future<String> latestVersion() async => '2.3.0';

  @override
  Future<String> runningVersion() async => '2.3.0';

  @override
  Future<bool> updateAvailable() async => false;
}

final msPaintWindow = Window(
  id: 132334,
  process: Process(
    executable: 'mspaint.exe',
    pid: 3716,
    status: ProcessStatus.normal,
  ),
  title: 'Untitled - Paint',
);

void main() {
  group('AppCubit', () {
    final _nativePlatform = MockNativePlatform();
    final _prefs = MockPreferences();
    final _prefsCubit = MockPreferencesCubit();
    final _versions = MockVersions();

    late AppCubit _appCubit;

    setUp(() {
      _appCubit = AppCubit(
        nativePlatform: _nativePlatform,
        prefs: _prefs,
        prefsCubit: _prefsCubit,
        versionRepository: _versions,
        testing: true,
      );

      // Start with empty window list.
      when(() => _nativePlatform.windows(showHidden: false))
          .thenAnswer((_) async => []);
    });

    test('Initial state has no windows', () {
      expect(_appCubit.state.windows.length, 0);
    });

    test('New window is added to state', () async {
      final numStartingWindows = _appCubit.state.windows.length;

      when(() => _nativePlatform.windows(showHidden: false)).thenAnswer(
        (_) async => [
          msPaintWindow,
        ],
      );

      await _appCubit.manualRefresh();
      final numUpdatedWindows = _appCubit.state.windows.length;
      expect(numUpdatedWindows, numStartingWindows + 1);
    });

    test('ProcessStatus changing externally updates state', () async {
      when(() => _nativePlatform.windows(showHidden: false)).thenAnswer(
        (_) async => [msPaintWindow],
      );

      await _appCubit.manualRefresh();

      // Verify we have one window, and it has a normal status.
      var windows = _appCubit.state.windows;
      expect(windows.length, 1);
      var window = windows[0];
      expect(window.process.status, ProcessStatus.normal);

      // Simulate the process being suspended outside Nyrna.
      when(() => _nativePlatform.windows(showHidden: false)).thenAnswer(
        (_) async => [
          msPaintWindow.copyWith(
            process: msPaintWindow.process.copyWith(
              status: ProcessStatus.suspended,
            ),
          ),
        ],
      );

      // Verify we pick up this status change.
      await _appCubit.manualRefresh();
      windows = _appCubit.state.windows;
      expect(windows.length, 1);
      window = windows[0];
      expect(window.process.status, ProcessStatus.suspended);
    });
  });
}