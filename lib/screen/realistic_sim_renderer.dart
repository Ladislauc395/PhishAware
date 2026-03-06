import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'groq_service.dart';

class RealisticSimRenderer extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final Set<String> tappedElements;
  final ValueChanged<SuspiciousElement> onElementTap;

  const RealisticSimRenderer({
    super.key,
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedElements,
    required this.onElementTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (scenario.type) {
      case 'sms':
        return _RealSmsRenderer(
          scenario: scenario,
          revealed: revealed,
          inspectMode: inspectMode,
          tappedElements: tappedElements,
          onElementTap: onElementTap,
        );
      case 'whatsapp':
        return _RealWhatsAppRenderer(
          scenario: scenario,
          revealed: revealed,
          inspectMode: inspectMode,
          tappedElements: tappedElements,
          onElementTap: onElementTap,
        );
      case 'login_page':
        return _RealLoginRenderer(
          scenario: scenario,
          revealed: revealed,
          inspectMode: inspectMode,
          tappedElements: tappedElements,
          onElementTap: onElementTap,
        );
      case 'url':
        return _RealUrlRenderer(
          scenario: scenario,
          revealed: revealed,
          inspectMode: inspectMode,
          tappedElements: tappedElements,
          onElementTap: onElementTap,
        );
      default:
        return _RealEmailRenderer(
          scenario: scenario,
          revealed: revealed,
          inspectMode: inspectMode,
          tappedElements: tappedElements,
          onElementTap: onElementTap,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS — Logo real via Clearbit + fallback emoji
// ─────────────────────────────────────────────────────────────────────────────

/// Extrai domínio do endereço do remetente para buscar favicon real
String _domainFromAddress(String address) {
  final match = RegExp(r'@([\w\-\.]+)').firstMatch(address);
  if (match != null) return match.group(1) ?? '';
  if (address.contains('.')) return address;
  return '';
}

/// Retorna URL do logo via Clearbit Logo API (gratuito, sem autenticação)
String _logoUrl(AiScenario s) {
  if (s.logoUrl.isNotEmpty) return s.logoUrl;
  final domain = _domainFromAddress(s.senderAddress);
  if (domain.isEmpty) return '';
  return 'https://logo.clearbit.com/$domain';
}

/// Favicon de qualquer domínio via Google
String _faviconUrl(String domain) =>
    'https://www.google.com/s2/favicons?domain=$domain&sz=64';

class _BrandMark extends StatelessWidget {
  final AiScenario scenario;
  final double size;
  final bool inspectMode;
  final bool isTapped;
  final VoidCallback? onTap;

  const _BrandMark({
    required this.scenario,
    this.size = 44,
    this.inspectMode = false,
    this.isTapped = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = _logoUrl(scenario);
    Widget logo = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: url.isNotEmpty
          ? Image.network(url,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  _FallbackBrand(scenario: scenario, size: size),
              loadingBuilder: (_, child, prog) => prog == null
                  ? child
                  : _FallbackBrand(scenario: scenario, size: size))
          : _FallbackBrand(scenario: scenario, size: size),
    );

    if (inspectMode && onTap != null) {
      logo = GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.2 + 3),
            border: Border.all(
              color: isTapped
                  ? const Color(0xFFFFCC00)
                  : const Color(0xFFFFCC00).withAlpha(120),
              width: isTapped ? 2.5 : 1.5,
            ),
          ),
          child: logo,
        ),
      );
    }
    return logo;
  }
}

class _FallbackBrand extends StatelessWidget {
  final AiScenario scenario;
  final double size;
  const _FallbackBrand({required this.scenario, required this.size});

  static const _icons = {
    'paypal': ('PP', Color(0xFF009CDE)),
    'mbway': ('MB', Color(0xFFE4032E)),
    'cgd': ('CGD', Color(0xFF00923F)),
    'bpi': ('BPI', Color(0xFF003087)),
    'santander': ('SAN', Color(0xFFEC0000)),
    'millennium': ('BCP', Color(0xFF003399)),
    'amazon': ('a', Color(0xFFFF9900)),
    'netflix': ('N', Color(0xFFE50914)),
    'google': ('G', Color(0xFF4285F4)),
    'microsoft': ('M', Color(0xFF00A4EF)),
    'apple': ('', Color(0xFF555555)),
    'facebook': ('f', Color(0xFF1877F2)),
    'instagram': ('ig', Color(0xFFE1306C)),
    'twitter': ('X', Color(0xFF000000)),
    'dhl': ('DHL', Color(0xFFFFCC00)),
    'fedex': ('Fd', Color(0xFF4D148C)),
    'ctt': ('CTT', Color(0xFFE2001A)),
    'correos': ('C', Color(0xFFFFCC00)),
    'irs': ('IRS', Color(0xFF003366)),
    'at': ('AT', Color(0xFF00439C)),
    'sns': ('SNS', Color(0xFF006BB6)),
    'fidelidade': ('FID', Color(0xFF0066CC)),
  };

