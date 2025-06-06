class AppConfig {
  // Configurações da API
  static const String apiBaseUrl = 'http://10.0.2.2:3000'; // Para emulador Android usar 10.0.2.2 em vez de localhost
  static const int apiTimeout = 10000; // Timeout em milissegundos (10 segundos)
  
  // Modo de dados (altere para false para usar a API real)
  static const bool useMockData = false;
  
  // Intervalo de atualização dos dados em segundos
  static const int dataRefreshInterval = 15;
  
  // Configurações de armazenamento local (se necessário)
  static const String cacheKey = 'rfid_data_cache';
  
  // Versão do aplicativo
  static const String appVersion = '1.0.0';
  
  // Ambiente de execução
  static const String environment = 'development'; // 'development', 'staging', 'production'
  
  // Configurações de debug
  static const bool enableLogging = true;
}