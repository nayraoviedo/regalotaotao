import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:taotao/models/app_user.dart';
import 'package:taotao/models/casita.dart';
import 'package:taotao/screens/casita/casita_screen.dart';
import 'package:taotao/screens/casita/casa_en_corte.dart';
import 'package:taotao/screens/casita/cuarto.dart';
import 'package:taotao/services/foto_pixelada.dart';
import 'package:taotao/services/pescaditos_service.dart';
import 'package:taotao/theme.dart';
import 'package:taotao/widgets/texto_doodle.dart';

void main() {
  group('Catálogo', () {
    test('cada cosa tiene id único y sus dibujos existen', () {
      final ids = Catalogo.cosas.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final c in Catalogo.cosas) {
        final archivos = c.esRopa
            ? [c.assetRopa('naranja'), c.assetRopa('blanco')]
            : c.especial == Especial.stickers
            ? [
                for (final n in Catalogo.stickersDe[c.id]!)
                  'assets/notas/sticker_$n.png',
              ]
            : c.especial == Especial.tema
            ? <String>[]
            : c.esBebe
            ? [
                for (final f in ['a', 'b', 'zz']) Casita.asset('${c.id}_$f'),
              ]
            : [c.asset];
        if (c.especial == Especial.tema) {
          expect(TemaApp.de(c.claveTema).clave, c.claveTema, reason: c.id);
        }
        for (final a in archivos) {
          expect(File(a).existsSync(), isTrue, reason: 'falta $a');
        }
      }
      for (final a in [
        Casita.asset('gatito_naranja'),
        Casita.asset('gatito_blanco'),
        Casita.asset('marco'),
        Casita.asset('marco_jardin'),
        Casita.iconoPescadito,
      ]) {
        expect(File(a).existsSync(), isTrue, reason: 'falta $a');
      }
    });

    test('el aviso del Worker tiene el nombre de todo lo que se compra', () {
      final worker = File('worker/src/index.js').readAsStringSync();
      for (final c in Catalogo.cosas.where((c) => !c.gratis)) {
        expect(worker, contains('  ${c.id}: "'), reason: c.id);
      }
    });

    test('lo inicial es gratis y lo demás cuesta', () {
      for (final l in Lugar.values) {
        if (l.inicial case final id?) {
          expect(Catalogo.porId(id)!.gratis, isTrue);
        }
      }
      expect(Catalogo.cosas.where((c) => c.gratis).length, 12);
    });
  });

  group('Temas y stickers', () {
    test('lo comprado se puede usar', () {
      const e = EstadoCasita(tenemos: {'tema_menta', 'stickers_comida'});
      expect(e.temas, ['clasico', 'menta']);
      expect(e.stickersExtra, ['pizza', 'onigiri', 'boba', 'helado']);
      expect(EstadoCasita.vacio.stickersExtra, isEmpty);
      expect(TemaApp.de('nada'), TemaApp.clasico);
    });

    test('los colores de la app siguen al tema', () {
      addTearDown(() => AppTheme.tema.value = TemaApp.clasico);
      AppTheme.tema.value = TemaApp.de('sakura');
      expect(AppTheme.azul, TemaApp.de('sakura').principal);
      expect(
        AppTheme.light.scaffoldBackgroundColor,
        TemaApp.de('sakura').fondo,
      );
    });
  });

  group('Casita viva', () {
    test('día, tarde y noche según la hora', () {
      expect(Momento.de(DateTime(2026, 1, 1, 9)), Momento.dia);
      expect(Momento.de(DateTime(2026, 1, 1, 18, 30)), Momento.tarde);
      expect(Momento.de(DateTime(2026, 1, 1, 23)), Momento.noche);
      expect(Momento.de(DateTime(2026, 1, 1, 3)), Momento.noche);
      expect(Momento.de(DateTime(2026, 1, 1, 7)), Momento.dia);
    });

    test('los dibujos de la casita viva existen', () {
      for (final n in [
        'noche',
        'tarde',
        for (final g in ['naranja', 'blanco']) ...[
          'gatito_${g}_cola',
          'parpadeo_$g',
        ],
        for (final c in ['camita', 'cama']) ...[
          'dormidos_$c',
          'zzz_${c}_1',
          'zzz_${c}_2',
        ],
        for (final id in Casita.animadas) '${id}_2',
        for (final id in Casita.conLuz) 'luz_$id',
      ]) {
        expect(File(Casita.asset(n)).existsSync(), isTrue, reason: 'falta $n');
      }
      for (final id in [...Casita.animadas, ...Casita.conLuz]) {
        expect(Catalogo.porId(id), isNotNull, reason: id);
      }
    });

    test('de noche se prenden las luces y duermen en la camita', () {
      const e = EstadoCasita(
        tenemos: {'camita_cojin', 'lampara_pie'},
        puestos: {'camita': 'camita_cojin', 'lampara': 'lampara_pie'},
        ropa: {
          'naranja': {'cabeza': 'gorrito'},
        },
      );
      final noche = e.capas(Cuarto.sala, true, Momento.noche);
      expect(noche, contains(Casita.asset('dormidos_camita')));
      expect(noche, contains(Casita.asset('noche')));
      expect(noche, contains(Casita.asset('luz_lampara_pie')));
      expect(noche, isNot(contains(Casita.asset('gatito_naranja'))));
      // La luz va encima de la noche.
      expect(
        noche.indexOf(Casita.asset('luz_lampara_pie')),
        greaterThan(noche.indexOf(Casita.asset('noche'))),
      );

      final dia = e.capas(Cuarto.sala, true, Momento.dia);
      expect(dia, contains(Casita.asset('gatito_naranja')));
      expect(dia, isNot(contains(Casita.asset('luz_lampara_pie'))));

      // Sin camita, de noche se quedan despiertos.
      expect(
        EstadoCasita.vacio.capas(Cuarto.sala, true, Momento.noche),
        contains(Casita.asset('gatito_naranja')),
      );
      // En la cocina no hay dónde dormir.
      expect(e.duermen(Cuarto.cocina, Momento.noche), isFalse);
    });

    test('los gatitos parpadean y mueven la cola, y el pajarito se mueve', () {
      const e = EstadoCasita(
        tenemos: {'pajarito_azul'},
        puestos: {'pajarito': 'pajarito_azul'},
      );
      final vistas = [
        for (var t = 0; t < 26; t++) e.capas(Cuarto.sala, true, Momento.dia, t),
      ];
      bool alguna(String a) => vistas.any((v) => v.contains(Casita.asset(a)));
      expect(alguna('parpadeo_naranja'), isTrue);
      expect(alguna('parpadeo_blanco'), isTrue);
      expect(alguna('gatito_naranja_cola'), isTrue);
      expect(alguna('pajarito_azul_2'), isTrue);
      // Quieto (tick 0), todo normal.
      expect(vistas.first, contains(Casita.asset('gatito_naranja')));
      expect(vistas.first, contains(Casita.asset('pajarito_azul')));
      expect(
        alguna('parpadeo_naranja') &&
            !vistas.first.contains(Casita.asset('parpadeo_naranja')),
        isTrue,
      );
    });

    test('alcancía: lo ahorrado queda apartado y se recorta al cambiar', () {
      final e = EstadoCasita.fromMap({
        'pescaditos': 150,
        'meta': 'sofa_rosa',
        'ahorrado': 100,
        'aportes': {'a': 70, 'b': 30},
      });
      expect(e.aportes, {'a': 70, 'b': 30});
      expect(e.libres, 50);
      expect(e.alcanciaLlena, isFalse);
      expect(e.paraGastarEn(Catalogo.porId('sofa_rosa')!), 150);
      expect(e.paraGastarEn(Catalogo.porId('sofa_azul')!), 50);
      // Sin la meta, nada apartado.
      expect(const EstadoCasita(pescaditos: 40).libres, 40);
      // Al cambiar a una meta más barata, se quita primero de quien puso más.
      expect(PescaditosService.recortarAportes({'a': 70, 'b': 30}, 60), {
        'a': 30,
        'b': 30,
      });
      expect(PescaditosService.recortarAportes({'a': 70, 'b': 30}, 200), {
        'a': 70,
        'b': 30,
      });
    });

    test('regalos sorpresa y alcancía desde Firestore', () {
      final e = EstadoCasita.fromMap({
        'tenemos': ['sofa_rosa', 'esmoquin'],
        'regalos': {
          'sofa_rosa': {'de': 'a', 'mensaje': 'hola'},
          'esmoquin': {'de': 'b', 'mensaje': '', 'gatito': 'naranja'},
        },
        'meta': 'cuarto_jardin',
      });
      expect(e.regalosPara('b').single.$1.id, 'sofa_rosa');
      expect(e.regalosPara('a').single.$2.gatito, 'naranja');
      expect(e.envuelto(Catalogo.porId('sofa_rosa')!), isTrue);
      expect(e.metaCosa?.id, 'cuarto_jardin');
      // La cajita aparece en la sala.
      expect(e.capas(), contains(Casita.regaloEnvuelto));
      expect(
        EstadoCasita.vacio.capas(),
        isNot(contains(Casita.regaloEnvuelto)),
      );
      // Ya comprada, la meta deja de contar.
      expect(
        const EstadoCasita(tenemos: {'sofa_rosa'}, meta: 'sofa_rosa').metaCosa,
        isNull,
      );
      expect(const Regalo(de: 'a', gatito: 'blanco').toMap(), {
        'de': 'a',
        'mensaje': '',
        'gatito': 'blanco',
      });
      expect(File(Casita.regaloEnvuelto).existsSync(), isTrue);
    });

    test('la foto pixelada se lee de Firestore y se baja de tonos', () {
      final px = List.filled(Casita.fotoAncho * Casita.fotoAlto, 0xFF112233);
      expect(EstadoCasita.fromMap({'foto': px}).foto, px);
      expect(
        EstadoCasita.fromMap({
          'foto': [1, 2],
        }).foto,
        isNull,
      );
      expect(EstadoCasita.fromMap({}).foto, isNull);

      final c = colores(Uint8List.fromList([250, 13, 100, 255, 0, 0, 0, 255]));
      expect(c, [0xFFF01860, 0xFF000000]);
    });
  });

  group('Estado de la casita', () {
    test('al principio: pared, piso, ventana y los dos gatitos', () {
      const e = EstadoCasita.vacio;
      expect(e.puesto(Lugar.pared)?.id, 'pared_crema');
      expect(e.puesto(Lugar.piso)?.id, 'piso_madera');
      expect(e.puesto(Lugar.ventana)?.id, 'ventana_simple');
      expect(e.puesto(Lugar.sofa), isNull);
      expect(e.capas(), [
        'assets/casita/pared_crema.png',
        'assets/casita/piso_madera.png',
        'assets/casita/ventana_simple.png',
        'assets/casita/gatito_naranja.png',
        'assets/casita/gatito_blanco.png',
        'assets/casita/marco.png',
      ]);
    });

    test('lo comprado se pone, se quita y la ropita es por gatito', () {
      final e = EstadoCasita.fromMap({
        'pescaditos': 40,
        'tenemos': ['sofa_azul', 'mono', 'pared_rosa'],
        'puestos': {'sofa': 'sofa_azul', 'ventana': '', 'pared': ''},
        'ropa': {
          'blanco': {'cuello': 'mono'},
          // No la compraron: no se muestra.
          'naranja': {'cabeza': 'corona'},
        },
      });
      expect(e.pescaditos, 40);
      expect(e.puesto(Lugar.sofa)?.id, 'sofa_azul');
      expect(e.puesto(Lugar.ventana), isNull);
      // La pared nunca queda vacía.
      expect(e.puesto(Lugar.pared)?.id, 'pared_crema');
      expect(e.prenda('blanco', Parte.cuello)?.id, 'mono');
      expect(e.prenda('naranja', Parte.cabeza), isNull);
      expect(e.quienLleva(Catalogo.porId('mono')!), ['blanco']);
      expect(e.capas(), contains('assets/casita/ropa_mono_blanco.png'));
      expect(e.tiene(Catalogo.porId('corona')!), isFalse);
    });

    test('tocar el cuarto encuentra el mueble o a los gatitos', () {
      expect(CuartoCasita.queHay(40, 80), CuartoCasita.zonaGatitos);
      expect(CuartoCasita.queHay(40, 50), Lugar.sofa);
      expect(CuartoCasita.queHay(20, 25), Lugar.ventana);
      expect(CuartoCasita.queHay(55, 25), Lugar.cuadro);
      expect(CuartoCasita.queHay(70, 88), Lugar.camita);
      expect(CuartoCasita.queHay(30, 95), Lugar.alfombra);
      expect(CuartoCasita.queHay(10, 40, Cuarto.cocina), Lugar.refri);
      expect(CuartoCasita.queHay(60, 50, Cuarto.dormitorio), Lugar.cama);
      expect(CuartoCasita.queHay(66, 88, Cuarto.jardin), Lugar.estanque);
      expect(CuartoCasita.queHay(60, 55, Cuarto.bano), Lugar.tina);
      expect(CuartoCasita.queHay(10, 90, Cuarto.bano), Lugar.arenero);
      expect(CuartoCasita.queHay(70, 90, Cuarto.bano), Lugar.patito);
    });

    test('los bebés adoptados pasean por el piso y de noche duermen', () {
      final e = EstadoCasita.fromMap({
        'tenemos': ['bebe_calico', 'bebe_siames'],
        'bebes': {'calico': 'Mochi'},
      });
      expect(e.bebes.map((b) => b.id), ['bebe_siames', 'bebe_calico']);
      expect(e.nombreDe(Catalogo.porId('bebe_calico')!), 'Mochi');
      expect(e.nombreDe(Catalogo.porId('bebe_siames')!), isNull);
      expect(e.capas(), contains(Casita.bebesPaseando));
      expect(
        e.capas(Cuarto.sala, true, Momento.noche),
        contains(Casita.bebesDurmiendo),
      );
      expect(EstadoCasita.vacio.capas(), isNot(contains(Casita.bebesPaseando)));
      // Siempre en el piso, sin subirse a los gatitos grandes ni encimarse
      // entre ellos, y se mueven.
      bool choca(PaseoBebe a, double x, double y, double w, double h) =>
          a.x < x + w &&
          a.x + PaseoBebe.ancho > x &&
          a.y < y + h &&
          a.y + PaseoBebe.alto > y;
      final vistos = <(double, double)>{};
      for (var tick = 0; tick < 2000; tick++) {
        final n = 1 + tick % 6;
        final ps = [
          for (var i = 0; i < n; i++) PaseoBebe.en(i, tick, total: n),
        ];
        for (final (i, p) in ps.indexed) {
          expect(p.x, inInclusiveRange(2, 78 - PaseoBebe.ancho));
          expect(p.y, inInclusiveRange(60, 100 - PaseoBebe.alto));
          expect(choca(p, 20, 70, 42, 21), isFalse, reason: 'tick $tick');
          for (final q in ps.skip(i + 1)) {
            expect(
              choca(p, q.x, q.y, PaseoBebe.ancho, PaseoBebe.alto),
              isFalse,
              reason: 'tick $tick',
            );
          }
          vistos.add((p.x, p.y));
        }
      }
      expect(vistos.length, greaterThan(100));
      expect(
        PaseoBebe.en(0, 3).caminando || PaseoBebe.en(0, 12).caminando,
        isTrue,
      );
    });

    test('los bebés se reparten por los cuartos abiertos', () {
      final e = EstadoCasita.fromMap({
        'tenemos': [
          'cuarto_cocina',
          'cuarto_jardin',
          ...Catalogo.bebes.map((b) => b.id),
        ],
      });
      final hora = DateTime(2026, 11, 23, 12);
      final dondeAndan = [for (final c in Cuarto.values) ...e.bebesEn(c, hora)];
      // Cada bebé está en un solo cuarto, y nunca en uno cerrado.
      expect(dondeAndan.length, 6);
      expect(dondeAndan.toSet().length, 6);
      expect(e.bebesEn(Cuarto.bano, hora), isEmpty);
      // Con el tiempo se cambian de cuarto.
      final otraHora = [
        for (var m = 0; m < 24 * 60; m += 15)
          e.bebesEn(Cuarto.cocina, hora.add(Duration(minutes: m))).length,
      ];
      expect(otraHora.toSet().length, greaterThan(1));
    });

    test('con cuarto de juegos, los bebés andan ahí más seguido', () {
      final e = EstadoCasita.fromMap({
        'tenemos': [
          'cuarto_cocina',
          'cuarto_juegos',
          ...Catalogo.bebes.map((b) => b.id),
        ],
      });
      final cuenta = {for (final c in Cuarto.values) c: 0};
      final hora = DateTime(2026, 11, 23, 12);
      for (var m = 0; m < 24 * 60; m += 15) {
        final t = hora.add(Duration(minutes: m));
        var total = 0;
        for (final c in Cuarto.values) {
          final n = e.bebesEn(c, t).length;
          cuenta[c] = cuenta[c]! + n;
          total += n;
        }
        expect(total, 6); // cada bebé en un solo cuarto
      }
      expect(cuenta[Cuarto.juegos]!, greaterThan(cuenta[Cuarto.sala]! * 2));
      expect(cuenta[Cuarto.huerto], 0); // cerrado
    });

    test('la rutina del día: bañito, comidas, cocinar, siesta y picnic', () {
      final e = EstadoCasita.fromMap({
        'tenemos': [
          'cuarto_dormitorio',
          'cama_estrellas',
          'cuarto_cocina',
          'cuarto_bano',
          'tina_blanca',
          'cuarto_jardin',
        ],
        'puestos': {'cama': 'cama_estrellas', 'tina': 'tina_blanca'},
      });
      String a(String n) => 'assets/casita/$n.png';
      Escena? aLas(int h) => e.escena(DateTime(2026, 11, 24, h, 20));
      expect(aLas(7), Escena.bano);
      expect(aLas(8), Escena.desayuno);
      expect(aLas(9), Escena.besitos);
      expect(
        CasaView.queHacen(e, DateTime(2026, 11, 24, 9, 20)),
        'Los gatitos están dándose besitos en la sala',
      );
      expect(aLas(12), Escena.cocinando);
      expect(aLas(13), Escena.almuerzo);
      expect([aLas(14), aLas(15)], everyElement(Escena.siesta));
      expect([aLas(16), aLas(17)], everyElement(Escena.picnic));
      expect(aLas(18), Escena.cocinando);
      expect(aLas(19), Escena.cena);
      expect(aLas(20), Escena.drama);
      // A las 21 ven las estrellas en el jardín (sin jardín, siguen con
      // su drama).
      expect(aLas(21), Escena.estrellas);
      expect(
        EstadoCasita.fromMap({
          'tenemos': ['cuarto_cocina'],
        }).escena(DateTime(2026, 11, 24, 21, 20)),
        Escena.drama,
      );
      expect([aLas(3), aLas(6), aLas(22)], everyElement(isNull));
      // La siesta es en la cama, y se ve que duermen.
      final tres = DateTime(2026, 11, 24, 14, 20);
      expect(e.dondeEstan(tres), Cuarto.dormitorio);
      expect(
        e.capas(Cuarto.dormitorio, true, Momento.dia, 0, false, tres),
        contains(a('dormidos_cama')),
      );
      // A las 7 están en la tina.
      final siete = DateTime(2026, 11, 24, 7, 20);
      expect(
        e.capas(Cuarto.bano, true, Momento.dia, 0, false, siete),
        contains(a('banando_1')),
      );
      // Uno cocina (se turnan cada día) y el otro pica.
      final doce = DateTime(2026, 11, 24, 12, 20);
      final quien = EstadoCasita.quienCocina(doce);
      expect(
        EstadoCasita.quienCocina(DateTime(2026, 11, 25, 12)),
        isNot(quien),
      );
      expect(
        e.capas(Cuarto.cocina, true, Momento.dia, 0, false, doce),
        containsAll([
          a('escena_cocinar_${quien}_1'),
          a('picando_pescadito_${EstadoCasita.otro(quien)}'),
        ]),
      );
      expect(
        CasaView.queHacen(e, doce),
        'El gatito $quien cocina pescadito y el '
        '${EstadoCasita.otro(quien)} le ayuda',
      );
      // Sin cocina ni tina, esas horas son un rato libre.
      final sala = EstadoCasita.fromMap({});
      for (final h in [7, 8, 12, 13, 19]) {
        final esc = sala.escena(DateTime(2026, 11, 24, h, 20));
        expect(esc == null || esc.libre, isTrue, reason: '$h');
      }
      // Todos los dibujos de la rutina existen.
      for (final c in Comida.values) {
        expect(File(a('plato_${c.dibujo}')).existsSync(), isTrue);
        for (final g in ['naranja', 'blanco']) {
          expect(File(a('picando_${c.picando}_$g')).existsSync(), isTrue);
          expect(File(a('escena_cocinar_${g}_2')).existsSync(), isTrue);
        }
      }
      for (final r in Receta.values) {
        expect(File(a('plato_${r.dibujo}')).existsSync(), isTrue);
        for (final g in ['naranja', 'blanco']) {
          expect(
            File(a('picando_${r.principal.name}_$g')).existsSync(),
            isTrue,
          );
        }
      }
    });

    test('lo del huerto se recoge y se cocina', () {
      final ahora = DateTime(2026, 11, 24, 10);
      final huerto = EstadoCasita.fromMap({
        'tenemos': ['cuarto_huerto', 'tomatera', 'lechugas'],
        'puestos': {'tomatera': 'tomatera', 'surco': 'lechugas'},
        'sembrado': {
          // El tomate ya creció; la lechuga recién se sembró.
          'tomatera': ahora
              .subtract(const Duration(days: 3))
              .millisecondsSinceEpoch,
          'lechugas': ahora.millisecondsSinceEpoch,
        },
      });
      expect(huerto.cosechables(ahora).map((c) => c.id), ['tomatera']);
      // Cada ingrediente sale de una semilla de la tienda, y cada uno se
      // usa en alguna receta.
      // (lo básico no se siembra: lo trae el repartidor).
      for (final i in Ingrediente.values) {
        if (!i.delRepartidor) {
          expect(Catalogo.porId(i.semilla)?.semilla, isTrue, reason: i.name);
        }
        expect(
          Receta.values.any((r) => r.ingredientes.containsKey(i)),
          isTrue,
          reason: i.name,
        );
      }
      final e = EstadoCasita.fromMap({
        'tenemos': ['cuarto_cocina'],
        'despensa': {'tomate': 3, 'lechuga': 0, 'sal': 1},
        'cocinado': {
          'receta': 'sopaTomate',
          'en': ahora.millisecondsSinceEpoch,
        },
      });
      expect(e.hay(Ingrediente.tomate), 3);
      expect(e.puedeCocinar(Receta.sopaTomate), isTrue);
      expect(e.puedeCocinar(Receta.ensalada), isFalse);
      // Lo cocinado se come en el almuerzo y la cena (no en el desayuno).
      final una = DateTime(2026, 11, 24, 13, 10);
      expect(e.platoDe(Comida.almuerzo, una), Receta.sopaTomate);
      expect(e.platoDe(Comida.desayuno, una), isNull);
      expect(
        e.capas(Cuarto.cocina, true, Momento.dia, 0, false, una),
        containsAll([
          'assets/casita/escena_comer_1.png',
          'assets/casita/plato_sopa_tomate.png',
        ]),
      );
      expect(
        CasaView.queHacen(e, una),
        'Los gatitos están almorzando sopa de tomate del huerto',
      );
      final seis = DateTime(2026, 11, 24, 18, 10);
      final quien = EstadoCasita.quienCocina(seis);
      expect(
        CasaView.queHacen(e, seis),
        'El gatito $quien cocina sopa de tomate del huerto y el '
        '${EstadoCasita.otro(quien)} le ayuda picando tomates',
      );
      // Al día siguiente ya se lo comieron: vuelve lo de siempre.
      expect(
        e.platoDe(Comida.almuerzo, una.add(const Duration(days: 1))),
        isNull,
      );
      expect(
        CasaView.queHacen(e, DateTime(2026, 11, 25, 8, 10)),
        'Los gatitos están desayunando pancito con leche',
      );
    });

    test('el cielo detrás de la casa sigue la hora real', () {
      Cielo a(int h) => Cielo.de(DateTime(2026, 11, 24, h, 30));
      expect(a(6), Cielo.amanecer);
      expect([a(7), a(12), a(17)], everyElement(Cielo.dia));
      expect([a(18), a(19)], everyElement(Cielo.atardecer));
      expect([a(20), a(23), a(0), a(5)], everyElement(Cielo.noche));
      for (final c in Cielo.values) {
        expect(File(c.asset).existsSync(), isTrue, reason: c.asset);
      }
    });

    test('la casa en corte: cada cuarto en su lugar y los gatitos en uno', () {
      expect(CasaEnCorte.queCuarto(200, 190), Cuarto.dormitorio);
      expect(CasaEnCorte.queCuarto(280, 280), Cuarto.cocina);
      expect(CasaEnCorte.queCuarto(120, 280), Cuarto.jardin);
      expect(CasaEnCorte.queCuarto(40, 280), Cuarto.huerto);
      expect(CasaEnCorte.queCuarto(250, 100), Cuarto.juegos);
      expect(CasaEnCorte.queCuarto(250, 30), isNull); // el techo
      expect(File(CasaEnCorte.marco).existsSync(), isTrue);
      expect(File(CasaEnCorte.fachada).existsSync(), isTrue);
      final conCama = EstadoCasita.fromMap({
        'tenemos': ['cuarto_dormitorio', 'cama_estrellas', 'cuarto_cocina'],
        'puestos': {'cama': 'cama_estrellas'},
      });
      expect(conCama.dondeEstan(DateTime(2026, 11, 23, 23)), Cuarto.dormitorio);
      expect(
        EstadoCasita.vacio.dondeEstan(DateTime(2026, 11, 23, 23)),
        Cuarto.sala,
      );
      // De día andan por un cuarto abierto (nunca uno cerrado).
      for (var h = 0; h < 48; h++) {
        final d = conCama.dondeEstan(
          DateTime(2026, 11, 23, 8).add(Duration(minutes: 30 * h ~/ 4)),
        );
        expect(conCama.abierto(d), isTrue);
      }
      expect(
        conCama.capas(Cuarto.sala, true, Momento.dia, 0, false, null, false),
        isNot(contains('assets/casita/gatito_naranja.png')),
      );
    });

    test('las semillas crecen en dos días', () {
      final sembrado = DateTime(2026, 11, 23, 9);
      final e = EstadoCasita.fromMap({
        'tenemos': ['cuarto_huerto', 'tomatera', 'espantapajaros'],
        'puestos': {'tomatera': 'tomatera', 'fondoHuerto': 'espantapajaros'},
        'sembrado': {'tomatera': sembrado.millisecondsSinceEpoch},
      });
      final tomate = Catalogo.porId('tomatera')!;
      expect(tomate.semilla, isTrue);
      String a(String n) => 'assets/casita/$n.png';
      List<String> capas(DateTime t) =>
          e.capas(Cuarto.huerto, true, Momento.dia, 0, false, t);
      expect(e.etapa(tomate, sembrado.add(const Duration(hours: 5))), 0);
      expect(
        capas(sembrado.add(const Duration(hours: 5))),
        contains(a('brote_tomatera')),
      );
      expect(
        capas(sembrado.add(const Duration(hours: 30))),
        contains(a('planta_tomatera')),
      );
      final listo = capas(sembrado.add(const Duration(days: 3)));
      expect(listo, contains(a('tomatera')));
      expect(listo, isNot(contains(a('planta_tomatera'))));
      // Lo que no es semilla se ve igual desde el principio.
      expect(capas(sembrado), contains(a('espantapajaros')));
      // Sin fecha de siembra (de antes), ya está crecido.
      expect(EstadoCasita.vacio.etapa(tomate), 2);
      // Todas las etapas tienen dibujo, y cada semilla es de huerto o jardín.
      for (final c in Catalogo.cosas.where((c) => c.semilla)) {
        expect(c.lugar!.cuarto, anyOf(Cuarto.huerto, Cuarto.jardin));
        for (final n in ['brote', 'planta']) {
          expect(
            File(a('${n}_${c.lugar!.name}')).existsSync(),
            isTrue,
            reason: c.id,
          );
        }
        expect(File(c.asset).existsSync(), isTrue, reason: c.id);
      }
    });

    test('en el huerto no se repite la palabra', () {
      final e = EstadoCasita.fromMap({
        'tenemos': ['cuarto_huerto'],
      });
      for (var m = 0; m < 20 * 60; m += 30) {
        final t = DateTime(2026, 11, 23, 8).add(Duration(minutes: m));
        if (e.escena(t) == Escena.huerto) {
          expect(
            CasaView.queHacen(e, t),
            'Los gatitos están regando el huerto en el jardín',
          );
          return;
        }
      }
      fail('nunca riegan el huerto');
    });

    test('escenas de pareja según la hora', () {
      final e = EstadoCasita.fromMap({
        'tenemos': ['cuarto_dormitorio', 'cama_estrellas', 'cuarto_cocina'],
        'puestos': {'cama': 'cama_estrellas'},
      });
      String a(String n) => 'assets/casita/$n.png';
      // Todos los dibujos existen.
      for (final esc in Escena.values) {
        for (final tick in [0, 2]) {
          expect(File(esc.capa(tick)).existsSync(), isTrue, reason: esc.name);
        }
      }
      // A las 8 de la noche ven su drama en la sala, con el brillo de la tele.
      final ocho = DateTime(2026, 11, 23, 20);
      expect(e.escena(ocho), Escena.drama);
      expect(e.dondeEstan(ocho), Cuarto.sala);
      final drama = e.capas(Cuarto.sala, true, Momento.noche, 0, false, ocho);
      expect(drama, containsAll([a('gatito_blanco'), a('escena_drama_1')]));
      expect(drama, contains(a('escena_drama_luz_1')));
      // A la una: el naranja come en la cocina y el blanco duerme solito.
      final una = DateTime(2026, 11, 24, 1);
      expect(e.escena(una), Escena.medianoche);
      final cocina = e.capas(Cuarto.cocina, true, Momento.noche, 0, false, una);
      expect(cocina, contains(a('gatito_naranja')));
      expect(cocina, isNot(contains(a('gatito_blanco'))));
      expect(cocina, contains(a('escena_medianoche_1')));
      final cama = e.capas(
        Cuarto.dormitorio,
        true,
        Momento.noche,
        0,
        false,
        una,
      );
      expect(cama, contains(a('dormido_blanco_cama')));
      expect(cama, isNot(contains(a('dormidos_cama'))));
      expect(e.hayGatitos(Cuarto.cocina, una), isTrue);
      expect(e.hayGatitos(Cuarto.dormitorio, una), isTrue);
      expect(e.hayGatitos(Cuarto.sala, una), isFalse);
      // Sin cocina no hay comilona: duermen los dos.
      final sinCocina = EstadoCasita.fromMap({
        'tenemos': ['cuarto_dormitorio', 'cama_estrellas'],
        'puestos': {'cama': 'cama_estrellas'},
      });
      expect(sinCocina.escena(una), isNull);
      expect(
        sinCocina.capas(Cuarto.dormitorio, true, Momento.noche, 0, false, una),
        contains(a('dormidos_cama')),
      );
      expect(
        CasaView.queHacen(e, ocho),
        'Los gatitos están viendo un drama en la sala',
      );
      expect(
        CasaView.queHacen(e, una),
        'El gatito naranja se levantó a comer a medianoche y el blanco '
        'duerme en el dormitorio',
      );
      expect(
        CasaView.queHacen(e, DateTime(2026, 11, 23, 23)),
        'Los gatitos duermen en el dormitorio',
      );
      // A las 23 duermen juntos.
      expect(e.escena(DateTime(2026, 11, 23, 23)), isNull);
      // De día la escena siempre es del cuarto donde andan, y hay varias.
      final vistas = <Escena>{};
      for (var m = 0; m < 10 * 60; m += 30) {
        final t = DateTime(2026, 11, 23, 8).add(Duration(minutes: m));
        if (e.escena(t) case final esc?) {
          expect(esc.cuarto, e.dondeEstan(t));
          expect(esc, isNot(Escena.medianoche));
          vistas.add(esc);
        }
      }
      expect(vistas.length, greaterThan(1));
      // Sin la hora (vistas quietas) no hay escena.
      expect(
        e.capas(Cuarto.sala, true, Momento.noche, 0),
        isNot(contains(a('escena_drama_1'))),
      );
    });

    test('en el baño, con tina, se bañan los gatitos', () {
      final e = EstadoCasita.fromMap({
        'tenemos': ['cuarto_bano', 'tina_blanca'],
        'puestos': {'tina': 'tina_blanca'},
      });
      expect(e.sePuedenBanar(Cuarto.bano), isTrue);
      final banando = e.capas(Cuarto.bano, true, Momento.noche, 0, true);
      expect(banando, contains('assets/casita/banando_1.png'));
      expect(banando, isNot(contains('assets/casita/gatito_naranja.png')));
      // Sin tina no hay baño (y en la sala tampoco).
      const sinTina = EstadoCasita(tenemos: {'cuarto_bano'});
      expect(sinTina.sePuedenBanar(Cuarto.bano), isFalse);
      expect(
        sinTina.capas(Cuarto.bano, true, Momento.dia, 0, true),
        contains('assets/casita/gatito_naranja.png'),
      );
      expect(e.sePuedenBanar(Cuarto.sala), isFalse);
    });

    test('las festividades caen en sus fechas', () {
      bool activa(Festividad f, DateTime d) =>
          f.activaEn(d, inicioPareja: DateTime(2024, 3, 9)) != null;
      expect(Festividad.pascuaDe(2027), DateTime(2027, 3, 28));
      expect(Festividad.pascuaDe(2026), DateTime(2026, 4, 5));
      expect(activa(Festividad.navidad, DateTime(2026, 12, 24)), isTrue);
      expect(activa(Festividad.navidad, DateTime(2026, 11, 23)), isFalse);
      // Año Nuevo cruza de un año al otro.
      expect(activa(Festividad.anioNuevo, DateTime(2026, 12, 31)), isTrue);
      expect(activa(Festividad.anioNuevo, DateTime(2027, 1, 3)), isTrue);
      expect(activa(Festividad.anioNuevoChino, DateTime(2027, 2, 6)), isTrue);
      expect(activa(Festividad.anioNuevoChino, DateTime(2027, 2, 20)), isTrue);
      expect(activa(Festividad.medioOtono, DateTime(2027, 9, 15)), isTrue);
      expect(activa(Festividad.carnaval, DateTime(2027, 2, 6)), isTrue);
      expect(activa(Festividad.aniversario, DateTime(2027, 3, 10)), isTrue);
      expect(activa(Festividad.primavera, DateTime(2027, 9, 21)), isTrue);
      // Acción de Gracias: cuarto jueves de noviembre.
      expect(Festividad.accionDeGraciasDe(2026), DateTime(2026, 11, 26));
      expect(Festividad.accionDeGraciasDe(2027), DateTime(2027, 11, 25));
      expect(activa(Festividad.accionGracias, DateTime(2026, 11, 26)), isTrue);
      final proximas = Festividad.proximas(DateTime(2026, 11, 23));
      expect(proximas.first.$1, Festividad.accionGracias);
      expect(proximas[1].$1, Festividad.navidad);
      // Cada festividad tiene cosas a la venta.
      for (final f in Festividad.values) {
        expect(Catalogo.cosas.where((c) => c.fiesta == f), isNotEmpty);
      }
    });

    test('la comida de fiesta solo se vende y se cocina en su fecha', () {
      final pavo = Catalogo.cosas.firstWhere((c) => c.id == 'comida_pavo');
      expect(pavo.aLaVenta(DateTime(2026, 11, 26)), isTrue);
      expect(pavo.aLaVenta(DateTime(2026, 12, 20)), isTrue);
      expect(pavo.aLaVenta(DateTime(2026, 11, 10)), isFalse);
      expect(pavo.fiestasTexto, 'Acción de Gracias y Navidad');
      expect(Receta.pavo.deTemporada(DateTime(2026, 12, 24)), isTrue);
      expect(Receta.pavo.deTemporada(DateTime(2026, 7, 1)), isFalse);
      expect(Receta.dumplings.deTemporada(DateTime(2026, 7, 1)), isTrue);
    });

    test('cada cosa de la tienda tiene su dibujo', () {
      for (final c in Catalogo.cosas) {
        if (c.esCuarto || c.esEspecial) continue;
        final archivo = c.esRopa
            ? 'assets/casita/ropa_${c.id}_naranja.png'
            : 'assets/casita/${c.id}.png';
        expect(File(archivo).existsSync(), isTrue, reason: c.id);
        if (c.lugar == Lugar.comida) {
          expect(File(c.assetDelante).existsSync(), isTrue, reason: c.id);
        }
      }
      for (final e in Escena.values.where((e) => e.libre)) {
        expect(File(e.capa(0)).existsSync(), isTrue, reason: e.name);
      }
    });

    test('al darles de comer se despiertan y comen', () {
      final pastel = Catalogo.porId('comida_pastel_chocolate')!;
      final e = EstadoCasita.fromMap({
        'tenemos': ['cuarto_cocina', pastel.id],
      });
      final noche = DateTime(2026, 11, 24, 23, 30);
      final capas = e.capas(
        Cuarto.sala,
        true,
        Momento.noche,
        0,
        false,
        noche,
        true,
        pastel,
      );
      expect(capas, contains('assets/casita/delante_pastel_chocolate.png'));
      expect(capas, contains('assets/casita/escena_comer_1.png'));
      expect(capas.any((c) => c.contains('dormidos')), isFalse);
    });

    test('cada receta tiene su plato y sus ingredientes se cosechan', () {
      final ids = Catalogo.cosas.map((c) => c.id).toSet();
      for (final i in Ingrediente.values) {
        if (i.delRepartidor) {
          expect(
            File('assets/casita/ingrediente_${i.name}.png').existsSync(),
            isTrue,
            reason: i.name,
          );
          continue;
        }
        expect(ids, contains(i.semilla), reason: i.name);
        expect(File('assets/casita/${i.semilla}.png').existsSync(), isTrue);
        expect(
          File('assets/casita/picando_${i.name}_naranja.png').existsSync(),
          isTrue,
          reason: i.name,
        );
      }
      for (final r in Receta.values) {
        expect(
          File('assets/casita/plato_${r.dibujo}.png').existsSync(),
          isTrue,
          reason: r.name,
        );
      }
    });

    test('el repartidor llega cada lunes con lo básico', () {
      // Del lunes 23 al domingo 29 de noviembre es la misma semana.
      expect(Repartidor.semana(DateTime(2026, 11, 23, 8)), '2026-11-23');
      expect(Repartidor.semana(DateTime(2026, 11, 26, 20)), '2026-11-23');
      expect(Repartidor.semana(DateTime(2026, 11, 29, 23)), '2026-11-23');
      expect(Repartidor.semana(DateTime(2026, 11, 30)), '2026-11-30');
      // Cruza de mes y de año.
      expect(Repartidor.semana(DateTime(2027, 1, 2)), '2026-12-28');

      final jueves = DateTime(2026, 11, 26, 10);
      // Sin cocina no viene (no hay dónde guardar).
      expect(EstadoCasita.vacio.repartidorEsperando(jueves), isFalse);
      final conCocina = EstadoCasita.fromMap({
        'tenemos': ['cuarto_cocina'],
      });
      expect(conCocina.repartidorEsperando(jueves), isTrue);
      final recibido = EstadoCasita.fromMap({
        'tenemos': ['cuarto_cocina'],
        'reparto': '2026-11-23',
      });
      expect(recibido.repartidorEsperando(jueves), isFalse);
      // El lunes siguiente vuelve.
      expect(recibido.repartidorEsperando(DateTime(2026, 11, 30, 9)), isTrue);

      for (final i in Ingrediente.basicos) {
        expect(i.semilla, isEmpty);
        expect(Ingrediente.deSemilla(''), isNull);
      }
    });

    test('cada receta tiene de verdad lo que dice su nombre', () {
      final nombres = Receta.values.map((r) => r.nombre).join(' ');
      // Sin recetas bolivianas (pedido de nayra) ni cuy sin cuy.
      for (final no in ['cuy', 'huminta', 'picana']) {
        expect(nombres, isNot(contains(no)));
      }
      expect(Receta.pavo.ingredientes, contains(Ingrediente.pavo));
      expect(Receta.sopaMiso.ingredientes, contains(Ingrediente.miso));
      expect(Receta.sopaPollo.ingredientes, contains(Ingrediente.pollo));
      expect(Receta.sushi.ingredientes, contains(Ingrediente.pescado));
      expect(Ingrediente.choclo.uno, 'elote (choclo)');
      final e = EstadoCasita.fromMap({
        'despensa': {'trigo': 1, 'queso': 1},
      });
      expect(e.faltan(Receta.pizzaCuatroQuesos), {Ingrediente.queso: 2});
    });

    test('la caja del repartidor cambia cada semana y trae lo que falta', () {
      final semanas = [
        for (var k = 0; k < 12; k++)
          Repartidor.semana(DateTime(2027, 1, 4 + 7 * k)),
      ];
      final cajas = [for (final s in semanas) Repartidor.cajaPara(s)];
      // La misma semana siempre trae lo mismo (en los dos celulares).
      expect(Repartidor.cajaPara(semanas.first), cajas.first);
      // Pero no todas las semanas traen lo mismo.
      expect(cajas.map((c) => c.toString()).toSet().length, greaterThan(3));
      for (final c in cajas) {
        // Sal, leche y huevos siempre; nunca viene casi vacía.
        expect(
          c.keys,
          containsAll([Ingrediente.sal, Ingrediente.leche, Ingrediente.huevo]),
        );
        expect(c.length, greaterThanOrEqualTo(Repartidor.minimoDeCosas));
        for (final e in c.entries) {
          expect(e.key.delRepartidor, isTrue);
          expect(e.value, inInclusiveRange(1, e.key.caja));
        }
        // El pavo solo en Acción de Gracias y Navidad.
        expect(c.containsKey(Ingrediente.pavo), isFalse);
      }
      expect(
        Repartidor.cajaPara('2026-11-23').containsKey(Ingrediente.pavo),
        isTrue,
      );
      expect(
        Repartidor.cajaPara('2026-12-21').containsKey(Ingrediente.pavo),
        isTrue,
      );
      // Lo que se les acabó viene sí o sí.
      final llenos = {for (final i in Ingrediente.basicos) i.name: 5};
      for (final s in semanas) {
        final caja = Repartidor.cajaPara(
          s,
          despensa: {...llenos, 'queso': 0, 'chocolate': 0},
        );
        expect(caja[Ingrediente.queso], greaterThanOrEqualTo(2));
        expect(caja[Ingrediente.chocolate], greaterThanOrEqualTo(2));
      }
    });

    test('rollos de canela y pizzas con lo del repartidor', () {
      final pizzas = Receta.values.where((r) => r.nombre.startsWith('pizza'));
      expect(pizzas.length, greaterThanOrEqualTo(8));
      final e = EstadoCasita.fromMap({
        'despensa': {'trigo': 3, 'canela': 3, 'mantequilla': 3, 'azucar': 3},
      });
      expect(e.puedeCocinar(Receta.rollosCanela), isTrue);
      expect(e.puedeCocinar(Receta.pizzaCuatroQuesos), isFalse);
      // Lo que pica el que ayuda siempre es algo del huerto.
      for (final r in Receta.values) {
        expect(r.principal.delRepartidor, isFalse, reason: r.name);
      }
    });

    test('el recetario de Navidad abre recetas en diciembre', () {
      final recetario = Catalogo.porId('recetario_navidad')!;
      expect(recetario.especial, Especial.recetario);
      // Se vende solo en Navidad y no sale en Especiales.
      expect(recetario.aLaVenta(DateTime(2026, 11, 26)), isFalse);
      expect(recetario.aLaVenta(DateTime(2026, 12, 10)), isTrue);
      expect(Catalogo.especiales, isNot(contains(recetario)));

      final diciembre = DateTime(2026, 12, 10);
      final navidenas = Receta.values.where(
        (r) => r.recetario == 'recetario_navidad',
      );
      expect(navidenas.length, greaterThanOrEqualTo(5));
      expect(navidenas, contains(Receta.galletasJengibre));
      final sin = EstadoCasita.fromMap({
        'tenemos': ['cuarto_cocina'],
      });
      final con = EstadoCasita.fromMap({
        'tenemos': ['cuarto_cocina', 'recetario_navidad'],
      });
      for (final r in navidenas) {
        expect(r.disponible(sin, diciembre), isFalse, reason: r.name);
        expect(r.disponible(con, diciembre), isTrue, reason: r.name);
        // Fuera de Navidad no se cocinan aunque tengan el recetario.
        expect(r.disponible(con, DateTime(2027, 3, 1)), isFalse);
      }
      // Las de siempre no piden recetario.
      expect(Receta.galletas.disponible(sin, DateTime(2027, 3, 1)), isTrue);
    });

    test('recetarios de las fiestas chinas, en su fecha lunar', () {
      final ids = Catalogo.recetarios.map((c) => c.id);
      expect(
        ids,
        containsAll([
          'recetario_navidad',
          'recetario_anio_nuevo_chino',
          'recetario_bote_dragon',
          'recetario_medio_otono',
        ]),
      );
      for (final c in Catalogo.recetarios) {
        final recetas = Catalogo.recetasDe(c);
        expect(recetas.length, greaterThanOrEqualTo(3), reason: c.id);
        for (final r in recetas) {
          // Se cocinan en la misma fiesta en que se vende el recetario.
          expect(r.fiestas, {c.fiesta}, reason: r.name);
        }
      }
      final chino = Catalogo.porId('recetario_anio_nuevo_chino')!;
      final dragon = Catalogo.porId('recetario_bote_dragon')!;
      final luna = Catalogo.porId('recetario_medio_otono')!;
      // 2027: Año Nuevo chino el 6 de febrero, Bote del Dragón el 9 de
      // junio y Medio Otoño el 15 de septiembre.
      expect(chino.aLaVenta(DateTime(2027, 2, 6)), isTrue);
      expect(chino.aLaVenta(DateTime(2027, 4, 1)), isFalse);
      expect(dragon.aLaVenta(DateTime(2027, 6, 9)), isTrue);
      expect(dragon.aLaVenta(DateTime(2027, 7, 20)), isFalse);
      expect(luna.aLaVenta(DateTime(2027, 9, 15)), isTrue);
      expect(luna.aLaVenta(DateTime(2027, 11, 1)), isFalse);
      final con = EstadoCasita.fromMap({
        'tenemos': ['cuarto_cocina', 'recetario_medio_otono'],
      });
      expect(
        Receta.pastelesLuna.disponible(con, DateTime(2027, 9, 15)),
        isTrue,
      );
      expect(Receta.zongziDulce.disponible(con, DateTime(2027, 6, 9)), isFalse);
    });

    test('los cuartos nuevos se abren comprándolos', () {
      const cerrado = EstadoCasita.vacio;
      expect(cerrado.abierto(Cuarto.sala), isTrue);
      expect(cerrado.abierto(Cuarto.cocina), isFalse);
      final e = EstadoCasita.fromMap({
        'tenemos': ['cuarto_cocina', 'refri_azul'],
        'puestos': {'refri': 'refri_azul'},
      });
      expect(e.abierto(Cuarto.cocina), isTrue);
      expect(e.capas(Cuarto.cocina), [
        'assets/casita/pared_cocina_azulejos.png',
        'assets/casita/piso_cocina_terracota.png',
        'assets/casita/cuarto_cocina.png',
        'assets/casita/refri_azul.png',
        'assets/casita/gatito_naranja.png',
        'assets/casita/gatito_blanco.png',
        'assets/casita/marco.png',
      ]);
      // El jardín tiene su propio marco de setos.
      expect(e.capas(Cuarto.jardin).last, 'assets/casita/marco_jardin.png');
      // Cada lugar es de un solo cuarto y cada cuarto tiene qué comprar.
      for (final c in Cuarto.values) {
        for (final l in c.lugares) {
          expect(
            Catalogo.de(l).length,
            greaterThanOrEqualTo(2),
            reason: l.name,
          );
        }
        if (c != Cuarto.sala) expect(Catalogo.abre(c)!.precio, c.precio);
      }
      const m = Movimiento(
        id: 'compra_cuarto_cocina',
        tipo: Movimiento.compra,
        uid: 'a',
        cantidad: -200,
        ref: 'cuarto_cocina',
      );
      expect(m.que, 'abrió la cocina');
    });
  });

  group('Pantalla', () {
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
      view.physicalSize = const Size(390, 2600);
      view.devicePixelRatio = 1;
    });
    tearDown(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    final me = AppUser(uid: 'a', name: 'nayra', pairCode: '');
    final partner = AppUser(uid: 'b', name: 'Xixi', pairCode: '');

    Widget pantalla(
      EstadoCasita estado, {
      List<(Cosa, String?)>? compras,
      List<(Lugar, Cosa?)>? puestos,
      Cuarto? cuarto,
      DateTime? hoy,
      List<Cosa?>? metas,
      List<(Cosa, String?, String)>? regalos,
      List<Cosa>? abiertos,
      List<Cosa>? propuestas,
      List<Propuesta>? aprobadas,
      List<int>? aportes,
      AppUser? yo,
    }) => MaterialApp(
      home: CasitaView(
        estado: estado,
        movimientos: const [
          Movimiento(
            id: 'pregunta_2026-11-23_b',
            tipo: Movimiento.pregunta,
            uid: 'b',
            cantidad: 10,
          ),
        ],
        me: yo ?? me,
        partner: yo == null ? partner : me,
        onComprar: (c, g) async => compras?.add((c, g)),
        onMeta: metas == null ? null : (c) async => metas.add(c),
        onAportar: aportes == null
            ? null
            : (n) async {
                aportes.add(n);
                return n;
              },
        onRegalar: regalos == null
            ? null
            : (c, g, m) async => regalos.add((c, g, m)),
        onAbrirRegalo: abiertos == null
            ? null
            : (c, _) async => abiertos.add(c),
        onProponer: propuestas == null
            ? null
            : (c, _) async => propuestas.add(c),
        onAprobar: aprobadas == null ? null : (p) async => aprobadas.add(p),
        onDescartar: () async {},
        onPoner: (l, c) async => puestos?.add((l, c)),
        onVestir: (_, _, _) async {},
        cuartoInicial: cuarto,
        hoy: hoy ?? DateTime(2026, 11, 23),
        inicioPareja: DateTime(2024, 3, 9),
      ),
    );

    testWidgets('comprar un sofá con los pescaditos de los dos', (t) async {
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 130), compras: compras),
      );
      expect(find.text('130'), findsOneWidget);
      await t.tap(find.text('Sofá azul'));
      await t.pumpAndSettle();
      expect(find.text('¿Comprar Sofá azul?'), findsOneWidget);
      expect(find.textContaining('Les quedarían 10'), findsOneWidget);
      await t.tap(find.text('Comprar'));
      await t.pumpAndSettle();
      expect(compras.single.$1.id, 'sofa_azul');
    });

    testWidgets('si no alcanza, avisa cuántos faltan', (t) async {
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 20), compras: compras),
      );
      await t.tap(find.text('Sofá rosa'));
      await t.pump();
      expect(find.textContaining('Les faltan 100 pescaditos'), findsOneWidget);
      expect(compras, isEmpty);
    });

    testWidgets('si no alcanza, pueden ahorrar para eso en la alcancía', (
      t,
    ) async {
      final metas = <Cosa?>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 20), metas: metas),
      );
      await t.tap(find.text('Sofá rosa'));
      await t.pumpAndSettle();
      await t.tap(textoDoodle('🐷 Ahorrar para esto'));
      await t.pumpAndSettle();
      expect(metas.single?.id, 'sofa_rosa');

      // Con la meta puesta, la alcancía muestra cuánto falta.
      await t.pumpWidget(
        pantalla(
          const EstadoCasita(pescaditos: 20, meta: 'sofa_rosa'),
          metas: metas,
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Ahorrando juntos para Sofá rosa'), findsOneWidget);
      expect(
        find.textContaining('Llevan 0 de 120: faltan 120'),
        findsOneWidget,
      );
      await t.tap(find.byTooltip('Dejar de ahorrar para esto'));
      await t.pumpAndSettle();
      expect(metas.last, isNull);
    });

    testWidgets('elegir algo para ahorrar juntos desde la tienda', (t) async {
      final metas = <Cosa?>[];
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(
          const EstadoCasita(pescaditos: 130),
          metas: metas,
          compras: compras,
          propuestas: [],
        ),
      );
      await t.tap(find.text('Sofá azul'));
      await t.pumpAndSettle();
      // "Yo lo compro" sigue siendo lo de siempre; ahorrar es opcional.
      expect(textoDoodle('🛒 Yo lo compro'), findsOneWidget);
      expect(textoDoodle('🤝 En pareja'), findsOneWidget);
      await t.tap(textoDoodle('🐷 Ahorrar juntos'));
      await t.pumpAndSettle();
      expect(find.textContaining('cuando esté llena'), findsOneWidget);
      await t.tap(find.text('Ahorrar juntos'));
      await t.pumpAndSettle();
      expect(metas.single?.id, 'sofa_azul');
      expect(compras, isEmpty);
    });

    testWidgets(
      'cada uno pone pescaditos y lo ahorrado no se gasta en otra cosa',
      (t) async {
        final aportes = <int>[];
        final compras = <(Cosa, String?)>[];
        await t.pumpWidget(
          pantalla(
            const EstadoCasita(
              pescaditos: 140,
              meta: 'sofa_rosa',
              ahorrado: 100,
              aportes: {'a': 60, 'b': 40},
            ),
            metas: [],
            aportes: aportes,
            compras: compras,
          ),
        );
        await t.pumpAndSettle();
        expect(
          find.textContaining('Llevan 100 de 120: faltan 20'),
          findsOneWidget,
        );
        expect(find.text('Pusieron: nayra 60 · Xixi 40'), findsOneWidget);
        // Solo hay 40 libres: el sofá azul (120) no alcanza aunque haya 140.
        await t.tap(find.text('Sofá azul'));
        await t.pumpAndSettle();
        expect(find.text('Les faltan 80 pescaditos'), findsOneWidget);
        await t.tap(find.text('Ahora no'));
        await t.pumpAndSettle();
        expect(compras, isEmpty);
        // Pone lo que falta.
        await t.ensureVisible(textoDoodle('🐟 Poner pescaditos'));
        await t.tap(textoDoodle('🐟 Poner pescaditos'));
        await t.pumpAndSettle();
        await t.tap(find.text('20 (¡la llena!)'));
        await t.pumpAndSettle();
        expect(aportes.single, 20);
      },
    );

    testWidgets('con la alcancía llena se le pide el sí a la pareja', (
      t,
    ) async {
      final propuestas = <Cosa>[];
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(
          const EstadoCasita(
            pescaditos: 130,
            meta: 'sofa_rosa',
            ahorrado: 120,
            aportes: {'a': 70, 'b': 50},
          ),
          metas: [],
          propuestas: propuestas,
          compras: compras,
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.text('¡La alcancía está llena para Sofá rosa!'),
        findsOneWidget,
      );
      await t.ensureVisible(find.text('Pedirle el sí'));
      await t.tap(find.text('Pedirle el sí'));
      await t.pumpAndSettle();
      expect(find.textContaining('Ya juntaron los 120'), findsOneWidget);
      await t.tap(find.text('Pedirle el sí').last);
      await t.pumpAndSettle();
      // No se compra de una: espera el sí de Xixi.
      expect(propuestas.single.id, 'sofa_rosa');
      expect(compras, isEmpty);
    });

    testWidgets('al comprar se elige: yo, en pareja o regalar', (t) async {
      final compras = <(Cosa, String?)>[];
      final regalos = <(Cosa, String?, String)>[];
      await t.pumpWidget(
        pantalla(
          const EstadoCasita(pescaditos: 130),
          compras: compras,
          regalos: regalos,
        ),
      );
      await t.tap(find.text('Sofá azul'));
      await t.pumpAndSettle();
      // Por defecto lo compras tú; en pareja o regalar es si quieres.
      expect(textoDoodle('🛒 Yo lo compro'), findsOneWidget);
      expect(textoDoodle('🎁 Regalar'), findsOneWidget);
      expect(
        find.text('Va directo a la casita, para los dos.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      await t.tap(find.text('Comprar'));
      await t.pumpAndSettle();
      expect(compras.single.$1.id, 'sofa_azul');
      expect(regalos, isEmpty);
    });

    testWidgets('regalar una prenda con un mensajito', (t) async {
      final regalos = <(Cosa, String?, String)>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 500), regalos: regalos),
      );
      await t.ensureVisible(find.text('Ropa'));
      await t.tap(find.text('Ropa'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Camiseta a rayas'));
      await t.tap(find.text('Camiseta a rayas'));
      await t.pumpAndSettle();
      await t.tap(textoDoodle('🎁 Regalar'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Para nuestra cita');
      await t.tap(find.text('Regalar'));
      await t.pumpAndSettle();
      final (cosa, gatito, mensaje) = regalos.single;
      expect(cosa.id, 'camiseta');
      // Se lo pone al gatito de la pareja.
      expect(gatito, 'blanco');
      expect(mensaje, 'Para nuestra cita');
    });

    testWidgets('quien recibe el regalo lo abre; quien lo dio lo ve envuelto', (
      t,
    ) async {
      const estado = EstadoCasita(
        tenemos: {'sofa_rosa'},
        regalos: {'sofa_rosa': Regalo(de: 'a', mensaje: 'Te quiero')},
      );
      final abiertos = <Cosa>[];
      // nayra (a) lo regaló: lo ve envuelto y no hay aviso para abrir.
      await t.pumpWidget(pantalla(estado, abiertos: abiertos));
      await t.pumpAndSettle();
      expect(textoDoodle('Envuelto 🎁'), findsOneWidget);
      expect(find.textContaining('te dejó un regalo sorpresa'), findsNothing);

      // Xixi (b) lo recibe.
      await t.pumpWidget(
        pantalla(
          estado,
          abiertos: abiertos,
          yo: AppUser(uid: 'b', name: 'Xixi', pairCode: ''),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('nayra te dejó un regalo sorpresa'), findsOneWidget);
      await t.tap(find.text('Abrir'));
      await t.pumpAndSettle();
      await t.tap(textoDoodle('Abrir 🎁'));
      await t.pumpAndSettle();
      expect(find.text('¡Sofá rosa!'), findsOneWidget);
      expect(find.textContaining('Te quiero'), findsOneWidget);
      await t.tap(find.text('¡Gracias! Ponerlo en la casita'));
      await t.pumpAndSettle();
      expect(abiertos.single.id, 'sofa_rosa');
    });

    testWidgets('cada uno compra solo; en pareja es opcional', (t) async {
      final propuestas = <Cosa>[];
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(
          const EstadoCasita(pescaditos: 300),
          propuestas: propuestas,
          compras: compras,
          aprobadas: [],
        ),
      );
      // Aunque sea grande, por defecto lo compras tú de una vez.
      await t.ensureVisible(find.text('Sofá'));
      await t.tap(find.text('Sofá'));
      await t.pumpAndSettle();
      await t.tap(find.text('Sofá azul'));
      await t.pumpAndSettle();
      expect(find.text('Comprar'), findsOneWidget);
      await t.tap(find.text('Comprar'));
      await t.pumpAndSettle();
      expect(compras.single.$1.id, 'sofa_azul');
      expect(propuestas, isEmpty);

      // Si quieres, le pides el sí a tu pareja.
      await t.ensureVisible(find.text('Planta'));
      await t.tap(find.text('Planta'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cactus'));
      await t.pumpAndSettle();
      await t.tap(textoDoodle('🤝 En pareja'));
      await t.pumpAndSettle();
      expect(find.textContaining('cuando te dé el sí'), findsOneWidget);
      await t.tap(find.text('Pedirle el sí'));
      await t.pumpAndSettle();
      expect(propuestas.single.id, 'planta_cactus');
      expect(compras, hasLength(1));
    });

    test('una propuesta ya comprada no sigue pidiendo el sí', () {
      const p = Propuesta(id: 'p1', cosa: 'cuarto_cocina', de: 'a');
      expect(const EstadoCasita(propuesta: p).pendiente, isNotNull);
      expect(
        const EstadoCasita(propuesta: p, tenemos: {'cuarto_cocina'}).pendiente,
        isNull,
      );
    });

    testWidgets('la pareja ve la propuesta y la aprueba', (t) async {
      const estado = EstadoCasita(
        pescaditos: 300,
        propuesta: Propuesta(id: 'p1', cosa: 'sofa_azul', de: 'a'),
      );
      final aprobadas = <Propuesta>[];
      // nayra la propuso: espera.
      await t.pumpWidget(pantalla(estado, aprobadas: aprobadas));
      await t.pumpAndSettle();
      expect(find.text('Esperando que Xixi apruebe Sofá azul'), findsOneWidget);
      expect(find.text('¡Sí, comprarlo!'), findsNothing);

      // Xixi la aprueba.
      await t.pumpWidget(
        pantalla(
          estado,
          aprobadas: aprobadas,
          yo: AppUser(uid: 'b', name: 'Xixi', pairCode: ''),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('nayra quiere comprar Sofá azul'), findsOneWidget);
      await t.tap(find.text('¡Sí, comprarlo!'));
      await t.pumpAndSettle();
      expect(aprobadas.single.cosa, 'sofa_azul');
    });

    testWidgets('usar un tema comprado cambia los colores', (t) async {
      addTearDown(() => AppTheme.tema.value = TemaApp.clasico);
      await t.pumpWidget(
        pantalla(const EstadoCasita(tenemos: {'tema_lavanda'})),
      );
      await t.ensureVisible(textoDoodle('✨ Especiales'));
      await t.tap(textoDoodle('✨ Especiales'));
      await t.pumpAndSettle();
      expect(find.text('Stickers de gatitos'), findsOneWidget);
      await t.tap(find.text('Tema lavanda'));
      await t.pumpAndSettle();
      expect(AppTheme.tema.value.clave, 'lavanda');
      expect(textoDoodle('En uso ✓'), findsOneWidget);
      // Tocarlo otra vez vuelve al clásico.
      await t.tap(find.text('Tema lavanda'));
      await t.pumpAndSettle();
      expect(AppTheme.tema.value, TemaApp.clasico);
    });

    testWidgets('lo que ya tienen se pone o se quita', (t) async {
      final puestos = <(Lugar, Cosa?)>[];
      await t.pumpWidget(
        pantalla(
          const EstadoCasita(
            tenemos: {'sofa_azul', 'sofa_rosa'},
            puestos: {'sofa': 'sofa_azul'},
          ),
          puestos: puestos,
        ),
      );
      expect(textoDoodle('Puesto ✓'), findsOneWidget);
      await t.tap(find.text('Sofá rosa'));
      await t.pump();
      await t.tap(find.text('Sofá azul'));
      await t.pump();
      expect(puestos.map((p) => (p.$1, p.$2?.id)), [
        (Lugar.sofa, 'sofa_rosa'),
        (Lugar.sofa, null),
      ]);
    });

    testWidgets('abrir la cocina con pescaditos', (t) async {
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 250), compras: compras),
      );
      await t.tap(find.text('Cocina').first);
      await t.pumpAndSettle();
      expect(find.text('Abrir cocina · '), findsOneWidget);
      // Sus muebles no se compran hasta abrirla.
      await t.tap(find.text('Estufa retro'));
      await t.pump();
      expect(find.textContaining('Primero abran cocina'), findsOneWidget);
      await t.tap(find.text('Abrir cocina · '));
      await t.pumpAndSettle();
      expect(find.text('¿Comprar Cocina?'), findsOneWidget);
      await t.tap(find.text('Comprar'));
      await t.pumpAndSettle();
      expect(compras.single.$1.id, 'cuarto_cocina');
    });

    testWidgets('al repartidor se le paga la caja con pescaditos', (t) async {
      var recibidas = 0;
      Widget vista(String? reparto, int pescaditos) => MaterialApp(
        home: CasitaView(
          estado: EstadoCasita(
            pescaditos: pescaditos,
            tenemos: const {'cuarto_cocina'},
            reparto: reparto,
          ),
          movimientos: const [],
          me: me,
          partner: null,
          onComprar: (c, g) async {},
          onPoner: (l, c) async {},
          onVestir: (g, p, c) async {},
          onRecibirReparto: () async {
            recibidas++;
            return true;
          },
          hoy: DateTime(2026, 11, 26, 10),
        ),
      );
      final pagar = textoDoodle('Pagar 60 🐟 y recibir la caja');
      // Sin pescaditos suficientes no se puede: hay que jugar primero.
      await t.pumpWidget(vista(null, 45));
      expect(find.text('¡Toc, toc! Llegó el repartidor'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is TextoDoodle && w.texto.startsWith('Les faltan 15 🐟'),
        ),
        findsOneWidget,
      );
      await t.tap(pagar);
      await t.pump();
      expect(recibidas, 0);
      // Con 60 o más, se paga y se recibe.
      await t.pumpWidget(vista(null, 80));
      await t.tap(pagar);
      await t.pump();
      expect(recibidas, 1);
      expect(
        find.textContaining('Guardaron la caja', findRichText: true),
        findsOneWidget,
      );
      // Ya la recibieron esta semana: no vuelve hasta el lunes.
      await t.pumpWidget(vista('2026-11-23', 20));
      await t.pumpAndSettle();
      expect(find.text('¡Toc, toc! Llegó el repartidor'), findsNothing);
    });

    testWidgets('el lugar para cocinar: despensa y menú de recetas', (t) async {
      final cocinadas = <Receta>[];
      await t.pumpWidget(
        MaterialApp(
          home: CasitaView(
            estado: EstadoCasita.fromMap({
              'tenemos': ['cuarto_cocina'],
              'reparto': '2026-11-23',
              'despensa': {'tomate': 2, 'sal': 1, 'trigo': 1},
            }),
            movimientos: const [],
            me: me,
            partner: null,
            onComprar: (c, g) async {},
            onPoner: (l, c) async {},
            onVestir: (g, p, c) async {},
            onCocinar: (r) async {
              cocinadas.add(r);
              return true;
            },
            cuartoInicial: Cuarto.cocina,
            hoy: DateTime(2026, 11, 26, 10),
          ),
        ),
      );
      expect(find.text('Les alcanza para 1 receta'), findsOneWidget);
      await t.ensureVisible(find.text('Ir a cocinar'));
      await t.tap(find.text('Ir a cocinar'));
      await t.pumpAndSettle();
      expect(find.text('Despensa'), findsOneWidget);
      expect(find.text('Pueden cocinar ahora'), findsOneWidget);
      expect(find.text('Sopa de tomate'), findsOneWidget);
      await t.tap(find.text('Cocinar'));
      await t.pump();
      expect(cocinadas, [Receta.sopaTomate]);
      // El menú ☰ muestra todas, con lo que les falta.
      await t.tap(find.text('Menú'));
      await t.pumpAndSettle();
      expect(find.text('Almuerzo y cena'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is TextoDoodle && w.texto.startsWith('Les falta:'),
        ),
        findsWidgets,
      );
    });

    testWidgets('adoptar un bebé y ponerle nombre', (t) async {
      final compras = <(Cosa, String?)>[];
      final nombres = <String>[];
      await t.pumpWidget(
        MaterialApp(
          home: CasitaView(
            estado: const EstadoCasita(pescaditos: 150),
            movimientos: const [],
            me: me,
            partner: null,
            onComprar: (c, g) async => compras.add((c, g)),
            onPoner: (l, c) async {},
            onVestir: (g, p, c) async {},
            onNombrar: (b, n) async => nombres.add('${b.colorBebe}:$n'),
            categoriaInicial: '_bebes',
          ),
        ),
      );
      expect(find.text('Bebé calicó'), findsOneWidget);
      await t.ensureVisible(find.text('Bebé calicó'));
      await t.tap(find.text('Bebé calicó'));
      await t.pumpAndSettle();
      expect(find.text('¿Adoptar al bebé calicó?'), findsOneWidget);
      await t.tap(find.text('Adoptar'));
      await t.pumpAndSettle();
      expect(compras.single.$1.id, 'bebe_calico');
      expect(textoDoodle('¡Bienvenido a casa! 🐾'), findsOneWidget);
      await t.enterText(find.byType(TextFormField), 'Mochi');
      await t.tap(find.text('Listo'));
      await t.pumpAndSettle();
      expect(nombres, ['calico:Mochi']);
    });

    testWidgets('en la casa en corte, tocar un cuarto lo abre', (t) async {
      final tocados = <Cuarto>[];
      await t.pumpWidget(
        MaterialApp(
          home: CasaView(
            estado: const EstadoCasita(tenemos: {'cuarto_cocina'}),
            onCuarto: tocados.add,
            ahora: DateTime(2026, 11, 23, 23),
          ),
        ),
      );
      expect(find.text('Los gatitos están en la sala'), findsOneWidget);
      // Los cuartos cerrados tienen candado.
      expect(find.byIcon(Icons.lock_rounded), findsNWidgets(5));
      final casa = t.getRect(find.byType(CasaEnCorte));
      final s = casa.width / CasaEnCorte.ancho;
      await t.tapAt(casa.topLeft + Offset(280 * s, 280 * s));
      await t.tapAt(casa.topLeft + Offset(200 * s, 280 * s));
      expect(tocados, [Cuarto.cocina, Cuarto.sala]);
    });

    testWidgets('bañar a los gatitos en la tina', (t) async {
      await t.pumpWidget(
        pantalla(
          const EstadoCasita(
            tenemos: {'cuarto_bano', 'tina_rosa'},
            puestos: {'tina': 'tina_rosa'},
          ),
          cuarto: Cuarto.bano,
        ),
      );
      await t.tap(find.text('Bañar a los gatitos'));
      await t.pump();
      expect(find.text('¡Qué rico bañito!'), findsOneWidget);
      await t.pump(const Duration(seconds: 6));
      expect(find.text('Bañar a los gatitos'), findsOneWidget);
    });

    testWidgets('darles de comer algo que compraron', (t) async {
      await t.pumpWidget(
        pantalla(
          const EstadoCasita(tenemos: {'cuarto_cocina', 'comida_donas'}),
        ),
      );
      await t.tap(find.text('Darles de comer'));
      await t.pumpAndSettle();
      await t.tap(find.text('Donas'));
      await t.pumpAndSettle();
      expect(find.text('¡Ñam! Les encantó'), findsOneWidget);
      await t.pump(const Duration(seconds: 7));
      expect(find.text('Darles de comer'), findsOneWidget);
    });

    testWidgets('los movimientos dicen quién hizo qué', (t) async {
      await t.pumpWidget(pantalla(EstadoCasita.vacio));
      await t.scrollUntilVisible(
        find.text('Xixi respondió la pregunta del día'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Xixi respondió la pregunta del día'), findsOneWidget);
      expect(find.text('Próximas festividades'), findsOneWidget);
    });

    testWidgets('en diciembre se venden cosas de Navidad', (t) async {
      final compras = <(Cosa, String?)>[];
      // En noviembre no aparece el arbolito.
      await t.pumpWidget(pantalla(const EstadoCasita(pescaditos: 300)));
      expect(find.textContaining('De temporada'), findsNothing);
      await t.pumpWidget(
        pantalla(
          const EstadoCasita(pescaditos: 300),
          compras: compras,
          hoy: DateTime(2026, 12, 10),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.textContaining(
          'Navidad: cosas especiales hasta el 26 de diciembre',
        ),
        findsOneWidget,
      );
      await t.tap(textoDoodle('🎄 De temporada'));
      await t.pumpAndSettle();
      await t.tap(find.text('Arbolito de Navidad'));
      await t.pumpAndSettle();
      await t.tap(find.text('Comprar'));
      await t.pumpAndSettle();
      expect(compras.single.$1.id, 'temporada_arbolito');
    });

    testWidgets('la ropita se compra para un gatito', (t) async {
      final compras = <(Cosa, String?)>[];
      await t.pumpWidget(
        pantalla(const EstadoCasita(pescaditos: 200), compras: compras),
      );
      await t.ensureVisible(find.text('Accesorios'));
      await t.pumpAndSettle();
      await t.tap(find.text('Accesorios'));
      await t.pumpAndSettle();
      await t.tap(find.text('Corbatín'));
      await t.pumpAndSettle();
      await t.tap(find.text('el gatito de Xixi'));
      await t.pump();
      await t.tap(find.text('Comprar'));
      await t.pumpAndSettle();
      expect(compras.single.$1.id, 'mono');
      expect(compras.single.$2, 'blanco');
    });
  });
}

/// Busca un texto que tiene emojis (en pantalla salen como doodles).
Finder textoDoodle(String texto, {bool skipOffstage = true}) =>
    find.byWidgetPredicate(
      (w) => w is TextoDoodle && w.texto == texto,
      skipOffstage: skipOffstage,
    );
