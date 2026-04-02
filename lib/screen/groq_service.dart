import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'package:flutter/material.dart';
import 'package:phishing/models/app_models.dart';

class GroqService {
  static Future<AiScenario> generateScenario({
    String? type,
    String? difficulty,
    bool? isPhishing,
  }) async {
    final body = <String, dynamic>{};
    if (type != null) body['type'] = type;
    if (difficulty != null) body['difficulty'] = difficulty;
    if (isPhishing != null) body['is_phishing'] = isPhishing;

    final uri = Uri.parse('${ApiService.baseUrl}/ai-simulations/generate');
    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 35));

      if (res.statusCode == 503) throw GroqServiceUnavailableException();
      if (res.statusCode == 429) throw RateLimitException();
      if (res.statusCode != 200) throw GroqException(_extractDetail(res.body));

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return AiScenario.fromJson(json);
    } on GroqException {
      rethrow;
    } on RateLimitException {
      rethrow;
    } on GroqServiceUnavailableException {
      rethrow;
    } catch (e) {
      throw GroqException('Erro de ligação ao servidor: $e');
    }
  }

  static String _extractDetail(String body) {
    try {
      final j = jsonDecode(body);
      return j['detail']?.toString() ?? 'Erro desconhecido';
    } catch (_) {
      return 'Erro desconhecido';
    }
  }
}

class GroqServiceUnavailableException implements Exception {
  @override
  String toString() => 'Serviço de simulações IA temporariamente indisponível.';
}

class RateLimitException implements Exception {
  @override
  String toString() => 'Demasiados pedidos. Aguarda um momento.';
}

class GroqException implements Exception {
  final String message;
  const GroqException(this.message);
  @override
  String toString() => message;
}

