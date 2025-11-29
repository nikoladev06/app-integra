import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/professionalpost_model.dart';
import '../model/user_model.dart';

class ProfessionalFeed {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<List<ProfessionalPost>> obterPostsProfissionais() async {
    try {
      print('🔄 Obtendo posts profissionais do Firebase...');
      print('📍 Acessando collection: posts_profissionais');
      
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('posts_profissionais')
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ ${snapshot.docs.length} posts profissionais encontrados');
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ Nenhum documento encontrado na collection');
        return [];
      }

      List<ProfessionalPost> posts = [];
      
      for (var doc in snapshot.docs) {
        print('📄 Documento: ${doc.id}');
        print('📊 Dados: ${doc.data()}');
        
        try {
          final user = UserModel(
            uid: doc['userId'] ?? '',
            email: doc['userId'] ?? '',
            nomeCompleto: doc['nomeCompleto'] ?? 'Usuário',
            username: doc['username'] ?? 'usuario',
            universidade: 'FATEC RP',
            curso: 'ADS',
            telefone: '',
          );
          
          final post = ProfessionalPost(
            id: doc['id'] ?? 0,
            title: doc['title'] ?? '',
            description: doc['description'] ?? '',
            company: doc['company'] ?? '',
            user: user,
            createdAt: doc['createdAt'] != null
                ? (doc['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            isLiked: doc['isLiked'] ?? false,
            likesCount: doc['likesCount'] ?? 0,
            comentarios: [],
          );
          
          posts.add(post);
          print('✅ Post adicionado: ${post.description}');
        } catch (e) {
          print('❌ Erro ao processar documento ${doc.id}: $e');
        }
      }
      
      print('✅ Total de posts processados: ${posts.length}');
      return posts;
    } catch (e) {
      print('❌ Erro ao obter posts profissionais: $e');
      return [];
    }
  }
}