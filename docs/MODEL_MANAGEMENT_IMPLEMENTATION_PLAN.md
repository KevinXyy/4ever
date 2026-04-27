# Model Management Implementation Plan

目标：第一版只完成一个可验证闭环，让双端 Flutter App 能下载 Gemma 4 模型、
校验文件、初始化本地 runtime、通过 smoke test，并进入最小 demo chat。

本方案用于下一步代码实现。第一版不做健康数据、不做 agent skills、不做云端分析，
也不做自研下载器或 SQLCipher model registry。

## 1. 第一版闭环

```text
manifest
  -> 选择 Gemma 4 E4B/E2B
  -> 检查内存/磁盘
  -> background_downloader 下载
  -> crypto SHA-256 校验
  -> 写 model_registry.json
  -> LlmRuntime.initialize
  -> smoke test
  -> demo chat
```

这条链路在 Dart/Flutter 层统一编排。Android 和 iOS 只实现必要的平台能力：

```text
DeviceCapabilitiesApi
LlmRuntimeHostApi
```

## 2. 双端边界

双端共用：

- `.litertlm` 模型格式
- LiteRT-LM runtime 语义
- manifest
- 下载、校验、registry、状态机、smoke test 编排
- Flutter `LlmRuntime` 抽象
- demo chat 页面和 controller

平台分别实现：

- Android: Kotlin adapter 调 LiteRT-LM Android API。
- iOS: Swift/Pigeon 入口 + ObjC++ wrapper 调 LiteRT-LM C++ API。
- 内存、磁盘、GPU/Metal 等平台能力检测。

iOS 不等待 Swift-native SDK。官方 Swift API 成熟后，只替换 iOS adapter，
Flutter 业务层和模型管理层不改。

## 3. 官方路线判断

Gemma 4 E2B/E4B 的 LiteRT-LM 模型页明确提供 `.litertlm` 文件，并标注可用于
Android、iOS、Desktop、IoT 和 Web。Google AI Edge Gallery 已在 iOS 和 Android
上展示 Gemma 4，本项目第一版按 LiteRT-LM 集成。

工程选择：

- Android 使用 LiteRT-LM Android/Kotlin API。
- iOS 使用 LiteRT-LM C++ API，经 ObjC++ 暴露给 Swift/Pigeon。
- Flutter 不直接感知 LiteRT-LM、Gemma SDK、C++、Kotlin 或 Swift runtime 细节。

## 4. 第一版依赖

Flutter/Dart：

```yaml
dependencies:
  background_downloader: pinned
  crypto: pinned
  path_provider: pinned
  path: pinned

dev_dependencies:
  pigeon: pinned
```

说明：

- `background_downloader` 负责 Android/iOS 下载、进度、暂停/恢复、后台任务能力。
- `crypto` 负责 SHA-256，必须用 chunked hashing 处理 2GB+ 文件。
- `path_provider` 负责 Application Support 路径。
- `pigeon` 负责类型安全平台桥接。

第一版不用：

- 自研 Android WorkManager 下载器。
- 自研 iOS URLSession background downloader。
- SQLCipher `model_registry` 表。
- native 侧 SHA-256。
- 多模型降级系统。

## 5. 目标目录

```text
app/
  assets/
    model_manifest.json

  lib/
    domain/
      ai/
        model_manifest.dart
        model_manifest_entry.dart
        model_install_status.dart
        model_install_progress.dart
        model_install_record.dart
        model_failure_reason.dart

    application/
      ai/
        model/
          model_catalog_service.dart
          model_selection_service.dart
          model_lifecycle_service.dart
          model_download_service.dart
          model_file_verifier.dart
          model_registry_store.dart
          model_storage_paths.dart
          device_capabilities.dart
          model_smoke_test_service.dart

    data/
      model/
        asset_model_catalog_service.dart
        background_model_download_service.dart
        dart_model_file_verifier.dart
        json_model_registry_store.dart
        app_support_model_storage_paths.dart

    presentation/
      model_demo/
        model_demo_screen.dart
        model_demo_controller.dart

  pigeon/
    device_capabilities_api.dart
    llm_runtime_api.dart

  android/
    app/src/main/kotlin/.../
      DeviceCapabilitiesHostApiImpl.kt
      LlmRuntimeHostApiImpl.kt
      LiteRtLmRuntimeAdapter.kt

  ios/
    Runner/
      NativeBridge/
        DeviceCapabilitiesHostApiAdapter.swift
        LlmRuntimeHostApiAdapter.swift
      ModelRuntime/
        LiteRtLmBridge.h
        LiteRtLmBridge.mm
        LiteRtLmRuntimeAdapter.swift
```

