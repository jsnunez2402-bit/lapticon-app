import 'package:flutter_test/flutter_test.dart';

import 'package:app/utils.dart';

void main() {
  test('formato de fecha ISO', () {
    expect(fechaIso(DateTime(2026, 12, 1)), '2026-12-01');
  });
}
