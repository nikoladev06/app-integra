// controller/addevento_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventoController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<bool> criarEvento(
    String titulo,
    String descricao,
    DateTime data,
    String localizacao,
    String? imagemUrl,
  ) async {
    try {
      print('🔄 Criando evento...');
      User? user = _firebaseAuth.currentUser;

      if (user == null) {
        throw 'Usuário não autenticado';
      }

      // Validações
      if (titulo.isEmpty) {
        throw 'Título é obrigatório';
      }

      if (descricao.isEmpty) {
        throw 'Descrição é obrigatória';
      }

      if (localizacao.isEmpty) {
        throw 'Localização é obrigatória';
      }

      if (data.isBefore(DateTime.now())) {
        throw 'A data do evento não pode ser no passado';
      }

      // Obter dados do usuário
      DocumentSnapshot userDoc =
          await _firebaseFirestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        throw 'Perfil do usuário não encontrado';
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Gerar ID único para o evento
      int eventoId = DateTime.now().millisecondsSinceEpoch;

      // Criar documento do evento
      await _firebaseFirestore.collection('eventos').add({
        'id': eventoId,
        'userId': user.uid,
        'title': titulo,
        'description': descricao,
        'date': Timestamp.fromDate(data),
        'location': localizacao,
        'imageUrl': imagemUrl ?? '',
        'nomeCompleto': userData['nomeCompleto'] ?? '',
        'username': userData['username'] ?? '',
        'createdAt': Timestamp.now(),
        'isLiked': false,
        'likesCount': 0,
        'comentarios': [],
      });

      print('✅ Evento criado com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao criar evento: $e');
      rethrow;
    }
  }
}