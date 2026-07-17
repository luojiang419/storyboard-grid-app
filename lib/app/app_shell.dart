import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/providers/app_providers.dart';
import '../features/exporter/presentation/exporter_page.dart';
import '../features/grid_cut/presentation/grid_cut_page.dart';
import '../features/onboarding/application/onboarding_controller.dart';
import '../features/onboarding/data/onboarding_repository.dart';
import '../features/onboarding/presentation/onboarding_overlay.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/story_design/presentation/story_design_page.dart';
import '../features/storyboard/presentation/storyboard_page.dart';
import '../features/updater/application/updater_controller.dart';
import '../features/updater/domain/app_update_config.dart';
import 'window_title_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    this.enableWindowControls = true,
    this.initialTabIndex = 0,
    this.projectName,
    this.onCloseProject,
  });

  final bool enableWindowControls;
  final int initialTabIndex;
  final String? projectName;
  final Future<void> Function()? onCloseProject;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _selectedTabIndexKey = 'appShellSelectedTabIndex';
  static const _selectedTabIndexVersionKey = 'appShellSelectedTabIndexVersion';
  static const _selectedTabIndexVersion = 2;

  late int _tabIndex;
  late final UpdaterController _updaterController;
  late final OnboardingController _onboardingController;
  bool _updatePromptVisible = false;

  static const _tabs = <_ShellTab>[
    _ShellTab('设计分镜图', Icons.draw_rounded),
    _ShellTab('多宫格裁切', Icons.grid_view_rounded),
    _ShellTab('故事板拼图', Icons.dashboard_customize_rounded),
    _ShellTab('导出故事板', Icons.ios_share_rounded),
    _ShellTab('设置', Icons.tune_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _updaterController = ref.read(updaterControllerProvider);
    _updaterController.addListener(_handleUpdaterStateChanged);
    _onboardingController = OnboardingController(
      repository: OnboardingRepository(_globalDatabase()),
    )..addListener(_handleOnboardingChanged);
    _tabIndex =
        _loadSavedTabIndex() ??
        widget.initialTabIndex.clamp(0, _tabs.length - 1).toInt();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_onboardingController.shouldStartAutomatically) {
        _onboardingController.start(originTabIndex: _tabIndex, automatic: true);
      }
      _updaterController.beginStartupFlow();
      _handleUpdaterStateChanged();
    });
  }

  @override
  void dispose() {
    _onboardingController.removeListener(_handleOnboardingChanged);
    _onboardingController.dispose();
    _updaterController.removeListener(_handleUpdaterStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface,
              scheme.surfaceContainerHighest.withValues(alpha: 0.72),
              scheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            WindowTitleBar(
              enableWindowControls: widget.enableWindowControls,
              title: widget.projectName == null
                  ? null
                  : '${AppUpdateConfig.windowTitle} — ${widget.projectName}',
              actions: [
                IconButton(
                  key: const ValueKey('show-onboarding-help'),
                  onPressed: _showOnboarding,
                  tooltip: '新手引导',
                  icon: const Icon(Icons.help_outline_rounded),
                ),
              ],
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: KeyedSubtree(
                            key: ValueKey(_tabIndex),
                            child: switch (_tabIndex) {
                              0 => StoryDesignPage(
                                onOpenGridCutPage: () => _selectTab(1),
                              ),
                              1 => const GridCutPage(),
                              2 => const StoryboardPage(),
                              3 => const ExporterPage(),
                              _ => const SettingsPage(),
                            },
                          ),
                        ),
                      ),
                      _BottomTabs(
                        tabs: _tabs,
                        selectedIndex: _tabIndex,
                        onSelected: _selectTab,
                        projectName: widget.projectName,
                        onCloseProject: widget.onCloseProject,
                      ),
                    ],
                  ),
                  if (_onboardingController.visible)
                    OnboardingOverlay(controller: _onboardingController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _loadSavedTabIndex() {
    try {
      final raw = ref
          .read(appDatabaseProvider)
          .getSetting(_selectedTabIndexKey);
      final index = int.tryParse(raw ?? '');
      if (index == null) {
        return null;
      }
      final version = ref
          .read(appDatabaseProvider)
          .getSetting(_selectedTabIndexVersionKey);
      final migratedIndex = version == '$_selectedTabIndexVersion'
          ? index
          : index + 1;
      final clamped = migratedIndex.clamp(0, _tabs.length - 1).toInt();
      if (version != '$_selectedTabIndexVersion') {
        ref
            .read(appDatabaseProvider)
            .setSetting(_selectedTabIndexKey, clamped.toString());
        ref
            .read(appDatabaseProvider)
            .setSetting(
              _selectedTabIndexVersionKey,
              _selectedTabIndexVersion.toString(),
            );
      }
      return clamped;
    } catch (_) {
      return null;
    }
  }

  AppDatabase _globalDatabase() {
    try {
      return ref.read(globalDatabaseProvider);
    } catch (_) {
      // 独立组件测试与预览可能只注入工作区数据库；生产环境始终使用全局数据库。
      return ref.read(appDatabaseProvider);
    }
  }

  void _selectTab(int index) {
    _setTabIndex(index, persist: true);
  }

  void _setTabIndex(int index, {required bool persist}) {
    final nextIndex = index.clamp(0, _tabs.length - 1).toInt();
    if (_tabIndex == nextIndex) {
      return;
    }
    setState(() => _tabIndex = nextIndex);
    if (!persist) {
      return;
    }
    try {
      ref
          .read(appDatabaseProvider)
          .setSetting(_selectedTabIndexKey, nextIndex.toString());
      ref
          .read(appDatabaseProvider)
          .setSetting(
            _selectedTabIndexVersionKey,
            _selectedTabIndexVersion.toString(),
          );
    } catch (_) {
      // 测试或预览环境可能没有注入数据库，生产环境会正常保存。
    }
  }

  void _showOnboarding() {
    _onboardingController.start(originTabIndex: _tabIndex);
  }

  void _handleOnboardingChanged() {
    if (!mounted) {
      return;
    }
    final requestedTabIndex = _onboardingController.visible
        ? _onboardingController.currentStep.tabIndex
        : _onboardingController.takeExitTabIndex();
    if (requestedTabIndex != null && requestedTabIndex != _tabIndex) {
      _setTabIndex(requestedTabIndex, persist: false);
    } else {
      setState(() {});
    }
    if (!_onboardingController.visible) {
      _handleUpdaterStateChanged();
    }
  }

  void _handleUpdaterStateChanged() {
    if (!mounted || _updatePromptVisible || _onboardingController.visible) {
      return;
    }
    if (!_updaterController.shouldShowReadyPrompt) {
      return;
    }
    _updatePromptVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showUpdateReadyDialog());
    });
  }

  Future<void> _showUpdateReadyDialog() async {
    try {
      if (!mounted ||
          _onboardingController.visible ||
          !_updaterController.shouldShowReadyPrompt) {
        return;
      }
      final versionTag = _updaterController.value.readyVersionTag;
      if (versionTag == null) {
        return;
      }
      final action = await showDialog<_UpdateReadyAction>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(Icons.system_update_alt_rounded),
            title: const Text('更新已下载完成'),
            content: Text('新版本 $versionTag 已准备好。可以现在更新并重启故事板，也可以安排到下次启动时更新。'),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(_UpdateReadyAction.nextStartup);
                },
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('下次启动更新'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(_UpdateReadyAction.installNow);
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('立即更新'),
              ),
            ],
          );
        },
      );
      if (!mounted) {
        return;
      }
      switch (action) {
        case _UpdateReadyAction.installNow:
          await _updaterController.installPendingUpdateNow();
        case _UpdateReadyAction.nextStartup:
          _updaterController.installPendingUpdateOnNextStartup();
        case null:
          _updaterController.installPendingUpdateOnNextStartup();
      }
    } finally {
      _updatePromptVisible = false;
      if (mounted && _updaterController.shouldShowReadyPrompt) {
        _handleUpdaterStateChanged();
      }
    }
  }
}