  @override
  Widget build(BuildContext context) {
    final brandLower = scenario.brand.toLowerCase();
    MapEntry<String, Color>? found;
    for (final e in _icons.entries) {
      if (brandLower.contains(e.key)) {
        found = MapEntry(e.value.$1, e.value.$2);
        break;
      }
    }
    final label = found?.key ?? scenario.brand.substring(0, 1).toUpperCase();
    final color = found?.value ?? scenario.brandColorParsed;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w800,
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ATTACHMENT WIDGETS — Ficheiros falsos (PDF, DOC, IMG)
// ─────────────────────────────────────────────────────────────────────────────

enum _AttachType { pdf, doc, xls, zip, img }

class _FakeAttachment extends StatelessWidget {
  final _AttachType type;
  final String name;
  final String size;
  final bool isPhishing;
  final bool revealed;
  final bool inspectMode;
  final bool isTapped;
  final VoidCallback? onTap;

  const _FakeAttachment({
    required this.type,
    required this.name,
    required this.size,
    required this.isPhishing,
    required this.revealed,
    this.inspectMode = false,
    this.isTapped = false,
    this.onTap,
  });

  Color get _typeColor {
    switch (type) {
      case _AttachType.pdf:
        return const Color(0xFFE53935);
      case _AttachType.doc:
        return const Color(0xFF1565C0);
      case _AttachType.xls:
        return const Color(0xFF2E7D32);
      case _AttachType.zip:
        return const Color(0xFFF9A825);
      case _AttachType.img:
        return const Color(0xFF6A1B9A);
    }
  }

  String get _typeLabel {
    switch (type) {
      case _AttachType.pdf:
        return 'PDF';
      case _AttachType.doc:
        return 'DOC';
      case _AttachType.xls:
        return 'XLS';
      case _AttachType.zip:
        return 'ZIP';
      case _AttachType.img:
        return 'IMG';
    }
  }

  IconData get _icon {
    switch (type) {
      case _AttachType.pdf:
        return Icons.picture_as_pdf_outlined;
      case _AttachType.doc:
        return Icons.description_outlined;
      case _AttachType.xls:
        return Icons.table_chart_outlined;
      case _AttachType.zip:
        return Icons.folder_zip_outlined;
      case _AttachType.img:
        return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dangerBorder = revealed && isPhishing;
    return GestureDetector(
      onTap: inspectMode ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: dangerBorder
              ? const Color(0xFFFF4444).withAlpha(10)
              : _typeColor.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dangerBorder
                ? const Color(0xFFFF4444).withAlpha(100)
                : inspectMode && isTapped
                    ? const Color(0xFFFFCC00)
                    : _typeColor.withAlpha(60),
            width: isTapped ? 2 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _typeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _typeColor.withAlpha(80)),
            ),
            child: Icon(_icon, color: _typeColor, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: _typeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_typeLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              Text(size,
                  style:
                      GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
              if (dangerBorder) ...[
                const SizedBox(width: 6),
                const Icon(Icons.warning_amber,
                    color: Color(0xFFFF4444), size: 12),
              ],
            ]),
          ]),
          const SizedBox(width: 10),
          Icon(Icons.download_outlined, color: Colors.white38, size: 18),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE-AS-PHISHING — Simulação de mensagem onde TODO o conteúdo é uma imagem
// (técnica real usada para evitar filtros de texto)
// ─────────────────────────────────────────────────────────────────────────────

class _ImagePhishingBanner extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final bool isTapped;
  final VoidCallback? onTap;

  const _ImagePhishingBanner({
    required this.scenario,
    required this.revealed,
    this.inspectMode = false,
    this.isTapped = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Simula visualmente um email onde o corpo é uma imagem (não texto)
    // O utilizador tem de perceber que é imagem, não texto real
    final s = scenario;
    final brand = s.brand;
    final brandColor = s.brandColorParsed;

    return GestureDetector(
      onTap: inspectMode ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: revealed && s.isPhishing
                ? const Color(0xFFFF4444).withAlpha(150)
                : inspectMode && isTapped
                    ? const Color(0xFFFFCC00)
                    : Colors.white.withAlpha(15),
            width: isTapped ? 2.5 : 1.5,
          ),
          boxShadow: revealed && s.isPhishing
              ? [
                  BoxShadow(
                      color: const Color(0xFFFF4444).withAlpha(40),
                      blurRadius: 12)
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: _FakeImageContent(
              scenario: s, brandColor: brandColor, brand: brand),
        ),
      ),
    );
  }
}

/// Simula visualmente uma imagem de phishing desenhada com Flutter Canvas
/// (representa fielmente o que um utilizador veria num email real com imagem)
class _FakeImageContent extends StatelessWidget {
  final AiScenario scenario;
  final Color brandColor;
  final String brand;

