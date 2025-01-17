import 'dart:io' as io;

import '../native_platform.dart';
import '../window.dart';
import 'linux_process.dart';

/// System-level or non-app executables. Nyrna shouldn't show these.
const List<String> _filteredWindows = [
  'nyrna',
];

/// Interact with the native Linux operating system.
class Linux implements NativePlatform {
  int? _desktop;

  // Active virtual desktop as reported by wmctrl.
  @override
  Future<int> currentDesktop() async {
    final result = await io.Process.run('wmctrl', ['-d']);
    final lines = result.stdout.toString().split('\n');
    lines.forEach((line) {
      if (line.contains('*')) _desktop = int.tryParse(line[0]);
    });
    return _desktop ?? 0;
  }

  // Gets all open windows as reported by wmctrl.
  @override
  Future<List<Window>> windows({bool showHidden = false}) async {
    await currentDesktop();

    final wmctrlOutput = await io.Process.run('bash', ['-c', 'wmctrl -lp']);

    // Each line from wmctrl will be something like:
    // 0x03600041  1 1459   SHODAN Inbox - Unified Folders - Mozilla Thunderbird
    // windowId, desktopId, pid, user, window title
    final lines = wmctrlOutput.stdout.toString().split('\n');

    final windows = <Window>[];

    for (var line in lines) {
      final window = await _buildWindow(line, showHidden);
      if (window != null) windows.add(window);
    }

    return windows;
  }

  /// Takes a line of output from wmctrl and if valid returns a [Window].
  Future<Window?> _buildWindow(String wmctrlLine, bool showHidden) async {
    final parts = wmctrlLine.split(' ');
    parts.removeWhere((part) => part == ''); // Happens with multiple spaces.

    if (parts.length < 2) return null;

    // Which virtual desktop this window is on.
    final windowDesktop = int.tryParse(parts[1]);
    final windowOnCurrentDesktop = (windowDesktop == _desktop);
    if (!windowOnCurrentDesktop && !showHidden) return null;

    final pid = int.tryParse(parts[2]);
    final id = int.tryParse(parts[0]);
    if ((pid == null) || (id == null)) return null;

    final executable = await _getExecutableName(pid);
    if (_filteredWindows.contains(executable)) return null;

    final linuxProcess = LinuxProcess(executable: executable, pid: pid);
    final title = parts.sublist(4).join(' ');

    return Window(id: id, process: linuxProcess, title: title);
  }

  Future<String> _getExecutableName(int pid) async {
    final result = await io.Process.run('readlink', ['/proc/$pid/exe']);
    final executable = result.stdout.toString().split('/').last.trim();
    return executable;
  }

  @override
  Future<Window> activeWindow() async {
    final windowId = await _activeWindowId();
    if (windowId == 0) throw (Exception('No window id'));

    final pid = await _activeWindowPid(windowId);
    if (pid == 0) throw (Exception('No pid'));

    final executable = await _getExecutableName(pid);
    final process = LinuxProcess(pid: pid, executable: executable);
    final windowTitle = await _activeWindowTitle();

    return Window(
      id: windowId,
      process: process,
      title: windowTitle,
    );
  }

  // Returns the unique hex ID of the active window as reported by xdotool.
  Future<int> _activeWindowId() async {
    final result = await io.Process.run('xdotool', ['getactivewindow']);
    final _windowId = int.tryParse(result.stdout.toString().trim());
    return _windowId ?? 0;
  }

  Future<int> _activeWindowPid(int windowId) async {
    final result = await io.Process.run(
      'xdotool',
      ['getwindowpid', '$windowId'],
    );
    final _pid = int.tryParse(result.stdout.toString().trim());
    return _pid ?? 0;
  }

  Future<String> _activeWindowTitle() async {
    final result = await io.Process.run(
      'xdotool',
      ['getactivewindow getwindowname'],
    );
    return result.stdout.toString().trim();
  }

  // Verify wmctrl and xdotool are present on the system.
  @override
  Future<bool> checkDependencies() async {
    try {
      await io.Process.run('wmctrl', ['-d']);
    } catch (err) {
      return false;
    }
    try {
      await io.Process.run('xdotool', ['getactivewindow']);
    } catch (err) {
      return false;
    }
    return true;
  }

  @override
  Future<bool> minimizeWindow(int windowId) async {
    final result = await io.Process.run(
      'xdotool',
      ['windowminimize', '$windowId'],
    );
    return (result.stderr == '') ? true : false;
  }

  @override
  Future<bool> restoreWindow(int windowId) async {
    final result = await io.Process.run(
      'xdotool',
      ['windowactivate', '$windowId'],
    );
    return (result.stderr == '') ? true : false;
  }
}
