import 'dart:typed_data';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nyrna/application/app/app.dart';
import 'package:nyrna/infrastructure/icon_manager/icon_manager.dart';
import 'package:nyrna/infrastructure/preferences/preferences.dart';
import 'package:nyrna/presentation/styles.dart';
import 'package:window_size/window_size.dart' as window;

import '../../../infrastructure/launcher/src/hotkey.dart';
import '../../helpers/json_converters.dart';

part 'preferences_state.dart';

late PreferencesCubit preferencesCubit;

class PreferencesCubit extends Cubit<PreferencesState> {
  final Preferences _prefs;

  PreferencesCubit(Preferences prefs)
      : _prefs = prefs,
        super(
          PreferencesState(
            autoStartHotkey: prefs.getBool('autoStartHotkey') ?? false,
            autoRefresh: _checkAutoRefresh(prefs),
            refreshInterval: prefs.getInt('refreshInterval') ?? 5,
            showHiddenWindows: prefs.getBool('showHiddenWindows') ?? false,
            trayIconColor: Color(
              prefs.getInt('trayIconColor') ?? AppColors.defaultIconColor,
            ),
          ),
        ) {
    preferencesCubit = this;
  }

  static bool _checkAutoRefresh(Preferences prefs) {
    return prefs.getBool('autoRefresh') ?? true;
  }

  /// If user wishes to ignore this update, save to SharedPreferences.
  Future<void> ignoreUpdate(String version) async {
    await _prefs.setString(key: 'ignoredUpdate', value: version);
  }

  Future<void> setRefreshInterval(int interval) async {
    if (interval > 0) {
      await _prefs.setInt(key: 'refreshInterval', value: interval);
      emit(state.copyWith(refreshInterval: interval));
    }
  }

  Future<bool> updateAutoStartHotkey(bool value) async {
    final successful = await Hotkey().autoStart(value);
    if (!successful) return false;
    await _prefs.setBool(key: 'autoStartHotkey', value: value);
    emit(state.copyWith(autoStartHotkey: value));
    return true;
  }

  Future<void> updateAutoRefresh([bool? autoEnabled]) async {
    if (autoEnabled != null) {
      await _prefs.setBool(key: 'autoRefresh', value: autoEnabled);
      appCubit.setAutoRefresh(
        autoRefresh: autoEnabled,
        refreshInterval: state.refreshInterval,
      );
      emit(state.copyWith(autoRefresh: autoEnabled));
    }
  }

  Future<Uint8List> iconBytes() async {
    final iconManager = IconManager();
    final iconBytes = await iconManager.iconBytes();
    return iconBytes;
  }

  Future<void> updateIconColor(Color newColor) async {
    final successful = await IconManager().updateIconColor(newColor);
    if (successful) {
      await _prefs.setInt(key: 'trayIconColor', value: newColor.value);
      emit(state.copyWith(trayIconColor: newColor));
    }
  }

  Future<void> updateShowHiddenWindows(bool value) async {
    await _prefs.setBool(key: 'showHiddenWindows', value: value);
    emit(state.copyWith(showHiddenWindows: value));
  }

  /// Save the current window size & position to storage.
  ///
  /// Allows the app to remember its window size for next launch.
  Future<void> saveWindowSize() async {
    final windowInfo = await window.getWindowInfo();
    final rectJson = windowInfo.frame.toJson();
    await _prefs.setString(key: 'windowSize', value: rectJson);
  }

  /// Returns if available the last window size and position.
  Future<Rect?> savedWindowSize() async {
    final rectJson = _prefs.getString('windowSize');
    if (rectJson == null) return null;
    final windowRect = RectConverter.fromJson(rectJson);
    return windowRect;
  }
}
