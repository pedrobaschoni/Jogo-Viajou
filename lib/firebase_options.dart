// ESTE ARQUIVO É SÓ UM ESPAÇO RESERVADO.
//
// Rode `flutterfire configure` (veja o README) e ele será substituído pelo arquivo
// verdadeiro, com as chaves do SEU projeto Firebase.
//
// Enquanto isso, o jogo abre normalmente e o modo "celular único" funciona.
// Só as salas online ficam desativadas.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Firebase ainda não configurado. Rode `flutterfire configure`.',
      );
}