  const _FakeImageContent({
    required this.scenario,
    required this.brandColor,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Stack(children: [
        // Marca d'água "IMAGEM" — dica visual para o utilizador
        Positioned.fill(
          child: Center(
            child: Transform.rotate(
              angle: -0.3,
              child: Text('IMAGEM',
                  style: TextStyle(
                    color: Colors.black.withAlpha(8),
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  )),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Header da marca dentro da "imagem"
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _BrandMark(scenario: s, size: 32),
              const SizedBox(width: 8),
              Text(brand.toUpperCase(),
                  style: TextStyle(
                      color: brandColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ]),
            const SizedBox(height: 16),
            // Banner vermelho de urgência
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              color: const Color(0xFFD32F2F),
              child: Text('⚠ AÇÃO URGENTE NECESSÁRIA ⚠',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 14),
            Text(s.subject,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              'A tua conta foi suspensa temporariamente.\n'
              'Clica no botão abaixo para verificar a tua identidade\n'
              'e reativar o acesso nas próximas 24 horas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.black54, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 16),
            // Botão CTA dentro da imagem
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: brandColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(s.ctaText.isNotEmpty ? s.ctaText : 'VERIFICAR CONTA',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            // URL suspeita visível dentro da imagem
            Text(s.ctaUrl,
                style: GoogleFonts.jetBrainsMono(
                    color: Colors.black38, fontSize: 9),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            // Footer da "imagem"
            Divider(color: Colors.black.withAlpha(20)),
            const SizedBox(height: 6),
            Text(
                '© ${DateTime.now().year} $brand — Todos os direitos reservados',
                style: GoogleFonts.inter(color: Colors.black26, fontSize: 9)),
            Text('Clicando confirmas os nossos Termos de Serviço',
                style: GoogleFonts.inter(color: Colors.black26, fontSize: 9)),
          ]),
        ),
        // Overlay de "não é texto" — pulsating indicator
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withAlpha(220),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.image, color: Colors.white, size: 10),
              const SizedBox(width: 4),
              Text('IMG',
                  style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAPPABLE SPAN (reutilizado de ai_lab_screen)
// ─────────────────────────────────────────────────────────────────────────────
class _TappableSpan extends StatelessWidget {
  final SuspiciousElement element;
  final bool inspectMode;
  final bool isTapped;
  final bool revealed;
  final VoidCallback onTap;
  final Widget child;

  const _TappableSpan({
    required this.element,
    required this.inspectMode,
    required this.isTapped,
    required this.revealed,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!inspectMode && !revealed) return child;
    return GestureDetector(
      onTap: inspectMode && !revealed ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: revealed
              ? (element.isSuspicious
                  ? const Color(0xFFFF4444).withAlpha(30)
                  : const Color(0xFF00FF88).withAlpha(20))
              : isTapped
                  ? const Color(0xFFFFCC00).withAlpha(30)
                  : const Color(0xFFFFCC00).withAlpha(12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: revealed
                ? (element.isSuspicious
                    ? const Color(0xFFFF4444).withAlpha(100)
                    : const Color(0xFF00FF88).withAlpha(80))
                : isTapped
                    ? const Color(0xFFFFCC00)
                    : const Color(0xFFFFCC00).withAlpha(80),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMAIL RENDERER — Ultra-realista com logo, anexo, imagem de phishing
// ─────────────────────────────────────────────────────────────────────────────

class _RealEmailRenderer extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final Set<String> tappedElements;
  final ValueChanged<SuspiciousElement> onElementTap;

  const _RealEmailRenderer({
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedElements,
    required this.onElementTap,
  });

  SuspiciousElement? _el(String id) =>
      scenario.suspiciousElements.where((e) => e.id == id).firstOrNull;

  /// Decide tipo de anexo baseado no brand/assunto
  _AttachType _attachTypeFor(AiScenario s) {
    final sub = s.subject.toLowerCase();
    if (sub.contains('fatura') ||
        sub.contains('invoice') ||
        sub.contains('comprov')) {
      return _AttachType.pdf;
    }
    if (sub.contains('contrat') ||
        sub.contains('termo') ||
        sub.contains('document')) {
      return _AttachType.doc;
    }
    if (sub.contains('extrato') ||
        sub.contains('relatório') ||
        sub.contains('excel')) {
      return _AttachType.xls;
    }
    return _AttachType.pdf;
  }

  String _attachName(AiScenario s) {
    final sub = s.subject.toLowerCase();
    if (sub.contains('fatura')) return 'Fatura_${DateTime.now().year}.pdf';
    if (sub.contains('extrato'))
      return 'Extrato_Conta_${DateTime.now().month}.pdf';
    if (sub.contains('contrat')) return 'Contrato_Servico.docx';
    if (sub.contains('comprov')) return 'Comprovativo_Pagamento.pdf';
    return '${s.brand.replaceAll(' ', '_')}_Documento.pdf';
  }

  /// Verifica se o cenário deve usar "imagem-como-corpo" em vez de texto
  bool _isImageBasedPhishing(AiScenario s) {
    final body = s.body.toLowerCase();
    // Cenários onde a técnica image-as-content é usada
    return s.isPhishing &&
        (body.contains('imagem') ||
            body.contains('banner') ||
            body.length < 80 ||
            s.difficulty == 'hard');
  }

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    final brandColor = s.brandColorParsed;
    final hasAttachment = s.isPhishing && s.difficulty != 'easy';
    final useImageBody = _isImageBasedPhishing(s);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: revealed
              ? s.isPhishing
                  ? const Color(0xFFFF4444).withAlpha(120)
                  : const Color(0xFF00FF88).withAlpha(120)
              : Colors.white.withAlpha(20),
          width: revealed ? 1.5 : 1,
        ),
        boxShadow: revealed && s.isPhishing
            ? [
                BoxShadow(
                    color: const Color(0xFFFF4444).withAlpha(20),
                    blurRadius: 24)
              ]
            : [],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Barra de email client ──
        _EmailClientBar(scenario: s, revealed: revealed),

        // ── Header do email ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Assunto
            Builder(builder: (_) {
              final el = _el('subject');
              final w = Text(s.subject,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700));
              return el != null
                  ? _TappableSpan(
                      element: el,
                      inspectMode: inspectMode,
                      isTapped: tappedElements.contains(el.id),
                      revealed: revealed,
                      onTap: () => onElementTap(el),
                      child: w)
                  : w;
            }),
            const SizedBox(height: 12),

            // Remetente com logo real
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _BrandMark(
                scenario: s,
                size: 42,
                inspectMode: inspectMode,
                isTapped: tappedElements.contains('logo'),
                onTap: () {
                  final el = _el('logo');
                  if (el != null) onElementTap(el);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.senderName,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Builder(builder: (_) {
                        final el = _el('sender');
                        final w = Row(children: [
                          const Text('<',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 10)),
                          Expanded(
                            child: Text(s.senderAddress,
                                style: GoogleFonts.jetBrainsMono(
                                    color: revealed && s.isPhishing
                                        ? const Color(0xFFFF6B6B)
                                        : Colors.white38,
                                    fontSize: 10),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const Text('>',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 10)),
                        ]);
                        return el != null
                            ? _TappableSpan(
                                element: el,
                                inspectMode: inspectMode,
                                isTapped: tappedElements.contains(el.id),
                                revealed: revealed,
                                onTap: () => onElementTap(el),
                                child: w)
                            : w;
                      }),
                      const SizedBox(height: 2),
                      Text('Para: eu@meumail.com',
                          style: GoogleFonts.inter(
                              color: Colors.white24, fontSize: 10)),
                    ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(s.timestamp,
                    style:
                        GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
                if (hasAttachment) ...[
                  const SizedBox(height: 4),
                  const Icon(Icons.attach_file,
                      color: Colors.white38, size: 14),
                ],
              ]),
            ]),

            const SizedBox(height: 14),
            Divider(color: Colors.white.withAlpha(12)),
            const SizedBox(height: 12),
          ]),
        ),

        // ── Corpo do email ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Preview text (se existir)
            if (s.previewText.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: brandColor.withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: brandColor.withAlpha(40)),
                ),
                child: Text(s.previewText,
                    style: GoogleFonts.inter(
                        color: brandColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 12),
            ],

            // CORPO: texto normal OU imagem-como-phishing
            if (useImageBody) ...[
              // Label de alerta educativo (só aparece após reveal)
              if (revealed && s.isPhishing)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFFF6B35).withAlpha(80)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.image, color: Color(0xFFFF6B35), size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(
                      '⚠ Todo o conteúdo é uma IMAGEM — técnica para evitar filtros de texto',
                      style: GoogleFonts.inter(
                          color: const Color(0xFFFF6B35), fontSize: 10),
                    )),
                  ]),
                ),
              _ImagePhishingBanner(
                scenario: s,
                revealed: revealed,
                inspectMode: inspectMode,
                isTapped: tappedElements.contains('body_image'),
                onTap: () {
                  final el =
                      _el('body_image') ?? _el('body_text') ?? _el('cta_url');
                  if (el != null) onElementTap(el);
                },
              ),
            ] else ...[
              // Texto do corpo
              Builder(builder: (_) {
                final el = _el('body_text');
                final w = Text(s.body,
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 13, height: 1.65));
                return el != null
                    ? _TappableSpan(
                        element: el,
                        inspectMode: inspectMode,
                        isTapped: tappedElements.contains(el.id),
                        revealed: revealed,
                        onTap: () => onElementTap(el),
                        child: w)
                    : w;
              }),
            ],

            const SizedBox(height: 18),

            // Botão CTA
            if (s.ctaText.isNotEmpty && !useImageBody)
              Builder(builder: (_) {
                final el = _el('cta_url') ?? _el('cta');
                final btn = _RealCtaButton(
                  text: s.ctaText,
                  url: s.ctaUrl,
                  brandColor: brandColor,
                  isPhishing: s.isPhishing,
                  revealed: revealed,
                );
                return el != null
                    ? _TappableSpan(
                        element: el,
                        inspectMode: inspectMode,
                        isTapped: tappedElements.contains(el.id),
                        revealed: revealed,
                        onTap: () => onElementTap(el),
                        child: btn)
                    : btn;
              }),

            // URL visível após reveal
            if (s.ctaUrl.isNotEmpty && revealed) ...[
              const SizedBox(height: 8),
              _UrlRevealBar(url: s.ctaUrl, isPhishing: s.isPhishing),
            ],

            const SizedBox(height: 16),

            // ── ANEXO FALSO ──
            if (hasAttachment)
              Builder(builder: (_) {
                final el = _el('attachment');
                final attach = _FakeAttachment(
                  type: _attachTypeFor(s),
                  name: _attachName(s),
                  size: '${(s.brand.length * 17 + 128) % 800 + 200} KB',
                  isPhishing: s.isPhishing,
                  revealed: revealed,
                  inspectMode: inspectMode,
                  isTapped: tappedElements.contains('attachment'),
                  onTap: () {
                    if (el != null) onElementTap(el);
                  },
                );
                return attach;
              }),

            const SizedBox(height: 16),

            // Footer do email
            _EmailFooter(
                scenario: s, brandColor: brandColor, revealed: revealed),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMAIL HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _EmailClientBar extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  const _EmailClientBar({required this.scenario, required this.revealed});

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161E2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(12))),
      ),
      child: Row(children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(30),
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(30),
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(30),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.mail_outline, color: Colors.white38, size: 14),
        const SizedBox(width: 6),
        Text('Gmail',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
        const Spacer(),
        if (revealed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: s.isPhishing
                  ? const Color(0xFFFF4444).withAlpha(30)
                  : const Color(0xFF00FF88).withAlpha(20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              s.isPhishing ? '⚠ PHISHING DETETADO' : '✓ LEGÍTIMO',
              style: GoogleFonts.jetBrainsMono(
                  color: s.isPhishing
                      ? const Color(0xFFFF4444)
                      : const Color(0xFF00FF88),
                  fontSize: 8,
                  fontWeight: FontWeight.w700),
            ),
          ),
        const SizedBox(width: 8),
        Text('🔒 TLS',
            style:
                GoogleFonts.jetBrainsMono(color: Colors.white24, fontSize: 9)),
      ]),
    );
  }
}

