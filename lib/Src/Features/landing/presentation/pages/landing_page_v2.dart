import 'package:agente_vendas_saas/Src/Shared/components/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _cyanLight = Color(0xFF67E8F9);
  static const Color _purple = Color(0xFF7C3AED);
  static const Color _navy = Color(0xFF030712);

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      alignment: 0.04,
    );
  }

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
          const Positioned.fill(child: CustomPaint(painter: _GridPainter())),
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
                controller: _scrollController,
                child: Column(
                  children: <Widget>[
                    _Header(
                      onFeatures: () => _scrollTo(_featuresKey),
                      onHowItWorks: () => _scrollTo(_howItWorksKey),
                      onAccess: () => context.go('/login'),
                    ),
                    _Hero(
                      onAccess: () => context.go('/login'),
                      onRegister: () => context.go('/register'),
                    ),
                    KeyedSubtree(
                      key: _featuresKey,
                      child: const _FeatureSection(),
                    ),
                    KeyedSubtree(
                      key: _howItWorksKey,
                      child: const _HowItWorksSection(),
                    ),
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
  const _Header({
    required this.onFeatures,
    required this.onHowItWorks,
    required this.onAccess,
  });

  final VoidCallback onFeatures;
  final VoidCallback onHowItWorks;
  final VoidCallback onAccess;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 760;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 18 : 36,
                vertical: 18,
              ),
              child: compact
                  ? Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const _Logo(width: 150, height: 56),
                            const Spacer(),
                            OutlinedButton(
                              onPressed: onAccess,
                              style: _accessButtonStyle,
                              child: const Text('Entrar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            _HeaderLink(label: 'Recursos', onTap: onFeatures),
                            const SizedBox(width: 8),
                            _HeaderLink(
                              label: 'Como funciona',
                              onTap: onHowItWorks,
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        const _Logo(width: 185, height: 66),
                        const Spacer(),
                        _HeaderLink(label: 'Recursos', onTap: onFeatures),
                        const SizedBox(width: 26),
                        _HeaderLink(
                          label: 'Como funciona',
                          onTap: onHowItWorks,
                        ),
                        const SizedBox(width: 30),
                        OutlinedButton(
                          onPressed: onAccess,
                          style: _accessButtonStyle,
                          child: const Text('Acessar CRM'),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  static ButtonStyle get _accessButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
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
          color: Colors.white.withValues(alpha: 0.82),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onAccess, required this.onRegister});

  final VoidCallback onAccess;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 70, 28, 90),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final desktop = constraints.maxWidth >= 900;
              final copy = Column(
                crossAxisAlignment:
                    desktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        Icon(Icons.auto_awesome_rounded, color: _LandingPageState._cyanLight, size: 18),
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
                          backgroundColor: _LandingPageState._cyan,
                          foregroundColor: const Color(0xFF03212A),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: onRegister,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Criar conta'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ],
                  ),
                ],
              );

              final preview = const _DashboardPreview();
              if (!desktop) {
                return Column(children: <Widget>[copy, const SizedBox(height: 58), preview]);
              }
              return Row(
                children: <Widget>[
                  Expanded(flex: 11, child: copy),
                  const SizedBox(width: 58),
                  const Expanded(flex: 9, child: _DashboardPreview()),
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
            color: _LandingPageState._cyan.withValues(alpha: 0.12),
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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Visão comercial',
              style: TextStyle(color: Color(0xFF101828), fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text('Tudo em um único painel', style: TextStyle(color: Color(0xFF667085))),
            SizedBox(height: 24),
            _MetricRow(label: 'Leads ativos', value: '128'),
            SizedBox(height: 12),
            _MetricRow(label: 'Oportunidades', value: '34'),
            SizedBox(height: 12),
            _MetricRow(label: 'Conversões', value: '21%'),
            SizedBox(height: 12),
            _MetricRow(label: 'Follow-ups', value: '47'),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF667085)))),
          Text(value, style: const TextStyle(color: Color(0xFF101828), fontWeight: FontWeight.w900)),
        ],
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
                eyebrow: 'RECURSOS',
                title: 'Sua operação comercial conectada de ponta a ponta.',
                subtitle: 'Menos ferramentas espalhadas. Mais contexto para sua equipe e mais velocidade para fechar negócios.',
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final columns = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 560 ? 2 : 1;
                  final itemWidth = (constraints.maxWidth - ((columns - 1) * 18)) / columns;
                  final cards = <Widget>[
                    const _FeatureCard(icon: Icons.people_alt_outlined, title: 'CRM e Leads', text: 'Organize contatos, histórico e oportunidades sem perder o contexto de cada negociação.'),
                    const _FeatureCard(icon: Icons.forum_outlined, title: 'Conversas centralizadas', text: 'Acompanhe conversas dentro da jornada comercial do cliente.'),
                    const _FeatureCard(icon: Icons.auto_awesome_rounded, title: 'Agente de IA', text: 'Apoie prospecção, atendimento, qualificação e execução comercial com IA.'),
                    const _FeatureCard(icon: Icons.account_tree_outlined, title: 'Pipeline visual', text: 'Veja oportunidades por etapa, prioridade e responsável.'),
                    const _FeatureCard(icon: Icons.schedule_send_outlined, title: 'Follow-up inteligente', text: 'Reduza oportunidades esquecidas com automações e acompanhamento estruturado.'),
                    const _FeatureCard(icon: Icons.analytics_outlined, title: 'Dados em tempo real', text: 'Acompanhe métricas e gargalos da operação comercial.'),
                  ];
                  return Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: cards.map((card) => SizedBox(width: itemWidth, child: card)).toList(),
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
                eyebrow: 'COMO FUNCIONA',
                title: 'Do primeiro contato ao fechamento.',
                subtitle: 'O CormeX acompanha o fluxo comercial sem transformar a operação em um labirinto de sistemas.',
                dark: true,
              ),
              SizedBox(height: 52),
              _Step(number: '01', title: 'Capture oportunidades', text: 'Centralize leads originados de campanhas, canais e prospecção.'),
              _Step(number: '02', title: 'Qualifique com contexto', text: 'Use dados, histórico e IA para priorizar quem tem maior chance de avançar.'),
              _Step(number: '03', title: 'Conduza a negociação', text: 'Mova oportunidades pelo pipeline e mantenha conversas e follow-ups organizados.'),
              _Step(number: '04', title: 'Aprenda com os resultados', text: 'Acompanhe métricas e identifique gargalos para evoluir continuamente.'),
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
              gradient: const LinearGradient(colors: <Color>[Color(0xFF071A2E), Color(0xFF073B4C)]),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Wrap(
              spacing: 32,
              runSpacing: 24,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: <Widget>[
                const SizedBox(
                  width: 650,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Sua operação comercial pode trabalhar de forma mais inteligente.',
                        style: TextStyle(color: Colors.white, fontSize: 28, height: 1.18, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Entre no CormeX e leve CRM, automação e IA para o mesmo fluxo de vendas.',
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAccess,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Acessar CRM'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _LandingPageState._cyan,
                    foregroundColor: const Color(0xFF03212A),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 19),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
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
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final compact = constraints.maxWidth < 680;
              final copyright = Text(
                '© 2026 Genesys Sistem. Todos os direitos reservados.',
                textAlign: compact ? TextAlign.center : TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.52),
                  fontSize: 12,
                ),
              );
              if (compact) {
                return Column(
                  children: <Widget>[
                    const _Logo(width: 145, height: 52),
                    const SizedBox(height: 14),
                    copyright,
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  const _Logo(width: 145, height: 52),
                  const Spacer(),
                  copyright,
                ],
              );
            },
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
      child: const Align(
        alignment: Alignment.centerLeft,
        child: AppBrand(light: true),
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
    final titleColor = dark ? Colors.white : const Color(0xFF101828);
    final subtitleColor = dark ? Colors.white.withValues(alpha: 0.66) : const Color(0xFF667085);
    return Column(
      children: <Widget>[
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _LandingPageState._cyan, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        const SizedBox(height: 13),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(color: titleColor, fontSize: 35, height: 1.15, fontWeight: FontWeight.w900, letterSpacing: -1),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: const Color(0xFFECFEFF), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: _LandingPageState._cyan, size: 25),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: Color(0xFF101828), fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: Color(0xFF667085), height: 1.55, fontSize: 14)),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.text});

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _LandingPageState._cyan.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _LandingPageState._cyan.withValues(alpha: 0.32)),
            ),
            child: Text(number, style: const TextStyle(color: _LandingPageState._cyanLight, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.66), height: 1.5)),
              ],
            ),
          ),
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
            colors: <Color>[color.withValues(alpha: 0.20), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
