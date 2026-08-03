import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_haptics.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';

class LegalSectionData {
  final String title;
  final List<InlineSpan> body;

  const LegalSectionData({required this.title, required this.body});
}

/// Pantalla legal in-app (texto sobre fondo negro; título en el app bar).
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final List<InlineSpan> intro;
  final List<LegalSectionData> sections;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.intro,
    required this.sections,
  });

  factory LegalDocumentScreen.terms() {
    return LegalDocumentScreen(
      title: 'Términos y Condiciones',
      intro: [
        const TextSpan(
          text:
              'Estos términos y condiciones se aplican a la aplicación ',
        ),
        const TextSpan(
          text: 'DevLokos',
          style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
        ),
        const TextSpan(
          text:
              ' (en adelante denominada la "Aplicación") desarrollada por ',
        ),
        const TextSpan(
          text: 'DevLokos Enterprise',
          style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
        ),
        const TextSpan(
          text: ' (en adelante denominado el "Proveedor de Servicios") como un servicio ',
        ),
        const TextSpan(
          text: 'Gratuito',
          style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
        ),
        const TextSpan(text: '.\n\n'),
        const TextSpan(
          text:
              'Al descargar o usar la Aplicación, aceptas los siguientes términos. Por favor, léelos cuidadosamente antes de usar la Aplicación.',
        ),
      ],
      sections: [
        LegalSectionData(
          title: 'Uso y Propiedad',
          body: const [
            TextSpan(
              text:
                  'No tienes permiso para copiar, modificar o distribuir la Aplicación, su código o cualquiera de su contenido (incluyendo podcasts, tutoriales o materiales de DevLokos Academy y DevLokos Empresarial).\n\nTodos los derechos de propiedad intelectual relacionados con la Aplicación permanecen como propiedad del Proveedor de Servicios.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Propósito de la Aplicación',
          body: const [
            TextSpan(
              text:
                  'La Aplicación DevLokos proporciona contenido educativo y de desarrollo profesional, incluyendo:\n\n',
            ),
            TextSpan(
              text: '• Podcasts: ',
              style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
            ),
            TextSpan(
              text: 'Entrevistas y discusiones con profesionales de la industria\n',
            ),
            TextSpan(
              text: '• Tutoriales: ',
              style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
            ),
            TextSpan(
              text:
                  'Experiencias de aprendizaje paso a paso en desarrollo móvil y de software\n',
            ),
            TextSpan(
              text: '• Academia: ',
              style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
            ),
            TextSpan(
              text: 'Programas de aprendizaje estructurados por DevLokos\n',
            ),
            TextSpan(
              text: '• Empresarial: ',
              style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
            ),
            TextSpan(
              text: 'Contenido enfocado en negocios y carrera profesional\n\n',
            ),
            TextSpan(
              text: 'La Aplicación está diseñada para inspirar a los usuarios a ',
            ),
            TextSpan(
              text: 'Aprender, Crear y Crecer',
              style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
            ),
            TextSpan(text: ' a través del ecosistema DevLokos.'),
          ],
        ),
        LegalSectionData(
          title: 'Responsabilidades y Restricciones',
          body: const [
            TextSpan(
              text:
                  'Eres responsable de mantener la seguridad de tu dispositivo y credenciales de acceso.\n\nNo intentes extraer, descompilar o modificar la Aplicación o sus servicios.\n\nEvita usar dispositivos con root o jailbreak, ya que esto puede comprometer la seguridad y causar que la Aplicación funcione incorrectamente.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Servicios de Terceros',
          body: const [
            TextSpan(
              text:
                  'La Aplicación utiliza servicios de terceros, incluyendo Google Analytics for Firebase, Firebase Authentication y YouTube Data API Services. Estos servicios están gobernados por sus propios términos y políticas.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Conexión a Internet',
          body: const [
            TextSpan(
              text:
                  'Se requiere una conexión a internet activa para usar la mayoría de las funciones.\n\nEl Proveedor de Servicios no es responsable de ningún cargo de datos o problemas de conectividad que puedan ocurrir mientras usas la Aplicación.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Responsabilidad',
          body: const [
            TextSpan(
              text:
                  'Si bien el Proveedor de Servicios se esfuerza por mantener el contenido preciso y actualizado, DevLokos no es responsable de ninguna pérdida, directa o indirecta, que surja del uso o dependencia del contenido de la Aplicación.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Actualizaciones y Terminación',
          body: const [
            TextSpan(
              text:
                  'El Proveedor de Servicios puede actualizar o modificar la Aplicación en cualquier momento. Aceptas instalar las actualizaciones cuando estén disponibles.\n\nEl Proveedor de Servicios también puede discontinuar la Aplicación sin previo aviso, y al terminar, debes cesar de usarla.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Cambios a Estos Términos',
          body: const [
            TextSpan(
              text:
                  'El Proveedor de Servicios puede actualizar estos Términos y Condiciones periódicamente. El uso continuado de la Aplicación implica la aceptación de todas las actualizaciones.\n\nEstos Términos son efectivos a partir del ',
            ),
            TextSpan(
              text: '19 de octubre de 2025',
              style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
            ),
            TextSpan(text: '.'),
          ],
        ),
        LegalSectionData(
          title: 'Contáctanos',
          body: const [
            TextSpan(
              text:
                  'Si tienes alguna pregunta o sugerencia sobre estos Términos y Condiciones, por favor contáctanos en info@devlokos.com.',
            ),
          ],
        ),
      ],
    );
  }

  factory LegalDocumentScreen.privacy() {
    return LegalDocumentScreen(
      title: 'Política de Privacidad',
      intro: [
        const TextSpan(text: 'Esta política de privacidad se aplica a la aplicación '),
        const TextSpan(
          text: 'DevLokos',
          style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
        ),
        const TextSpan(
          text:
              ' (en adelante denominada la "Aplicación") para dispositivos móviles que fue creada por ',
        ),
        const TextSpan(
          text: 'DevLokos Enterprise',
          style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
        ),
        const TextSpan(
          text: ' (en adelante denominado el "Proveedor de Servicios") como un servicio ',
        ),
        const TextSpan(
          text: 'Gratuito',
          style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
        ),
        const TextSpan(text: '. Este servicio está destinado a ser utilizado '),
        const TextSpan(
          text: '"TAL CUAL"',
          style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
        ),
        const TextSpan(text: '.'),
      ],
      sections: [
        LegalSectionData(
          title: 'Recopilación y Uso de Información',
          body: const [
            TextSpan(
              text:
                  'La Aplicación recopila información cuando la descargas y la utilizas. Esta información puede incluir datos como:\n\n• La dirección IP de tu dispositivo\n• Las páginas de la Aplicación que visitas, la hora y fecha de tu visita, y el tiempo dedicado\n• Analíticas de uso general\n• El sistema operativo de tu dispositivo\n\nLa Aplicación ',
            ),
            TextSpan(
              text: 'no',
              style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
            ),
            TextSpan(
              text:
                  ' recopila información precisa sobre la ubicación de tu dispositivo.\n\nEl Proveedor de Servicios puede usar la información que proporciones para contactarte con actualizaciones importantes, avisos requeridos y contenido promocional ocasional relacionado con DevLokos.\n\nPara una mejor experiencia, puede requerirse información de identificación personal como tu nombre y correo electrónico. La información será almacenada de forma segura y utilizada como se describe en esta política.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Acceso de Terceros',
          body: const [
            TextSpan(
              text:
                  'Solo los datos agregados y anonimizados se transmiten periódicamente a servicios externos para mejorar la Aplicación.\n\nLa Aplicación utiliza servicios de terceros (Google Analytics for Firebase, Firebase Authentication, YouTube Data API) con sus propias políticas de privacidad.\n\nEl Proveedor de Servicios puede divulgar información según lo requiera la ley, para proteger derechos/seguridad, o con socios de confianza bajo confidencialidad.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Derechos de Exclusión',
          body: const [
            TextSpan(
              text:
                  'Puedes detener toda la recopilación de información desinstalando la Aplicación mediante el proceso estándar de tu dispositivo o tienda de aplicaciones.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Política de Retención de Datos',
          body: const [
            TextSpan(
              text:
                  'El Proveedor de Servicios conservará los datos del usuario durante el tiempo que uses la Aplicación y un período razonable después. Para eliminar tu cuenta o datos, contáctanos en info@devlokos.com.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Privacidad de los Niños',
          body: const [
            TextSpan(
              text:
                  'La Aplicación no está dirigida a niños menores de 13 años. El Proveedor de Servicios no recopila conscientemente datos personales de niños menores de 13 años.\n\nSi descubrimos que un menor ha proporcionado información personal, la eliminaremos de inmediato. Si eres padre o tutor, contáctanos en info@devlokos.com.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Seguridad',
          body: const [
            TextSpan(
              text:
                  'El Proveedor de Servicios valora tu confianza y toma medidas apropiadas para salvaguardar tu información personal mediante servidores seguros, conexiones encriptadas y acceso limitado a los datos.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Cambios',
          body: const [
            TextSpan(
              text:
                  'Esta Política de Privacidad puede actualizarse de vez en cuando. El uso continuado de la Aplicación constituye la aceptación de cualquier revisión.\n\nEsta Política de Privacidad es efectiva a partir del ',
            ),
            TextSpan(
              text: '19 de octubre de 2025',
              style: TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primaryWhite),
            ),
            TextSpan(text: '.'),
          ],
        ),
        LegalSectionData(
          title: 'Tu Consentimiento',
          body: const [
            TextSpan(
              text:
                  'Al usar la Aplicación, consientes la recopilación y uso de información de acuerdo con esta Política de Privacidad.',
            ),
          ],
        ),
        LegalSectionData(
          title: 'Contáctanos',
          body: const [
            TextSpan(
              text:
                  'Si tienes alguna pregunta sobre esta Política de Privacidad, contáctanos en info@devlokos.com.',
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openEmail(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrandColors.cardBackground,
        title: const Text(
          'Abrir correo',
          style: TextStyle(color: BrandColors.primaryWhite),
        ),
        content: const Text(
          '¿Quieres abrir tu app de correo para escribir a info@devlokos.com?',
          style: TextStyle(color: BrandColors.grayMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: BrandColors.grayMedium),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Abrir',
              style: TextStyle(
                color: BrandColors.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final uri = Uri(
      scheme: 'mailto',
      path: 'info@devlokos.com',
      query: 'subject=Consulta legal DevLokos',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      appBar: CustomAppBar(
        title: title,
        showBackButton: true,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: BrandColors.primaryWhite.withValues(alpha: 0.85),
                    fontSize: 15,
                    height: 1.55,
                  ),
                  children: intro,
                ),
              ),
              for (final section in sections) ...[
                const SizedBox(height: 28),
                Text(
                  section.title,
                  style: const TextStyle(
                    color: BrandColors.primaryOrange,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: BrandColors.primaryWhite.withValues(alpha: 0.85),
                      fontSize: 15,
                      height: 1.55,
                    ),
                    children: section.body,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              GestureDetector(
                onTap: AppHaptics.wrap(() => _openEmail(context)),
                child: Text(
                  'info@devlokos.com',
                  style: TextStyle(
                    color: BrandColors.primaryOrange.withValues(alpha: 0.95),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