class _RealCtaButton extends StatelessWidget {
  final String text, url;
  final Color brandColor;
  final bool isPhishing, revealed;
  const _RealCtaButton({
    required this.text,
    required this.url,
    required this.brandColor,
    required this.isPhishing,
    required this.revealed,
  });

  @override
  Widget build(BuildContext context) {
    final danger = revealed && isPhishing;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: danger
              ? [
                  const Color(0xFFFF4444).withAlpha(80),
                  const Color(0xFFFF6B35).withAlpha(80)
                ]
              : [brandColor.withAlpha(200), brandColor.withAlpha(160)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: danger
              ? const Color(0xFFFF4444).withAlpha(150)
              : brandColor.withAlpha(100),
        ),
        boxShadow: [
          BoxShadow(
            color:
                (danger ? const Color(0xFFFF4444) : brandColor).withAlpha(40),
            blurRadius: 12,
            spreadRadius: -3,
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (danger)
          const Icon(Icons.warning_amber, color: Color(0xFFFF6B6B), size: 14),
        if (danger) const SizedBox(width: 6),
        Text(text,
            style: GoogleFonts.inter(
                color: danger ? const Color(0xFFFF6B6B) : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward,
            size: 13, color: danger ? const Color(0xFFFF6B6B) : Colors.white70),
      ]),
    );
  }
}