## 6. Manifest

第一版 manifest 必须包含下载和校验所需字段：

```json
{
  "schema_version": "1.0",
  "models": [
    {
      "id": "gemma-4-e4b-it",
      "display_name": "Gemma 4 E4B",
      "provider": "litert-community",
      "model_id": "litert-community/gemma-4-E4B-it-litert-lm",
      "file_name": "gemma-4-E4B-it.litertlm",
      "download_url": "TO_BE_FILLED",
      "source_commit": "9695417f248178c63a9f318c6e0c56cb917cb837",
      "sha256": "TO_BE_FILLED",
      "size_bytes": 3654467584,
      "min_memory_gb": 12,
      "min_free_disk_bytes": 7308935168,
      "modalities": ["text", "image", "audio"],
      "supports_thinking": true,
      "max_context_tokens": 32000,
      "default_generation_config": {
        "top_k": 64,
        "top_p": 0.95,
        "temperature": 1.0,
        "max_tokens": 4000
      },
      "accelerators": ["gpu", "cpu"],
      "platforms": ["android", "ios"],
      "default": true,
      "selection_priority": 10
    }
  ]
}
```

规则：

- `id` 是 app 内稳定 id。
- `model_id` 是 Hugging Face 或内部模型源 id。
- `source_commit` 用于版本化存储目录。
- `sha256` 生产构建必须是真实值。
- `min_free_disk_bytes` 至少为模型大小的 2 倍。
- E4B 是默认目标；设备不满足时选择 E2B。

## 7. 关键接口

### ModelCatalogService

```dart
abstract interface class ModelCatalogService {
  Future<ModelManifest> loadManifest();
  Future<List<ModelManifestEntry>> listAvailableModels();
  Future<ModelManifestEntry?> findById(String modelId);
  Future<ModelManifestEntry> getDefaultModel();
}
```

### ModelSelectionService

```dart
abstract interface class ModelSelectionService {
  Future<ModelManifestEntry> selectBestModel();
  Future<bool> isSupported(ModelManifestEntry model);
}
```

选择顺序：

```text
1. 用户手动选择且设备支持。
2. E4B 已安装且设备支持。
3. E4B 未安装但设备支持，推荐安装 E4B。
4. E4B 不满足内存/磁盘要求时，选择或推荐 E2B。
5. E2B 也不满足时，提示设备不支持当前 Gemma 4 档位。
```

### ModelLifecycleService

```dart
abstract interface class ModelLifecycleService {
  Future<List<ModelManifestEntry>> listModels();
  Future<ModelInstallRecord?> getRecord(String modelId);
  Stream<ModelInstallProgress> install(String modelId);
  Future<void> load(String modelId);
  Future<void> unload();
  Future<void> delete(String modelId);
  Future<void> runSmokeTest(String modelId);
}
```

### ModelRegistryStore

第一版用 JSON 文件，不进数据库。

```dart
abstract interface class ModelRegistryStore {
  Future<ModelInstallRecord?> findById(String modelId);
  Future<List<ModelInstallRecord>> listRecords();
  Future<void> upsert(ModelInstallRecord record);
  Future<void> updateStatus(String modelId, ModelInstallStatus status);
  Future<void> delete(String modelId);
}
```

文件位置：

```text
Application Support/model_registry.json
```

模型文件位置：

```text
Application Support/models/{model_id}/{source_commit}/{file_name}
```

不要放 `Documents`，避免暴露到用户文件共享和备份语义里。

## 8. Pigeon API

### DeviceCapabilitiesApi

```dart
class NativeDeviceCapabilities {
  int totalMemoryBytes;
  int availableDiskBytes;
  bool supportsGpu;
  bool supportsNpu;
  String platformVersion;
  String deviceModel;
}

@HostApi()
abstract class DeviceCapabilitiesHostApi {
  @async
  NativeDeviceCapabilities getCapabilities();
}
```

Android：

- `ActivityManager.MemoryInfo.totalMem`
- `StatFs.getAvailableBytes()`

iOS：

- `ProcessInfo.processInfo.physicalMemory`
- `FileManager` volume capacity / available capacity resource values

