import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const key = '564c2af3abc67c7000e90ede24794545';

  print('=== 1. TESTING API-SPORTS DIRECT (v3.football.api-sports.io) ===');
  final directHeaders = {
    'x-apisports-key': key,
  };
  for (final lId in [567, 39, 140, 135, 2]) {
    for (final season in [2024, 2023, 2025]) {
      final res = await http.get(
        Uri.parse('https://v3.football.api-sports.io/standings?league=$lId&season=$season'),
        headers: directHeaders,
      );
      final data = jsonDecode(res.body);
      final resp = data['response'] as List?;
      final errors = data['errors'];
      print('Direct League $lId ($season): status=${res.statusCode}, respLen=${resp?.length}, errors=$errors');
      if (resp != null && resp.isNotEmpty) {
        final st = resp[0]['league']['standings'] as List?;
        print('  Standing groups: ${st?.length}');
        if (st != null && st.isNotEmpty && st[0] is List && (st[0] as List).isNotEmpty) {
          final top = st[0][0];
          print('  Top: #${top['rank']} ${top['team']['name']} (Pts: ${top['points']})');
        }
      }
    }
  }

  print('\n=== 2. TESTING FIXTURES ON DATES ===');
  // Test today, yesterday, tomorrow
  final now = DateTime.now();
  for (final offset in [-1, 0, 1]) {
    final d = now.add(Duration(days: offset));
    final dStr = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    final res = await http.get(
      Uri.parse('https://v3.football.api-sports.io/fixtures?date=$dStr'),
      headers: directHeaders,
    );
    final data = jsonDecode(res.body);
    final resp = data['response'] as List?;
    final errors = data['errors'];
    print('Date $dStr (offset $offset): status=${res.statusCode}, count=${resp?.length}, errors=$errors');
  }

  print('\n=== 3. TESTING ESPN NEWS ===');
  for (final cat in ['all', 'ucl', 'epl', 'laliga', 'transfer']) {
    String espnLeague = 'all';
    if (cat == 'epl') espnLeague = 'eng.1';
    if (cat == 'laliga') espnLeague = 'esp.1';
    if (cat == 'ucl') espnLeague = 'uefa.champions';
    final res = await http.get(Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/$espnLeague/news'));
    final data = jsonDecode(res.body);
    final articles = data['articles'] as List?;
    print('News $cat ($espnLeague): status=${res.statusCode}, count=${articles?.length}');
  }
}
