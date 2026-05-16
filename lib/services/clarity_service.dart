// Conditional import: native on mobile, stub on web
export 'clarity_stub.dart'
    if (dart.library.io) 'clarity_native.dart';
