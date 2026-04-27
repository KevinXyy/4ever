import 'package:pigeon/pigeon.dart';

@HostApi()
abstract class BackgroundTaskHostApi {
  @async
  void registerBackgroundRefresh();

  @async
  void cancelBackgroundRefresh();
}
