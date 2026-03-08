import 'package:url_launcher/url_launcher.dart';
import 'functions_service.dart';

class StripeService {
  final FunctionsService _functions = FunctionsService();

  /// Open Stripe Checkout for plan upgrade
  /// Calls createCheckoutSession Cloud Function, then opens the returned URL
  Future<void> openCheckout({
    required String plan,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final checkoutUrl = await _functions.createCheckoutSession(
      plan: plan,
      successUrl: successUrl,
      cancelUrl: cancelUrl,
    );

    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not open Stripe Checkout URL');
    }
  }
}
