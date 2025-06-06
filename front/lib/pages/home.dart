import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/date_format.dart';
import '../config/app_config.dart';
import '../modelos/cartao.dart';
import '../services/data_service_interface.dart';
import '../services/data_service_provider.dart';
import '../components/drawer.dart';

// Enum para os tipos de filtro de tempo
enum FiltroTempo {
  hoje,
  seteDias,
  quinzeDias,
  trintaDias,
  todos
}

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
    
    _dataService = DataServiceProvider.getService(
      useMockData: AppConfig.useMockData,
      apiBaseUrl: AppConfig.apiBaseUrl
    );
    
    _carregarDados();
    
    _timer = Timer.periodic(
      Duration(seconds: AppConfig.dataRefreshInterval), 
      (timer) => _carregarDados()
    );
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
    
    return _registros.where((registro) => 
      registro.timestamp >= timestampLimite
    ).toList();
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
        title: const Text('Apontamentos'),
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
                Text(
                  'Controle de acesso', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 18,
                    color: _primaryBlue
                  )
                ),
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
              'Copyright © 2025',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   backgroundColor: Colors.green,
      //   child: const Icon(Icons.add),
      // ),
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

    return Column(
      children: [
        Container(
          color: _primaryBlue,
          child: Row(
            children: [
              _buildHeaderCell('Nome', flex: 1),
              _buildHeaderCell('Início', flex: 1),
              _buildHeaderCell('Fim', flex: 1),
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
                
                return Container(
                  color: isEven ? Colors.white : _lightBlue,
                  child: Row(
                    children: [
                      _buildDataCell(registro.nome ?? 'Nome', flex: 1),
                      _buildDataCell(_formatarTimestamp(registro.timestamp), flex: 1),
                      _buildDataCell('Fim', flex: 1),
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