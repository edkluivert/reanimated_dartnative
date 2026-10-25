import 'package:dartnative/dartnative.dart';

import '../common/common.dart';

const _white = Color(0xFFFFFFFF);

/// The front of the flip card demo's credit card.
class CreditCardFront extends StatelessWidget {
  const CreditCardFront({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9A6BEA), Palette.purple, Palette.navy],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('REANIMATED', style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                width: 44,
                height: 28,
                decoration: BoxDecoration(color: const Color(0x55FFFFFF), borderRadius: BorderRadius.circular(14)),
              ),
            ]),
            const SizedBox(height: 18),
            Container(
              width: 46,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(colors: [Color(0xFFF6D365), Color(0xFFD4A017)]),
              ),
            ),
            const Spacer(),
            const Text('4242  ••••  ••••  2026',
                style: TextStyle(color: _white, fontSize: 20, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Row(children: [
              Text('DART NATIVE', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
              Spacer(),
              Text('12/30', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
            ]),
          ],
        ),
      );
}

/// The back of the flip card demo's credit card.
class CreditCardBack extends StatelessWidget {
  const CreditCardBack({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Palette.navy, Color(0xFF2A1B5C)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 26),
            Container(height: 40, color: const Color(0xFF0B0B12)),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 34,
                    color: const Color(0xFFEDEEF4),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 10),
                    child: const Text('signature', style: TextStyle(color: Color(0xFF8A8FA3))),
                  ),
                ),
                Container(
                  width: 54,
                  height: 34,
                  color: _white,
                  alignment: Alignment.center,
                  child: const Text('123', style: TextStyle(color: Palette.navy, fontSize: 16)),
                ),
              ]),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 18),
              child: Text('Spun with withSpring · velocity carried from your fling',
                  style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
            ),
          ],
        ),
      );
}
