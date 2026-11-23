import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/sala_musica.dart';
import 'package:taotao/screens/musica/musica_inicio.dart';

void main() {
  group('Cancion.idDe', () {
    test('entiende links de YouTube y YouTube Music', () {
      for (final l in [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://music.youtube.com/watch?v=dQw4w9WgXcQ&feature=share',
        'https://youtu.be/dQw4w9WgXcQ?si=abc',
        'https://m.youtube.com/watch?v=dQw4w9WgXcQ&pp=xx',
        'https://www.youtube.com/shorts/dQw4w9WgXcQ',
        'dQw4w9WgXcQ',
      ]) {
        expect(Cancion.idDe(l), 'dQw4w9WgXcQ', reason: l);
      }
    });

    test('no acepta otras cosas', () {
      for (final l in [
        '',
        'hola',
        'https://open.spotify.com/track/abc',
        'https://www.youtube.com/playlist?list=PL123456',
        'https://m.youtube.com/results?search_query=sutra',
      ]) {
        expect(Cancion.idDe(l), isNull, reason: l);
      }
    });
  });

  group('SalaMusica', () {
    final t0 = DateTime(2026, 11, 23, 20);

    test('en play, la posición avanza con el reloj', () {
      final s = SalaMusica(sonando: true, posicion: 30, cambiadoEn: t0);
      expect(s.posicionEn(t0.add(const Duration(seconds: 12))), 42);
    });

    test('en pausa, se queda quieta', () {
      final s = SalaMusica(posicion: 30, cambiadoEn: t0);
      expect(s.posicionEn(t0.add(const Duration(minutes: 5))), 30);
    });

    test('lee el documento de Firestore', () {
      final s = SalaMusica.fromMap({
        'actual': {'videoId': 'dQw4w9WgXcQ', 'titulo': 'Sutra', 'por': 'A'},
        'sonando': true,
        'posicion': 3,
        'cambiadoEn': Timestamp.fromDate(t0),
        'cola': [
          {'videoId': 'abcdefghijk', 'titulo': '', 'por': 'B'},
          'basura',
        ],
        'oyentes': {'B': Timestamp.fromDate(t0)},
      });
      expect(s.actual!.titulo, 'Sutra');
      expect(s.posicion, 3.0);
      expect(s.cola.single.tituloVisible, 'Canción');
      expect(s.escuchando('B', t0.add(const Duration(minutes: 1))), isTrue);
      expect(s.escuchando('B', t0.add(const Duration(minutes: 10))), isFalse);
      expect(s.escuchando('A', t0), isFalse);
    });
  });

  group('AppMusica', () {
    test('busca por nombre en cada app', () {
      expect(
        AppMusica.spotify.enlace('Sutra').toString(),
        'https://open.spotify.com/search/Sutra',
      );
      expect(
        AppMusica.youtubeMusic.enlace('mi canción').toString(),
        'https://music.youtube.com/search?q=mi+canci%C3%B3n',
      );
    });

    test('un link de YouTube se abre en YouTube Music', () {
      expect(
        AppMusica.youtubeMusic
            .enlace('https://youtu.be/dQw4w9WgXcQ')
            .toString(),
        'https://music.youtube.com/watch?v=dQw4w9WgXcQ',
      );
    });

    test('QQ Music busca y abre sus links tal cual', () {
      expect(
        AppMusica.qqMusic.enlace('月亮代表我的心').toString(),
        startsWith('https://y.qq.com/n/ryqq/search?w='),
      );
      const link = 'https://y.qq.com/n/ryqq/songDetail/0039MnYb0qxYhV';
      expect(AppMusica.qqMusic.enlace(link).toString(), link);
      expect(AppMusica.spotify.enlace(link).toString(), link);
    });

    test('un link de Spotify se abre tal cual', () {
      expect(
        AppMusica.spotify
            .enlace('https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC')
            .toString(),
        'https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC',
      );
    });
  });

  group('CuentaJuntos', () {
    test('el ¡ya! llega a los segundos pedidos', () {
      final t0 = DateTime(2026, 11, 23, 20);
      final c = CuentaJuntos(cancion: 'x', por: 'A', inicio: t0);
      expect(c.ya(t0), t0.add(const Duration(seconds: CuentaJuntos.duracion)));
      expect(c.vieja(t0.add(const Duration(seconds: 10))), isFalse);
      expect(c.vieja(t0.add(const Duration(minutes: 2))), isTrue);
    });
  });

  testWidgets('la tarjeta del inicio invita a unirse', (tester) async {
    final sala = SalaMusica(
      actual: const Cancion(videoId: 'dQw4w9WgXcQ', titulo: 'Sutra'),
      sonando: true,
      cambiadoEn: DateTime.now(),
      oyentes: {'B': DateTime.now()},
    );
    var tocada = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MusicaInicioCard(
            sala: sala,
            partnerUid: 'B',
            partnerName: 'Taotao',
            onTap: () => tocada = true,
          ),
        ),
      ),
    );
    expect(find.text('Música juntos'), findsOneWidget);
    expect(find.textContaining('Taotao está escuchando "Sutra"'), findsOne);
    await tester.tap(find.text('Música juntos'));
    expect(tocada, isTrue);
  });

  testWidgets('sin música, explica para qué sirve', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MusicaInicioCard(
            sala: SalaMusica.vacia,
            partnerUid: 'B',
            partnerName: 'Taotao',
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('aunque estén lejos'), findsOneWidget);
  });
}