final List<ForensicCase> kForensicCases = [
  const ForensicCase(
    id: 'twitter-2020',
    title: 'Twitter Bitcoin Hack',
    year: '2020',
    target: 'Twitter Inc.',
    country: 'EUA',
    attackType: 'Spear Phishing + Vishing',
    attackVector: 'Chamada telefónica a funcionários do suporte',
    emoji: '🐦',
    threat_actor: 'Graham Ivan Clark (17 anos) e cúmplices',
    summary:
        'Hackers comprometeram 130 contas de alto perfil incluindo Barack Obama, Elon Musk, Apple e Bill Gates para lançar golpe de Bitcoin que rendeu \$120,000 em horas.',
    howItWorked:
        'Os atacantes ligaram para funcionários do Twitter fingindo ser da equipa de TI interna. Convenceram-nos a fornecer credenciais VPN ignorando 2FA, alegando problemas de "home office". Com acesso às ferramentas internas, redefiniram emails e passwords das vítimas.',
    redFlags: [
      'Chamada não solicitada alegando ser de TI interno',
      'Pedido de credenciais por telefone (nunca é legítimo)',
      'Urgência criada pela situação pandémica',
      'Contornar procedimentos de segurança habituais',
    ],
    outcome:
        'Graham Clark arrestado com 17 anos. Sentenciado a 3 anos. Twitter multado em \$150M.',
    financialImpact: '\$120,000 em Bitcoin + danos reputacionais incalculáveis',
    lessons: [
      'Nunca fornecer credenciais por telefone, mesmo para "TI interno"',
      'Verificar identidade via canal separado antes de qualquer acção',
      'Treino de vishing é tão importante quanto treino de phishing',
      'Acesso a ferramentas admin deve ter múltiplos fatores de aprovação',
    ],
  ),
  const ForensicCase(
    id: 'google-facebook-bec',
    title: 'Google & Facebook: \$121M BEC',
    year: '2013–2015',
    target: 'Google e Facebook',
    country: 'EUA / Lituânia',
    attackType: 'Business Email Compromise (BEC)',
    attackVector: 'Faturas falsas por email',
    emoji: '🏦',
    threat_actor: 'Evaldas Rimasauskas (Lituânia)',
    summary:
        'Um único hacker enganou dois dos maiores gigantes tecnológicos do mundo durante 2 anos, enviando faturas falsas que totalizaram \$121 milhões.',
    howItWorked:
        'Rimasauskas criou uma empresa na Lituânia com o mesmo nome de um fornecedor real (Quanta Computer). Enviou faturas convincentes com contratos forjados e cartas em papel timbrado falso para os departamentos financeiros de ambas as empresas.',
    redFlags: [
      'Domínio do email ligeiramente diferente do fornecedor real',
      'IBAN bancário diferente do habitual',
      'Pedido de mudança de conta bancária por email',
      'Faturas de montante inusualmente alto sem verificação adicional',
    ],
    outcome:
        'Extraditado para os EUA em 2017. Declarou-se culpado em 2019. Fundos maioritariamente recuperados.',
    financialImpact: '\$121 milhões roubados',
    lessons: [
      'Verificar SEMPRE mudanças de IBAN por telefone para o número oficial',
      'Dupla aprovação para pagamentos acima de certo valor',
      'Verificar domínio do email, não apenas o nome apresentado',
    ],
  ),
  const ForensicCase(
    id: 'podesta-2016',
    title: 'Hack Clinton: Email de Podesta',
    year: '2016',
    target: 'John Podesta (Campanha Hillary Clinton)',
    country: 'EUA',
    attackType: 'Spear Phishing',
    attackVector: 'Email falso do Google Security',
    emoji: '🗳️',
    threat_actor: 'APT28 / Fancy Bear (GRU russo)',
    summary:
        'Um simples email de phishing comprometeu o chefe de campanha de Hillary Clinton, levando à publicação de 50,000 emails pelo WikiLeaks.',
    howItWorked:
        'Podesta recebeu um email aparentemente do Google a pedir alteração de password. Um assessor de TI confirmou erroneamente que era "legítimo". Podesta introduziu as suas credenciais numa página falsa.',
    redFlags: [
      'Email de segurança não solicitado a pedir acção urgente',
      'URL do link não era accounts.google.com',
      'Uso de encurtador de URL (bit.ly) para esconder destino real',
      'Conta sem autenticação de 2 fatores',
    ],
    outcome:
        '50,000 emails publicados pelo WikiLeaks. Impacto político significativo.',
    financialImpact:
        'Incalculável — impacto nas eleições presidenciais dos EUA',
    lessons: [
      'SEMPRE verificar URL antes de introduzir credenciais',
      'Ativar autenticação de 2 fatores em todas as contas críticas',
      'Não clicar em links de emails de segurança — ir diretamente ao site',
    ],
  ),
  const ForensicCase(
    id: 'colonial-pipeline',
    title: 'Colonial Pipeline Ransomware',
    year: '2021',
    target: 'Colonial Pipeline Co.',
    country: 'EUA',
    attackType: 'Credential Phishing → Ransomware',
    attackVector: 'Password vazada + VPN sem MFA',
    emoji: '⛽',
    threat_actor: 'DarkSide (grupo ransomware-as-a-service)',
    summary:
        'Uma única password roubada paralisou o maior oleoduto de combustível dos EUA por 6 dias, causando escassez de gasolina em 17 estados.',
    howItWorked:
        'Os atacantes obtiveram uma password de uma conta VPN desativada encontrada numa base de dados de credenciais vazadas na dark web. A conta não tinha MFA. Em menos de 2 horas introduziram ransomware que encriptou 100GB.',
    redFlags: [
      'Conta VPN antiga sem MFA ativa',
      'Password reutilizada em bases de dados vazadas',
      'Acesso VPN de IP inusual sem alerta',
      'Sem monitorização de movimento lateral na rede',
    ],
    outcome:
        'Oleoduto parado 6 dias. Colonial Pipeline pagou \$4.4M em Bitcoin. FBI recuperou \$2.3M.',
    financialImpact: '\$4.4M em resgate + \$50M+ em custos de recuperação',
    lessons: [
      'Desativar completamente contas sem uso',
      'MFA obrigatório em TODOS os acessos remotos',
      'Monitorizar credenciais em bases de dados vazadas',
      'Segmentação de rede para limitar movimento lateral',
    ],
  ),
  const ForensicCase(
    id: 'mgm-2023',
    title: 'MGM Resorts: \$100M Vishing',
    year: '2023',
    target: 'MGM Resorts International',
    country: 'EUA',
    attackType: 'Vishing + Social Engineering',
    attackVector: 'Chamada de 10 minutos ao helpdesk',
    emoji: '🎰',
    threat_actor: 'Scattered Spider / ALPHV',
    summary:
        'Uma chamada de 10 minutos ao helpdesk da MGM deu aos hackers acesso a sistemas críticos. Resultado: \$100M em prejuízos e dados de 37 milhões de clientes roubados.',
    howItWorked:
        'Pesquisaram funcionários no LinkedIn e contactaram o helpdesk fingindo ser um funcionário que "perdeu o acesso". Com informações públicas do LinkedIn convenceram o helpdesk a resetar credenciais sem verificação adequada.',
    redFlags: [
      'Pedido de reset de credenciais sem verificação presencial',
      'Helpdesk não questionou suficientemente a identidade',
      'OSINT (LinkedIn) usado para obter informações convincentes',
    ],
    outcome:
        'Slot machines offline. Check-in manual. MGM pagou \$45M. 37M clientes afetados.',
    financialImpact: '\$100M+ em impacto financeiro total',
    lessons: [
      'Procedimentos rigorosos de verificação de identidade no helpdesk',
      'Nunca resetar credenciais baseado apenas em informação pública',
      'Treinar helpdesk especificamente para resistir a social engineering',
    ],
  ),
  const ForensicCase(
    id: 'toyota-2019',
    title: 'Toyota: \$37M por Email',
    year: '2019',
    target: 'Toyota Boshoku Corporation',
    country: 'Japão',
    attackType: 'Business Email Compromise',
    attackVector: 'Email fraudulento de "executivo"',
    emoji: '🚗',
    threat_actor: 'Grupo criminoso organizado (não identificado)',
    summary:
        'A subsidiária de peças da Toyota foi convencida a transferir \$37 milhões após receber instruções por email de alguém que se fazia passar por um parceiro europeu.',
    howItWorked:
        'Um atacante comprometeu o email de um executivo parceiro europeu. Usando esse email legítimo comprometido, contactou o departamento financeiro com instruções urgentes para alterar conta bancária.',
    redFlags: [
      'Pedido urgente de mudança de conta bancária por email',
      'Pressão de tempo para efetuar transferência antes de "prazo"',
      'Falta de verificação telefónica para mudanças de IBAN',
    ],
    outcome:
        'Toyota reportou a perda como incidente de cibersegurança. Maioria dos fundos não recuperados.',
    financialImpact: '\$37 milhões (≈4 bilhões de ienes)',
    lessons: [
      'Regra de ouro: qualquer mudança de IBAN requer confirmação por voz',
      'Dupla autorização para transferências internacionais',
      'Treino específico de BEC para equipas financeiras',
    ],
  ),
  const ForensicCase(
    id: 'covid-who-2020',
    title: 'Phishing COVID-19 / OMS',
    year: '2020',
    target: 'Cidadãos globais',
    country: 'Global',
    attackType: 'Mass Phishing Campaign',
    attackVector: 'Emails fingindo ser da OMS/WHO',
    emoji: '🦠',
    threat_actor: 'Múltiplos grupos (crime organizado + APTs)',
    summary:
        'Durante a pandemia, campanhas de phishing cresceram 600%. Criminosos usaram o medo do COVID-19 para distribuir malware usando a marca da OMS e governos.',
    howItWorked:
        'Emails alegavam ter "instruções de segurança COVID", "resultados de testes" ou "subsídios governamentais". Os attachments continham malware. As campanhas exploram o stress emocional para reduzir o pensamento crítico.',
    redFlags: [
      'WHO/OMS nunca envia emails não solicitados a particulares',
      'Links para domínios não-oficiais (who-info.org)',
      'Pedido de dados pessoais/financeiros para "receber apoio"',
      'Attachments suspeitos (.exe disfarçado de .pdf)',
    ],
    outcome:
        'INTERPOL: 907,000 emails spam, 737 incidentes malware, 48,000 URLs maliciosas em 4 meses.',
    financialImpact: 'Estimado em centenas de milhões globalmente',
    lessons: [
      'Em crises, o alerta de phishing deve AUMENTAR, não diminuir',
      'Verificar sites oficiais diretamente (gov.pt, who.int)',
      'Nunca abrir attachments de emails não solicitados',
    ],
  ),
];
