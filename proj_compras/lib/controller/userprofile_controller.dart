import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/user_profile_model.dart';
import '../model/user_model.dart';
import '../model/postevento_model.dart';
import '../model/professionalpost_model.dart';

class UserProfileController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Obter dados do usuário atual
  Future<UserProfile?> obterPerfilAtual() async {
    try {
      print('🔄 Obtendo perfil do usuário...');
      User? user = _firebaseAuth.currentUser;

      if (user == null) {
        print('❌ Usuário não autenticado');
        return null;
      }

      DocumentSnapshot doc =
          await _firebaseFirestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        print('✅ Perfil obtido com sucesso');
        return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao obter perfil: $e');
      return null;
    }
  }

  // Atualizar dados do usuário
  Future<bool> atualizarPerfil(
    String nomeCompleto,
    String username,
    String universidade,
    String curso,
  ) async {
    try {
      print('🔄 Atualizando perfil...');
      User? user = _firebaseAuth.currentUser;

      if (user == null) {
        throw 'Usuário não autenticado';
      }

      // Validações
      if (nomeCompleto.isEmpty || nomeCompleto.split(' ').length < 2) {
        throw 'Nome completo deve ter pelo menos 2 nomes';
      }

      if (username.isEmpty || username.length < 3) {
        throw 'Username deve ter pelo menos 3 caracteres';
      }

      if (universidade.isEmpty) {
        throw 'Universidade é obrigatória';
      }

      if (curso.isEmpty) {
        throw 'Curso é obrigatório';
      }

      // Verificar se novo username já existe (se foi alterado)
      UserProfile? perfilAtual = await obterPerfilAtual();
      if (perfilAtual?.username != username.toLowerCase()) {
        bool usernameExiste = await _usernameJaExiste(username);
        if (usernameExiste) {
          throw 'Username já existe';
        }
      }

      await _firebaseFirestore.collection('users').doc(user.uid).update({
        'nomeCompleto': nomeCompleto,
        'username': username.toLowerCase(),
        'universidade': universidade,
        'curso': curso,
        'alteradoEm': DateTime.now(),
      });

      print('✅ Perfil atualizado com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  // Atualizar senha
  Future<bool> atualizarSenha(
    String senhaAtual,
    String novaSenha,
    String confirmarSenha,
  ) async {
    try {
      print('🔄 Atualizando senha...');
      User? user = _firebaseAuth.currentUser;

      if (user == null) {
        throw 'Usuário não autenticado';
      }

      // Validações
      if (senhaAtual.isEmpty) {
        throw 'Senha atual é obrigatória';
      }

      if (novaSenha.isEmpty || novaSenha.length < 6) {
        throw 'Nova senha deve ter pelo menos 6 caracteres';
      }

      if (novaSenha != confirmarSenha) {
        throw 'As senhas não correspondentem';
      }

      if (senhaAtual == novaSenha) {
        throw 'A nova senha deve ser diferente da atual';
      }

      // Reautenticar usuário
      String email = user.email ?? '';
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: senhaAtual,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(novaSenha);

      print('✅ Senha atualizada com sucesso');
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Erro ao atualizar senha: ${e.code}');
      if (e.code == 'wrong-password') {
        throw 'Senha atual está incorreta';
      }
      throw 'Erro ao atualizar senha: ${e.message}';
    } catch (e) {
      print('❌ Erro geral: $e');
      rethrow;
    }
  }

  // Obter posts de eventos do usuário
  Future<List<Evento>> obterPostsEventos() async {
    try {
      print('🔄 Obtendo posts de eventos do usuário...');
      User? user = _firebaseAuth.currentUser;

      if (user == null) {
        print('❌ Usuário não autenticado');
        return [];
      }

      print('📍 User ID: ${user.uid}');
      print('📍 Acessando collection: eventos');

      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('eventos')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ ${snapshot.docs.length} posts de eventos encontrados');

      if (snapshot.docs.isEmpty) {
        print('⚠️ Nenhum evento encontrado para este usuário');
        return [];
      }

      List<Evento> eventos = [];
      
      for (var doc in snapshot.docs) {
        print('📄 Documento: ${doc.id}');
        print('📊 Dados: ${doc.data()}');
        
        try {
          final userModel = UserModel(
            uid: doc['userId'] ?? '',
            email: doc['userId'] ?? '',
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
            user: userModel,
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
          print('❌ Erro ao processar evento: $e');
        }
      }

      print('✅ Total de eventos processados: ${eventos.length}');
      return eventos;
    } catch (e) {
      print('❌ Erro ao obter posts de eventos: $e');
      return [];
    }
  }

  // Obter posts profissionais do usuário
  Future<List<ProfessionalPost>> obterPostsProfissionais() async {
    try {
      print('🔄 Obtendo posts profissionais do usuário...');
      User? user = _firebaseAuth.currentUser;

      if (user == null) {
        print('❌ Usuário não autenticado');
        return [];
      }

      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('posts_profissionais')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ ${snapshot.docs.length} posts profissionais encontrados');

      List<ProfessionalPost> posts = [];
      
      for (var doc in snapshot.docs) {
        try {
          final userModel = UserModel(
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
            user: userModel,
            createdAt: doc['createdAt'] != null
                ? (doc['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            isLiked: doc['isLiked'] ?? false,
            likesCount: doc['likesCount'] ?? 0,
            comentarios: [],
          );
          
          posts.add(post);
          print('✅ Post profissional adicionado ao perfil');
        } catch (e) {
          print('❌ Erro ao processar post profissional: $e');
        }
      }

      return posts;
    } catch (e) {
      print('❌ Erro ao obter posts profissionais: $e');
      return [];
    }
  }

  // Deletar post de evento
  Future<bool> deletarPostEvento(int postId) async {
    try {
      print('🔄 Deletando post de evento ID: $postId');
      User? user = _firebaseAuth.currentUser;

      if (user == null) throw 'Usuário não autenticado';

      // 🔥 BUSCA PELO ID NUMÉRICO NO CAMPO 'id'
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('eventos')
          .where('id', isEqualTo: postId)
          .where('userId', isEqualTo: user.uid)
          .get();

      print('📊 Documentos encontrados para deletar: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        print('❌ Nenhum documento encontrado com ID: $postId');
        return false;
      }

      // 🔥 DELETA CADA DOCUMENTO ENCONTRADO
      for (var doc in snapshot.docs) {
        print('🗑️ Deletando documento: ${doc.id}');
        await doc.reference.delete();
      }

      print('✅ Post de evento deletado com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao deletar post: $e');
      return false;
    }
  }

  // Deletar post profissional
  Future<bool> deletarPostProfissional(int postId) async {
    try {
      print('🔄 Deletando post profissional...');
      User? user = _firebaseAuth.currentUser;

      if (user == null) throw 'Usuário não autenticado';

      await _firebaseFirestore
          .collection('posts_profissionais')
          .where('id', isEqualTo: postId)
          .where('userId', isEqualTo: user.uid)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      print('✅ Post profissional deletado');
      return true;
    } catch (e) {
      print('❌ Erro ao deletar post: $e');
      return false;
    }
  }

  Future<bool> atualizarPostEvento(Evento evento) async {
    try {
      print('🔄 Atualizando evento...');
      User? user = _firebaseAuth.currentUser;

      if (user == null) throw 'Usuário não autenticado';

      await _firebaseFirestore
          .collection('eventos')
          .where('id', isEqualTo: evento.id)
          .where('userId', isEqualTo: user.uid)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({
            'title': evento.title,
            'description': evento.description,
            'location': evento.location,
          });
        }
      });

      print('✅ Evento atualizado com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao atualizar evento: $e');
      return false;
    }
  }

  Future<bool> atualizarPostProfissional(ProfessionalPost post) async {
    try {
      print('🔄 Atualizando post profissional...');
      User? user = _firebaseAuth.currentUser;

      if (user == null) throw 'Usuário não autenticado';

      await _firebaseFirestore
          .collection('posts_profissionais')
          .where('id', isEqualTo: post.id)
          .where('userId', isEqualTo: user.uid)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({
            'description': post.description,
          });
        }
      });

      print('✅ Post profissional atualizado com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao atualizar post: $e');
      return false;
    }
  }

  // Fazer logout
  Future<bool> fazerLogout() async {
    try {
      print('🔄 Fazendo logout...');
      await _firebaseAuth.signOut();
      print('✅ Logout realizado');
      return true;
    } catch (e) {
      print('❌ Erro ao fazer logout: $e');
      return false;
    }
  }

  // Verificar username único
  Future<bool> _usernameJaExiste(String username) async {
    try {
      final query = await _firebaseFirestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}