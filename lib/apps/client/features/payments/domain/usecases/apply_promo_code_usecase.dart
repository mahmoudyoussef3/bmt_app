class ApplyPromoCodeUseCase {
  const ApplyPromoCodeUseCase();

  int call(String code) {
    return switch (code.trim().toUpperCase()) {
      'WELCOME10' => 10,
      'MEGA20' => 20,
      _ => 0,
    };
  }
}
