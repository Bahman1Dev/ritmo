import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/ai_connection_models.dart';
import 'package:ritmo/core/ai/ai_connection_repository.dart';
import 'package:ritmo/core/ai/ai_endpoint_normalizer.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/services/secure_key_store.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_button.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_card.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_page_scaffold.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_segmented_control.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_text_field.dart';
import 'package:ritmo/core/widgets/ritmo_module_app_bar.dart';
import 'package:ritmo/features/profile/presentation/widgets/ai_provider_preset_card.dart';
import 'package:ritmo/features/profile/presentation/widgets/ai_secret_field.dart';
import 'package:ritmo/features/profile/presentation/widgets/ai_status_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiConnectionScreen extends StatefulWidget {
  const AiConnectionScreen({super.key});

  @override
  State<AiConnectionScreen> createState() => _AiConnectionScreenState();
}

class _AiConnectionScreenState extends State<AiConnectionScreen> {
  late final Future<void> _loadFuture;

  late final TextEditingController _urlController;
  late final TextEditingController _keyController;
  late final TextEditingController _modelController;
  late final TextEditingController _customModelController;
  late final TextEditingController _cloudflareAccountIdController;

  late final TextEditingController _backupUrlController;
  late final TextEditingController _backupKeyController;

  late final TextEditingController _featuresUrlController;
  late final TextEditingController _featuresKeyController;
  late final TextEditingController _featuresModelController;

  AiMode _mode = AiMode.ritmoServer;
  String _selectedPresetId = 'zhipu';
  int _timeoutMs = 60000;
  bool _separateFeaturesConfig = false;

  bool _isTesting = false;
  bool _isTestingBackup = false;

  AiTestResult? _lastTestResult;
  List<AiChainEntry> _chainEntries = [];
  bool _cloudConsentGranted = true;

  int _dailyQuotaUsed = 0;
  int _dailyQuotaLimit = 5;
  bool _showDailyQuota = false;

  String? _urlError;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _keyController = TextEditingController();
    _modelController = TextEditingController();
    _customModelController = TextEditingController();
    _cloudflareAccountIdController = TextEditingController();

    _backupUrlController = TextEditingController();
    _backupKeyController = TextEditingController();

    _featuresUrlController = TextEditingController();
    _featuresKeyController = TextEditingController();
    _featuresModelController = TextEditingController();

    _loadFuture = _loadInitialData();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _modelController.dispose();
    _customModelController.dispose();
    _cloudflareAccountIdController.dispose();

    _backupUrlController.dispose();
    _backupKeyController.dispose();

    _featuresUrlController.dispose();
    _featuresKeyController.dispose();
    _featuresModelController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final repo = AiConnectionRepository.instance;
    final config = await repo.load(slot: AiSlot.assistant);
    final featuresConfig = await repo.load(slot: AiSlot.features);
    final mode = await repo.loadMode();
    final lastTest = await repo.lastTest();
    final chain = await repo.describeChain();

    final prefs = await SharedPreferences.getInstance();
    final consent = prefs.getBool('assistant_cloud_consent') ?? true;

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final quotaUsed = prefs.getInt('local_ai_quota_count_$todayStr') ?? 0;
    final isPremium = PremiumService.instance.isPremium;
    final limit = PremiumService.instance.limitFor(PremiumFeature.unlimitedAi);

