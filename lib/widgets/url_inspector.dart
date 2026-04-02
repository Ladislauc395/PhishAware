import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Modelo de análise ────────────────────────────────────────────────────────

enum _PartRisk { safe, warning, danger }

class _UrlPart {
  final String text;
  final String label;
  final String explanation;
  final _PartRisk risk;

  const _UrlPart({
    required this.text,
    required this.label,
    required this.explanation,
    required this.risk,
  });

  Color get color {
    switch (risk) {
      case _PartRisk.safe:
        return const Color(0xFF00E5A0);
      case _PartRisk.warning:
        return const Color(0xFFF59E0B);
      case _PartRisk.danger:
        return const Color(0xFFEF4444);
    }
  }
}

// ─── Analisador de URL ────────────────────────────────────────────────────────

class UrlAnalysis {
  final String rawUrl;
  final List<_UrlPart> parts;
  final int riskScore; // 0–100
  final String verdict;
  final List<String> redFlags;

  const UrlAnalysis({
    required this.rawUrl,
    required this.parts,
    required this.riskScore,
    required this.verdict,
    required this.redFlags,
  });
}

/// Analisa uma URL e devolve uma [UrlAnalysis] detalhada.
/// Esta função é local (sem chamada à API) para resposta imediata.
UrlAnalysis analyzeUrl(String rawUrl) {
  final url = rawUrl.trim().toLowerCase();
  final parts = <_UrlPart>[];
  final redFlags = <String>[];
  int riskScore = 0;

  // ── Protocolo ────────────────────────────────────────────────────────────
  if (url.startsWith('https://')) {
    parts.add(
      const _UrlPart(
        text: 'https://',
        label: 'Protocolo Seguro',
        explanation: 'A ligação é encriptada com TLS/SSL.',
        risk: _PartRisk.safe,
      ),
    );
  } else if (url.startsWith('http://')) {
    parts.add(
      const _UrlPart(
        text: 'http://',
        label: 'Protocolo Inseguro',
        explanation: 'Sem encriptação — os teus dados viajam em texto puro.',
        risk: _PartRisk.danger,
      ),
    );
    riskScore += 30;
    redFlags.add('Protocolo HTTP sem encriptação');
  } else {
    parts.add(
      _UrlPart(
        text: url.substring(
          0,
          url.indexOf('/') < 0 ? url.length : url.indexOf('/'),
        ),
        label: 'Protocolo Desconhecido',
        explanation: 'URL sem protocolo reconhecido.',
        risk: _PartRisk.warning,
      ),
    );
    riskScore += 15;
  }

  // ── Extrai domínio + path ─────────────────────────────────────────────────
  String remaining = url
      .replaceFirst('https://', '')
      .replaceFirst('http://', '');

  final pathIndex = remaining.indexOf('/');
  final domainFull = pathIndex >= 0
      ? remaining.substring(0, pathIndex)
      : remaining;
  final path = pathIndex >= 0 ? remaining.substring(pathIndex) : '';

  // ── Subdomain ─────────────────────────────────────────────────────────────
  final domainParts = domainFull.split('.');
  String subdomain = '';
  String domain = '';
  String tld = '';

  if (domainParts.length >= 3) {
    subdomain = domainParts.sublist(0, domainParts.length - 2).join('.');
    domain = domainParts[domainParts.length - 2];
    tld = '.${domainParts.last}';

    final suspiciousSubdomains = [
      'secure',
      'login',
      'verify',
      'account',
      'update',
      'bank',
      'support',
    ];
    final isSubdomainSuspicious = suspiciousSubdomains.any(
      (s) => subdomain.contains(s),
    );

    if (isSubdomainSuspicious) {
      parts.add(
        _UrlPart(
          text: '$subdomain.',
          label: 'Subdomínio Suspeito',
          explanation:
              '"$subdomain" é frequentemente usado em ataques de phishing para enganar a vítima.',
          risk: _PartRisk.danger,
        ),
      );
      riskScore += 30;
      redFlags.add('Subdomínio suspeito: "$subdomain"');
    } else if (subdomain.isNotEmpty) {
      parts.add(
        _UrlPart(
          text: '$subdomain.',
          label: 'Subdomínio',
          explanation: 'Prefixo do domínio principal.',
          risk: _PartRisk.safe,
        ),
      );
    }
  } else if (domainParts.length == 2) {
    domain = domainParts[0];
    tld = '.${domainParts[1]}';
  } else {
    domain = domainFull;
  }

  // ── Domínio ───────────────────────────────────────────────────────────────
  final knownBrands = [
    'google',
    'microsoft',
    'facebook',
    'apple',
    'amazon',
    'paypal',
    'netflix',
  ];
  final lookalike = knownBrands.any((b) => domain.contains(b) && domain != b);

  if (lookalike) {
    parts.add(
      _UrlPart(
        text: domain,
        label: 'Domínio Falso!',
        explanation:
            '"$domain" imita uma marca conhecida mas não é o domínio oficial.',
        risk: _PartRisk.danger,
      ),
    );
    riskScore += 40;
    redFlags.add('Domínio lookalike: imita uma marca conhecida');
  } else {
    // Verifica hífens excessivos (sinal de phishing)
    final hyphenCount = domain.split('-').length - 1;
    final _PartRisk domainRisk = hyphenCount >= 2
        ? _PartRisk.warning
        : _PartRisk.safe;
    if (hyphenCount >= 2) {
      riskScore += 15;
      redFlags.add('Domínio com múltiplos hífens');
    }
    parts.add(
      _UrlPart(
        text: domain,
        label: 'Domínio Principal',
        explanation: domainRisk == _PartRisk.safe
            ? 'O domínio parece legítimo.'
            : 'Múltiplos hífens são comuns em domínios de phishing.',
        risk: domainRisk,
      ),
    );
  }

  // ── TLD ───────────────────────────────────────────────────────────────────
  const suspiciousTlds = [
    '.xyz',
    '.tk',
    '.ml',
    '.ga',
    '.cf',
    '.top',
    '.click',
    '.work',
  ];
  final isSuspiciousTld = suspiciousTlds.contains(tld);

  if (tld.isNotEmpty) {
    parts.add(
      _UrlPart(
        text: tld,
        label: isSuspiciousTld ? 'TLD Suspeito' : 'Extensão',
        explanation: isSuspiciousTld
            ? '"$tld" é frequentemente abusado por atacantes devido ao registo gratuito.'
            : '"$tld" é uma extensão comum e legítima.',
        risk: isSuspiciousTld ? _PartRisk.danger : _PartRisk.safe,
      ),
    );
    if (isSuspiciousTld) {
      riskScore += 25;
      redFlags.add('TLD suspeito: "$tld"');
    }
  }

  // ── Path / Query ──────────────────────────────────────────────────────────
  if (path.isNotEmpty) {
    final hasToken =
        path.contains('token=') ||
        path.contains('verify') ||
        path.contains('reset');
    parts.add(
      _UrlPart(
        text: path.length > 30 ? '${path.substring(0, 30)}…' : path,
        label: hasToken ? 'Parâmetros Sensíveis' : 'Caminho',
        explanation: hasToken
            ? 'Parâmetros como "token" ou "verify" são usados em esquemas de reset forçado.'
            : 'Caminho da página no servidor.',
        risk: hasToken ? _PartRisk.warning : _PartRisk.safe,
      ),
    );
    if (hasToken) {
      riskScore += 10;
      redFlags.add('Parâmetros de token/verificação no URL');
    }
  }

  // ── Veredito ──────────────────────────────────────────────────────────────
  riskScore = riskScore.clamp(0, 100);
  final String verdict;
  if (riskScore >= 60) {
    verdict = '🚨 URL de Alto Risco — Provável Phishing';
  } else if (riskScore >= 25) {
    verdict = '⚠️ URL Suspeito — Procede com Cautela';
  } else {
    verdict = '✅ URL Aparentemente Seguro';
  }

  return UrlAnalysis(
    rawUrl: rawUrl,
    parts: parts,
    riskScore: riskScore,
    verdict: verdict,
    redFlags: redFlags,
  );
}

