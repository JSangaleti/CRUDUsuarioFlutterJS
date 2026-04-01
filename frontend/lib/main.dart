import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

const String baseUrl = 'http://localhost:3000';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Usuários',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Usuario {
  final int? id;
  final String nome;
  final String email;

  Usuario({
    this.id,
    required this.nome,
    required this.email,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Usuários'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sistema de Usuários',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 240,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CadastroPage()),
                  );
                },
                child: const Text('CADASTRAR USUÁRIO'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 240,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ListagemPage()),
                  );
                },
                child: const Text('LISTAR USUÁRIOS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  bool salvando = false;

  Future<void> salvarUsuario() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();

    if (nome.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome e e-mail.')),
      );
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': nome,
          'email': email,
        }),
      );

      if (response.statusCode == 201) {
        nomeController.clear();
        emailController.clear();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha na conexão com o servidor.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          salvando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Usuário'),
      ),
      body: Center(
        child: SizedBox(
          width: 420,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: salvando ? null : salvarUsuario,
                    child: Text(salvando ? 'Salvando...' : 'Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ListagemPage extends StatefulWidget {
  const ListagemPage({super.key});

  @override
  State<ListagemPage> createState() => _ListagemPageState();
}

class _ListagemPageState extends State<ListagemPage> {
  late Future<List<Usuario>> futurosUsuarios;

  @override
  void initState() {
    super.initState();
    futurosUsuarios = buscarUsuarios();
  }

  Future<List<Usuario>> buscarUsuarios() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/usuarios'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Usuario.fromJson(e)).toList();
      } else {
        throw Exception('Erro ao buscar usuários');
      }
    } catch (e) {
      throw Exception('Falha na conexão');
    }
  }

  void recarregar() {
    setState(() {
      futurosUsuarios = buscarUsuarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listar Usuários'),
        actions: [
          IconButton(
            onPressed: recarregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Usuario>>(
        future: futurosUsuarios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Falha na conexão com o servidor.'),
            );
          }

          final usuarios = snapshot.data ?? [];

          if (usuarios.isEmpty) {
            return const Center(
              child: Text('Nenhum usuário cadastrado.'),
            );
          }

          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(usuario.nome),
                subtitle: Text(usuario.email),
              );
            },
          );
        },
      ),
    );
  }
}