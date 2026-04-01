import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

// Para Flutter Web e Linux desktop, localhost costuma funcionar.
// Para Android Emulator, troque para: http://10.0.2.2:3000
// Para celular físico, use o IP da sua máquina, ex: http://192.168.0.10:3000
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

  Usuario({this.id, required this.nome, required this.email});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'email': email};
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
                    MaterialPageRoute(
                      builder: (_) => const FormularioUsuarioPage(),
                    ),
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

class FormularioUsuarioPage extends StatefulWidget {
  final Usuario? usuario;

  const FormularioUsuarioPage({super.key, this.usuario});

  @override
  State<FormularioUsuarioPage> createState() => _FormularioUsuarioPageState();
}

class _FormularioUsuarioPageState extends State<FormularioUsuarioPage> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  bool salvando = false;

  bool get editando => widget.usuario != null;

  @override
  void initState() {
    super.initState();

    if (editando) {
      nomeController.text = widget.usuario!.nome;
      emailController.text = widget.usuario!.email;
    }
  }

  Future<void> salvarUsuario() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();

    if (nome.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha nome e e-mail.')));
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      late http.Response response;

      if (editando) {
        response = await http.put(
          Uri.parse('$baseUrl/usuarios/${widget.usuario!.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'nome': nome, 'email': email}),
        );
      } else {
        response = await http.post(
          Uri.parse('$baseUrl/usuarios'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'nome': nome, 'email': email}),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editando
                  ? 'Usuário atualizado com sucesso!'
                  : 'Usuário cadastrado com sucesso!',
            ),
          ),
        );

        Navigator.pop(context, true);
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
        title: Text(editando ? 'Editar Usuário' : 'Cadastrar Usuário'),
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

  Future<void> editarUsuario(Usuario usuario) async {
    final alterou = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioUsuarioPage(usuario: usuario),
      ),
    );

    if (alterou == true) {
      recarregar();
    }
  }

  Future<void> excluirUsuario(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir usuário'),
        content: Text('Deseja realmente excluir ${usuario.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/usuarios/${usuario.id}'),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário excluído com sucesso!')),
        );

        recarregar();
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha na conexão com o servidor.')),
      );
    }
  }

  Future<void> novoUsuario() async {
    final alterou = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormularioUsuarioPage()),
    );

    if (alterou == true) {
      recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listar Usuários'),
        actions: [
          IconButton(onPressed: recarregar, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: novoUsuario,
        child: const Icon(Icons.add),
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
            return const Center(child: Text('Nenhum usuário cadastrado.'));
          }

          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(usuario.nome),
                subtitle: Text(usuario.email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => editarUsuario(usuario),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => excluirUsuario(usuario),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