    setState(() {
      _mode = mode;
      _selectedPresetId = config.providerPresetId.isNotEmpty ? config.providerPresetId : 'zhipu';
      _urlController.text = config.baseUrl;
      _keyController.text = config.apiKey;
      _modelController.text = config.model;
      _timeoutMs = config.timeoutMs;
      _backupUrlController.text = config.backupBaseUrl;
      _backupKeyController.text = config.backupApiKey;
      _cloudflareAccountIdController.text = config.cloudflareAccountId;
      _separateFeaturesConfig = config.separateFeaturesConfig;

      _featuresUrlController.text = featuresConfig.baseUrl;
      _featuresKeyController.text = featuresConfig.apiKey;
      _featuresModelController.text = featuresConfig.model;

      _lastTestResult = lastTest;
      _chainEntries = chain;
      _cloudConsentGranted = consent;

      _dailyQuotaUsed = quotaUsed;
      _dailyQuotaLimit = limit;
      _showDailyQuota = !isPremium;

      _urlError = AiEndpointNormalizer.validate(_urlController.text);
    });
  }

  String get _statusSubtitle {
    if (_mode == AiMode.ritmoServer) {
      return 'متصل · سرور ریتمو';
    }
    final preset = kAiProviderPresets.firstWhere(
      (p) => p.id == _selectedPresetId,
      orElse: () => kAiProviderPresets.first,
    );
    if (_lastTestResult != null && _lastTestResult!.ok) {
      return 'متصل · ${preset.nameFa}';
    } else if (_keyController.text.isEmpty && _urlController.text.isEmpty) {
      return 'پیکربندی نشده';
    } else if (_lastTestResult != null && !_lastTestResult!.ok) {
      return 'مشکل در اتصال';
    }
    return 'پیکربندی شده · ${preset.nameFa}';
  }

  AiHealth get _currentHealth {
    if (_mode == AiMode.ritmoServer) {
      return AiHealth.connected;
    }
    if (_keyController.text.isEmpty && _urlController.text.isEmpty) {
      return AiHealth.unconfigured;
    }
    if (_lastTestResult == null) {
      return AiHealth.untested;
    }
    return _lastTestResult!.ok ? AiHealth.connected : AiHealth.failing;
  }

  String get _currentProviderName {
    if (_mode == AiMode.ritmoServer) return 'سرور ریتمو';
    final preset = kAiProviderPresets.firstWhere(
      (p) => p.id == _selectedPresetId,
      orElse: () => kAiProviderPresets.first,
    );
    return preset.nameFa;
  }

  String get _effectiveModelPreview {
    if (_mode == AiMode.ritmoServer) return 'مدل پیش‌فرض سرور ریتمو';
    final normalized = AiEndpointNormalizer.normalize(_urlController.text);
    return AIGateway.instance.previewEffectiveModel(
      baseUrl: normalized,
      model: _modelController.text,
    );
  }

  Future<void> _saveConfig() async {
    final normalizedUrl = AiEndpointNormalizer.normalize(_urlController.text);
    var finalUrl = normalizedUrl;
    if (_selectedPresetId == 'cloudflare' && _cloudflareAccountIdController.text.isNotEmpty) {
      finalUrl = finalUrl.replaceAll('{ACCOUNT_ID}', _cloudflareAccountIdController.text.trim());
      finalUrl = finalUrl.replaceAll('YOUR_ACCOUNT_ID', _cloudflareAccountIdController.text.trim());
    }

    final config = AiConnectionConfig(
      slot: AiSlot.assistant,
      mode: _mode,
      providerPresetId: _selectedPresetId,
      baseUrl: finalUrl,
      apiKey: _keyController.text.trim(),
      model: _modelController.text.trim(),
      timeoutMs: _timeoutMs,
      backupBaseUrl: AiEndpointNormalizer.normalize(_backupUrlController.text),
      backupApiKey: _backupKeyController.text.trim(),
      cloudflareAccountId: _cloudflareAccountIdController.text.trim(),
      separateFeaturesConfig: _separateFeaturesConfig,
      lastTestAt: _lastTestResult?.latencyMs != null ? DateTime.now().millisecondsSinceEpoch : null,
      lastTestOk: _lastTestResult?.ok,
      lastTestLatencyMs: _lastTestResult?.latencyMs,
      lastErrorCode: _lastTestResult?.statusCode?.toString(),
    );

    await AiConnectionRepository.instance.save(config);

    if (_separateFeaturesConfig) {
      final featuresConfig = AiConnectionConfig(
        slot: AiSlot.features,
        mode: _mode,
        providerPresetId: 'custom',
        baseUrl: AiEndpointNormalizer.normalize(_featuresUrlController.text),
        apiKey: _featuresKeyController.text.trim(),
        model: _featuresModelController.text.trim(),
        timeoutMs: _timeoutMs,
      );
      await AiConnectionRepository.instance.save(featuresConfig);
    }

    final updatedChain = await AiConnectionRepository.instance.describeChain();
    if (mounted) {
      setState(() {
        _chainEntries = updatedChain;
      });
    }
  }

  Future<void> _testPrimaryConnection() async {
    setState(() {
      _isTesting = true;
    });

    await _saveConfig();

    var targetUrl = AiEndpointNormalizer.normalize(_urlController.text);
    if (_selectedPresetId == 'cloudflare' && _cloudflareAccountIdController.text.isNotEmpty) {
      targetUrl = targetUrl.replaceAll('{ACCOUNT_ID}', _cloudflareAccountIdController.text.trim());
    }

    final result = await AIGateway.instance.testConnection(
      baseUrl: targetUrl,
      apiKey: _keyController.text.trim(),
      model: _modelController.text.trim(),
      timeoutMs: _timeoutMs,
    );

    if (mounted) {
      setState(() {
        _isTesting = false;
        _lastTestResult = result;
      });

      if (result.ok) {
        RitmoHaptics.tap();
        RitmoToast.show(
          context,
          'اتصال با موفقیت برقرار است',
          icon: Icons.check_circle_rounded,
          iconColor: context.colors.success,
        );
      } else {
        RitmoToast.show(
          context,
          result.messageFa,
          icon: Icons.error_outline_rounded,
          iconColor: context.colors.warning,
        );
      }
    }
  }

  Future<void> _testBackupConnection() async {
    setState(() {
      _isTestingBackup = true;
    });

    final targetUrl = AiEndpointNormalizer.normalize(_backupUrlController.text);
    final result = await AIGateway.instance.testConnection(
      baseUrl: targetUrl,
      apiKey: _backupKeyController.text.trim(),
      model: _modelController.text.trim(),
      timeoutMs: _timeoutMs,
    );

    if (mounted) {
      setState(() {
        _isTestingBackup = false;
      });

      if (result.ok) {
        RitmoHaptics.tap();
        RitmoToast.show(
          context,
          'کلید پشتیبان با موفقیت متصل شد',
          icon: Icons.check_circle_rounded,
          iconColor: context.colors.success,
        );
      } else {
        RitmoToast.show(
          context,
          result.messageFa,
          icon: Icons.error_outline_rounded,
          iconColor: context.colors.warning,
        );
      }
    }
  }

  void _onPresetSelected(AiProviderPreset preset) {
    setState(() {
      _selectedPresetId = preset.id;
      _urlController.text = preset.endpoint;
      if (preset.models.isNotEmpty) {
        _modelController.text = preset.models.first;
      }
      _urlError = AiEndpointNormalizer.validate(_urlController.text);
    });
    _saveConfig();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return RitmoPageScaffold(
      appBar: RitmoModuleAppBar(
        title: 'اتصال هوش مصنوعی',
        subtitle: _statusSubtitle,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(RitmoSpacing.md),
                child: Column(
                  children: [
                    RitmoSkeletonCard(height: 180),
                    const SizedBox(height: RitmoSpacing.md),
                    RitmoSkeletonCard(height: 240),
                  ],
                ),
              );
            }

            final currentPreset = kAiProviderPresets.firstWhere(
              (p) => p.id == _selectedPresetId,
              orElse: () => kAiProviderPresets.first,
            );

            final modelIsOverridden = _modelController.text.isNotEmpty &&
                _effectiveModelPreview != _modelController.text;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                vertical: RitmoSpacing.md,
                horizontal: RitmoSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Live Status Hero Card
                  AiStatusCard(
                    health: _currentHealth,
                    providerName: _currentProviderName,
                    effectiveModel: _effectiveModelPreview,
                    lastTestLatencyMs: _lastTestResult?.latencyMs,
                    lastTestAt: DateTime.now().millisecondsSinceEpoch,
                    errorMessage: _lastTestResult?.messageFa,
                    isTesting: _isTesting,
                    onTest: _testPrimaryConnection,
                    cloudConsentGranted: _cloudConsentGranted,
                  ),
                  const SizedBox(height: RitmoSpacing.md),

                  // 2. Mode Selector
                  RitmoSegmentedControl<AiMode>(
                    segments: const {
                      AiMode.ritmoServer: 'سرور ریتمو',
                      AiMode.personalKey: 'کلید شخصی',
                    },
                    selected: _mode,
                    onSelected: (mode) async {
                      setState(() {
                        _mode = mode;
                      });
                      await AiConnectionRepository.instance.saveMode(mode);
                      await _saveConfig();
                    },
                  ),
                  const SizedBox(height: RitmoSpacing.md),

                  // Ritmo Server Informational Card
                  if (_mode == AiMode.ritmoServer) ...[
                    RitmoCard(
                      padding: const EdgeInsets.all(RitmoSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield_outlined, color: colors.primary, size: 20),
                              const SizedBox(width: RitmoSpacing.xs),
                              Text(
                                'اتصال ابری امن ریتمو',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: RitmoSpacing.sm),
                          Text(
                            'ریتمو درخواست‌ها را از سرور خودش عبور می‌دهد. نیازی به کلید ندارید و هیچ کلیدی روی دستگاه شما ذخیره نمی‌شود. اگر می‌خواهید از سرویس‌دهندهٔ خودتان استفاده کنید، «کلید شخصی» را انتخاب کنید.',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                              height: 1.6,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 3. Provider Presets List
                    Text(
                      'انتخاب سرویس‌دهنده هوش مصنوعی',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: RitmoSpacing.sm),
                    for (final preset in kAiProviderPresets)
                      AiProviderPresetCard(
                        preset: preset,
                        isSelected: _selectedPresetId == preset.id,
                        onSelect: () => _onPresetSelected(preset),
                        hasApiKey: _keyController.text.isNotEmpty,
                        accountIdController: _cloudflareAccountIdController,
                        onAccountIdChanged: (_) => _saveConfig(),
                      ),
                    const SizedBox(height: RitmoSpacing.md),

                    // 4. Credential Fields
                    Text(
                      'مشخصات اتصال و اعتبارنامه',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: RitmoSpacing.sm),
                    RitmoTextField(
                      label: 'آدرس سرویس‌دهنده (Endpoint URL)',
                      icon: Icons.link_rounded,
                      controller: _urlController,
                      errorText: _urlError,
                      keyboardType: TextInputType.url,
                      onChanged: (val) {
                        setState(() {
                          _urlError = AiEndpointNormalizer.validate(val);
                        });
                        _saveConfig();
                      },
                    ),
                    const SizedBox(height: RitmoSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'آدرس نهایی: ${AiEndpointNormalizer.normalize(_urlController.text)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textTertiary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                    const SizedBox(height: RitmoSpacing.md),

                    AiSecretField(
                      label: 'کلید دسترسی (API Key)',
                      controller: _keyController,
                      hint: 'sk-... یا کلید سرویس‌دهنده',
                      hasStoredKey: _keyController.text.isNotEmpty,
                      onChanged: (_) => _saveConfig(),
                      onDelete: () async {
                        await AiConnectionRepository.instance.deleteKey(AiSlot.assistant);
                        setState(() {
                          _keyController.clear();
                          _lastTestResult = null;
                        });
                        if (mounted && context.mounted) RitmoToast.show(context, 'کلید با موفقیت حذف شد');
                      },
                    ),
                    const SizedBox(height: RitmoSpacing.md),

                    // Model Selection
                    DropdownButtonFormField<String>(
                      initialValue: currentPreset.models.contains(_modelController.text)
                          ? _modelController.text
                          : (currentPreset.models.isNotEmpty ? currentPreset.models.first : null),
                      items: [
                        for (final m in currentPreset.models)
                          DropdownMenuItem(
                            value: m,
                            child: Text(m, style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                          ),
                        const DropdownMenuItem(
                          value: '__custom__',
                          child: Text('مدل دلخواه...', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == '__custom__') {
                          // keep current custom or clear
                        } else if (val != null) {
                          setState(() {
                            _modelController.text = val;
                          });
                          _saveConfig();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'مدل هوش مصنوعی',
                        filled: true,
                        fillColor: colors.surfaceSunken,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(RitmoRadius.field),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(RitmoRadius.field),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                    ),
                    if (!currentPreset.models.contains(_modelController.text) && _modelController.text.isNotEmpty) ...[
                      const SizedBox(height: RitmoSpacing.sm),
                      RitmoTextField(
                        label: 'نام مدل دلخواه',
                        icon: Icons.psychology_outlined,
                        controller: _modelController,
                        onChanged: (_) => _saveConfig(),
                      ),
                    ],
                    if (modelIsOverridden) ...[
                      const SizedBox(height: RitmoSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: colors.warning, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'این مدل با این سرویس‌دهنده سازگار نیست. ریتمو به‌جای آن «$_effectiveModelPreview» را می‌فرستد.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.warning,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: RitmoSpacing.md),

                    // 5. Backup Key ExpansionTile (T-B6)
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          'کلید پشتیبان',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        subtitle: Text(
                          'اختیاری · برای جابجایی خودکار در زمان اتمام سهمیه',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: RitmoSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'وقتی سهمیهٔ کلید اول تمام شود یا سرویس‌دهنده پاسخ ندهد، ریتمو خودکار سراغ این کلید می‌رود. لازم نیست از همان سرویس‌دهنده باشد.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                    height: 1.5,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const SizedBox(height: RitmoSpacing.sm),
                                RitmoTextField(
                                  label: 'آدرس سرویس‌دهنده پشتیبان',
                                  icon: Icons.link_rounded,
                                  controller: _backupUrlController,
                                  onChanged: (_) => _saveConfig(),
                                ),
                                const SizedBox(height: RitmoSpacing.md),
                                AiSecretField(
                                  label: 'کلید دسترسی پشتیبان (Backup API Key)',
                                  controller: _backupKeyController,
                                  hint: 'sk-...',
                                  hasStoredKey: _backupKeyController.text.isNotEmpty,
                                  onChanged: (_) => _saveConfig(),
                                  onDelete: () async {
                                    final db = await DatabaseHelper.instance.database;
                                    await SecureKeyStore.deleteKey('ai_api_key_2');
                                    await db.delete('app_settings', where: 'key = ?', whereArgs: ['ai_api_key_2']);
                                    setState(() {
                                      _backupKeyController.clear();
                                    });
                                    await _saveConfig();
                                    if (mounted && context.mounted) RitmoToast.show(context, 'کلید پشتیبان حذف شد');
                                  },
                                ),
                                const SizedBox(height: RitmoSpacing.sm),
                                RitmoPrimaryButton(
                                  label: 'آزمایش کلید پشتیبان',
                                  icon: Icons.bolt_rounded,
                                  isLoading: _isTestingBackup,
                                  onPressed: _testBackupConnection,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: RitmoSpacing.sm),

                    // 6. Advanced Settings ExpansionTile (T-B7)
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          'تنظیمات پیشرفته',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: RitmoSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'مهلت پاسخ سرویس‌دهنده (Timeout)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const SizedBox(height: RitmoSpacing.xs),
                                RitmoSegmentedControl<int>(
                                  segments: const {
                                    15000: '۱۵ ثانیه',
                                    30000: '۳۰ ثانیه',
                                    60000: '۶۰ ثانیه',
                                    120000: '۲ دقیقه',
                                  },
                                  selected: _timeoutMs,
                                  onSelected: (timeout) {
                                    setState(() {
                                      _timeoutMs = timeout;
                                    });
                                    _saveConfig();
                                  },
                                ),
                                const SizedBox(height: RitmoSpacing.md),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'سرویس‌دهندهٔ جداگانه برای تحلیل‌ها',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  subtitle: Text(
                                    '«دستیار» چت زنده است و به سرعت نیاز دارد. «تحلیل‌ها» کارهای سنگین‌تر پس‌زمینه مثل خلاصهٔ هفتگی است. می‌توانید برای هرکدام سرویس‌دهندهٔ متفاوتی بگذارید.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textSecondary,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  value: _separateFeaturesConfig,
                                  onChanged: (val) {
                                    setState(() {
                                      _separateFeaturesConfig = val;
                                    });
                                    _saveConfig();
                                  },
                                ),
                                if (_separateFeaturesConfig) ...[
                                  const SizedBox(height: RitmoSpacing.sm),
                                  RitmoTextField(
                                    label: 'آدرس تحلیل‌ها (Features Base URL)',
                                    controller: _featuresUrlController,
                                    onChanged: (_) => _saveConfig(),
                                  ),
                                  const SizedBox(height: RitmoSpacing.sm),
                                  AiSecretField(
                                    label: 'کلید دسترسی تحلیل‌ها (Features API Key)',
                                    controller: _featuresKeyController,
                                    onChanged: (_) => _saveConfig(),
                                  ),
                                  const SizedBox(height: RitmoSpacing.sm),
                                  RitmoTextField(
                                    label: 'مدل تحلیل‌ها (Features Model)',
                                    controller: _featuresModelController,
                                    onChanged: (_) => _saveConfig(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: RitmoSpacing.md),

                  // 7. Connection Chain Panel (T-C1)
                  if (_chainEntries.isNotEmpty) ...[
                    RitmoCard(
                      padding: const EdgeInsets.all(RitmoSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ترتیب تلاش (Connection Chain)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          const SizedBox(height: RitmoSpacing.sm),
                          for (var i = 0; i < _chainEntries.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    '${toPersianDigits((i + 1).toString())} · ${_chainEntries[i].labelFa}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _chainEntries[i].host,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  const SizedBox(width: RitmoSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceSunken,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _chainEntries[i].model,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textTertiary,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: RitmoSpacing.xs),
                          Text(
                            'اگر عضو اول جواب ندهد، ریتمو به‌ترتیب سراغ بعدی‌ها می‌رود.',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textTertiary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: RitmoSpacing.md),
                  ],

                  // 8. Daily Quota Usage Counter (T-C2)
                  if (_showDailyQuota) ...[
                    RitmoCard(
                      padding: const EdgeInsets.all(RitmoSpacing.md),
                      child: Row(
                        children: [
                          Icon(Icons.bolt_outlined, color: colors.primary, size: 20),
                          const SizedBox(width: RitmoSpacing.sm),
                          Text(
                            'درخواست‌های امروز: ${toPersianDigits(_dailyQuotaUsed.toString())} از ${toPersianDigits(_dailyQuotaLimit.toString())}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: RitmoSpacing.md),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
