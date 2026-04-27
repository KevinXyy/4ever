import 'package:pigeon/pigeon.dart';

class NativeHealthSample {
  NativeHealthSample({
    required this.id,
    required this.type,
    required this.unit,
    required this.startTimeMillis,
    required this.endTimeMillis,
    required this.source,
    required this.sensitivity,
    this.numericValue,
    this.textValue,
  });

  String id;
  String type;
  double? numericValue;
  String? textValue;
  String unit;
  int startTimeMillis;
  int endTimeMillis;
  String source;
  String sensitivity;
}

@HostApi()
abstract class HealthDataHostApi {
  @async
  bool isAvailable();

  @async
  bool requestReadPermissions(List<String> metricTypes);

  @async
  List<NativeHealthSample> readSamples(
    List<String> metricTypes,
    int startTimeMillis,
    int endTimeMillis,
  );
}
