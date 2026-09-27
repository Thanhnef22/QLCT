import 'package:flutter/material.dart';
import '../app/app_routes.dart';
import '../app/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _slides = const [
    _OnboardingData(
      eyebrow: 'TÀI CHÍNH NHẸ NHÀNG',
      title: 'Quản lý tiền\ndễ dàng hơn',
      description:
          'Tập trung vào những điều quan trọng. Mọi khoản thu chi luôn nằm trong tầm mắt.',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFB9F1DF),
    ),
    _OnboardingData(
      eyebrow: 'CHI TIÊU CÓ CHỦ ĐÍCH',
      title: 'Biết tiền của bạn\nđang đi đâu',
      description:
          'Theo dõi ngân sách trực quan và đưa ra lựa chọn tốt hơn mỗi ngày.',
      icon: Icons.insights_rounded,
      color: Color(0xFFD9D4FF),
    ),
    _OnboardingData(
      eyebrow: 'BẮT ĐẦU NGAY HÔM NAY',
      title: 'Một phiên bản\ntốt hơn của bạn',
      description:
          'Tạo thói quen tài chính lành mạnh, từng bước nhỏ và thật bền vững.',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFFFFE0B6),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openLogin() => Navigator.pushReplacementNamed(context, AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: _openLogin, child: const Text('Bỏ qua')),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (_, index) =>
                      _OnboardingSlide(data: _slides[index]),
                ),
              ),
              Row(
                children: [
                  ...List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      width: index == _page ? 28 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: index == _page
                            ? AppColors.mint
                            : AppColors.mint.withAlpha(45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      if (isLast) {
                        _openLogin();
                      } else {
                        _controller.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic);
                      }
                    },
                    icon: Icon(isLast
                        ? Icons.arrow_forward_rounded
                        : Icons.chevron_right_rounded),
                    label: Text(isLast ? 'Bắt đầu' : 'Tiếp tục'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData(
      {required this.eyebrow,
      required this.title,
      required this.description,
      required this.icon,
      required this.color});

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 560;
        final imageHeight = compact ? 220.0 : 300.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: imageHeight,
              width: double.infinity,
              margin: EdgeInsets.only(bottom: compact ? 22 : 48),
              decoration: BoxDecoration(
                  color: data.color, borderRadius: BorderRadius.circular(36)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                      top: 20,
                      right: 20,
                      child: Icon(Icons.blur_on_rounded,
                          size: compact ? 58 : 84,
                          color: Colors.white.withAlpha(150))),
                  Container(
                    width: compact ? 110 : 150,
                    height: compact ? 110 : 150,
                    decoration: BoxDecoration(
                        color: Colors.white.withAlpha(215),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withAlpha(18),
                              blurRadius: 30,
                              offset: const Offset(0, 16))
                        ]),
                    child: Icon(data.icon,
                        size: compact ? 48 : 64, color: AppColors.mintDark),
                  ),
                  Positioned(
                      bottom: 18,
                      left: 20,
                      child: _MiniMetric(color: Colors.white.withAlpha(190))),
                ],
              ),
            ),
            Text(data.eyebrow,
                style: textTheme.labelSmall
                    ?.copyWith(color: AppColors.mintDark, letterSpacing: 1.4)),
            SizedBox(height: compact ? 8 : 14),
            Text(data.title,
                textAlign: TextAlign.center,
                style: compact
                    ? textTheme.headlineMedium
                    : textTheme.headlineLarge),
            SizedBox(height: compact ? 8 : 16),
            ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 310),
                child: Text(data.description,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.mutedInk))),
          ],
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      height: 58,
      padding: const EdgeInsets.all(10),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 34,
            height: 6,
            decoration: BoxDecoration(
                color: AppColors.mint.withAlpha(100),
                borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 8),
        Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
                color: AppColors.ink.withAlpha(180),
                borderRadius: BorderRadius.circular(8))),
      ]),
    );
  }
}
