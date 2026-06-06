import 'dart:math';

class GeneratePaymentReferenceUseCase {
  GeneratePaymentReferenceUseCase({Random? random})
    : _random = random ?? Random();

  final Random _random;

  String call({required String prefix, int length = 5}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final body = List.generate(
      length,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
    return '$prefix-2026-$body';
  }
}
