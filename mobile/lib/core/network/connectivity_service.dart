import 'dart:async';
import 'package:dio/dio.dart';

class ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  bool _lastStatus = true;

  // Single reusable client — avoids leaking a new Dio instance every 10 s
  final Dio _client = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  ConnectivityService() {
    // Periodically ping to verify true internet connectivity
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      final isOnline = await checkRealConnectivity();
      if (isOnline != _lastStatus) {
        _lastStatus = isOnline;
        _controller.add(isOnline);
      }
    });
  }

  Stream<bool> get onConnectivityChanged => _controller.stream;
  bool get isCurrentlyConnected => _lastStatus;

  Future<bool> checkRealConnectivity() async {
    
    try {
      final Response<dynamic> response =
      await _client.get<dynamic>(
      'https://connectivitycheck.gstatic.com/generate_204',
      options: Options(responseType: ResponseType.bytes),
);
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
    _controller.close();
  }
}