class _UrlRevealBar extends StatelessWidget {
  final String url;
  final bool isPhishing;
  const _UrlRevealBar({required this.url, required this.isPhishing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isPhishing
            ? const Color(0xFFFF4444).withAlpha(12)
            : const Color(0xFF00FF88).withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPhishing
              ? const Color(0xFFFF4444).withAlpha(60)
              : const Color(0xFF00FF88).withAlpha(50),
        ),
      ),
      child: Row(children: [
        Icon(
          isPhishing ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          color: isPhishing ? const Color(0xFFFF4444) : const Color(0xFF00FF88),
          size: 13,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(url,
              style: GoogleFonts.jetBrainsMono(
                  color: isPhishing
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF00FF88),
                  fontSize: 10),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

class _EmailFooter extends StatelessWidget {
  final AiScenario scenario;
  final Color brandColor;
  final bool revealed;
  const _EmailFooter(
      {required this.scenario,
      required this.brandColor,
      required this.revealed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _BrandMark(scenario: scenario, size: 24),
        const SizedBox(height: 8),
        Text(scenario.brand,
            style: GoogleFonts.inter(
                color: brandColor, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Este email foi enviado para tu@meumail.com\nSe não reconheces esta atividade, ignora esta mensagem.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              color: Colors.white24, fontSize: 9, height: 1.5),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Cancelar subscrição',
              style: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 9,
                  decoration: TextDecoration.underline)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child:
                Text('·', style: TextStyle(color: Colors.white24, fontSize: 9)),
          ),
          Text('Política de Privacidade',
              style: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 9,
                  decoration: TextDecoration.underline)),
        ]),
        if (revealed && scenario.isPhishing) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4444).withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFF4444).withAlpha(60)),
            ),
            child: Text(
              '🚩 Footer genérico — sem endereço físico da empresa (sinal de phishing)',
              style: GoogleFonts.inter(
                  color: const Color(0xFFFF6B6B), fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMS RENDERER — Ultra-realista estilo iOS/Android
// ─────────────────────────────────────────────────────────────────────────────

class _RealSmsRenderer extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final Set<String> tappedElements;
  final ValueChanged<SuspiciousElement> onElementTap;

  const _RealSmsRenderer({
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedElements,
    required this.onElementTap,
  });

  SuspiciousElement? _el(String id) =>
      scenario.suspiciousElements.where((e) => e.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: revealed
              ? s.isPhishing
                  ? const Color(0xFFFF4444).withAlpha(100)
                  : const Color(0xFF00FF88).withAlpha(100)
              : Colors.white.withAlpha(15),
        ),
      ),
      child: Column(children: [
        // ── Status bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          decoration: const BoxDecoration(
            color: Color(0xFF000000),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Text(timeStr,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.signal_cellular_alt,
                color: Colors.white, size: 13),
            const SizedBox(width: 5),
            const Icon(Icons.wifi, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(children: [
                Container(
                  width: 14,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ]),
            ),
          ]),
        ),

        // ── Navigation bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            border:
                Border(bottom: BorderSide(color: Colors.white.withAlpha(10))),
          ),
          child: Row(children: [
            Text('< Mensagens',
                style: GoogleFonts.inter(
                    color: const Color(0xFF007AFF), fontSize: 14)),
            const Spacer(),
            _BrandMark(
              scenario: s,
              size: 36,
              inspectMode: inspectMode,
              isTapped: tappedElements.contains('logo'),
              onTap: () {
                final el = _el('logo');
                if (el != null) onElementTap(el);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(builder: (_) {
                      final el = _el('sender');
                      final w = Text(s.senderName,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600));
                      return el != null
                          ? _TappableSpan(
                              element: el,
                              inspectMode: inspectMode,
                              isTapped: tappedElements.contains(el.id),
                              revealed: revealed,
                              onTap: () => onElementTap(el),
                              child: w)
                          : w;
                    }),
                    Text(s.phoneNumber ?? s.senderAddress,
                        style: GoogleFonts.jetBrainsMono(
                            color: revealed && s.isPhishing
                                ? const Color(0xFFFF6B6B)
                                : Colors.white38,
                            fontSize: 10)),
                  ]),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.info_outline, color: Color(0xFF007AFF), size: 20),
          ]),
        ),

        // ── Mensagem ──
        Container(
          color: const Color(0xFF000000),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Data/hora
            Center(
              child: Text(s.timestamp,
                  style:
                      GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
            ),
            const SizedBox(height: 12),

            // Bolha de mensagem
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(builder: (_) {
                        final el = _el('body_text');
                        final w = Text(s.body,
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.5));
                        return el != null
                            ? _TappableSpan(
                                element: el,
                                inspectMode: inspectMode,
                                isTapped: tappedElements.contains(el.id),
                                revealed: revealed,
                                onTap: () => onElementTap(el),
                                child: w)
                            : w;
                      }),
                      if (s.ctaUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Builder(builder: (_) {
                          final el = _el('cta_url');
                          final w = Text(s.ctaUrl,
                              style: GoogleFonts.jetBrainsMono(
                                  color: revealed && s.isPhishing
                                      ? const Color(0xFFFF6B6B)
                                      : const Color(0xFF007AFF),
                                  fontSize: 11),
                              overflow: TextOverflow.ellipsis);
                          return el != null
                              ? _TappableSpan(
                                  element: el,
                                  inspectMode: inspectMode,
                                  isTapped: tappedElements.contains(el.id),
                                  revealed: revealed,
                                  onTap: () => onElementTap(el),
                                  child: w)
                              : w;
                        }),
                      ],
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text(timeStr,
                            style: GoogleFonts.inter(
                                color: Colors.white24, fontSize: 9)),
                      ]),
                    ]),
              ),
            ),

            // Aviso de phishing (após reveal)
            if (revealed && s.isPhishing) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4444).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: const Color(0xFFFF4444).withAlpha(60)),
                ),
                child: Row(children: [
                  const Text('🚨', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                    'Número desconhecido a enviar link. Operadoras legítimas não pedem dados via SMS.',
                    style: GoogleFonts.inter(
                        color: const Color(0xFFFF6B6B),
                        fontSize: 10,
                        height: 1.4),
                  )),
                ]),
              ),
            ],
          ]),
        ),

        // ── Input bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Row(children: [
            const Icon(Icons.add_circle_outline,
                color: Color(0xFF007AFF), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Mensagem de texto',
                    style:
                        GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.mic, color: Color(0xFF007AFF), size: 22),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WHATSAPP RENDERER — Com suporte a imagem de phishing e logo real
