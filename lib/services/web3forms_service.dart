import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/enterprise.dart';

/// Servicio para enviar formularios mediante Web3Forms.
/// La API Key se obtiene de Firebase Remote Config (web_3_form).
class Web3FormsService {
  static const String _apiUrl = 'https://api.web3forms.com/submit';

  /// Envía el formulario de contacto a Web3Forms.
  /// El email se enviará a la dirección configurada en tu cuenta Web3Forms.
  Future<void> submitContactForm({
    required String accessKey,
    required ContactSubmission submission,
  }) async {
    if (accessKey.isEmpty) {
      throw Web3FormsException('Access Key de Web3Forms no configurada. Configura web_3_form en Firebase Remote Config.');
    }

    final body = {
      'access_key': accessKey,
      'name': submission.name,
      'email': submission.email,
      'subject': 'Nuevo proyecto: ${submission.name}',
      'message': _formatMessage(submission),
      if (submission.phone != null && submission.phone!.isNotEmpty) 'phone': submission.phone,
      if (submission.company != null && submission.company!.isNotEmpty) 'company': submission.company,
      if (submission.projectType != null && submission.projectType!.isNotEmpty) 'projectType': submission.projectType,
    };

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        final message = data['message'] as String? ?? 'Error al enviar el formulario';
        throw Web3FormsException(message);
      }
    } else if (response.statusCode == 429) {
      throw Web3FormsException('Demasiadas solicitudes. Intenta más tarde.');
    } else {
      throw Web3FormsException('Error al enviar el formulario. Código: ${response.statusCode}');
    }
  }

  String _formatMessage(ContactSubmission submission) {
    final buffer = StringBuffer();
    buffer.writeln('Nombre: ${submission.name}');
    buffer.writeln('Email: ${submission.email}');
    if (submission.phone != null && submission.phone!.isNotEmpty) {
      buffer.writeln('Teléfono: ${submission.phone}');
    }
    if (submission.company != null && submission.company!.isNotEmpty) {
      buffer.writeln('Empresa: ${submission.company}');
    }
    if (submission.projectType != null && submission.projectType!.isNotEmpty) {
      buffer.writeln('Tipo de proyecto: ${submission.projectType}');
    }
    buffer.writeln();
    buffer.write(submission.message);
    return buffer.toString();
  }
}

class Web3FormsException implements Exception {
  final String message;
  Web3FormsException(this.message);
  @override
  String toString() => message;
}
