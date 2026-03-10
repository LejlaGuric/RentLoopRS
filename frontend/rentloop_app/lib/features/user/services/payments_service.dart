import 'dart:convert';
import '../../../core/http/api_client.dart';

class CreateOrderResult {
  final String orderId;
  final String approveUrl;

  CreateOrderResult({
    required this.orderId,
    required this.approveUrl,
  });

  factory CreateOrderResult.fromJson(Map<String, dynamic> json) {
    return CreateOrderResult(
      orderId: json['orderId'] as String,
      approveUrl: json['approveUrl'] as String,
    );
  }
}

class CapturePayPalResult {
  final String status;

  CapturePayPalResult({required this.status});

  factory CapturePayPalResult.fromJson(Map<String, dynamic> json) {
    return CapturePayPalResult(
      status: (json['status'] as String?) ?? 'UNKNOWN',
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

  Future<CapturePayPalResult> capturePayPalOrder({
    required int reservationId,
    required String orderId,
  }) async {
    final res = await _api.post(
      '/api/payments/paypal/capture',
      {
        'reservationId': reservationId,
        'orderId': orderId,
      },
      auth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body);
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return CapturePayPalResult.fromJson(json);
  }

  Future<String> capturePayPal(int reservationId, String orderId) async {
    final result = await capturePayPalOrder(
      reservationId: reservationId,
      orderId: orderId,
    );
    return result.status;
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