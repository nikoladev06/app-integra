import 'package:flutter/material.dart';
import '../controller/userprofile_controller.dart';
import '../model/user_profile_model.dart';
import '../controller/feedeventos_controller.dart' as feed_eventos;
import '../controller/professionalfeed_controller.dart' as feed_profissional;
import '../model/postevento_model.dart';
import '../model/professionalpost_model.dart';

import 'userprofile_view.dart';
import 'addevento_view.dart';
import 'addprofessionalpost_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final UserProfileController _profileController = UserProfileController();
  final feed_eventos.FeedEventos _feedEventosController =
      feed_eventos.FeedEventos();
  final feed_profissional.ProfessionalFeed _feedProfissionalController =
      feed_profissional.ProfessionalFeed();

  int _currentIndex = 0;
  late List<Evento> _eventosAtuais;
  late List<ProfessionalPost> _postsAtuais;
  bool _isLoadingEventos = true;
  UserProfile? _userProfile;
  bool _isLoadingProfissional = true;

  @override
  void initState() {
    super.initState();
    _eventosAtuais = [];
    _postsAtuais = [];
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await _carregarPerfil();
    await _carregarEventos();
    await _carregarPostsProfissionais();
  }

  Future<void> _carregarEventos() async {
    setState(() => _isLoadingEventos = true);
    try {
      _eventosAtuais = await _feedEventosController.obterEventos();
      if (mounted) {
        setState(() => _isLoadingEventos = false);
      }
    } catch (e) {
      print('❌ Erro ao carregar eventos: $e');
      if (mounted) {
        setState(() => _isLoadingEventos = false);
      }
    }
  }

  Future<void> _carregarPostsProfissionais() async {
    setState(() => _isLoadingProfissional = true);
    try {
      _postsAtuais =
          await _feedProfissionalController.obterPostsProfissionais();
      if (mounted) {
        setState(() => _isLoadingProfissional = false);
      }
    } catch (e) {
      print('❌ Erro ao carregar posts profissionais: $e');
      if (mounted) {
        setState(() => _isLoadingProfissional = false);
      }
    }
  }

  Future<void> _carregarPerfil() async {
    try {
      UserProfile? perfil = await _profileController.obterPerfilAtual();
      if (mounted) {
        setState(() {
          _userProfile = perfil;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar perfil no drawer: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111112),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Garante que a seta de voltar e outros ícones sejam brancos
        leading: Builder( // O leading é mantido para a lógica do drawer
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Integra',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1F1F20),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF6200EE),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF6200EE),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userProfile?.nomeCompleto ?? 'Carregando...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userProfile != null ? '@${_userProfile!.username}' : '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: Colors.grey,
              ),
              title: const Text(
                'Perfil',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfileView(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Sair',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                // Captura o context da HomeView antes de mostrar o diálogo
                final homeContext = context;

                final bool? deveSair = await showDialog<bool>(
                  context: homeContext,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: const Color(0xFF1F1F20),
                    title: const Text(
                      'Sair',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      'Você deseja sair da sua conta?',
                      style: TextStyle(color: Colors.grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text(
                          'Sair',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                // Se o usuário confirmou a saída no diálogo
                if (deveSair == true) {
                  final bool logoutSucesso = await _profileController.fazerLogout();
                  if (logoutSucesso && homeContext.mounted) {
                    Navigator.pushNamed(homeContext, 'inicio');
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6200EE),
        onPressed: () async {
          if (_currentIndex == 0) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEventoView(),
              ),
            );
            // Se retornar true, recarrega os eventos
            if (result == true) {
              await _carregarEventos();
            }
          } else {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddProfessionalPostView(),
              ),
            );
            // Se retornar true, recarrega os posts
            if (result == true) {
              await _carregarPostsProfissionais();
            }
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1F1F20),
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF6200EE),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Profissional',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 0) {
      return _isLoadingEventos
          ? const Center(child: CircularProgressIndicator())
          : _eventosAtuais.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum evento ainda',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarEventos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _eventosAtuais.length,
                    itemBuilder: (context, index) {
                      final evento = _eventosAtuais[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                evento.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                evento.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    evento.location,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${evento.date.day}/${evento.date.month}/${evento.date.year}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    evento.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_outline,
                                    size: 18,
                                    color: evento.isLiked
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${evento.likesCount}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
    } else {
      return _isLoadingProfissional
          ? const Center(child: CircularProgressIndicator())
          : _postsAtuais.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma oportunidade ainda',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarPostsProfissionais,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _postsAtuais.length,
                    itemBuilder: (context, index) {
                      final post = _postsAtuais[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                post.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    post.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_outline,
                                    size: 18,
                                    color: post.isLiked
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.likesCount}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
    }
  }
}