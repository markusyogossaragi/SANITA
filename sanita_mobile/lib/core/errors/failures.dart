abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak dapat terhubung ke server SANITA.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan pemrosesan pada server.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Data yang diminta tidak ditemukan.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class SecurityFailure extends Failure {
  const SecurityFailure([super.message = 'Pelanggaran keamanan terdeteksi (Anti-Breach Shield).']);
}