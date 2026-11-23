import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../projects/application/project_workspace_controller.dart';
import '../../storyboard/domain/image_generation_model_catalog.dart';
import '../../storyboard/presentation/widgets/image_generation_model_selector.dart';
import '../../updater/domain/app_update_config.dart';
import '../../updater/domain/update_models.dart';
import '../application/settings_controller.dart';
import '../domain/app_settings.dart';
import '../domain/image_generation_api_config.dart';
import '../domain/vision_api_config.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

enum _SettingsSection {
  projects,
  exportDirectory,
  storyboardExport,
  visionApi,
  imageGenerationApi,
  updater,
  dataDirectories,
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const _expandedSectionsKey = 'settingsPageExpandedSections';

  late final SettingsController _settingsController;
  late final TextEditingController _exportPathController;
  late final TextEditingController _imageGenerationApiBaseUrlController;
  late final TextEditingController _imageGenerationApiKeyController;
  late final TextEditingController _imageGenerationGeminiApiBaseUrlController;
  late final TextEditingController _imageGenerationGeminiApiKeyController;
  late final TextEditingController _imageGenerationApiMartApiBaseUrlController;
  late final TextEditingController _imageGenerationApiMartApiKeyController;
  late final TextEditingController _imageGenerationModelController;
  late final TextEditingController _updateManualProxyUrlController;
  bool _imageGenerationApiKeyObscured = true;
  bool _imageGenerationGeminiApiKeyObscured = true;
  bool _imageGenerationApiMartApiKeyObscured = true;
  final _expandedSections = <_SettingsSection>{};

  @override
  void initState() {
    super.initState();
    final controller = ref.read(settingsControllerProvider);
    _settingsController = controller;
    _exportPathController = TextEditingController(
      text: controller.value.exportDirectory,
    );
    _imageGenerationApiBaseUrlController = TextEditingController(
      text: controller.value.imageGenerationApiBaseUrl,
    );
    _imageGenerationApiKeyController = TextEditingController(
      text: controller.value.imageGenerationApiKey,
    );
    _imageGenerationGeminiApiBaseUrlController = TextEditingController(
      text: controller.value.imageGenerationGeminiApiBaseUrl,
    );
    _imageGenerationGeminiApiKeyController = TextEditingController(
      text: controller.value.imageGenerationGeminiApiKey,
    );
    _imageGenerationApiMartApiBaseUrlController = TextEditingController(
      text: controller.value.imageGenerationApiMartApiBaseUrl,
    );
    _imageGenerationApiMartApiKeyController = TextEditingController(
      text: controller.value.imageGenerationApiMartApiKey,
    );
    _imageGenerationModelController = TextEditingController(
      text: controller.value.imageGenerationModel,
    );
    _updateManualProxyUrlController = TextEditingController(
      text: controller.value.updateManualProxyUrl,
    );
    _expandedSections.addAll(_loadExpandedSections());
    controller.addListener(_syncFromSettings);
  }

  @override
  void dispose() {
    _settingsController.removeListener(_syncFromSettings);
    _exportPathController.dispose();
    _imageGenerationApiBaseUrlController.dispose();
    _imageGenerationApiKeyController.dispose();
    _imageGenerationGeminiApiBaseUrlController.dispose();
    _imageGenerationGeminiApiKeyController.dispose();
    _imageGenerationApiMartApiBaseUrlController.dispose();
    _imageGenerationApiMartApiKeyController.dispose();
    _imageGenerationModelController.dispose();
    _updateManualProxyUrlController.dispose();
    super.dispose();
  }

  void _syncFromSettings() {
    final settings = ref.read(settingsControllerProvider).value;
    if (_exportPathController.text != settings.exportDirectory) {
      _exportPathController.text = settings.exportDirectory;
    }
    if (_imageGenerationApiBaseUrlController.text !=
        settings.imageGenerationApiBaseUrl) {
      _imageGenerationApiBaseUrlController.text =
          settings.imageGenerationApiBaseUrl;
    }
    if (_imageGenerationApiKeyController.text !=
        settings.imageGenerationApiKey) {
      _imageGenerationApiKeyController.text = settings.imageGenerationApiKey;
    }
    if (_imageGenerationGeminiApiBaseUrlController.text !=
        settings.imageGenerationGeminiApiBaseUrl) {
      _imageGenerationGeminiApiBaseUrlController.text =
          settings.imageGenerationGeminiApiBaseUrl;
    }
    if (_imageGenerationGeminiApiKeyController.text !=
        settings.imageGenerationGeminiApiKey) {
      _imageGenerationGeminiApiKeyController.text =
          settings.imageGenerationGeminiApiKey;
    }
    if (_imageGenerationApiMartApiBaseUrlController.text !=
        settings.imageGenerationApiMartApiBaseUrl) {
      _imageGenerationApiMartApiBaseUrlController.text =
          settings.imageGenerationApiMartApiBaseUrl;
    }
    if (_imageGenerationApiMartApiKeyController.text !=
        settings.imageGenerationApiMartApiKey) {
      _imageGenerationApiMartApiKeyController.text =
          settings.imageGenerationApiMartApiKey;
    }
    if (_imageGenerationModelController.text != settings.imageGenerationModel) {
      _imageGenerationModelController.text = settings.imageGenerationModel;
    }
    if (_updateManualProxyUrlController.text != settings.updateManualProxyUrl) {
      _updateManualProxyUrlController.text = settings.updateManualProxyUrl;
    }
  }

