import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _cyanLight = Color(0xFF67E8F9);
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _navy = Color(0xFF030712);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF030712),
                    Color(0xFF071A2E),
                    Color(0xFF073B4C),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: CustomPaint(painter: _LandingGridPainter())),
          const Positioned(
            top: -220,
            left: -180,
            child: _GlowOrb(size: 520, color: Color(0xFF00E5FF)),
          ),
          const Positioned(
            top: 420,
            right: -220,
            child: _GlowOrb(size: 580, color: _purple),
          ),
          SafeArea(
            child: SelectionArea(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _Header(onAccess: () => context.go('/login')),
                    _Hero(onAccess: () => context.go('/login')),
                    const _FeatureSection(),
                    const _HowItWorksSection(),
                    _CtaSection(onAccess: () => context.go('/login')),
                    const _Footer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAccess});

  final VoidCallback onAccess;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 760;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 36,
                vertical: 18,
              ),
              child: Row(
                children: <Widget>[
                  const _Logo(width: 185, height: 66),
                  const Spacer(),
                  if (!compact) ...<Widget>[
                    _HeaderLink(label: 'Recursos', onTap: () {}),
                    const SizedBox(width: 26),
                    _HeaderLink(label: 'Como funciona', onTap: () {}),
                    const SizedBox(width: 30),
                  ],
                  OutlinedButton(
                    onPressed: onAccess,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(compact ? 'Entrar' : 'Acessar CRM'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.76),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onAccess});

  final VoidCallback onAccess;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 70, 28, 90),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool desktop = constraints.maxWidth >= 900;
              final Widget copy = Column(
                crossAxisAlignment:
                    desktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.32),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: LandingPage._cyanLight,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'CRM COM INTELIGÊNCIA ARTIFICIAL',
                          style: TextStyle(
                            color: Color(0xFFA5F3FC),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Venda mais. Organize menos.\nDeixe o CormeX trabalhar por você.',
                    textAlign: desktop ? TextAlign.left : TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: desktop ? 54 : 38,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Text(
                      'O CormeX é um CRM inteligente para centralizar leads, conversas, oportunidades e follow-ups enquanto a IA ajuda sua equipe a prospectar, atender e converter clientes.',
                      textAlign: desktop ? TextAlign.left : TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 18,
                        height: 1.65,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    alignment: desktop ? WrapAlignment.start : WrapAlignment.center,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: onAccess,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Acessar o CormeX CRM'),
                        style: FilledButton.styleFrom(
                          backgroundColor: LandingPage._cyan,
                          foregroundColor: const Color(0xFF03212A),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 19,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/register'),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Criar conta'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      _TrustItem(icon: Icons.check_circle_outline, text: 'Pipeline comercial'),
                      _TrustItem(icon: Icons.check_circle_outline, text: 'WhatsApp e conversas'),
                      _TrustItem(icon: Icons.check_circle_outline, text: 'Automação com IA'),
                    ],
                  ),
                ],
              );

              final Widget dashboard = const _DashboardPreview();

              if (!desktop) {
                return Column(
                  children: <Widget>[
                    copy,
                    const SizedBox(height: 58),
                    dashboard,
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(flex: 11, child: copy),
                  const SizedBox(width: 58),
                  Expanded(flex: 9, child: dashboard),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: LandingPage._cyan.withValues(alpha: 0.12),
            blurRadius: 80,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[LandingPage._cyan, LandingPage._purple],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.insights_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Visão comercial',
                        style: TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Tudo em um único painel',
                        style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const _LiveBadge(),
              ],
            ),
            const SizedBox(height: 24),
            const Row(
              children: <Widget>[
                Expanded(child: _MetricCard(label: 'Leads ativos', value: '128', icon: Icons.people_alt_outlined)),
                SizedBox(width: 12),
                Expanded(child: _MetricCard(label: 'Oportunidades', value: '34', icon: Icons.track_changes_rounded)),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: <Widget>[
                Expanded(child: _MetricCard(label: 'Conversões', value: '21%', icon: Icons.trending_up_rounded)),
                SizedBox(width: 12),
                Expanded(child: _MetricCard(label: 'Follow-ups', value: '47', icon: Icons.schedule_send_outlined)),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Pipeline inteligente',
              style: TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const _PipelineRow(label: 'Novo lead', count: 42, progress: .82),
            const _PipelineRow(label: 'Qualificado', count: 29, progress: .62),
            const _PipelineRow(label: 'Proposta', count: 18, progress: .44),
            const _PipelineRow(label: 'Fechamento', count: 11, progress: .28),
          ],
        ),
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 92),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Column(
            children: <Widget>[
              const _SectionTitle(
                eyebrow: 'UM CRM CONSTRUÍDO PARA VENDER',
                title: 'Sua operação comercial conectada de ponta a ponta.',
                subtitle: 'Menos ferramentas espalhadas. Mais contexto para sua equipe e mais velocidade para fechar negócios.',
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final int columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 560
                          ? 2
                          : 1;
                  final double itemWidth = (constraints.maxWidth - ((columns - 1) * 18)) / columns;
                  return Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: <Widget>[
                      SizedBox(width: itemWidth, child: const _FeatureCard(icon: Icons.people_alt_outlined, title: 'CRM e Leads', text: 'Organize contatos, empresas, histórico e oportunidades sem perder o contexto de cada negociação.')),
                      SizedBox(width: itemWidth, child: const _FeatureCard(icon: Icons.forum_outlined, title: 'Conversas centralizadas', text: 'Conecte o atendimento ao funil comercial e acompanhe cada conversa dentro da jornada do cliente.')),
                      SizedBox(width: itemWidth, child: const _FeatureCard(icon: Icons.auto_awesome_rounded, title: 'Agente de IA', text: 'Use inteligência artificial para apoiar prospecção, atendimento, qualificação e execução comercial.')),
                      SizedBox(width: itemWidth, child: const _FeatureCard(icon: Icons.account_tree_outlined, title: 'Pipeline visual', text: 'Veja oportunidades por etapa, prioridade e responsável e saiba exatamente onde agir.')),
                      SizedBox(width: itemWidth, child: const _FeatureCard(icon: Icons.schedule_send_outlined, title: 'Follow-up inteligente', text: 'Reduza oportunidades esquecidas com acompanhamento estruturado e automações comerciais.')),
                      SizedBox(width: itemWidth, child: const _FeatureCard(icon: Icons.analytics_outlined, title: 'Dados em tempo real', text: 'Tenha uma visão executiva da operação com métricas que mostram o que está avançando e o que exige atenção.')),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 92),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1060),
          child: const Column(
            children: <Widget>[
              _SectionTitle(
                eyebrow: 'SIMPLES PARA A EQUIPE. PODEROSO PARA O NEGÓCIO.',
                title: 'Do primeiro contato ao fechamento.',
                subtitle: 'O CormeX acompanha o fluxo comercial sem transformar a operação em um labirinto de sistemas.',
                dark: true,
              ),
              SizedBox(height: 52),
              _StepRow(number: '01', icon: Icons.campaign_outlined, title: 'Capture oportunidades', text: 'Centralize leads originados de campanhas, canais e prospecção.'),
              _StepRow(number: '02', icon: Icons.psychology_alt_outlined, title: 'Qualifique com contexto', text: 'Use dados, histórico e IA para priorizar quem tem maior chance de avançar.'),
              _StepRow(number: '03', icon: Icons.handshake_outlined, title: 'Conduza a negociação', text: 'Mova oportunidades pelo pipeline e mantenha conversas e follow-ups organizados.'),
              _StepRow(number: '04', icon: Icons.insights_rounded, title: 'Aprenda com os resultados', text: 'Acompanhe métricas e identifique gargalos para evoluir a operação continuamente.', last: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtaSection extends StatelessWidget {
  const _CtaSection({required this.onAccess});

  final VoidCallback onAccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 84),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 46),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF071A2E), Color(0xFF073B4C)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                  blurRadius: 45,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool desktop = constraints.maxWidth >= 760;
                final Widget text = Column(
                  crossAxisAlignment: desktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Sua operação comercial pode trabalhar de forma mais inteligente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Entre no CormeX e leve CRM, automação e IA para o mesmo fluxo de vendas.',
                      textAlign: desktop ? TextAlign.left : TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                );

                final Widget button = FilledButton.icon(
                  onPressed: onAccess,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Acessar CRM'),
                  style: FilledButton.styleFrom(
                    backgroundColor: LandingPage._cyan,
                    foregroundColor: const Color(0xFF03212A),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 19),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                );

                if (!desktop) {
                  return Column(
                    children: <Widget>[text, const SizedBox(height: 28), button],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: text),
                    const SizedBox(width: 40),
                    button,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          child: Row(
            children: <Widget>[
              const _Logo(width: 145, height: 52),
              const Spacer(),
              Text(
                'CormeX CRM • Inteligência comercial',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/images/cormex_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.smart_toy_outlined, color: LandingPage._cyanLight),
            SizedBox(width: 9),
            Text(
              'CormeX CRM',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.eyebrow, required this.title, required this.subtitle, this.dark = false});

  final String eyebrow;
  final String title;
  final String subtitle;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final Color titleColor = dark ? Colors.white : const Color(0xFF101828);
    final Color subtitleColor = dark ? Colors.white.withValues(alpha: 0.66) : const Color(0xFF667085);
    return Column(
      children: <Widget>[
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LandingPage._cyan,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 13),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 35,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor, fontSize: 16, height: 1.6),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.05),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFECFEFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: LandingPage._cyan, size: 25),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF667085), height: 1.55, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.icon, required this.title, required this.text, this.last = false});

  final String number;
  final IconData icon;
  final String title;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 58,
            child: Column(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LandingPage._cyan.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: LandingPage._cyan.withValues(alpha: 0.32)),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(color: LandingPage._cyanLight, fontWeight: FontWeight.w900),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.13),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 36),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: LandingPage._cyanLight, size: 24),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          text,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.62), height: 1.55),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: LandingPage._cyanLight, size: 17),
        const SizedBox(width: 7),
        Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 12)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: LandingPage._cyan, size: 19),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(color: Color(0xFF101828), fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Color(0xFF667085), fontSize: 11)),
        ],
      ),
    );
  }
}

class _PipelineRow extends StatelessWidget {
  const _PipelineRow({required this.label, required this.count, required this.progress});

  final String label;
  final int count;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 82,
            child: Text(label, style: const TextStyle(color: Color(0xFF667085), fontSize: 11)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: progress,
                backgroundColor: const Color(0xFFE4E7EC),
                valueColor: const AlwaysStoppedAnimation<Color>(LandingPage._cyan),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 24,
            child: Text('$count', textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF344054), fontWeight: FontWeight.w800, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.circle, color: Color(0xFF12B76A), size: 7),
          SizedBox(width: 5),
          Text('AO VIVO', style: TextStyle(color: Color(0xFF027A48), fontWeight: FontWeight.w800, fontSize: 9)),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandingGridPainter extends CustomPainter {
  const _LandingGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const double space = 64;
    for (double x = 0; x <= size.width; x += space) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += space) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