enum _UpdateReadyAction { installNow, nextStartup }

class _BottomTabs extends StatelessWidget {
  const _BottomTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.projectName,
    this.onCloseProject,
  });

  final List<_ShellTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String? projectName;
  final Future<void> Function()? onCloseProject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasProjectEntry = projectName != null || onCloseProject != null;
    final tabsWidget = Container(
      key: const ValueKey('app-shell-bottom-tabs'),
      constraints: const BoxConstraints(maxWidth: 920),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          if (hasProjectEntry)
            _ProjectShortcut(
              projectName: projectName,
              onCloseProject: onCloseProject,
            ),
          for (var i = 0; i < tabs.length; i++)
            _TabButton(
              tab: tabs[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
        ],
      ),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Center(child: tabsWidget),
    );
  }
}

class _ProjectShortcut extends StatelessWidget {
  const _ProjectShortcut({this.projectName, this.onCloseProject});

  final String? projectName;
  final Future<void> Function()? onCloseProject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = projectName ?? '返回首页';
    return SizedBox(
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: InkWell(
          key: const ValueKey('close-project-to-home'),
          borderRadius: BorderRadius.circular(10),
          onTap: onCloseProject == null ? null : () => onCloseProject!(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.home_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
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

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _ShellTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tab.label,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        key: ValueKey('app-shell-tab-${tab.label}'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.9)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.32)
                  : scheme.outlineVariant.withValues(alpha: 0.28),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 18,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                tab.label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab(this.label, this.icon);

  final String label;
  final IconData icon;
}
