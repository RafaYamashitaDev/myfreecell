import 'dart:isolate';

import 'package:myfreecell_domain/myfreecell_domain.dart'; // ignore: unused_import
import 'package:test/test.dart';

void main() {
  test('public library resolves', () async {
    final uri = await Isolate.resolvePackageUri(
      Uri.parse('package:myfreecell_domain/myfreecell_domain.dart'),
    );

    expect(uri, isNotNull);
  });
}
