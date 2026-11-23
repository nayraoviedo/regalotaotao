import 'package:cloud_firestore/cloud_firestore.dart';

/// Rutas de Firestore en un solo lugar.
///
/// users/{uid}                       perfil (nombre, código, coupleId, tokens)
/// users/{uid}/privateNotes/{id}     notas privadas
/// users/{uid}/pomodoroTasks/{id}    tareas propias del pomodoro
/// pairCodes/{code}                  código -> uid (para vincularse)
/// couples/{coupleId}                espacio de pareja (members, startDate)
///   moods/{uid}                     ánimo actual de cada uno
///   notes/{id}                      notas compartidas
///   letters/{id}                    cartas "Ábrelo cuando…"
///   pomodoros/{id}                  invitaciones de pomodoro
///   rewards/{id}                    lista de premios (la editan los dos)
///   achievements/{id}               pomodoros/tareas cumplidas y premio elegido
///   dailyAnswers/{yyyy-MM-dd}       respuestas a la pregunta del día
///   preguntas/{id}                  preguntas que escribieron para el mazo
///   datosCuriosos/{id}              datos curiosos de cada uno sobre sí
///   racha/{yyyy-MM-dd}              quién hizo su parte ese día (racha)
///   bucketList/{id}                 cosas por hacer juntos
///   missYou/{id}                    "te extraño" (el Worker envía el aviso)
///   abrazos/{id}                    abrazos cuando su ánimo no anda bien (también)
///   recomendaciones/{día}_{uid}     recomendación del día para la pareja
///   musica/sala                     música juntos (lo que suena, cola, 3-2-1)
class Db {
  static final _fs = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get users =>
      _fs.collection('users');
  static DocumentReference<Map<String, dynamic>> user(String uid) =>
      users.doc(uid);
  static CollectionReference<Map<String, dynamic>> privateNotes(String uid) =>
      user(uid).collection('privateNotes');

  static CollectionReference<Map<String, dynamic>> get pairCodes =>
      _fs.collection('pairCodes');

  static CollectionReference<Map<String, dynamic>> get couples =>
      _fs.collection('couples');
  static DocumentReference<Map<String, dynamic>> couple(String id) =>
      couples.doc(id);
  static CollectionReference<Map<String, dynamic>> coupleSub(
    String coupleId,
    String name,
  ) => couple(coupleId).collection(name);

  static FirebaseFirestore get instance => _fs;
}
