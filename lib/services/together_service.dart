import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bucket_item.dart';
import '../models/recomendacion.dart' show Resena;
import '../models/daily_card.dart';
import '../models/mimo.dart';
import 'db.dart';
import 'notify_service.dart';
import 'preguntas_propias_service.dart';
import 'pescaditos_service.dart';
import 'racha_service.dart';

export '../models/daily_card.dart';

/// Pregunta del día, lista de cosas por hacer juntos y "te extraño".
class TogetherService {
  TogetherService._();
  static final instance = TogetherService._();

  // ---- Pregunta del día ----
  /// Cada pregunta es un naipe del mazo. El dibujo de la criatura sale de
  /// `CartaStyle.criaturaDe(numero)`.
  static const questions = [
    '¿Qué es lo que más te gustó de hoy?',
    '¿Cuál es tu recuerdo favorito de nosotros?',
    '¿A dónde te gustaría viajar juntos?',
    '¿Qué canción te recuerda a mí?',
    '¿Qué pequeño detalle mío te hace sonreír?',
    '¿Qué te gustaría que hagamos este fin de semana?',
    '¿Qué es algo nuevo que quieras aprender conmigo?',
    '¿Qué gesto mío te hace sentir más amor?',
    '¿Qué comida te gustaría que cocinemos juntos?',
    '¿Qué sueño tienes para nosotros en 5 años?',
    '¿Qué pensaste la primera vez que me viste?',
    '¿Qué animal crees que sería yo y por qué?',
    '¿Cuál sería nuestra cita perfecta un día de lluvia?',
    '¿Qué película te gustaría ver conmigo otra vez?',
    '¿Qué cosa mía extrañas cuando no estamos juntos?',
    '¿Qué te hizo reír mucho esta semana?',
    '¿Qué te gustaría que te diga más seguido?',
    '¿Qué lugar de tu infancia te gustaría mostrarme?',
    '¿Cómo te imaginas una mañana perfecta juntos?',
    '¿Qué te da tranquilidad cuando tienes un mal día?',
    '¿Qué regalo pequeño te haría feliz hoy?',
    '¿Qué aventura loca te animarías a hacer conmigo?',
    '¿Qué es algo de ti que todavía no sé?',
    '¿Qué palabra nos describe como pareja?',
    '¿Qué es lo primero que pensaste de mí cuando hablamos por primera vez?',
    '¿Qué costumbre mía te parece más tierna?',
    '¿Qué canción pondrías en la banda sonora de nuestra historia?',
    '¿En qué momento supiste que te gustaba de verdad?',
    '¿Qué te gustaría que hagamos juntos antes de fin de año?',
    '¿Cuál ha sido el día más divertido que pasamos juntos?',
    '¿Qué superpoder te gustaría tener para usarlo conmigo?',
    '¿Qué plato mío (o que quieres que cocine) es tu favorito?',
    '¿Qué cosa pequeña puedo hacer mañana para alegrarte el día?',
    '¿Qué recuerdo de nuestra primera cita te hace sonreír?',
    '¿Qué foto nuestra es tu favorita y por qué?',
    '¿Qué te gustaría que celebremos aunque sea algo pequeño?',
    '¿Cómo sería nuestra casa ideal?',
    '¿Qué mascota te gustaría que tengamos algún día?',
    '¿Qué libro, serie o anime te gustaría que veamos juntos?',
    '¿Qué cosa te pone nervioso o nerviosa y cómo puedo ayudarte?',
    '¿Qué palabra o apodo mío te gusta más?',
    '¿Qué te gustaría que recordemos de este mes?',
    '¿Qué es lo más valiente que has hecho?',
    '¿Qué te enseñé sin darme cuenta?',
    '¿Qué aprendiste de ti desde que estamos juntos?',
    '¿Qué te gustaría que hagamos un domingo sin planes?',
    '¿Cuál es tu antojo secreto?',
    '¿Qué lugar de la ciudad quieres que conozcamos juntos?',
    '¿Qué harías si tuviéramos un día entero sin celular?',
    '¿Qué te hace sentir orgullo de nosotros?',
    '¿Qué meta tuya quieres que celebre contigo?',
    '¿Qué te gustaría escuchar de mí cuando estás triste?',
    '¿Qué juego te gustaría que juguemos juntos?',
    '¿Qué te parece lo más bonito de nuestra relación?',
    '¿A qué época de la historia te gustaría viajar conmigo?',
    '¿Qué recuerdo de tu niñez te hace reír?',
    '¿Qué olor o sabor te recuerda a mí?',
    '¿Qué cosa nueva te gustaría probar este mes?',
    '¿Qué detalle de nuestra rutina no cambiarías por nada?',
    '¿Qué sueño loco tienes que casi nunca cuentas?',
    '¿Qué te gustaría que hagamos en nuestro próximo aniversario?',
    '¿Qué te hace sentir en casa?',
    '¿Qué personaje de película seríamos como pareja?',
    '¿Qué te gustaría que hagamos para descansar después de una semana dura?',
    '¿Qué cumplido mío recuerdas todavía?',
    '¿Qué te gustaría regalarme si el dinero no importara?',
    '¿Qué hábito te gustaría que empecemos juntos?',
    '¿Qué te dio más risa de mí al principio?',
    '¿Qué te hace sentir que te cuido?',
    '¿Qué estación del año te gusta más para estar conmigo?',
    '¿Qué palabra usarías para describir este día?',
    '¿Qué es algo que te dé miedo intentar, pero te animarías conmigo?',
    '¿Qué mensaje mío guardarías para siempre?',
    '¿Qué cosa te gustaría que te pregunte más seguido?',
    '¿Cómo te imaginas una noche perfecta en casa juntos?',
    '¿Qué te gustaría que hagamos para ayudar a alguien juntos?',
    '¿Qué parte de tu día te gustaría que compartamos más?',
    '¿Qué te gustaría que te diga hoy antes de dormir?',
    '¿Qué cosa de mí te sorprendió para bien?',
    '¿Qué viaje corto podríamos hacer pronto?',
    '¿Qué fue lo mejor de esta semana para ti?',
    '¿Qué te gustaría que hagamos para conocernos todavía más?',
    '¿Qué te gustaría que dibujemos o creemos juntos?',
    '¿Qué es lo que más extrañas de cuando éramos nuevos?',
    '¿Qué tradición te gustaría que inventemos como pareja?',
    '¿Qué te pone de buen humor al instante?',
    '¿Qué crees que yo diría que es mi mayor sueño?',
    '¿Qué te gustaría agradecerme hoy?',
    '¿Qué cosa sencilla te hace sentir mucho amor?',
    '¿Qué te gustaría que hagamos la próxima vez que llueva?',
    '¿Qué lugar de la naturaleza te gustaría visitar conmigo?',
    '¿Qué te hace sentir en calma cuando estamos juntos?',
    '¿Qué emoji nos describe como pareja?',
    '¿Qué meta podríamos lograr juntos este año?',
    '¿Qué me dirías si nos viéramos por primera vez hoy?',
    '¿Qué es lo más dulce que alguien ha hecho por ti?',
    '¿Qué te gustaría que recordemos cuando seamos viejitos?',
    '¿Cuál sería el nombre de nuestra banda si tuviéramos una?',
    '¿Qué te gustaría que hagamos para celebrar un logro tuyo?',
    '¿Qué pregunta te gustaría que te hiciera ahora mismo?',
  ];

