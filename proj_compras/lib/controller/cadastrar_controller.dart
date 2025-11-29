import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CadastrarController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<bool> usernameJaExiste(String username) async {
    try {
      print('🔍 Verificando username: $username');
      final query = await _firebaseFirestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      print('✅ Username verificado. Existe: ${query.docs.isNotEmpty}');
      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erro ao verificar username: $e');
      return false;
    }
  }

  Future<bool> emailJaExiste(String email) async {
    try {
      print('🔍 Verificando email: $email');
      final query = await _firebaseFirestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      print('✅ Email verificado. Existe: ${query.docs.isNotEmpty}');
      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erro ao verificar email: $e');
      return false;
    }
  }

  Future<void> fazerCadastro(
    BuildContext context,
    String nomeCompleto,
    String email,
    String username,
    String universidade,
    String curso,
    String telefone,
    String senha,
    String confirmarSenha,
  ) async {
    try {
      print('🔄 Iniciando cadastro...');

      // Validações
      print('🔍 Validando campos...');

      if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
        throw 'Email inválido. Use o formato: usuario@exemplo.com';
      }
      
      if (nomeCompleto.isEmpty || nomeCompleto.split(' ').length < 2) {
        throw 'Nome completo deve ter pelo menos 2 nomes';
      }

      if (username.isEmpty || username.length < 3) {
        throw 'Username deve ter pelo menos 3 caracteres';
      }

      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
        throw 'Username pode conter apenas letras, números e underscore';
      }

      if (universidade.isEmpty) {
        throw 'Universidade é obrigatória';
      }

      if (curso.isEmpty) {
        throw 'Curso é obrigatório';
      }

      if (senha.isEmpty || senha.length < 6) {
        throw 'Senha deve ter pelo menos 6 caracteres';
      }

      if (senha != confirmarSenha) {
        throw 'As senhas não correspondem';
      }

      if (telefone.isEmpty ||
        !RegExp(r'^\(?\d{2}\)?[\s-]?\d{4,5}-?\d{4}$').hasMatch(telefone)) {
        throw 'Telefone inválido. Use o formato (XX)XXXXX-XXXX ou XXXXXXXXXXX';
      }


      print('✅ Validações concluídas');

      // Verificar email único
      print('🔄 Verificando unicidade do email...');
      bool emailExiste = await emailJaExiste(email);
      if (emailExiste) {
        throw 'Email já cadastrado';
      }
      print('✅ Email disponível');

      // Verificar username único
      print('🔄 Verificando unicidade do username...');
      bool usernameExiste = await usernameJaExiste(username);
      if (usernameExiste) {
        throw 'Username já existe';
      }
      print('✅ Username disponível');

      // Criar usuário no Firebase Auth
      print('🔄 Criando usuário no Firebase Auth...');
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.toLowerCase(),
        password: senha,
      );
      print('✅ Usuário criado no Auth. UID: ${userCredential.user?.uid}');

      // Salvar dados no Firestore
      print('🔄 Salvando dados no Firestore...');
      await _firebaseFirestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'nomeCompleto': nomeCompleto,
        'email': email.toLowerCase(),
        'username': username.toLowerCase(),
        'universidade': universidade,
        'curso': curso,
        'telefone': telefone,
        'profileImage': '',
        'criadoEm': DateTime.now(),
      });
      print('✅ Dados salvos no Firestore');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso! Faça login agora.')),
        );
        print('🔄 Navegando para login...');
        
        // Usar pop e push para garantir que navega
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.of(context).pushNamed('login');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Erro Firebase Auth: ${e.code} - ${e.message}');
      String mensagem = 'Erro ao cadastrar';

      if (e.code == 'weak-password') {
        mensagem = 'Senha muito fraca';
      } else if (e.code == 'email-already-in-use') {
        mensagem = 'Email já cadastrado';
      } else if (e.code == 'invalid-email') {
        mensagem = 'Email inválido';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem)),
        );
      }
    } catch (e) {
      print('❌ Erro geral: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
