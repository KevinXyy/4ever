import 'package:flutter/services.dart';

import 'native_channel_names.dart';

class IosBackgroundTaskApi {
  IosBackgroundTaskApi({
    MethodChannel? methodChannel,
  }) : _methodChannel = methodChannel ??
            const MethodChannel(NativeChannelNames.backgroundTask);

  final MethodChannel _methodChannel;

  Future<void> registerBackgroundRefresh() async {
    await _methodChannel.invokeMethod<void>('registerBackgroundRefresh');
  }

  Future<void> cancelBackgroundRefresh() async {
    await _methodChannel.invokeMethod<void>('cancelBackgroundRefresh');
  }
}
