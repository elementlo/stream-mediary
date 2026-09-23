import 'package:dio/dio.dart';

/// A single comment on the Waline board.
class WalineComment {
  const WalineComment({
    required this.objectId,
    required this.comment,
    required this.nick,
    required this.insertedAt,
    this.rid,
    this.link,
    this.avatar,
    this.addr,
    this.type,
    this.label,
  });

  factory WalineComment.fromJson(Map<String, dynamic> json) {
    return WalineComment(
      // The server returns numeric ids; stringify so comparisons between
      // `objectId` and `rid` stay consistent regardless of JSON type.
      objectId: '${json['objectId'] ?? ''}',
      // Waline stores sanitized HTML; render as plain text in-app.
      comment: htmlToText(json['comment'] as String? ?? ''),
      nick: (json['nick'] as String? ?? '').isEmpty
          ? 'anonymous'
          : json['nick'] as String,
      insertedAt: _parseTime(json),
      rid: json['rid'] == null ? null : '${json['rid']}',
      link: json['link'] as String?,
      avatar: json['avatar'] as String?,
      // Only present for registered users (matched by user_id on the
      // server); anonymous comments omit both.
      type: (json['type'] as String?)?.trim().isEmpty == false
          ? (json['type'] as String).trim()
          : null,
      label: (json['label'] as String?)?.trim().isEmpty == false
          ? (json['label'] as String).trim()
          : null,
      // IP-derived region. The server returns province-level for regular
      // users (city-level is admin-only by Waline's privacy design).
      addr: (json['addr'] as String?)?.trim().isEmpty == false
          ? (json['addr'] as String).trim()
          : null,
    );
  }

  /// Timestamps arrive as `insertedAt` (ISO string) on some builds and as
  /// `time` (epoch millis) on current ones.
  static DateTime _parseTime(Map<String, dynamic> json) {
    final iso = json['insertedAt'];
    if (iso is String) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) return parsed;
    }
    final epoch = json['time'];
    if (epoch is num) {
      return DateTime.fromMillisecondsSinceEpoch(epoch.toInt());
    }
    return DateTime.now();
  }

  final String objectId;
  final String comment;
  final String nick;
  final DateTime insertedAt;

  /// Parent comment id when this is a reply; null for top-level comments.
  final String? rid;
  final String? link;
  final String? avatar;

  /// Province-level IP region (e.g. "浙江省"); null when unavailable.
  final String? addr;

  /// Registered-user role, e.g. "administrator"; null for anonymous.
  final String? type;

  /// Custom badge text set by the admin (e.g. "admin"); null for anonymous.
  final String? label;

  bool get isReply => rid != null && rid!.isNotEmpty;
}

/// One page of comments plus paging info.
class WalineCommentPage {
  const WalineCommentPage({
    required this.comments,
    required this.page,
    required this.totalPages,
  });

  final List<WalineComment> comments;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

/// Thrown when the Waline server returns an error payload or is unreachable.
class WalineException implements Exception {
  const WalineException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Minimal REST client for a self-hosted Waline instance.
///
/// Only the endpoints the community board needs are implemented:
/// listing comments for a fixed path and posting new ones (top-level or
/// replies). No login: Waline accepts a nickname per comment, matching the
/// "guest book" experience.
class WalineClient {
  WalineClient({required String serverUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              // Without a connect timeout an unreachable host (e.g. a
              // DNS-polluted domain) hangs the request forever and the UI
              // spins indefinitely instead of showing the error state.
              connectTimeout: const Duration(seconds: 10),
            )),
        baseUrl = _normalize(serverUrl);

  /// The project's Waline deployment. Hardcoded on purpose: the board is a
  /// first-party feature, not something each user configures.
  static const String defaultServerUrl = 'https://board.263156.xyz';

  /// Board identity sent as Waline's `path`. All app comments live under it.
  static const String boardPath = '/mediary';

  final Dio _dio;
  final String baseUrl;

  static String _normalize(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// Fetches one page of comments, newest first.
  Future<WalineCommentPage> fetchComments({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final res = await _dio.get(
        '$baseUrl/api/comment',
        queryParameters: {
          'path': boardPath,
          'page': page,
          'pageSize': pageSize,
          'sortBy': 'insertedAt_desc',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final body = res.data as Map<String, dynamic>;
      if (!_isOk(body)) {
        throw WalineException(_errorMessage(body));
      }
      final data = body['data'] as Map<String, dynamic>;
      final flat = <WalineComment>[];
      void addTree(Map<String, dynamic> node) {
        flat.add(WalineComment.fromJson(node));
        for (final child in (node['children'] as List<dynamic>? ?? [])) {
          addTree(child as Map<String, dynamic>);
        }
      }

      for (final node in (data['data'] as List<dynamic>? ?? [])) {
        addTree(node as Map<String, dynamic>);
      }
      return WalineCommentPage(
        comments: flat,
        page: (data['page'] as num?)?.toInt() ?? page,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      );
    } on DioException catch (e) {
      throw WalineException(_dioMessage(e));
    }
  }

  /// Posts a comment. [rid] replies to an existing comment.
  Future<WalineComment> postComment({
    required String content,
    required String nick,
    String? rid,
  }) async {
    try {
      final res = await _dio.post(
        '$baseUrl/api/comment',
        data: {
          'comment': content,
          'nick': nick,
          // POST expects the page path under `url` (GET uses the `path`
          // query param); sending `path` here makes the server reject the
          // comment with "url need an URL under your options".
          'url': boardPath,
          // The server stores whatever we send and later calls
          // `.replace()` on these fields when listing; omitting them stores
          // null and crashes every subsequent GET. Mirror the official
          // client and always send empty strings.
          'mail': '',
          'link': '',
          'ua': 'MediaryApp',
          if (rid != null && rid.isNotEmpty) 'rid': rid,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final body = res.data as Map<String, dynamic>;
      if (!_isOk(body)) {
        throw WalineException(_errorMessage(body));
      }
      return WalineComment.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw WalineException(_dioMessage(e));
    }
  }

  /// Waline's success flag: legacy builds return `code`, current builds
  /// return `errno`. Accept either.
  bool _isOk(Map<String, dynamic> body) {
    final flag = body['errno'] ?? body['code'];
    return flag == 0;
  }

  String _errorMessage(Map<String, dynamic> body) =>
      (body['errmsg'] ?? body['msg'] ?? body['message'] ?? 'unknown error')
          .toString();

  String _dioMessage(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'connection timed out',
        DioExceptionType.connectionError =>
          'cannot reach the server (${e.message})',
        _ => e.response?.statusCode != null
            ? 'server returned ${e.response!.statusCode}'
            : (e.message ?? 'network error'),
      };
}

/// Converts the sanitized HTML Waline stores into readable plain text.
///
/// Handles the subset a comment box can produce: line breaks, paragraphs,
/// links, code and basic entities. Anything else is stripped.
String htmlToText(String html) {
  var text = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<a[^>]*href="([^"]*)"[^>]*>(.*?)</a>',
          caseSensitive: false, dotAll: true), r'$2 ($1)')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  const entities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
  };
  entities.forEach((k, v) => text = text.replaceAll(k, v));
  return text.trim();
}
