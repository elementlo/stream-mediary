import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/downloads/downloads_page.dart';
import '../../features/history/history_page.dart';
import '../../features/new_download/new_download_page.dart';
import '../../features/player/player_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/shell/adaptive_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/downloads',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AdaptiveShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/downloads',
            name: 'downloads',
            builder: (context, state) => const DownloadsPage(),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/new',
        name: 'new_download',
        builder: (context, state) => const NewDownloadPage(),
      ),
      GoRoute(
        path: '/player/:taskId',
        name: 'player',
        builder: (context, state) =>
            PlayerPage(taskId: state.pathParameters['taskId']!),
      ),
    ],
  );
});
