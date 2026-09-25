import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/user_error.dart';
import '../../engine/download_engine.dart';
import '../../engine/engine_store.dart';

Future<bool> showRecoverSourceDialog(
  BuildContext context,
  DownloadEngine engine,
  EngineTaskStore store,
  String taskId,
) async {
  final task = await store.loadTask(taskId);
  if (task == null || !context.mounted) return false;
  final urlController = TextEditingController(text: task.sourceUrl ?? task.url);
  final headersController = TextEditingController(
    text: task.headers.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n'),
  );
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.replaceSource),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l10n.m3u8UrlLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: headersController,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: l10n.headerSection,
                hintText: 'Referer: https://example.com',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );
  final url = urlController.text.trim();
  final headerLines = headersController.text.split(RegExp(r'\r?\n'));
  urlController.dispose();
  headersController.dispose();
  if (confirmed != true) return false;
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorInvalidUrl)));
    }
    return false;
  }
  final headers = <String, String>{};
  for (final line in headerLines) {
    if (line.trim().isEmpty) continue;
    final separator = line.indexOf(':');
    if (separator <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.invalidHeaderLine)));
      }
      return false;
    }
    headers[line.substring(0, separator).trim()] = line
        .substring(separator + 1)
        .trim();
  }
  try {
    await engine.replaceExpiredSource(taskId, url, headers: headers);
    return true;
  } catch (error, st) {
    logUserError('Replace expired source', error, st);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(userErrorMessage(error, l10n))));
    }
    return false;
  }
}
