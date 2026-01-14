import 'dart:convert';
import '../../../core/http/api_client.dart';

class CreateOrderResult {
  final String orderId;
  final String approveUrl;

  CreateOrderResult({required this.orderId, required this.approveUrl});

  factory CreateOrderResult.fromJson(Map<String, dynamic> json) {
    return CreateOrderResult(
      orderId: json['orderId'] as String,
      approveUrl: json['approveUrl'] as String,
    );
  }
}

class PaymentsService {
  final ApiClient _api = ApiClient();

  Future<CreateOrderResult> createPayPalOrder(int reservationId) async {
    final res = await _api.post(
      '/api/payments/paypal/create-order',
      {'reservationId': reservationId},
      auth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body);
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return CreateOrderResult.fromJson(json);
    }

  Future<String> capturePayPal(int reservationId, String orderId) async {
    final res = await _api.post(
      '/api/payments/paypal/capture',
      {'reservationId': reservationId, 'orderId': orderId},
      auth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body);
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['status'] as String?) ?? 'UNKNOWN';
  }

  Future<void> devForcePaid(int reservationId) async {
    final res = await _api.post(
      '/api/payments/paypal/dev-force-paid',
      {'reservationId': reservationId},
      auth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body);
    }
  }
}