  Future<void> _saveGrsaiImageGenerationSettings(
    SettingsController controller,
  ) async {
    await controller.setImageGenerationGrsaiSettings(
      baseUrl: _imageGenerationApiBaseUrlController.text,
      apiKey: _imageGenerationApiKeyController.text,
    );
  }

  Future<void> _saveGeminiImageGenerationSettings(
    SettingsController controller,
  ) async {
    await controller.setImageGenerationGeminiSettings(
      baseUrl: _imageGenerationGeminiApiBaseUrlController.text,
      apiKey: _imageGenerationGeminiApiKeyController.text,
    );
  }

  Future<void> _saveApiMartImageGenerationSettings(
    SettingsController controller,
  ) async {
    try {
      await controller.setImageGenerationApiMartSettings(
        baseUrl: _imageGenerationApiMartApiBaseUrlController.text,
        apiKey: _imageGenerationApiMartApiKeyController.text,
      );
      if (!mounted) {
        return;
      }
      final hasApiKey =
          controller.value.imageGenerationApiMartApiKey.isNotEmpty;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasApiKey
                ? 'APIMart 配置已保存，请求地址：${controller.value.imageGenerationApiMartApiBaseUrl}'
                : 'APIMart 地址已保存；API Key 为空，生成前请先填写',
          ),
        ),
      );
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _selectedImageProviderSummary(AppSettings settings) {
    final descriptor = ImageGenerationCatalog.descriptorFor(
      _imageGenerationModelController.text,
    );
    if (descriptor == null) {
      return '当前模型不在支持目录中，请重新选择';
    }
    return switch (descriptor.protocol) {
      ImageGenerationProviderProtocol.apiMart =>
        '将自动使用 APIMart 配置 · ${settings.imageGenerationApiMartApiBaseUrl}',
      ImageGenerationProviderProtocol.gemini =>
        '将自动使用 Gemini 配置 · ${settings.imageGenerationGeminiApiBaseUrl}',
      ImageGenerationProviderProtocol.grsai =>
        '将自动使用 GRSai 配置 · ${settings.imageGenerationApiBaseUrl}',
    };
  }

  Future<void> _saveUpdateSettings(SettingsController controller) async {
    await controller.setUpdateManualProxyUrl(
      _updateManualProxyUrlController.text,
    );
  }

  AppDatabase get _globalSettingsDatabase {
    try {
      return ref.read(globalDatabaseProvider);
    } catch (_) {
      return ref.read(appDatabaseProvider);
    }
  }

  bool get _showWelcomeOnStartup =>
      _globalSettingsDatabase.getSetting(
        ProjectWorkspaceController.showWelcomeSettingKey,
      ) !=
      'false';

  String _defaultProjectRoot(String fallback) {
    final saved = _globalSettingsDatabase.getSetting(
      ProjectWorkspaceController.defaultProjectRootSettingKey,
    );
    return saved == null || saved.trim().isEmpty ? fallback : saved.trim();
  }

  void _setShowWelcomeOnStartup(bool value) {
    _globalSettingsDatabase.setSetting(
      ProjectWorkspaceController.showWelcomeSettingKey,
      value.toString(),
    );
    setState(() {});
  }

  Future<void> _pickDefaultProjectRoot() async {
    final directories = ref.read(appDirectoriesProvider);
    final current = _defaultProjectRoot(directories.projects.path);
    final path = await getDirectoryPath(
      initialDirectory: current,
      confirmButtonText: '选择默认工程目录',
    );
    if (path == null) {
      return;
    }
    try {
      final directory = Directory(path);
      await directory.create(recursive: true);
      final probe = File(
        '${directory.path}${Platform.pathSeparator}.storyboard-write-test',
      );
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      _globalSettingsDatabase.setSetting(
        ProjectWorkspaceController.defaultProjectRootSettingKey,
        directory.absolute.path,
      );
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('目录不可写：$error')));
      }
    }
  }

  void _resetDefaultProjectRoot() {
    final directories = ref.read(appDirectoriesProvider);
    _globalSettingsDatabase.setSetting(
      ProjectWorkspaceController.defaultProjectRootSettingKey,
      directories.projects.path,
    );
    setState(() {});
  }

  bool _sectionExpanded(_SettingsSection section) {
    return _expandedSections.contains(section);
  }

  void _toggleSection(_SettingsSection section) {
    setState(() {
      if (!_expandedSections.add(section)) {
        _expandedSections.remove(section);
      }
    });
    _saveExpandedSections();
  }

  Set<_SettingsSection> _loadExpandedSections() {
    try {
      final raw = ref
          .read(appDatabaseProvider)
          .getSetting(_expandedSectionsKey);
      if (raw == null || raw.trim().isEmpty) {
        return {};
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return {};
      }
      final names = decoded.whereType<String>().toSet();
      return {
        for (final section in _SettingsSection.values)
          if (names.contains(section.name)) section,
      };
    } catch (_) {
      return {};
    }
  }

  void _saveExpandedSections() {
    try {
      final names = [
        for (final section in _SettingsSection.values)
          if (_expandedSections.contains(section)) section.name,
      ];
      ref
          .read(appDatabaseProvider)
          .setSetting(_expandedSectionsKey, jsonEncode(names));
    } catch (_) {
      // 测试或预览环境可能没有注入数据库，生产环境会正常保存。
    }
  }

  @override
  Widget build(BuildContext context) {
    final directories = ref.watch(appDirectoriesProvider);
    final settingsController = ref.watch(settingsControllerProvider);
    final updaterController = ref.watch(updaterControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: settingsController,
      builder: (context, settings, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Section(
              title: '外观',
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<AppThemePreference>(
                  segments: [
                    for (final preference in AppThemePreference.values)
                      ButtonSegment(
                        value: preference,
                        label: Text(preference.label),
                        icon: Icon(switch (preference) {
                          AppThemePreference.system =>
                            Icons.brightness_auto_rounded,
                          AppThemePreference.light => Icons.light_mode_rounded,
                          AppThemePreference.dark => Icons.dark_mode_rounded,
                        }),
                      ),
                  ],
                  selected: {settings.themePreference},
                  onSelectionChanged: (selection) {
                    settingsController.setThemePreference(selection.first);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            _CollapsibleSection(
              title: '工程与启动',
              expanded: _sectionExpanded(_SettingsSection.projects),
              onToggle: () => _toggleSection(_SettingsSection.projects),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('启动时显示欢迎页'),
                    subtitle: const Text('关闭后，软件下次启动将直接进入工程首页。'),
                    value: _showWelcomeOnStartup,
                    onChanged: _setShowWelcomeOnStartup,
                  ),
                  const SizedBox(height: 8),
                  Text('默认工程目录', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _defaultProjectRoot(directories.projects.path),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickDefaultProjectRoot,
                        icon: const Icon(Icons.folder_open_rounded),
                        label: const Text('更改'),
                      ),
                      TextButton(
                        onPressed: _resetDefaultProjectRoot,
                        child: const Text('恢复默认'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('默认位置为软件 data/project；不可写时请改用拥有写权限的目录。'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _CollapsibleSection(
              title: '导出文件夹',
              expanded: _sectionExpanded(_SettingsSection.exportDirectory),
              onToggle: () => _toggleSection(_SettingsSection.exportDirectory),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _exportPathController,
                    decoration: const InputDecoration(
                      labelText: '默认导出路径',
                      prefixIcon: Icon(Icons.folder_open_rounded),
                    ),
                    onSubmitted: settingsController.setExportDirectory,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          final path = await getDirectoryPath(
                            initialDirectory: settings.exportDirectory,
                          );
                          if (path != null) {
                            await settingsController.setExportDirectory(path);
                          }
                        },
                        icon: const Icon(Icons.folder_rounded),
                        label: const Text('选择文件夹'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => settingsController.setExportDirectory(
                          _exportPathController.text,
                        ),
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('保存路径'),
                      ),
                      TextButton.icon(
                        onPressed: settingsController.resetToDefaults,
                        icon: const Icon(Icons.settings_backup_restore_rounded),
                        label: const Text('恢复默认'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _CollapsibleSection(
              title: '故事板导出',
              expanded: _sectionExpanded(_SettingsSection.storyboardExport),
              onToggle: () => _toggleSection(_SettingsSection.storyboardExport),
              child: SwitchListTile(
                value: settings.storyboardSummaryPageEnabled,
                contentPadding: EdgeInsets.zero,
                title: const Text('故事板内容页'),
                subtitle: const Text('开启后导出时附带自动归纳的大纲、内容、场景和道具页'),
                onChanged: settingsController.setStoryboardSummaryPageEnabled,
              ),
            ),
            const SizedBox(height: 14),
            _CollapsibleSection(
              title: '视觉模型 API',
              expanded: _sectionExpanded(_SettingsSection.visionApi),
              onToggle: () => _toggleSection(_SettingsSection.visionApi),
              child: _VisionApiConfigsSection(
                settings: settings,
                controller: settingsController,
              ),
            ),
            const SizedBox(height: 14),
            _CollapsibleSection(
              title: '图片生成 API',
              expanded: _sectionExpanded(_SettingsSection.imageGenerationApi),
              onToggle: () =>
                  _toggleSection(_SettingsSection.imageGenerationApi),
              child: Column(
                children: [
                  _ImageApiConfigsSection(
                    settings: settings,
                    controller: settingsController,
                  ),
                  if (Platform
                          .environment['STORYBOARD_SHOW_LEGACY_IMAGE_API'] ==
                      '1') ...[
                    _ImageProviderSettingsCard(
                      key: const ValueKey('image-provider-card-default'),
                      icon: Icons.auto_fix_high_rounded,
                      title: '默认图片生成模型',
                      subtitle: '选择模型后会自动绑定对应服务商的地址和 Key',
                      actionKey: const ValueKey(
                        'save-image-generation-default-model',
                      ),
                      actionLabel: '保存默认模型',
                      onSave: () => settingsController.setImageGenerationModel(
                        _imageGenerationModelController.text,
                      ),
                      children: [
                        ImageGenerationModelSelector(
                          key: const ValueKey('image-generation-model-field'),
                          value: _imageGenerationModelController.text,
                          labelText: '默认模型',
                          prefixIcon: const Icon(Icons.account_tree_rounded),
                          onChanged: (model) {
                            setState(() {
                              _imageGenerationModelController.text = model;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        _ProviderRouteHint(
                          text: _selectedImageProviderSummary(settings),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ImageProviderSettingsCard(
                      key: const ValueKey('image-provider-card-grsai'),
                      icon: Icons.cloud_queue_rounded,
                      title: 'GRSai',
                      subtitle: '独立接口 · Nano Banana、GPT Image 系列',
                      actionKey: const ValueKey(
                        'save-image-generation-grsai-settings',
                      ),
                      actionLabel: '保存 GRSai 配置',
                      onSave: () =>
                          _saveGrsaiImageGenerationSettings(settingsController),
                      children: [
                        TextField(
                          key: const ValueKey(
                            'image-generation-api-base-url-field',
                          ),
                          controller: _imageGenerationApiBaseUrlController,
                          decoration: const InputDecoration(
                            labelText: 'GRSai API 地址',
                            prefixIcon: Icon(Icons.link_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const ValueKey('image-generation-api-key-field'),
                          controller: _imageGenerationApiKeyController,
                          obscureText: _imageGenerationApiKeyObscured,
                          decoration: InputDecoration(
                            labelText: 'GRSai API Key',
                            prefixIcon: const Icon(Icons.vpn_key_rounded),
                            suffixIcon: IconButton(
                              tooltip: _imageGenerationApiKeyObscured
                                  ? '显示 Key'
                                  : '隐藏 Key',
                              onPressed: () {
                                setState(() {
                                  _imageGenerationApiKeyObscured =
                                      !_imageGenerationApiKeyObscured;
                                });
                              },
                              icon: Icon(
                                _imageGenerationApiKeyObscured
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ImageProviderSettingsCard(
                      key: const ValueKey('image-provider-card-gemini'),
                      icon: Icons.auto_awesome_rounded,
                      title: 'Gemini',
                      subtitle: '独立诗影接口 · Gemini Image 系列',
                      actionKey: const ValueKey(
                        'save-image-generation-gemini-settings',
                      ),
                      actionLabel: '保存 Gemini 配置',
                      onSave: () => _saveGeminiImageGenerationSettings(
                        settingsController,
                      ),
                      children: [
                        TextField(
                          key: const ValueKey(
                            'image-generation-gemini-api-base-url-field',
                          ),
                          controller:
                              _imageGenerationGeminiApiBaseUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Gemini API 地址',
                            prefixIcon: Icon(Icons.link_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const ValueKey(
                            'image-generation-gemini-api-key-field',
                          ),
                          controller: _imageGenerationGeminiApiKeyController,
                          obscureText: _imageGenerationGeminiApiKeyObscured,
                          decoration: InputDecoration(
                            labelText: 'Gemini API Key',
                            prefixIcon: const Icon(Icons.key_rounded),
                            suffixIcon: IconButton(
                              tooltip: _imageGenerationGeminiApiKeyObscured
                                  ? '显示 Key'
                                  : '隐藏 Key',
                              onPressed: () {
                                setState(() {
                                  _imageGenerationGeminiApiKeyObscured =
                                      !_imageGenerationGeminiApiKeyObscured;
                                });
                              },
                              icon: Icon(
                                _imageGenerationGeminiApiKeyObscured
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ImageProviderSettingsCard(
                      key: const ValueKey('image-provider-card-apimart'),
                      icon: Icons.hub_rounded,
                      title: 'APIMart',
                      subtitle: '独立官方接口 · 异步任务、上传与多模型系列',
                      actionKey: const ValueKey(
                        'save-image-generation-apimart-settings',
                      ),
                      actionLabel: '保存 APIMart 配置',
                      onSave: () => _saveApiMartImageGenerationSettings(
                        settingsController,
                      ),
                      children: [
                        TextField(
                          key: const ValueKey(
                            'image-generation-apimart-api-base-url-field',
                          ),
                          controller:
                              _imageGenerationApiMartApiBaseUrlController,
                          decoration: const InputDecoration(
                            labelText: 'APIMart API 地址',
                            hintText: 'https://api.apimart.ai',
                            helperText: '可粘贴带 /v1 的地址，保存时会自动规范化',
                            prefixIcon: Icon(Icons.link_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const ValueKey(
                            'image-generation-apimart-api-key-field',
                          ),
                          controller: _imageGenerationApiMartApiKeyController,
                          obscureText: _imageGenerationApiMartApiKeyObscured,
                          decoration: InputDecoration(
                            labelText: 'APIMart API Key',
                            prefixIcon: const Icon(Icons.key_rounded),
                            suffixIcon: IconButton(
                              tooltip: _imageGenerationApiMartApiKeyObscured
                                  ? '显示 Key'
                                  : '隐藏 Key',
                              onPressed: () {
                                setState(() {
                                  _imageGenerationApiMartApiKeyObscured =
                                      !_imageGenerationApiMartApiKeyObscured;
                                });
                              },
                              icon: Icon(
                                _imageGenerationApiMartApiKeyObscured
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _CollapsibleSection(
              title: '软件更新',
              expanded: _sectionExpanded(_SettingsSection.updater),
              onToggle: () => _toggleSection(_SettingsSection.updater),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PathTile(
                    label: '当前版本',
                    path: AppUpdateConfig.currentVersionTag,
                  ),
                  SwitchListTile(
                    key: const ValueKey('auto-install-updates-switch'),
                    value: settings.autoInstallUpdates,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('自动更新'),
                    subtitle: const Text('开启后下载完成会直接升级，关闭时会先弹窗确认'),
                    onChanged: settingsController.setAutoInstallUpdates,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<UpdateDownloadMode>(
                      segments: [
                        for (final mode in UpdateDownloadMode.values)
                          ButtonSegment(
                            value: mode,
                            label: Text(mode.label),
                            icon: Icon(switch (mode) {
                              UpdateDownloadMode.automatic =>
                                Icons.travel_explore_rounded,
                              UpdateDownloadMode.manual =>
                                Icons.settings_ethernet_rounded,
                              UpdateDownloadMode.direct =>
                                Icons.near_me_rounded,
                            }),
                          ),
                      ],
                      selected: {settings.updateDownloadMode},
                      onSelectionChanged: (selection) {
                        settingsController.setUpdateDownloadMode(
                          selection.first,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _updateManualProxyUrlController,
                    decoration: const InputDecoration(
                      labelText: '手动代理',
                      prefixIcon: Icon(Icons.hub_rounded),
                    ),
                    onSubmitted: settingsController.setUpdateManualProxyUrl,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          await _saveUpdateSettings(settingsController);
                          await updaterController.checkForUpdates();
                        },
                        icon: const Icon(Icons.system_update_rounded),
                        label: const Text('检查更新'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _saveUpdateSettings(settingsController),
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('保存更新设置'),
                      ),
                      ValueListenableBuilder(
                        valueListenable: updaterController,
                        builder: (context, updateState, _) {
                          if (!updateState.hasReadyUpdate) {
                            return const SizedBox.shrink();
                          }
                          return FilledButton.tonalIcon(
                            onPressed: updateState.isBusy
                                ? null
                                : () => updaterController
                                      .installPendingUpdateNow(),
                            icon: const Icon(Icons.system_update_alt_rounded),
                            label: const Text('立即更新'),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder(
                    valueListenable: updaterController,
                    builder: (context, updateState, _) {
                      return _UpdateStatusPanel(state: updateState);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _CollapsibleSection(
              title: '数据目录',
              expanded: _sectionExpanded(_SettingsSection.dataDirectories),
              onToggle: () => _toggleSection(_SettingsSection.dataDirectories),
              child: Column(
                children: [
                  _PathTile(
                    label: '程序同级目录',
                    path: directories.executableDirectory.path,
                    onOpen: () =>
                        _openDirectory(directories.executableDirectory.path),
                  ),
                  _PathTile(
                    label: 'data',
                    path: directories.data.path,
                    onOpen: () => _openDirectory(directories.data.path),
                  ),
                  _PathTile(
                    label: 'imports',
                    path: directories.imports.path,
                    onOpen: () => _openDirectory(directories.imports.path),
                  ),
                  _PathTile(
                    label: 'cuts',
                    path: directories.cuts.path,
                    onOpen: () => _openDirectory(directories.cuts.path),
                  ),
                  _PathTile(
                    label: 'storyboards',
                    path: directories.storyboards.path,
                    onOpen: () => _openDirectory(directories.storyboards.path),
                  ),
                  _PathTile(
                    label: 'exports',
                    path: directories.exports.path,
                    onOpen: () => _openDirectory(directories.exports.path),
                  ),
                  _PathTile(
                    label: 'updates',
                    path: directories.updates.path,
                    onOpen: () => _openDirectory(directories.updates.path),
                  ),
                  _PathTile(
                    label: 'database',
                    path: directories.database.path,
                    onOpen: () => _openDirectory(directories.database.path),
                  ),
                  _PathTile(
                    label: 'temp',
                    path: directories.temp.path,
                    onOpen: () => _openDirectory(directories.temp.path),
                  ),
                  _PathTile(
                    label: 'logs',
                    path: directories.logs.path,
                    onOpen: () => _openDirectory(directories.logs.path),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '配置已持久化到 ${directories.databaseFile.path}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openDirectory(String path) async {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    await Process.start('explorer.exe', [directory.path]);
  }
}

class _VisionApiConfigsSection extends StatelessWidget {
  const _VisionApiConfigsSection({
    required this.settings,
    required this.controller,
  });

  final AppSettings settings;
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final configs = settings.visionApiConfigs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '点击卡片即可设为默认；双击或菜单可编辑。MiniMax-M3 默认最多并发 200 路。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final config in configs)
              SizedBox(
                width: 260,
                child: _VisionApiConfigCard(
                  config: config,
                  selected: config.id == settings.activeVisionApiConfig?.id,
                  allowDelete: configs.length > 1,
                  onSelect: () => controller.saveVisionApiConfigs(
                    configs: configs,
                    activeConfigId: config.id,
                  ),
                  onEdit: () => _showConfigDialog(context, config),
                  onDelete: () {
                    final remaining = configs
                        .where((item) => item.id != config.id)
                        .toList();
                    return controller.saveVisionApiConfigs(
                      configs: remaining,
                      activeConfigId:
                          settings.activeVisionApiConfig?.id == config.id
                          ? remaining.first.id
                          : settings.activeVisionApiConfig!.id,
                    );
                  },
                ),
              ),
            SizedBox(
              width: 160,
              height: 162,
              child: OutlinedButton.icon(
                onPressed: () => _showConfigDialog(context),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('添加 API 卡片'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showConfigDialog(
    BuildContext context, [
    VisionApiConfig? existing,
  ]) async {
    final result = await showDialog<VisionApiConfig>(
      context: context,
      builder: (_) => _VisionApiConfigDialog(config: existing),
    );
    if (result == null) {
      return;
    }
    final configs = existing == null
        ? [...settings.visionApiConfigs, result]
        : [
            for (final config in settings.visionApiConfigs)
              config.id == result.id ? result : config,
          ];
    await controller.saveVisionApiConfigs(
      configs: configs,
      activeConfigId: existing == null
          ? result.id
          : settings.activeVisionApiConfig?.id ?? result.id,
    );
  }
}

class _VisionApiConfigCard extends StatelessWidget {
  const _VisionApiConfigCard({
    required this.config,
    required this.selected,
    required this.allowDelete,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final VisionApiConfig config;
  final bool selected;
  final bool allowDelete;
  final Future<void> Function() onSelect;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.46)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onSelect,
        onDoubleTap: onEdit,
        child: Container(
          height: 162,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primary : scheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    config.isMiniMaxM3
                        ? Icons.bolt_rounded
                        : Icons.visibility_rounded,
                    color: selected ? primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      config.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: '配置操作',
                    onSelected: (action) async {
                      if (action == 'edit') {
                        await onEdit();
                      } else if (action == 'delete') {
                        await onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('编辑')),
                      if (allowDelete)
                        const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                config.model.isEmpty ? '未设置模型' : config.model,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: selected ? primary : scheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                config.baseUrl.isEmpty
                    ? '未设置接口地址'
                    : config.baseUrl.replaceFirst(RegExp(r'^https?://'), ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              if (selected)
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('当前默认'),
                )
              else if (config.isMiniMaxM3)
                Text(
                  'MiniMax 专用 · 最多 200 并发',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisionApiConfigDialog extends StatefulWidget {
  const _VisionApiConfigDialog({this.config});

  final VisionApiConfig? config;

  @override
  State<_VisionApiConfigDialog> createState() => _VisionApiConfigDialogState();
}

class _VisionApiConfigDialogState extends State<_VisionApiConfigDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  var _apiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _nameController = TextEditingController(text: config?.name ?? '');
    _baseUrlController = TextEditingController(text: config?.baseUrl ?? '');
    _apiKeyController = TextEditingController(text: config?.apiKey ?? '');
    _modelController = TextEditingController(text: config?.model ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _applyMiniMaxPreset() {
    setState(() {
      _nameController.text = _nameController.text.trim().isEmpty
          ? 'MiniMax M3'
          : _nameController.text;
      _baseUrlController.text = 'https://api.minimaxi.com';
      _modelController.text = 'MiniMax-M3';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.config == null ? '添加视觉 API 卡片' : '编辑视觉 API 卡片'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _applyMiniMaxPreset,
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text('使用 MiniMax-M3 预设'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '卡片名称'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'API 地址',
                  hintText: 'https://api.minimaxi.com',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                obscureText: !_apiKeyVisible,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  suffixIcon: IconButton(
                    tooltip: _apiKeyVisible ? '隐藏 Key' : '显示 Key',
                    icon: Icon(
                      _apiKeyVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () =>
                        setState(() => _apiKeyVisible = !_apiKeyVisible),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: '模型'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final baseUrl = _baseUrlController.text.trim();
            final model = _modelController.text.trim();
            if (name.isEmpty || baseUrl.isEmpty || model.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请填写卡片名称、API 地址和模型')),
              );
              return;
            }
            Navigator.pop(
              context,
              VisionApiConfig(
                id: widget.config?.id,
                name: name,
                baseUrl: baseUrl,
                apiKey: _apiKeyController.text.trim(),
                model: model,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _ImageApiConfigsSection extends StatelessWidget {
  const _ImageApiConfigsSection({
    required this.settings,
    required this.controller,
  });
  final AppSettings settings;
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final configs = settings.imageGenerationApiConfigs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '点击卡片设为全局默认；该卡片的模型、协议、地址和 Key 将用于生成。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final config in configs)
              SizedBox(
                width: 260,
                child: _ImageApiConfigCard(
                  config: config,
                  selected:
                      config.id == settings.activeImageGenerationApiConfig?.id,
                  onSelect: () => controller.saveImageGenerationApiConfigs(
                    configs: configs,
                    activeConfigId: config.id,
                  ),
                  onEdit: () => _edit(context, config),
                  onDelete: configs.length > 1
                      ? () {
                          final remaining = configs
                              .where((item) => item.id != config.id)
                              .toList();
                          return controller.saveImageGenerationApiConfigs(
                            configs: remaining,
                            activeConfigId:
                                settings.activeImageGenerationApiConfig?.id ==
                                    config.id
                                ? remaining.first.id
                                : settings.activeImageGenerationApiConfig!.id,
                          );
                        }
                      : null,
                ),
              ),
            SizedBox(
              width: 160,
              height: 160,
              child: OutlinedButton.icon(
                onPressed: () => _edit(context, null),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('添加 API 卡片'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    ImageGenerationApiConfig? existing,
  ) async {
    final saved = await showDialog<ImageGenerationApiConfig>(
      context: context,
      builder: (_) => _ImageApiConfigDialog(config: existing),
    );
    if (saved == null) return;
    final configs = existing == null
        ? [...settings.imageGenerationApiConfigs, saved]
        : [
            for (final config in settings.imageGenerationApiConfigs)
              if (config.id == saved.id) saved else config,
          ];
    await controller.saveImageGenerationApiConfigs(
      configs: configs,
      activeConfigId: existing == null
          ? saved.id
          : settings.activeImageGenerationApiConfig?.id ?? saved.id,
    );
  }
}

class _ImageApiConfigCard extends StatelessWidget {
  const _ImageApiConfigCard({
    required this.config,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    this.onDelete,
  });
  final ImageGenerationApiConfig config;
  final bool selected;
  final Future<void> Function() onSelect;
  final Future<void> Function() onEdit;
  final Future<void> Function()? onDelete;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onSelect,
        onDoubleTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.image_rounded,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      config.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'edit') {
                        await onEdit();
                      } else {
                        await onDelete?.call();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('编辑')),
                      if (onDelete != null)
                        const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${config.type.label} · ${config.model}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                config.baseUrl.replaceFirst(RegExp(r'^https?://'), ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              if (selected)
                const Chip(
                  label: Text('当前默认'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageApiConfigDialog extends StatefulWidget {
  const _ImageApiConfigDialog({this.config});
  final ImageGenerationApiConfig? config;
  @override
  State<_ImageApiConfigDialog> createState() => _ImageApiConfigDialogState();
}

class _ImageApiConfigDialogState extends State<_ImageApiConfigDialog> {
  late final TextEditingController _name, _url, _key, _model;
  late ImageGenerationApiType _type;
  var _visible = false;
  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _name = TextEditingController(text: config?.name ?? '');
    _url = TextEditingController(text: config?.baseUrl ?? '');
    _key = TextEditingController(text: config?.apiKey ?? '');
    _model = TextEditingController(text: config?.model ?? '');
    _type = config?.type ?? ImageGenerationApiType.grsai;
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.config == null ? '添加图片生成 API 卡片' : '编辑图片生成 API 卡片'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: '卡片名称'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField(
            initialValue: _type,
            items: [
              for (final type in ImageGenerationApiType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: (type) => setState(() => _type = type!),
            decoration: const InputDecoration(labelText: '服务商协议'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _model,
            decoration: const InputDecoration(labelText: '默认模型'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _url,
            decoration: const InputDecoration(labelText: 'API 地址'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _key,
            obscureText: !_visible,
            decoration: InputDecoration(
              labelText: 'API Key',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _visible = !_visible),
                icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
              ),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          if (_name.text.trim().isEmpty ||
              _url.text.trim().isEmpty ||
              _model.text.trim().isEmpty) {
            return;
          }
          Navigator.pop(
            context,
            ImageGenerationApiConfig(
              id: widget.config?.id,
              name: _name.text.trim(),
              type: _type,
              baseUrl: _url.text.trim(),
              apiKey: _key.text.trim(),
              model: _model.text.trim(),
            ),
          );
        },
        child: const Text('保存'),
      ),
    ],
  );
}

class _ImageProviderSettingsCard extends StatelessWidget {
  const _ImageProviderSettingsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.actionKey,
    required this.actionLabel,
    required this.onSave,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Key actionKey;
  final String actionLabel;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 21, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            key: actionKey,
            onPressed: onSave,
            icon: const Icon(Icons.save_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _ProviderRouteHint extends StatelessWidget {
  const _ProviderRouteHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.route_rounded,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.48),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.48),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateStatusPanel extends StatelessWidget {
  const _UpdateStatusPanel({required this.state});

  final UpdaterState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = state.statusMessage.trim().isEmpty
        ? '尚未检查更新'
        : state.statusMessage.trim();
    final progress = state.downloadProgress;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.isBusy
                    ? Icons.sync_rounded
                    : state.hasReadyUpdate
                    ? Icons.download_done_rounded
                    : Icons.info_outline_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (state.isBusy && progress != null) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress <= 0 ? null : progress),
          ],
        ],
      ),
    );
  }
}

class _PathTile extends StatelessWidget {
  const _PathTile({required this.label, required this.path, this.onOpen});

  final String label;
  final String path;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              path,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (onOpen != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: '打开目录',
              child: IconButton(
                onPressed: onOpen,
                icon: const Icon(Icons.folder_open_rounded),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
