sealed class AppException implements Exception {
  const AppException(this.userMessage);

  final String userMessage;

  @override
  String toString() => userMessage;
}

final class NetworkException extends AppException {
  const NetworkException()
    : super('No fue posible conectarse. Revisa tu conexión a internet.');
}

final class RequestTimeoutException extends AppException {
  const RequestTimeoutException()
    : super('La consulta tardó demasiado. Intenta nuevamente.');
}

final class InvalidResponseException extends AppException {
  const InvalidResponseException()
    : super('El SERCOP devolvió una respuesta que no pudo procesarse.');
}

final class JsonParsingException extends AppException {
  const JsonParsingException()
    : super('El SERCOP devolvió una respuesta que no pudo procesarse.');
}

final class SercopHttpException extends AppException {
  const SercopHttpException()
    : super('No fue posible consultar la información del SERCOP.');
}

final class ProcessNotFoundException extends AppException {
  const ProcessNotFoundException()
    : super('No se encontró el proceso solicitado.');
}

final class UnknownAppException extends AppException {
  const UnknownAppException()
    : super('Ocurrió un problema inesperado. Inténtalo nuevamente.');
}