// ─────────────────────────────────────────────────────────────────────────────

class _RealWhatsAppRenderer extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final Set<String> tappedElements;
  final ValueChanged<SuspiciousElement> onElementTap;

  const _RealWhatsAppRenderer({
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedElements,
    required this.onElementTap,
  });

  SuspiciousElement? _el(String id) =>
      scenario.suspiciousElements.where((e) => e.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    const waGreen = Color(0xFF25D366);
    const waDark = Color(0xFF111B21);
    const waBubble = Color(0xFF1F2C34);
    final hasImageContent = s.isPhishing && s.difficulty == 'hard';
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: waDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: revealed
              ? s.isPhishing
                  ? const Color(0xFFFF4444).withAlpha(100)
                  : waGreen.withAlpha(100)
              : Colors.white.withAlpha(20),
        ),
      ),
      child: Column(children: [
        // ── WhatsApp Header ──
        Container(
          padding: const EdgeInsets.fromLTRB(10, 14, 16, 14),
          decoration: const BoxDecoration(
            color: Color(0xFF1F2C34),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            const Icon(Icons.arrow_back, color: waGreen, size: 20),
            const SizedBox(width: 8),
            _BrandMark(
              scenario: s,
              size: 38,
              inspectMode: inspectMode,
              isTapped: tappedElements.contains('logo'),
              onTap: () {
                final el = _el('logo');
                if (el != null) onElementTap(el);
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(builder: (_) {
                      final el = _el('sender');
                      final w = Text(s.senderName,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600));
                      return el != null
                          ? _TappableSpan(
                              element: el,
                              inspectMode: inspectMode,
                              isTapped: tappedElements.contains(el.id),
                              revealed: revealed,
                              onTap: () => onElementTap(el),
                              child: w)
                          : w;
                    }),
                    Text(s.phoneNumber ?? s.senderAddress,
                        style: GoogleFonts.inter(
                            color: revealed && s.isPhishing
                                ? const Color(0xFFFF6B6B)
                                : Colors.white38,
                            fontSize: 11)),
                  ]),
            ),
            const Icon(Icons.videocam, color: waGreen, size: 20),
            const SizedBox(width: 16),
            const Icon(Icons.call, color: waGreen, size: 18),
            const SizedBox(width: 8),
            const Icon(Icons.more_vert, color: Colors.white54, size: 18),
          ]),
        ),

        // ── Chat area ──
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF0B141A),
          child: Column(children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF182229),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(s.timestamp,
                    style:
                        GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                decoration: BoxDecoration(
                  color: waBubble,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Se hard difficulty: imagem dentro da bolha
                      if (hasImageContent)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: _FakeImageContent(
                            scenario: s,
                            brandColor: s.brandColorParsed,
                            brand: s.brand,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.senderName,
                                  style: GoogleFonts.inter(
                                      color: waGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              if (!hasImageContent)
                                Builder(builder: (_) {
                                  final el = _el('body_text');
                                  final w = Text(s.body,
                                      style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          height: 1.5));
                                  return el != null
                                      ? _TappableSpan(
                                          element: el,
                                          inspectMode: inspectMode,
                                          isTapped:
                                              tappedElements.contains(el.id),
                                          revealed: revealed,
                                          onTap: () => onElementTap(el),
                                          child: w)
                                      : w;
                                }),
                              if (s.ctaUrl.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Builder(builder: (_) {
                                  final el = _el('cta_url');
                                  final w = Text(s.ctaUrl,
                                      style: GoogleFonts.jetBrainsMono(
                                          color: revealed && s.isPhishing
                                              ? const Color(0xFFFF6B6B)
                                              : const Color(0xFF53BDEB),
                                          fontSize: 11),
                                      overflow: TextOverflow.ellipsis);
                                  return el != null
                                      ? _TappableSpan(
                                          element: el,
                                          inspectMode: inspectMode,
                                          isTapped:
                                              tappedElements.contains(el.id),
                                          revealed: revealed,
                                          onTap: () => onElementTap(el),
                                          child: w)
                                      : w;
                                }),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(timeStr,
                                        style: GoogleFonts.inter(
                                            color: Colors.white24,
                                            fontSize: 9)),
                                  ]),
                            ]),
                      ),
                    ]),
              ),
            ),
          ]),
        ),

        // ── Input bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF1F2C34),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3942),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text('Mensagem',
                    style:
                        GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration:
                  const BoxDecoration(shape: BoxShape.circle, color: waGreen),
              child: const Icon(Icons.mic, color: Colors.white, size: 18),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN PAGE RENDERER — Ultra-realista com logo real e URL bar