### LlmRuntimeHostApi

现有 `llm_runtime_api.dart` 继续负责 runtime 初始化和生成。它不负责下载、
manifest、registry 或文件 hash。

需要传给 native 的核心字段：

```dart
modelId
localPath
sha256
sizeBytes
minMemoryGb
supportsText
supportsImage
supportsAudio
supportsThinking
maxContextTokens
acceleratorPreference
```

## 9. 状态机

```text
not_installed
  -> downloading
  -> verifying
  -> installed
  -> loading
  -> ready
  -> unloaded

任何状态 -> failed
failed -> downloading   retry install
failed -> loading       retry load when file is installed
failed -> not_installed delete
```

第一版状态定义：

- `not_installed`: 无已校验模型文件。
- `downloading`: background_downloader 正在下载。
- `verifying`: 正在计算 SHA-256。
- `installed`: 文件已校验，runtime 未加载。
- `loading`: 正在初始化 LiteRT-LM。
- `ready`: runtime 已加载且 smoke test 通过。
- `unloaded`: 文件存在，runtime 已释放。
- `failed`: 最近一次操作失败。

## 10. 安装与加载流程

安装：

```text
install(modelId)
  1. catalog.findById(modelId)
  2. validate platform
  3. DeviceCapabilitiesApi.getCapabilities
  4. check memory and disk
  5. download with background_downloader to Application Support
  6. compute SHA-256 with crypto chunked hashing
  7. compare manifest sha256
  8. write model_registry.json
  9. status = installed
```

加载：

```text
load(modelId)
  1. registry.findById(modelId)
  2. require installed/unloaded/ready
  3. verify model file exists
  4. LlmRuntime.initialize(LlmModelConfig)
  5. run smoke test
  6. status = ready
```

Smoke test：

```text
Prompt: Reply with the single word: ready
Expected: output contains "ready"
Timeout: 30 seconds
```

## 11. Demo UI

第一版做 `presentation/model_demo`，不是完整产品页。

需要能力：

- 展示 E4B/E2B 两个模型。
- 展示设备内存、可用磁盘、是否满足要求。
- 下载按钮。
- 下载进度。
- 校验状态。
- 加载模型按钮。
- smoke test 状态。
- 最小聊天输入框。
- 流式 token 或一次性回复展示。
- 删除模型按钮。

UI 不显示：

- access token
- 完整本地模型路径
- SDK 原始错误堆栈
- prompt/response 日志

## 12. 测试计划

Dart unit tests：

```text
manifest parse success
duplicated model id rejected
missing sha256 rejected in production mode
E4B selected when supported
E2B selected when E4B memory is insufficient
disk insufficient blocks install
hash mismatch blocks load
registry json read/write/update/delete
smoke test success
smoke test timeout
```

Native smoke tests：

```text
DeviceCapabilitiesApi returns memory/disk
runtime initialize with valid localPath succeeds
ready prompt returns ready
generateOnce returns non-empty text
cancel maps to GENERATION_CANCELLED
unload releases runtime state
SDK errors map to unified error codes
```

Manual tests：

```text
fresh install -> no model installed
download E2B -> progress visible
kill app during download -> task status restored if platform supports it
hash mismatch -> failed and load disabled
load model -> ready
send prompt -> response
unload -> runtime released
delete -> model file and registry record removed
E4B unsupported -> E2B suggested
```

## 13. 分阶段实现顺序

### Phase A: Dart foundation

生成 domain model、manifest loader、selection service、JSON registry store、fake
download/runtime tests。

当前状态：已完成。

已新增：

- `domain/ai/model_manifest.dart`
- `domain/ai/model_manifest_entry.dart`
- `domain/ai/model_install_status.dart`
- `domain/ai/model_install_progress.dart`
- `domain/ai/model_install_record.dart`
- `domain/ai/model_failure_reason.dart`
- `domain/ai/device_capabilities.dart`
- `application/ai/model/model_catalog.dart`
- `application/ai/model/model_selection_service.dart`
- `application/ai/model/model_lifecycle_service.dart`
- `application/ai/model/model_registry_store.dart`
- `application/ai/model/model_storage_paths.dart`
- `application/ai/model/model_file_downloader.dart`
- `application/ai/model/model_file_verifier.dart`
- `application/ai/model/device_capabilities_reader.dart`

### Phase B: Real download and verification

