class AppConfig {
  // Configurações da API
  static const String apiBaseUrl = 'http://localhost:3000'; // Para emulador Android usar 10.0.2.2 em vez de localhost
  static const int apiTimeout = 20000; // Timeout em milissegundos (10 segundos)
  
  
  // Intervalo de atualização dos dados em segundos
  static const int dataRefreshInterval = 15;
  
 
  // Versão do aplicativo
  static const String appVersion = '1.0.0';
  

  // Configurações de debug
  static const bool enableLogging = true;
}