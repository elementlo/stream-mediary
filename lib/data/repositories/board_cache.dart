import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../remote/waline_client.dart';

/// Shared read/write helpers for the board comment cache, used by both the
/// startup prefetch and the board page so they stay in sync.

List<WalineComment> commentsFromCache(List<BoardComment> rows) => [
      for (final row in rows)
        WalineComment(
          objectId: row.objectId,
          comment: row.comment,
          nick: row.nick,
          insertedAt:
              DateTime.fromMillisecondsSinceEpoch(row.insertedAt).toUtc(),
          rid: row.rid,
          link: row.link,
          avatar: row.avatar,
          addr: row.addr,
          type: row.type,
          label: row.label,
        ),
    ];

Future<List<WalineComment>> readCachedComments(AppDatabase db) async =>
    commentsFromCache(await db.cachedBoardComments());

Future<void> cacheComments(
    AppDatabase db, List<WalineComment> comments) async {
  await db.replaceBoardComments([
    for (var i = 0; i < comments.length; i++)
      BoardCommentsCompanion.insert(
        objectId: comments[i].objectId,
        comment: comments[i].comment,
        nick: comments[i].nick,
        insertedAt: comments[i].insertedAt.millisecondsSinceEpoch,
        sortIndex: Value(i),
        rid: Value(comments[i].rid),
        link: Value(comments[i].link),
        avatar: Value(comments[i].avatar),
        addr: Value(comments[i].addr),
        type: Value(comments[i].type),
        label: Value(comments[i].label),
      ),
  ]);
}
