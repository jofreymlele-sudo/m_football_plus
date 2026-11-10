import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const key = '564c2af3abc67c7000e90ede24794545';

  print('=== 1. TESTING RAPIDAPI (api-football-v1.p.rapidapi.com) ===');
  final rapidHeaders = {
    'x-rapidapi-key': key,
    'x-rapidapi-host': 'api-football-v1.p.rapidapi.com',
  };

  final resRapid = await http.get(
    Uri.parse('https://api-football-v1.p.rapidapi.com/v3/fixtures?live=all'),
    headers: rapidHeaders,
  );
  print('RapidAPI Live: status=${resRapid.statusCode}, body=${resRapid.body.substring(0, resRapid.body.length > 250 ? 250 : resRapid.body.length)}');

  final resStandings = await http.get(
    Uri.parse('https://api-football-v1.p.rapidapi.com/v3/standings?league=39&season=2024'),
    headers: rapidHeaders,
  );
  print('RapidAPI Standings EPL: status=${resStandings.statusCode}, body=${resStandings.body.substring(0, resStandings.body.length > 250 ? 250 : resStandings.body.length)}');

  final resDirect = await http.get(
    Uri.parse('https://v3.football.api-sports.io/status'),
    headers: {'x-apisports-key': key},
  );
  print('Direct API-Sports status: ${resDirect.body}');
}
