import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';
import 'globals.dart' as globals;

class AdicionaContaScreen extends StatefulWidget {
  const AdicionaContaScreen({super.key});

  @override
  _AdicionaContaScreenState createState() => _AdicionaContaScreenState();
}

class _AdicionaContaScreenState extends State<AdicionaContaScreen> {
  final _formKey = GlobalKey<FormState>();
  String _titulo = '';
  String _dataVencimento = '';
  bool _ehRecorrente = false;
  String _diaRecorrencia = '';

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _dataVencimentoController = TextEditingController();
  final TextEditingController _diaRecorrenciaController = TextEditingController();

  final valorMask = TextInputFormatter.withFunction((oldValue, newValue) {
    String cleanedText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedText.isEmpty) cleanedText = '00';
    else if (cleanedText.length == 1) cleanedText = '0$cleanedText';

    String formattedText = '${cleanedText.substring(0, cleanedText.length - 2)},${cleanedText.substring(cleanedText.length - 2)}';
    formattedText = formattedText.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  });

  Future<void> _enviarFormulario() async {
    if (_formKey.currentState!.validate()) {
      String valorFormatado = _valorController.text;

      final response = await http.post(
        Uri.parse('http://192.168.15.114:3000/contas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': globals.userId,
          'titulo': _titulo,
          'valor': valorFormatado,
          'data_vencimento': _dataVencimento,
          'eh_recorrente': _ehRecorrente,
          'dia_recorrencia': _ehRecorrente ? _diaRecorrencia : null,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta adicionada com sucesso!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao adicionar conta!')),
        );
      }
    }
  }

  void _preencherDataAtual() {
    final now = DateTime.now();
    final dataAtual = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    setState(() {
      _dataVencimento = dataAtual;
      _dataVencimentoController.text = dataAtual;
    });
  }

  void _corrigirDiaRecorrencia(String value) {
    int? dia = int.tryParse(value);
    if (dia != null) {
      if (dia > 31) dia = 31;
      _diaRecorrenciaController.text = dia.toString();
      _diaRecorrencia = dia.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Conta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Por favor, insira um título' : null,
                onChanged: (value) => setState(() => _titulo = value),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [valorMask],
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _dataVencimentoController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: 'Data de Vencimento (dd/mm/aaaa)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Por favor, insira a data de vencimento';
                  if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) return 'Formato inválido. Use dd/mm/aaaa.';
                  return null;
                },
                onChanged: (value) => setState(() => _dataVencimento = value),
              ),
              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: _preencherDataAtual,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
                child: const Text('Usar data atual', style: TextStyle(color: Colors.black)),
              ),
              const SizedBox(height: 10),

              SwitchListTile(
                title: const Text('É recorrente?'),
                value: _ehRecorrente,
                onChanged: (bool value) => setState(() => _ehRecorrente = value),
              ),

              if (_ehRecorrente)
                TextFormField(
                  controller: _diaRecorrenciaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Dia de Recorrência (1 a 31)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_ehRecorrente && (value == null || value.isEmpty)) {
                      return 'Por favor, insira o dia de recorrência';
                    }
                    int? dia = int.tryParse(value!);
                    if (dia == null || dia < 1 || dia > 31) {
                      return 'Dia inválido. Deve ser entre 1 e 31.';
                    }
                    return null;
                  },
                  onChanged: (value) => _corrigirDiaRecorrencia(value),
                ),
              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: _enviarFormulario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6200EE),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Adicionar Conta', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
