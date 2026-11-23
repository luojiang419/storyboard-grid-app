import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:storyboard_grid_app/app/app_theme.dart';
import 'package:storyboard_grid_app/core/database/app_database.dart';
import 'package:storyboard_grid_app/features/onboarding/application/onboarding_controller.dart';
import 'package:storyboard_grid_app/features/onboarding/data/onboarding_repository.dart';
import 'package:storyboard_grid_app/features/onboarding/presentation/onboarding_overlay.dart';

void main() {
  testWidgets('引导遮罩支持按钮、方向键和 Esc 跳过', (tester) async {
    late final Directory root;
    late final AppDatabase database;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('onboarding_overlay_');
      database = await AppDatabase.open(File(p.join(root.path, 'app.sqlite')));
    });
    OnboardingRepository.initializeInstallation(
      database: database,
      isFreshInstall: true,
    );
    final controller = OnboardingController(
      repository: OnboardingRepository(database),
    )..start(originTabIndex: 2, automatic: true);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await tester.runAsync(() async {
        database.dispose();
        await root.delete(recursive: true);
      });
    });

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Stack(
                children: [
                  const Positioned.fill(child: ColoredBox(color: Colors.black)),
                  if (controller.visible)
                    OnboardingOverlay(controller: controller),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('onboarding-overlay')), findsOneWidget);
    expect(find.text('从一个创意，到完整故事板'), findsOneWidget);
    expect(find.text('1 / 6'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('onboarding-previous')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('先把创意变成连贯镜头'), findsOneWidget);
    expect(find.text('2 / 6'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('把组合图拆成独立镜头'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('先把创意变成连贯镜头'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.byKey(const ValueKey('onboarding-overlay')), findsNothing);
    expect(
      database.getSetting(OnboardingRepository.completedVersionKey),
      '${OnboardingRepository.currentVersion}',
    );
  });
}