// ─────────────────────────────────────────────────────────────────────────────

class _RealLoginRenderer extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final Set<String> tappedElements;
  final ValueChanged<SuspiciousElement> onElementTap;

  const _RealLoginRenderer({
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedElements,
    required this.onElementTap,
  });

  SuspiciousElement? _el(String id) =>
      scenario.suspiciousElements.where((e) => e.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    final brandColor = s.brandColorParsed;
    final isInsecure = revealed && s.isPhishing;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isInsecure
              ? const Color(0xFFFF4444).withAlpha(150)
              : Colors.white.withAlpha(20),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 20,
              spreadRadius: -4),
        ],
      ),
      child: Column(children: [
        // ── Browser chrome ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border:
                Border(bottom: BorderSide(color: Colors.black.withAlpha(20))),
          ),
          child: Column(children: [
            // Tab bar
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4)
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _BrandMark(scenario: s, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    s.pageTitle?.split(' ').take(2).join(' ') ?? s.brand,
                    style: const TextStyle(color: Colors.black87, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.close, size: 10, color: Colors.black38),
                ]),
              ),
              const Spacer(),
            ]),
            const SizedBox(height: 8),
            // URL bar
            Row(children: [
              const Icon(Icons.arrow_back, size: 16, color: Colors.black38),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 16, color: Colors.black26),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isInsecure
                          ? const Color(0xFFFF4444).withAlpha(150)
                          : Colors.black.withAlpha(30),
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      isInsecure ? Icons.lock_open : Icons.lock,
                      size: 11,
                      color: isInsecure
                          ? const Color(0xFFCC0000)
                          : const Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Builder(builder: (_) {
                        final el = _el('cta_url') ?? _el('page_url');
                        final w = Text(
                          s.ctaUrl,
                          style: TextStyle(
                              color: isInsecure
                                  ? const Color(0xFFCC0000)
                                  : Colors.black87,
                              fontSize: 10,
                              fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis,
                        );
                        return el != null
                            ? _TappableSpan(
                                element: el,
                                inspectMode: inspectMode,
                                isTapped: tappedElements.contains(el.id),
                                revealed: revealed,
                                onTap: () => onElementTap(el),
                                child: w)
                            : w;
                      }),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.refresh, size: 16, color: Colors.black38),
            ]),
          ]),
        ),

        // ── Page content ──
        Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(children: [
            _BrandMark(
              scenario: s,
              size: 64,
              inspectMode: inspectMode,
              isTapped: tappedElements.contains('logo'),
              onTap: () {
                final el = _el('logo');
                if (el != null) onElementTap(el);
              },
            ),
            const SizedBox(height: 10),
            Builder(builder: (_) {
              final el = _el('logo') ?? _el('header');
              final w = Text(s.logoAltText,
                  style: TextStyle(
                      color: brandColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800));
              return el != null
                  ? _TappableSpan(
                      element: el,
                      inspectMode: inspectMode,
                      isTapped: tappedElements.contains(el.id),
                      revealed: revealed,
                      onTap: () => onElementTap(el),
                      child: w)
                  : w;
            }),
            const SizedBox(height: 4),
            Text(s.pageTitle ?? 'Iniciar Sessão',
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 24),
            // Form fields
            ...s.formFields.map((field) {
              final isPwd = field.toLowerCase().contains('senha') ||
                  field.toLowerCase().contains('password');
              final isSuspect = s.formFields.length > 2;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: revealed && s.isPhishing && isSuspect
                        ? const Color(0xFFFF4444).withAlpha(100)
                        : const Color(0xFFDDDDDD),
                  ),
                ),
                child: Row(children: [
                  Icon(isPwd ? Icons.lock_outline : Icons.person_outline,
                      size: 16, color: Colors.black38),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(field,
                          style: const TextStyle(
                              color: Colors.black38, fontSize: 13))),
                ]),
              );
            }),
            const SizedBox(height: 4),
            // Submit button
            Builder(builder: (_) {
              final el = _el('cta');
              final btn = Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isInsecure ? const Color(0xFFCC0000) : brandColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                    child: Text(
                  isInsecure
                      ? '⚠ Página Falsa!'
                      : (s.ctaText.isNotEmpty ? s.ctaText : 'Entrar'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                )),
              );
              return el != null
                  ? _TappableSpan(
                      element: el,
                      inspectMode: inspectMode,
                      isTapped: tappedElements.contains(el.id),
                      revealed: revealed,
                      onTap: () => onElementTap(el),
                      child: btn)
                  : btn;
            }),
            if (isInsecure) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4444).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFFFF4444).withAlpha(60)),
                ),
                child: Text(
                  '🚩 URL não corresponde ao domínio oficial — as tuas credenciais seriam roubadas',
                  style:
                      const TextStyle(color: Color(0xFFCC0000), fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// URL RENDERER — Análise detalhada de URL suspeita
// ─────────────────────────────────────────────────────────────────────────────

class _RealUrlRenderer extends StatelessWidget {
  final AiScenario scenario;
  final bool revealed;
  final bool inspectMode;
  final Set<String> tappedElements;
  final ValueChanged<SuspiciousElement> onElementTap;

  const _RealUrlRenderer({
    required this.scenario,
    required this.revealed,
    required this.inspectMode,
    required this.tappedElements,
    required this.onElementTap,
  });

  SuspiciousElement? _el(String id) =>
      scenario.suspiciousElements.where((e) => e.id == id).firstOrNull;

  /// Analisa partes da URL para highlighting
  List<_UrlPart> _analyzeUrl(String url, bool isPhishing) {
    final parts = <_UrlPart>[];
    try {
      final u = Uri.parse(url);
      final host = u.host;
      final domain = _extractDomain(host);

      if (u.scheme.isNotEmpty) {
        parts.add(_UrlPart(u.scheme + '://',
            isPhishing ? _UrlPartType.danger : _UrlPartType.safe));
      }
      if (host.isNotEmpty) {
        // Subdomain
        final hostParts = host.split('.');
        if (hostParts.length > 2) {
          final sub = hostParts.take(hostParts.length - 2).join('.');
          parts.add(_UrlPart(sub + '.',
              isPhishing ? _UrlPartType.warning : _UrlPartType.neutral));
        }
        // Domain
        parts.add(_UrlPart(
            domain, isPhishing ? _UrlPartType.danger : _UrlPartType.safe));
      }
      if (u.path.isNotEmpty && u.path != '/') {
        parts.add(_UrlPart(u.path, _UrlPartType.neutral));
      }
    } catch (_) {
      parts.add(_UrlPart(url, _UrlPartType.neutral));
    }
    return parts;
  }

  String _extractDomain(String host) {
    final parts = host.split('.');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2]}.${parts.last}';
    }
    return host;
  }

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    final urlParts = _analyzeUrl(s.ctaUrl, s.isPhishing);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: revealed
              ? s.isPhishing
                  ? const Color(0xFFFF4444).withAlpha(120)
                  : const Color(0xFF00FF88).withAlpha(120)
              : Colors.white.withAlpha(20),
        ),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161E2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border:
                Border(bottom: BorderSide(color: Colors.white.withAlpha(10))),
          ),
          child: Row(children: [
            _BrandMark(scenario: s, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.brand,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Text('Análise de Link',
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 10)),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: s.isPhishing
                    ? const Color(0xFFFF4444).withAlpha(20)
                    : const Color(0xFF00FF88).withAlpha(20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: s.isPhishing
                      ? const Color(0xFFFF4444).withAlpha(60)
                      : const Color(0xFF00FF88).withAlpha(60),
                ),
              ),
              child: Text(
                s.isPhishing ? '🔴 SUSPEITO' : '🟢 SEGURO',
                style: GoogleFonts.jetBrainsMono(
                    color: s.isPhishing
                        ? const Color(0xFFFF4444)
                        : const Color(0xFF00FF88),
                    fontSize: 9,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),

        // Body
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Contexto
            Text(s.body,
                style: GoogleFonts.inter(
                    color: Colors.white70, fontSize: 13, height: 1.5)),
            const SizedBox(height: 16),

            // URL com highlighting
            Text('Link recebido:',
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Builder(builder: (_) {
              final el = _el('cta_url');
              Widget urlWidget = Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161E2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: revealed && s.isPhishing
                        ? const Color(0xFFFF4444).withAlpha(80)
                        : Colors.white.withAlpha(15),
                  ),
                ),
                child: Wrap(
                    children:
                        urlParts.map((p) => _UrlPartChip(part: p)).toList()),
              );
              return el != null
                  ? _TappableSpan(
                      element: el,
                      inspectMode: inspectMode,
                      isTapped: tappedElements.contains(el.id),
                      revealed: revealed,
                      onTap: () => onElementTap(el),
                      child: urlWidget)
                  : urlWidget;
            }),

            if (revealed) ...[
              const SizedBox(height: 16),
              // Análise detalhada da URL
              _UrlAnalysisCards(scenario: s),
            ],
          ]),
        ),
      ]),
    );
  }
}

