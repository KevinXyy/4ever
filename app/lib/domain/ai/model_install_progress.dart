import 'model_failure_reason.dart';
import 'model_install_status.dart';

class ModelInstallProgress {
  const ModelInstallProgress({
    required this.modelId,
    required this.status,
    this.progress,
    this.failureReason,
    this.message,
  });

  final String modelId;
  final ModelInstallStatus status;
  final double? progress;
  final ModelFailureReason? failureReason;
  final String? message;
}