接入 `background_downloader`、Application Support storage、`crypto` chunked SHA-256。

当前状态：Dart 侧 adapter 已完成，真实大模型下载仍需在 demo UI 或设备上手动验证。

已新增：

- `data/model/asset_model_catalog.dart`
- `data/model/application_support_model_storage_paths.dart`
- `data/model/background_downloader_model_file_downloader.dart`
- `data/model/dart_model_file_verifier.dart`
- `data/model/json_model_registry_store.dart`
- `core/providers/model_management_providers.dart`
- `core/native/device_capabilities_channel_reader.dart`

注意：

- `crypto` 已作为直接依赖加入 `pubspec.yaml`，当前 lockfile 锁定到 `3.0.7`。
- `background_downloader` 当前 lockfile 版本为 `9.5.4`。
- `path_provider` 当前 lockfile 版本为 `2.1.5`。
- `path` 当前 lockfile 版本为 `1.9.1`。
- manifest 中 `sha256` 仍为 `TO_BE_FILLED`，拿到官方或自算真实 hash 后必须补齐。

### Phase C: Device capabilities

新增 Pigeon `DeviceCapabilitiesApi`，实现 Android/iOS 内存和磁盘检测。

当前状态：Dart 侧接口和 MethodChannel reader 已预留；native 端尚未实现。

下一步：

- 改为 Pigeon API，或保持现有 MethodChannel 到 Pigeon 迁移完成。
- Android 实现内存和磁盘检测。
- iOS 实现内存和磁盘检测。
- 增加 fake/native bridge 测试。

### Phase D: Demo UI

实现 `model_demo` 页面，先接 fake runtime，再接真实 runtime。

当前状态：未开始。

下一步最小目标：

- 页面显示 E4B/E2B、设备能力、安装状态。
- 点击按钮触发 `ModelLifecycleService.prepareDemoModel()`。
- 显示 downloading/verifying/installed/loading/ready/failed。
- smoke test 通过后展示最小 chat 输入框。
- 先使用 fake/stub runtime 跑通 UI，再接真实 LiteRT-LM runtime。

### Phase E: Android LiteRT-LM runtime

Kotlin adapter 接 LiteRT-LM Android API，只实现 `LlmRuntimeHostApi`。

当前状态：未开始。

### Phase F: iOS LiteRT-LM runtime

Swift/Pigeon 入口 + ObjC++ bridge + LiteRT-LM C++ API，只实现 `LlmRuntimeHostApi`。

当前状态：未开始。

## 14. 当前测试方法与结果

测试环境：

```text
Windows
Flutter SDK: .fvm/flutter_sdk
Branch: gemma-local-base
```

手动测试命令：

```powershell
.\.fvm\flutter_sdk\bin\flutter.bat pub get --directory app
cd app
..\.fvm\flutter_sdk\bin\dart.bat format lib\domain\ai lib\application\ai\model lib\data\model lib\core\native\device_capabilities_channel_reader.dart lib\core\providers\model_management_providers.dart test\model_management_test.dart
..\.fvm\flutter_sdk\bin\flutter.bat analyze
..\.fvm\flutter_sdk\bin\flutter.bat test test\model_management_test.dart
..\.fvm\flutter_sdk\bin\flutter.bat test
```

当前已验证结果：

```text
dart format completed.
flutter analyze passed.
flutter test test\model_management_test.dart passed.
flutter test passed.
```

新增测试覆盖：

- manifest 能解析 Gemma 4 E2B/E4B。
- 高内存设备选择 E4B。
- 8GB 设备选择 E2B。
- Dart SHA-256 校验可用。
- `model_registry.json` 可写入和读取。
- fake runtime 下 lifecycle 能完成 download -> verify -> installed -> loading -> ready。

## 15. Definition of Done

```text
1. manifest 可解析并有测试。
2. E4B/E2B 选择有测试。
3. 模型可下载到 Application Support。
4. SHA-256 mismatch 会阻断加载。
5. model_registry.json 可持久化 installed/ready/failed 状态。
6. LlmRuntime.initialize 能加载至少一个真实 Gemma 4 模型。
7. smoke test 通过。
8. demo chat 能收到模型回复。
9. Android 或 iOS 至少一端跑通真实 runtime。
10. Flutter UI 不直接调用 Pigeon、LiteRT-LM、文件 hash 或 registry。
11. flutter analyze 和 flutter test 通过。
```
