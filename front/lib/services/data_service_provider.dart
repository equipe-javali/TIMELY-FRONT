import '../config/app_config.dart';
import 'api_data_service.dart';
import 'data_service_interface.dart';
import 'mock_data_service.dart';

class DataServiceProvider {
  static DataServiceInterface getService({
    required bool useMockData,
    required String apiBaseUrl,
  }) {
    if (useMockData) {
      return MockDataService();
    } else {
      return ApiDataService(baseUrl: apiBaseUrl);
    }
  }
}