enum _UrlPartType { safe, danger, warning, neutral }

class _UrlPart {
  final String text;
  final _UrlPartType type;
  const _UrlPart(this.text, this.type);
}

class _UrlPartChip extends StatelessWidget {
  final _UrlPart part;
  const _UrlPartChip({required this.part});

  Color get _color {
    switch (part.type) {
      case _UrlPartType.safe:
        return const Color(0xFF00FF88);
      case _UrlPartType.danger:
        return const Color(0xFFFF4444);
      case _UrlPartType.warning:
        return const Color(0xFFFFCC00);
      case _UrlPartType.neutral:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) => Text(
        part.text,
        style: GoogleFonts.jetBrainsMono(
            color: _color, fontSize: 11, fontWeight: FontWeight.w600),
      );
}

class _UrlAnalysisCards extends StatelessWidget {
  final AiScenario scenario;
  const _UrlAnalysisCards({required this.scenario});

  @override
  Widget build(BuildContext context) {
    final s = scenario;
    final checks = [
      (
        'Domínio registado',
        s.isPhishing ? '⚠ Domínio suspeito' : '✓ Domínio verificado',
        s.isPhishing ? const Color(0xFFFF4444) : const Color(0xFF00FF88)
      ),
      (
        'Certificado SSL',
        s.isPhishing ? '⚠ Pode ser falso' : '✓ SSL válido',
        s.isPhishing ? const Color(0xFFFFCC00) : const Color(0xFF00FF88)
      ),
      (
        'Redirecionamento',
        s.isPhishing ? '⚠ Múltiplos redirects' : '✓ Direto ao destino',
        s.isPhishing ? const Color(0xFFFF4444) : const Color(0xFF00FF88)
      ),
      (
        'Reputação',
        s.isPhishing ? '🔴 Reportado como phishing' : '✓ Boa reputação',
        s.isPhishing ? const Color(0xFFFF4444) : const Color(0xFF00FF88)
      ),
    ];

    return Column(
      children: checks
          .map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: c.$3.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.$3.withAlpha(50)),
                ),
                child: Row(children: [
                  Text(c.$1,
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 11)),
                  const Spacer(),
                  Text(c.$2,
                      style: GoogleFonts.inter(
                          color: c.$3,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
              ))
          .toList(),
    );
  }
}
