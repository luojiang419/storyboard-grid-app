enum OnboardingSection {
  overview,
  design,
  gridCut,
  storyboard,
  exporter,
  settings,
}

class OnboardingStep {
  const OnboardingStep({
    required this.id,
    required this.section,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.tabIndex,
  });

  final String id;
  final OnboardingSection section;
  final String eyebrow;
  final String title;
  final String body;
  final int tabIndex;
}

const onboardingSteps = <OnboardingStep>[
  OnboardingStep(
    id: 'welcome',
    section: OnboardingSection.overview,
    eyebrow: '欢迎使用故事板',
    title: '从一个创意，到完整故事板',
    body: '这段快速导览会带你认识设计分镜、宫格裁切、拖拽排版、导出和设置。你可以随时跳过，也能通过标题栏的帮助按钮重新查看。',
    tabIndex: 0,
  ),
  OnboardingStep(
    id: 'design',
    section: OnboardingSection.design,
    eyebrow: '第 1 步 · 设计分镜图',
    title: '先把创意变成连贯镜头',
    body: '输入画面需求、选择比例和宫格，再生成完整分镜图。生成结果会保存在当前工程中，并可直接送往下一步裁切。',
    tabIndex: 0,
  ),
  OnboardingStep(
    id: 'grid-cut',
    section: OnboardingSection.gridCut,
    eyebrow: '第 2 步 · 多宫格裁切',
    title: '把组合图拆成独立镜头',
    body: '导入或接收分镜图后，软件会自动识别宫格。你也可以拖动标线、调整行列并手动修正每个镜头的边界。',
    tabIndex: 1,
  ),
  OnboardingStep(
    id: 'storyboard',
    section: OnboardingSection.storyboard,
    eyebrow: '第 3 步 · 故事板拼图',
    title: '拖拽排序并补充拍摄说明',
    body: '把左侧素材拖进画板，自由调整顺序、列数、间距和编号。镜头描述可以手动编辑，也可以使用视觉模型辅助整理。',
    tabIndex: 2,
  ),
  OnboardingStep(
    id: 'export',
    section: OnboardingSection.exporter,
    eyebrow: '第 4 步 · 导出故事板',
    title: '预览并交付最终成果',
    body: '选择需要交付的画板，预览最终排版，然后导出 PNG、JPG、PDF、画板图片或拍摄脚本。',
    tabIndex: 3,
  ),
  OnboardingStep(
    id: 'settings',
    section: OnboardingSection.settings,
    eyebrow: '第 5 步 · 设置',
    title: '按需要配置 AI 与工作环境',
    body: '图片生成和视觉分析需要先配置相应服务商的地址与 API Key；本地裁切、排版和导出功能不依赖这些配置。',
    tabIndex: 4,
  ),
];
