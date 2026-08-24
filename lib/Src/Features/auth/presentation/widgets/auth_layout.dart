import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    required this.title,
    required this.subtitle,
    required this.child,
    this.logoAsset = 'assets/images/cormex_logo.png',
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          const Positioned.fill(
            child: CustomPaint(painter: _TechGridPainter()),
          ),
          const Positioned(
            top: -180,
            left: -160,
            child: _GlowOrb(size: 450, color: Color(0xFF00E5FF)),
          ),
          const Positioned(
            bottom: -220,
            right: -180,
            child: _GlowOrb(size: 520, color: Color(0xFF7C3AED)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool desktop = constraints.maxWidth >= 920;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: desktop ? 40 : 20,
                    vertical: 28,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 56,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1160),
                        child: desktop
                            ? Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _BrandPresentation(
                                      logoAsset: logoAsset,
                                    ),
                                  ),
                                  const SizedBox(width: 72),
                                  SizedBox(
                                    width: 460,
                                    child: _LoginCard(
                                      title: title,
                                      subtitle: subtitle,
                                      child: child,
                                    ),
                                  ),
                                ],
                              )
                            : ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 500),
                                child: _LoginCard(
                                  title: title,
                                  subtitle: subtitle,
                                  logoAsset: logoAsset,
                                  showLogo: true,
                                  child: child,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPresentation extends StatelessWidget {
  const _BrandPresentation({required this.logoAsset});

  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF67E8F9),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'INTELIGÊNCIA COMERCIAL',
                style: TextStyle(
                  color: Color(0xFFA5F3FC),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _BrandLogo(logoAsset: logoAsset, large: true),
        const SizedBox(height: 32),
        const Text(
          'Transforme oportunidades\nem vendas, todos os dias.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Seu agente comercial inteligente para prospectar clientes, '
          'atender leads e acompanhar negociações até a conversão.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 17,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _FeaturePill(
              icon: Icons.radar_rounded,
              label: 'Prospecção automática',
            ),
            _FeaturePill(
              icon: Icons.forum_outlined,
              label: 'Atendimento 24 horas',
            ),
            _FeaturePill(
              icon: Icons.trending_up_rounded,
              label: 'Follow-up inteligente',
            ),
            _FeaturePill(
              icon: Icons.analytics_outlined,
              label: 'Resultados em tempo real',
            ),
          ],
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.logoAsset,
    this.showLogo = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? logoAsset;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 50,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
            blurRadius: 60,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showLogo && logoAsset != null) ...<Widget>[
            Center(child: _BrandLogo(logoAsset: logoAsset!)),
            const SizedBox(height: 26),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE6FFFB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF0F766E),
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'AMBIENTE SEGURO',
                  style: TextStyle(
                    color: Color(0xFF0F766E),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          child,
        ],
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.logoAsset, this.large = false});

  final String logoAsset;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: large ? 340 : 230,
      height: large ? 125 : 85,
      child: Image.asset(
        logoAsset,
        fit: BoxFit.contain,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: large ? 72 : 56,
                height: large ? 72 : 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF06B6D4), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: large ? 40 : 30,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'CormeX\nAI Agent',
                style: TextStyle(
                  color: large ? Colors.white : const Color(0xFF101828),
                  fontSize: large ? 30 : 23,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: const Color(0xFF67E8F9), size: 19),
          const SizedBox(width: 9),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
            colors: <Color>[
              color.withValues(alpha: 0.20),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechGridPainter extends CustomPainter {
  const _TechGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    const double space = 64;

    for (double x = 0; x <= size.width; x += space) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    for (double y = 0; y <= size.height; y += space) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
