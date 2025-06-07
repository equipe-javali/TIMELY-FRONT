
import 'api_data_service.dart';
import 'data_service_interface.dart';


class DataServiceProvider {
  static DataServiceInterface getService({
    required String apiBaseUrl,
  }) {
      return ApiDataService(baseUrl: apiBaseUrl);
    }
  }
