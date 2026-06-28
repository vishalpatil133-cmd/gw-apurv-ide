import 'dart:math';

class LineState {
  final String content;
  final int timestamp;

  LineState(this.content, this.timestamp);

  Map<String, dynamic> toJson() => {
        'content': content,
        'timestamp': timestamp,
      };

  factory LineState.fromJson(Map<String, dynamic> json) {
    return LineState(
      json['content'] as String,
      json['timestamp'] as int,
    );
  }
}

/// A line-level Last-Write-Wins (LWW) CRDT Conflict Resolution Engine for text files with a Garbage Collector.
class CRDTSyncEngine {
  final Map<String, Map<int, LineState>> _documentState = {};
  int _revisionCount = 0;

  /// Updates a line in a document with the current timestamp
  void updateLine(String filePath, int lineIndex, String content) {
    final doc = _documentState.putIfAbsent(filePath, () => {});
    doc[lineIndex] = LineState(content, DateTime.now().millisecondsSinceEpoch);
    _revisionCount++;
    _checkAndPrune();
  }

  /// Exports the entire document state to JSON
  Map<String, dynamic> exportState(String filePath) {
    final doc = _documentState[filePath] ?? {};
    return doc.map((key, value) => MapEntry(key.toString(), value.toJson()));
  }

  /// Merges remote document state updates with local state and returns the merged string
  String mergeState(String filePath, Map<String, dynamic> remoteJson, String localFallbackText) {
    final doc = _documentState.putIfAbsent(filePath, () => {});

    // Parse remote state
    remoteJson.forEach((key, val) {
      final lineIdx = int.parse(key);
      final remoteLine = LineState.fromJson(val as Map<String, dynamic>);
      final localLine = doc[lineIdx];

      if (localLine == null || remoteLine.timestamp > localLine.timestamp) {
        doc[lineIdx] = remoteLine;
        _revisionCount++;
      }
    });

    _checkAndPrune();

    // Reconstruct the full text from line map
    if (doc.isEmpty) return localFallbackText;
    final maxIdx = doc.keys.reduce(max);
    final List<String> lines = [];
    for (int i = 0; i <= maxIdx; i++) {
      lines.add(doc[i]?.content ?? "");
    }
    return lines.join("\n");
  }

  /// Reinitialize document state from raw text
  void initFromText(String filePath, String text) {
    final doc = _documentState.putIfAbsent(filePath, () => {});
    doc.clear();
    final lines = text.split("\n");
    final ts = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < lines.length; i++) {
      doc[i] = LineState(lines[i], ts);
    }
  }

  /// Perform Garbage Collection to clean up metadata and optimize memory footprint
  void _checkAndPrune() {
    if (_revisionCount > 1000) {
      pruneAllHistories();
      _revisionCount = 0;
      print("[CRDT GC] History pruned for performance (1,000 revisions threshold reached).");
    }
  }

  /// Wipes historical timestamps and reduces state data to current content snapshots
  void pruneAllHistories() {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var filePath in _documentState.keys) {
      final doc = _documentState[filePath] ?? {};
      for (var lineIdx in doc.keys) {
        final currentLine = doc[lineIdx];
        if (currentLine != null) {
          doc[lineIdx] = LineState(currentLine.content, now);
        }
      }
    }
  }
}