// ─── Widget Visual ────────────────────────────────────────────────────────────

/// Mostra uma análise de URL visualmente com cores, labels e explicações.
/// Integrar no AssistantScreen quando se detectar uma URL na mensagem.
class UrlInspectorCard extends StatefulWidget {
  final String url;
  const UrlInspectorCard({super.key, required this.url});

  @override
  State<UrlInspectorCard> createState() => _UrlInspectorCardState();
}

class _UrlInspectorCardState extends State<UrlInspectorCard>
    with SingleTickerProviderStateMixin {
  late final UrlAnalysis _analysis;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _analysis = analyzeUrl(widget.url);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _riskColor {
    if (_analysis.riskScore >= 60) return const Color(0xFFEF4444);
    if (_analysis.riskScore >= 25) return const Color(0xFFF59E0B);
    return const Color(0xFF00E5A0);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1520),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _riskColor.withAlpha(60)),
          boxShadow: [
            BoxShadow(
              color: _riskColor.withAlpha(20),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _riskColor.withAlpha(30)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: _riskColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Análise de URL',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.url));
                    },
                    child: Icon(
                      Icons.copy_outlined,
                      color: const Color(0xFF64748B),
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),

            // ── URL explodida ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                'URL Decomposta',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 10,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 4,
                runSpacing: 6,
                children: _analysis.parts.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  final isExpanded = _expandedIndex == i;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _expandedIndex = isExpanded ? null : i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p.color.withAlpha(isExpanded ? 30 : 15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: p.color.withAlpha(isExpanded ? 100 : 50),
                        ),
                      ),
                      child: Text(
                        p.text,
                        style: GoogleFonts.sourceCodePro(
                          color: p.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Explicação expandida ───────────────────────────────────
            if (_expandedIndex != null)
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _analysis.parts[_expandedIndex!].color.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _analysis.parts[_expandedIndex!].color.withAlpha(
                        40,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _analysis.parts[_expandedIndex!].label,
                        style: GoogleFonts.inter(
                          color: _analysis.parts[_expandedIndex!].color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _analysis.parts[_expandedIndex!].explanation,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // ── Risk Score ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Score de Risco',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_analysis.riskScore}/100',
                    style: GoogleFonts.spaceGrotesk(
                      color: _riskColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _analysis.riskScore / 100),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    backgroundColor: Colors.white.withAlpha(10),
                    valueColor: AlwaysStoppedAnimation(_riskColor),
                  ),
                ),
              ),
            ),

            // ── Red Flags ─────────────────────────────────────────────
            if (_analysis.redFlags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Sinais de Alerta',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _analysis.redFlags
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '•',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  f,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],

            // ── Veredito ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _riskColor.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _riskColor.withAlpha(50)),
              ),
              child: Text(
                _analysis.verdict,
                style: GoogleFonts.spaceGrotesk(
                  color: _riskColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detector de URL no texto ─────────────────────────────────────────────────

/// Devolve true se o texto contém uma URL que pode ser analisada.
bool containsUrl(String text) {
  return RegExp(r'https?://\S+|www\.\S+').hasMatch(text);
}

/// Extrai a primeira URL encontrada no texto.
String? extractUrl(String text) {
  final match = RegExp(r'https?://\S+|www\.\S+').firstMatch(text);
  return match?.group(0);
}
