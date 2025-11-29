// controller/addevento_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProfessionalPostController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<bool> criarPostProfissional(
    String titulo, 
    String descricao,
    String tipo, // vaga, oportunidade, estágio, etc
    String empresa,
  ) async {
    try {
      print('🔄 Criando post profissional...');
      User? user = _firebaseAuth.currentUser;

      if (user == null) {
        throw 'Usuário não autenticado';
      }

      // Validações
      if (descricao.isEmpty) {
        throw 'Descrição é obrigatória';
      }

      if (tipo.isEmpty) {
        throw 'Tipo de publicação é obrigatório';
      }

      if (empresa.isEmpty) {
        throw 'Nome da empresa é obrigatório';
      }

      // Obter dados do usuário
      DocumentSnapshot userDoc =
          await _firebaseFirestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        throw 'Perfil do usuário não encontrado';
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Gerar ID único para o post
      int postId = DateTime.now().millisecondsSinceEpoch;

      // Criar documento do post profissional
      await _firebaseFirestore.collection('posts_profissionais').add({
        'id': postId,
        'userId': user.uid,
        'title': titulo,
        'description': descricao,
        'type': tipo,
        'company': empresa,
        'nomeCompleto': userData['nomeCompleto'] ?? '',
        'username': userData['username'] ?? '',
        'createdAt': Timestamp.now(),
        'isLiked': false,
        'likesCount': 0,
        'comentarios': [],
      });

      print('✅ Post profissional criado com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao criar post profissional: $e');
      rethrow;
    }
  }
}