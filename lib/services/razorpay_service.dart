import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPaymentResult {
  final String paymentId;
  final String orderId;
  final String signature;

  const RazorpayPaymentResult({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });
}

class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();

  Razorpay? _razorpay;
  Completer<RazorpayPaymentResult>? _completer;

  void _ensureInit() {
    if (_razorpay != null) return;
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  Future<RazorpayPaymentResult> pay({
    required String razorpayKey,
    required String orderId,
    required int amountInPaise,
    required String contactPhone,
    String? name,
    String? email,
    String description = 'NEE Platform Payment',
  }) {
    _ensureInit();
    _completer = Completer<RazorpayPaymentResult>();

    _razorpay!.open({
      'key': razorpayKey,
      'amount': amountInPaise,
      'order_id': orderId,
      'name': name ?? 'NEE Platform',
      'description': description,
      'prefill': {
        'contact': contactPhone,
        if (email != null && email.isNotEmpty) 'email': email,
      },
      'external': {
        'wallets': ['paytm'],
      },
    });

    return _completer!.future;
  }

  void _onSuccess(PaymentSuccessResponse response) {
    _completer?.complete(RazorpayPaymentResult(
      paymentId: response.paymentId ?? '',
      orderId: response.orderId ?? '',
      signature: response.signature ?? '',
    ));
    _completer = null;
  }

  void _onError(PaymentFailureResponse response) {
    final raw = response.message ?? '';
    // Android SDK sends "undefined" for user-cancel; treat empty/undefined/null as cancelled.
    final isCancelled = raw.isEmpty || raw == 'undefined' || raw == 'null'
        || raw.toLowerCase().contains('cancel');
    _completer?.completeError(
      isCancelled
          ? PaymentCancelledException()
          : Exception(raw),
    );
    _completer = null;
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _completer?.completeError(
      Exception('Redirected to ${response.walletName}. Complete payment there and refresh.'),
    );
    _completer = null;
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}

final razorpayService = RazorpayService();

class PaymentCancelledException implements Exception {}
