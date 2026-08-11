class CaptainCounts {
  const CaptainCounts._();

  static String stops(int count) => switch (count) {
    1 => 'محطة واحدة',
    2 => 'محطتان',
    <= 10 => '$count محطات',
    _ => '$count محطة',
  };

  static String passengers(int count) => switch (count) {
    0 => 'لا ركاب',
    1 => 'راكب واحد',
    2 => 'راكبان',
    <= 10 => '$count ركاب',
    _ => '$count راكبًا',
  };
}