  static String todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Pregunta fija por fecha. Solo se usa si un día viejo no guardó carta.
  static String questionFor(DateTime day) => questions[cardForDay(day)];

  static int cardForDay(DateTime day) {
    final dayNumber =
        DateTime(day.year, day.month, day.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return dayNumber % questions.length;
  }

  /// La carta del día de la pareja: qué naipe salió y las respuestas.
  Stream<DailyCard> watchToday(String coupleId) =>
      Db.coupleSub(coupleId, 'dailyAnswers')
          .doc(todayKey())
          .snapshots()
          .map((d) => DailyCard.fromData(d.data(), deck: questions));

  /// Días anteriores de la pregunta del día, entre [desde] y [hasta]
  /// (incluidos), del más nuevo al más viejo. Se pide por rango de fechas
  /// (los ids son `yyyy-MM-dd`), así se lee poquito cada vez.
  Future<List<DiaRespondido>> historial(
    String coupleId, {
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final q = await Db.coupleSub(coupleId, 'dailyAnswers')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: todayKey(desde))
        .where(FieldPath.documentId, isLessThanOrEqualTo: todayKey(hasta))
        .get();
    final dias = [
      for (final d in q.docs)
        DiaRespondido(d.id, DailyCard.fromData(d.data(), deck: questions)),
    ]..sort((a, b) => b.dia.compareTo(a.dia));
    return dias;
  }

  /// El primer día en que sacaron una carta (para saber hasta dónde hay
  /// historial). `null` si nunca jugaron.
  Future<String?> primerDia(String coupleId) async {
    final q = await Db.coupleSub(
      coupleId,
      'dailyAnswers',
    ).orderBy(FieldPath.documentId).limit(1).get();
    return q.docs.isEmpty ? null : q.docs.first.id;
  }

  /// Saca un naipe al azar para hoy. Si tu pareja ya lo sacó, devuelve
  /// ese mismo, así los dos responden la misma pregunta.
  ///
  /// Las preguntas no se repiten: las que ya salieron se guardan en
  /// `couples/{id}.mazoUsado`, y solo cuando salieron todas se vuelve a
  /// barajar el mazo completo.
  Future<int> drawToday(String coupleId, String uid, {Random? random}) async {
    final ref = Db.coupleSub(coupleId, 'dailyAnswers').doc(todayKey());
    final coupleRef = Db.couple(coupleId);

    // Parejas que sacaban cartas antes de que se guardara el mazo: se
    // arma desde los días anteriores, una sola vez.
    List<int>? historial;
    final couple = await coupleRef.get();
    if (couple.data()?['mazoUsado'] == null) {
      final dias = await Db.coupleSub(coupleId, 'dailyAnswers').get();
      final ordenados = [...dias.docs]..sort((a, b) => a.id.compareTo(b.id));
      historial = mazoDesdeHistorial([
        for (final d in ordenados)
          if (d.id != todayKey())
            ?DailyCard.fromData(d.data(), deck: questions).card,
      ], questions.length);
    }

    // Las preguntas que escribieron ustedes salen antes que las del mazo.
    final propias = PreguntasPropiasService.instance;
    final propia = PreguntaPropia.siguiente(await propias.todas(coupleId));

    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final existing = DailyCard.fromData(snap.data(), deck: questions).card;
      if (existing != null) return existing;
      if (propia != null) {
        final pRef = propias.ref(coupleId, propia.id);
        final p = await tx.get(pRef);
        if (p.exists && p.data()?['usadaEn'] == null) {
          final card = PreguntaPropia.naipe(propia.id, questions.length);
          tx.update(pRef, {'usadaEn': todayKey()});
          tx.set(ref, {
            'carta': card,
            'question': p.data()?['texto'] ?? propia.texto,
            'autor': propia.autor,
            'propia': propia.id,
            'drawnBy': uid,
            if (!snap.exists) 'answers': <String, String>{},
          }, SetOptions(merge: true));
          return card;
        }
      }
      final c = await tx.get(coupleRef);
      final guardadas = (c.data()?['mazoUsado'] as List?)
          ?.map((e) => (e as num).toInt())
          .toList();
      final (card, usadas) = siguienteCarta(
        guardadas ?? historial ?? const [],
        questions.length,
        random ?? Random(),
      );
      tx.update(coupleRef, {'mazoUsado': usadas});
      tx.set(ref, {
        'carta': card,
        'question': questions[card],
        'drawnBy': uid,
        // Las reglas revisan `answers`; en un día nuevo va vacío.
        if (!snap.exists) 'answers': <String, String>{},
      }, SetOptions(merge: true));
      return card;
    });
  }

  /// Elige un naipe que todavía no salió. Devuelve el naipe y la lista de
  /// usados ya con él. Si ya salieron todos, se empieza un mazo nuevo.
  static (int, List<int>) siguienteCarta(
    List<int> usadas,
    int total,
    Random random,
  ) {
    final ya = {
      for (final u in usadas)
        if (u >= 0 && u < total) u,
    };
    var libres = [
      for (var i = 0; i < total; i++)
        if (!ya.contains(i)) i,
    ];
    if (libres.isEmpty) {
      ya.clear();
      libres = List.generate(total, (i) => i);
    }
    final card = libres[random.nextInt(libres.length)];
    return (card, [...ya, card]);
  }

  /// Los naipes del mazo actual, a partir de las cartas que salieron en
  /// orden (cada vez que se completa el mazo, se empieza otro).
  static List<int> mazoDesdeHistorial(List<int> cartasEnOrden, int total) {
    final mazo = <int>{};
    for (final c in cartasEnOrden) {
      if (c < 0 || c >= total) continue;
      if (mazo.length >= total) mazo.clear();
      mazo.add(c);
    }
    if (mazo.length >= total) mazo.clear();
    return [...mazo];
  }

  Future<void> answerToday(String coupleId, String uid, String answer) async {
    final hoy = todayKey();
    await Db.coupleSub(coupleId, 'dailyAnswers').doc(hoy).set({
      'answers': {uid: answer},
    }, SetOptions(merge: true));
    await RachaService.instance.marcarHoy(coupleId, uid);
    unawaited(
      PescaditosService.instance.intentar(
        () => PescaditosService.instance.ganarPregunta(coupleId, uid, hoy),
      ),
    );
  }

  // ---- Cosas por hacer juntos ----
  Stream<List<BucketItem>> watchBucket(String coupleId) =>
      Db.coupleSub(coupleId, 'bucketList')
          .orderBy('createdAt')
          .snapshots()
          .map((q) => q.docs.map(BucketItem.fromDoc).toList());

  Future<void> addBucket(
    String coupleId,
    String uid,
    String title,
    String category,
  ) => Db.coupleSub(coupleId, 'bucketList').add({
    'title': title,
    'category': category,
    'done': false,
    'createdBy': uid,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> toggleBucket(String coupleId, BucketItem item) => Db.coupleSub(
    coupleId,
    'bucketList',
  ).doc(item.id).update({'done': !item.done});

  Stream<BucketItem?> watchBucketItem(String coupleId, String id) =>
      Db.coupleSub(
        coupleId,
        'bucketList',
      ).doc(id).snapshots().map((d) => d.exists ? BucketItem.fromDoc(d) : null);

  /// Guarda (o quita, con `null`) mi reseña de algo que hicimos juntos.
  Future<void> resenarBucket(
    String coupleId,
    String id,
    String uid,
    Resena? resena,
  ) => Db.coupleSub(coupleId, 'bucketList').doc(id).update({
    'resenas.$uid': resena == null ? FieldValue.delete() : resena.toMap(),
  });

  Future<void> deleteBucket(String coupleId, String id) =>
      Db.coupleSub(coupleId, 'bucketList').doc(id).delete();

  // ---- Te extraño ----
  /// Crea un documento y le pide al Worker que avise a la pareja.
  Future<void> sendMissYou(
    String coupleId, {
    required String from,
    required String to,
  }) async {
    final ref = await Db.coupleSub(
      coupleId,
      'missYou',
    ).add({'from': from, 'to': to, 'createdAt': FieldValue.serverTimestamp()});
    NotifyService.instance.send(NotifyKind.missYou, coupleId, ref.id);
  }

  /// Abrazo para la pareja. Se guarda en `couples/{id}/abrazos` y el
  /// Worker le manda la notificación. [mood] es su ánimo cuando se manda
  /// desde la tarjeta de "está triste"; desde el botón del inicio va vacío.
  Future<void> sendHug(
    String coupleId, {
    required String from,
    required String to,
    String? mood,
  }) async {
    final ref = await Db.coupleSub(coupleId, 'abrazos').add({
      'from': from,
      'to': to,
      'mood': ?mood,
      'createdAt': FieldValue.serverTimestamp(),
    });
    NotifyService.instance.send(NotifyKind.hug, coupleId, ref.id);
  }

  /// Beso para la pareja, en `couples/{id}/besos`.
  Future<void> sendKiss(
    String coupleId, {
    required String from,
    required String to,
  }) async {
    final ref = await Db.coupleSub(
      coupleId,
      'besos',
    ).add({'from': from, 'to': to, 'createdAt': FieldValue.serverTimestamp()});
    NotifyService.instance.send(NotifyKind.kiss, coupleId, ref.id);
  }

  /// Cascabel para la pareja, en `couples/{id}/cascabeles`: un tilín para
  /// llamar su atención.
  Future<void> sendBell(
    String coupleId, {
    required String from,
    required String to,
  }) async {
    final ref = await Db.coupleSub(
      coupleId,
      'cascabeles',
    ).add({'from': from, 'to': to, 'createdAt': FieldValue.serverTimestamp()});
    NotifyService.instance.send(NotifyKind.bell, coupleId, ref.id);
  }

  /// Los últimos besos, abrazos o cascabeles de la pareja (de los dos), para mostrar la
  /// animación al que los recibe. Solo 5, para leer poquito.
  Stream<List<MimoRecibido>> watchMimos(String coupleId, Mimo mimo) =>
      Db.coupleSub(coupleId, mimo.coleccion)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots()
          .map((q) => [for (final d in q.docs) MimoRecibido.fromDoc(mimo, d)]);

  /// Cuántos "te extraño" mandó [from] en esta pareja.
  ///
  /// Usa una consulta de conteo: Firestore cobra 1 lectura por cada 1000
  /// documentos contados, así que cabe de sobra en el plan Spark.
  Future<int> countMissYou(String coupleId, String from) async {
    final snap = await Db.coupleSub(
      coupleId,
      'missYou',
    ).where('from', isEqualTo: from).count().get();
    return snap.count ?? 0;
  }
}
