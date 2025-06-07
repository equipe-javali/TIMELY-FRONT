import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/date_format.dart';
import '../config/app_config.dart';
import '../modelos/cartao.dart';
import '../services/data_service_interface.dart';
import '../services/data_service_provider.dart';
import '../components/drawer.dart';

// Enum para os tipos de filtro de tempo
enum FiltroTempo { hoje, seteDias, quinzeDias, trintaDias, todos }

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final DataServiceInterface _dataService;
  List<CartaoModel> _registros = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _timer;

  // Filtro de tempo selecionado (padrão: todos)
  FiltroTempo _filtroSelecionado = FiltroTempo.todos;

  final Color _primaryBlue = const Color(0xFF006699);
  final Color _lightBlue = const Color(0xFFE6F2F8);

  @override
  void initState() {
    super.initState();

    _dataService =
        DataServiceProvider.getService(apiBaseUrl: AppConfig.apiBaseUrl);

    _carregarDados();

    _timer = Timer.periodic(Duration(seconds: AppConfig.dataRefreshInterval),
        (timer) => _carregarDados());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    if (_isLoading) return;

    if (AppConfig.enableLogging) {
      print('Carregando dados...');
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final registros = await _dataService.getUltimosRegistros();

      if (mounted) {
        setState(() {
          _registros = registros;
          _isLoading = false;
        });
      }

      if (AppConfig.enableLogging) {
        print('Dados carregados: ${registros.length} registros');
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('Erro ao carregar dados: $e');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String _formatarTimestamp(int timestamp) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormatter.format(dateTime, 'HH:mm:ss');
  }

  String _formatarData(int timestamp) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormatter.format(dateTime, 'dd/MM/yyyy');
  }

  // Método para filtrar registros com base no período selecionado
  List<CartaoModel> _getRegistrosFiltrados() {
    final agora = DateTime.now();
    late final DateTime dataLimite;

    switch (_filtroSelecionado) {
      case FiltroTempo.hoje:
        dataLimite = DateTime(agora.year, agora.month, agora.day);
        break;
      case FiltroTempo.seteDias:
        dataLimite = agora.subtract(const Duration(days: 7));
        break;
      case FiltroTempo.quinzeDias:
        dataLimite = agora.subtract(const Duration(days: 15));
        break;
      case FiltroTempo.trintaDias:
        dataLimite = agora.subtract(const Duration(days: 30));
        break;
      case FiltroTempo.todos:
        return _registros; // Retorna todos os registros
    }

    final timestampLimite = dataLimite.millisecondsSinceEpoch;

    return _registros
        .where((registro) => registro.timestamp >= timestampLimite)
        .toList();
  }

  // String do título do filtro
  String _getTituloFiltro() {
    switch (_filtroSelecionado) {
      case FiltroTempo.hoje:
        return 'Registros de hoje';
      case FiltroTempo.seteDias:
        return 'Últimos 7 dias';
      case FiltroTempo.quinzeDias:
        return 'Últimos 15 dias';
      case FiltroTempo.trintaDias:
        return 'Últimos 30 dias';
      case FiltroTempo.todos:
        return 'Todos os registros';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Ponto'),
        backgroundColor: _primaryBlue,
      ),
      drawer: MeuDrawer(),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registro de Ponto',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _primaryBlue)),
                const SizedBox(height: 12),
                _buildFiltroSelect(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: _lightBlue,
            width: double.infinity,
            child: Text(
              _getTituloFiltro(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _primaryBlue,
              ),
            ),
          ),
          Expanded(
            child: _buildRegisterTable(_getRegistrosFiltrados()),
          ),
          Container(
            width: double.infinity,
            color: _primaryBlue,
            padding: EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Text(
              'Copyright © ${DateTime.now().year}',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCardDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget para o seletor de filtro (dropdown)
  Widget _buildFiltroSelect() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: _primaryBlue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FiltroTempo>(
          value: _filtroSelecionado,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: _primaryBlue),
          style: TextStyle(color: _primaryBlue, fontSize: 16),
          onChanged: (FiltroTempo? newValue) {
            if (newValue != null) {
              setState(() {
                _filtroSelecionado = newValue;
              });
            }
          },
          items: [
            DropdownMenuItem(
              value: FiltroTempo.hoje,
              child: Text('Hoje'),
            ),
            DropdownMenuItem(
              value: FiltroTempo.seteDias,
              child: Text('Últimos 7 dias'),
            ),
            DropdownMenuItem(
              value: FiltroTempo.quinzeDias,
              child: Text('Últimos 15 dias'),
            ),
            DropdownMenuItem(
              value: FiltroTempo.trintaDias,
              child: Text('Últimos 30 dias'),
            ),
            DropdownMenuItem(
              value: FiltroTempo.todos,
              child: Text('Todos os registros'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTable(List<CartaoModel> registros) {
    if (_isLoading && registros.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError && registros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _carregarDados,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (registros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Nenhum registro encontrado para este período'),
          ],
        ),
      );
    }

    // Agrupar os registros por código de cartão e por data (YYYY-MM-DD)
    final Map<String, Map<String, Map<String, String>>> registrosAgrupados = {};

    for (final registro in registros) {
      final data = _formatarData(registro.timestamp);
      final codigo = registro.codigo;
      final hora = _formatarTimestamp(registro.timestamp);

      // Normalizar o tipo para corresponder às chaves do mapa
      String tipoNormalizado;
      if (registro.tipo.toLowerCase() == 'saida' ||
          registro.tipo.toLowerCase() == 'saída') {
        tipoNormalizado = 'saida';
      } else {
        tipoNormalizado = 'entrada';
      }

      if (AppConfig.enableLogging) {
        print(
            'Registro: codigo=$codigo, data=$data, hora=$hora, tipo original=${registro.tipo}, normalizado=$tipoNormalizado');
      }

      // Criar chave para cartão se não existir
      if (!registrosAgrupados.containsKey(codigo)) {
        registrosAgrupados[codigo] = {};
      }

      // Criar chave para data se não existir
      if (!registrosAgrupados[codigo]!.containsKey(data)) {
        registrosAgrupados[codigo]![data] = {'entrada': '', 'saida': ''};
      }

      // Armazenar a hora na entrada ou saída conforme o tipo normalizado
      registrosAgrupados[codigo]![data]![tipoNormalizado] = hora;
    }

    // Converter mapa para lista de registros consolidados para exibir
    List<Map<String, dynamic>> registrosConsolidados = [];

    registrosAgrupados.forEach((codigo, dataMap) {
      dataMap.forEach((data, horarios) {
        registrosConsolidados.add({
          'codigo': codigo,
          'data': data,
          'entrada': horarios['entrada'] ?? '-',
          'saida': horarios['saida'] ?? '-',
        });
      });
    });

    // Ordenar por data (mais recente primeiro) e código
    registros.sort((a, b) {
      // Extrair apenas a data para comparação inicial
      final dataA = _formatarData(a.timestamp);
      final dataB = _formatarData(b.timestamp);

      // Comparar por data (decrescente)
      final dataComp = dataB.compareTo(dataA);
      if (dataComp != 0) return dataComp;

      // Se mesma data, comparar por código (crescente)
      final codigoComp = a.codigo.compareTo(b.codigo);
      if (codigoComp != 0) return codigoComp;

      // Se mesmo código, ordenar por timestamp (crescente = cronológica)
      return a.timestamp.compareTo(b.timestamp);
    });

    return Column(
      children: [
        Container(
          color: _primaryBlue,
          child: Row(
            children: [
              _buildHeaderCell('Código', flex: 2),
              _buildHeaderCell('Data', flex: 2),
              _buildHeaderCell('Hora', flex: 1),
              _buildHeaderCell('Tipo', flex: 1),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _carregarDados,
            child: ListView.builder(
              itemCount: registros.length,
              itemBuilder: (context, index) {
                final registro = registros[index];
                final bool isEven = index.isEven;

                final data = _formatarData(registro.timestamp);
                final hora = _formatarTimestamp(registro.timestamp);

                return Container(
                  color: isEven ? Colors.white : _lightBlue,
                  child: Row(
                    children: [
                      _buildDataCell(registro.codigo, flex: 2),
                      _buildDataCell(data, flex: 2),
                      _buildDataCell(hora, flex: 1),
                      _buildTypeCell(registro.tipo),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Novo método para construir células de horário com ícones
  Widget _buildTypeCell(String tipo) {
  // Normalizar tipo
  final tipoNormalizado = tipo.toLowerCase();
  final bool isEntrada = 
      tipoNormalizado == 'entrada';
  
  final Color color = isEntrada ? Colors.green : Colors.red;
  final IconData icon = isEntrada ? Icons.login : Icons.logout;
  
  return Expanded(
    flex: 1,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 4),
          Text(
            isEntrada ? 'ENTRADA' : 'SAÍDA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

  // Método para mostrar diálogo para adicionar cartão manualmente
  void _showAddCardDialog() {
    final codigoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registrar Cartão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Informe o código do cartão para registrar um ponto'),
            SizedBox(height: 15),
            TextField(
              controller: codigoController,
              decoration: InputDecoration(
                labelText: 'Código do cartão',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codigoController.text.isNotEmpty) {
                try {
                  await _enviarRegistroPonto(codigoController.text);
                  Navigator.of(context).pop();
                  _carregarDados();

                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ponto registrado com sucesso!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erro ao registrar ponto: $e'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
            ),
            child: Text('Registrar'),
          ),
        ],
      ),
    );
  }

  // Método para enviar um registro de ponto manualmente
  Future<void> _enviarRegistroPonto(String codigo) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/dados'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cartao': {'codigo': codigo}
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw Exception(
            'Erro ao registrar ponto. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
