import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/postevento_model.dart';
import '../model/user_model.dart';

class FeedEventos {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<List<Evento>> obterEventos() async {
    try {
      print('🔄 Obtendo eventos do Firebase...');
      print('📍 Acessando collection: eventos');
      
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('eventos')
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ ${snapshot.docs.length} eventos encontrados');
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ Nenhum documento encontrado na collection');
        return [];
      }

      List<Evento> eventos = [];
      
      for (var doc in snapshot.docs) {
        print('📄 Documento: ${doc.id}');
        print('📊 Dados: ${doc.data()}');
        
        try {
          final user = UserModel(
            uid: doc['userId'] ?? '',
            email: doc['userId'] ?? '', // Usando userId como email temporariamente
            nomeCompleto: doc['nomeCompleto'] ?? 'Usuário',
            username: doc['username'] ?? 'usuario',
            universidade: 'FATEC RP',
            curso: 'ADS',
            telefone: '',
          );
          
          final evento = Evento(
            id: doc['id'] ?? 0,
            title: doc['title'] ?? '',
            description: doc['description'] ?? '',
            date: doc['date'] != null 
                ? (doc['date'] as Timestamp).toDate()
                : DateTime.now(),
            location: doc['location'] ?? '',
            imageUrl: doc['imageUrl'] ?? '',
            user: user,
            createdAt: doc['createdAt'] != null
                ? (doc['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            isLiked: doc['isLiked'] ?? false,
            likesCount: doc['likesCount'] ?? 0,
            comentarios: [],
          );
          
          eventos.add(evento);
          print('✅ Evento adicionado: ${evento.title}');
        } catch (e) {
          print('❌ Erro ao processar documento ${doc.id}: $e');
        }
      }
      
      print('✅ Total de eventos processados: ${eventos.length}');
      return eventos;
    } catch (e) {
      print('❌ Erro ao obter eventos: $e');
      return [];
    }
  }
}