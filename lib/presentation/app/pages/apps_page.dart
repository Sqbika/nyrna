import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/app/app.dart';
import '../../../application/preferences/cubit/preferences_cubit.dart';
import '../../../application/theme/theme.dart';
import '../app.dart';

/// The main screen for Nyrna.
///
/// Shows a ListView with tiles for each open window on the current desktop.
class AppsPage extends StatefulWidget {
  static const id = 'running_apps_screen';

  const AppsPage({Key? key}) : super(key: key);

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> with WidgetsBindingObserver {
  /// Tracks the current window size.
  ///
  /// Updated in [initState], [dispose], and [didChangeMetrics] so that
  /// we can save the window size when the user resizes the window.
  late Size _appWindowSize;

  @override
  void initState() {
    super.initState();
    _appWindowSize = WidgetsBinding.instance!.window.physicalSize;
    // Listen for changes to the application's window size.
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final updatedWindowSize = WidgetsBinding.instance!.window.physicalSize;
    if (_appWindowSize != updatedWindowSize) {
      _appWindowSize = updatedWindowSize;
      preferencesCubit.saveWindowSize();
    }
    super.didChangeMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          return Stack(
            children: [
              Scrollbar(
                trackVisibility: true,
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    if (!state.loading && state.windows.isEmpty) ...[
                      const _NoWindowsCard(),
                    ] else ...[
                      ...state.windows
                          .map(
                            (window) => WindowTile(
                              key: ValueKey(window),
                              window: window,
                            ),
                          )
                          .toList(),
                    ],
                  ],
                ),
              ),
              const _ProgressOverlay(),
            ],
          );
        },
      ),
      // We don't show a manual refresh button with a short auto-refresh.
      floatingActionButton: const _FloatingActionButton(),
    );
  }
}

class _NoWindowsCard extends StatelessWidget {
  const _NoWindowsCard({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('No windows that can be suspended'),
        ),
      ),
    );
  }
}

class _ProgressOverlay extends StatelessWidget {
  const _ProgressOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return (state.loading)
            ? Stack(
                children: [
                  ModalBarrier(color: Colors.grey.withOpacity(0.1)),
                  Transform.scale(
                    scale: 2,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : const SizedBox();
      },
    );
  }
}

class _FloatingActionButton extends StatelessWidget {
  const _FloatingActionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      builder: (context, state) {
        final autoRefresh = state.autoRefresh;
        final refreshIntervalSufficient = (state.refreshInterval > 5);
        final showFloatingActionButton =
            ((autoRefresh && refreshIntervalSufficient) || !autoRefresh);

        return showFloatingActionButton
            ? BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, state) {
                  return FloatingActionButton(
                    backgroundColor: (state.appTheme == AppTheme.pitchBlack)
                        ? Colors.black
                        : null,
                    onPressed: () => appCubit.manualRefresh(),
                    child: const Icon(Icons.refresh),
                  );
                },
              )
            : Container();
      },
    );
  }
}
