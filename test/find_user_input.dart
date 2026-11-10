import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(r'C:\Users\Jofrey Mlele\.gemini\antigravity\brain\dc5e219b-fc0f-44da-a5ef-0672bccc3e2b\.system_generated\logs\transcript.jsonl');
  final lines = file.readAsLinesSync();
  for (final l in lines) {
    final obj = jsonDecode(l);
    final idx = obj['step_index'] as int?;
    if (idx != null && idx >= 573 && idx <= 586) {
      print('STEP $idx [${obj['type']}]: ${obj['content']?.toString().substring(0, (obj['content']?.toString().length ?? 0) > 200 ? 200 : (obj['content']?.toString().length ?? 0))}');
    }
  }
}
