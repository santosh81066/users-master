import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:users/models/callmodel.dart';
import 'package:users/providers/bookingnotifier.dart';
import 'package:users/widgets/callduration.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class ZegeoCloudNotifier extends StateNotifier<Call> {
  ZegeoCloudNotifier() : super(Call(amount: 0, minutes: 0));
  void onUserLogin(String userId, String userName, BuildContext context,
      String catname, String cattype, WidgetRef ref) {
    var getbooking = ref.read(bookingDataProvider.notifier);
    ZegoUIKitPrebuiltCallInvitationService().init(
        events: ZegoUIKitPrebuiltCallInvitationEvents(
          onOutgoingCallAccepted: (String callID, ZegoCallUser calee) {
            CallDurationWidget.startTimer(
                state.callRate!, context, cattype, ref);
          },
        ),
        appID: 381310215,
        appSign:
            'b27d415148d2f0d29cecb53b33709a09d9e5153705520c6ad5bf3f3c2d33b3ba',
        userID: userId,
        userName: "$userName($catname)",
        plugins: [ZegoUIKitSignalingPlugin()],
        requireConfig: (ZegoCallInvitationData data) {
          final config = (data.invitees.length > 1)
              ? ZegoCallType.videoCall == data.type
                  ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
              : ZegoCallType.videoCall == data.type
                  ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
            ..durationConfig.isVisible = true
            ..durationConfig.onDurationUpdate = (Duration duration) {
              if (duration.inSeconds >= 20 * 60) {
                state.zegoController.hangUp(context);
              }
            };

          /// support minimizing, show minimizing button
          config.topMenuBarConfig.isVisible = true;

          config.onHangUp = () {
            CallDurationWidget.stopTimer(context, ref);
            getbooking.getBookingHistory();
            Navigator.pop(context);
          };
          config.onOnlySelfInRoom = (context) {
            CallDurationWidget.stopTimer(context, ref);
            getbooking.getBookingHistory();
            Navigator.pop(context);
          };

          config.audioVideoViewConfig = ZegoPrebuiltAudioVideoViewConfig(
            foregroundBuilder: (context, size, user, extraInfo) {
              final screenSize = MediaQuery.of(context).size;
              final isSmallView = size.height < screenSize.height / 2;
              if (isSmallView) {
                return Container();
              } else {
                return const CallDurationWidget();
              }
            },
          );

          return config;
        },
        controller: state.zegoController);
  }

  List<ZegoUIKitUser> getInvitesFromTextCtrl(String textCtrlText) {
    final invitees = <ZegoUIKitUser>[];

    final inviteeIDs = textCtrlText.trim().replaceAll('，', '');
    inviteeIDs.split(',').forEach((inviteeUserID) {
      if (inviteeUserID.isEmpty) {
        return;
      }

      invitees.add(ZegoUIKitUser(
        id: inviteeUserID,
        name: 'user_$inviteeUserID',
      ));
    });

    return invitees;
  }

  void setPurohithDetails(double? callRate, int? catid, int? purohithId) {
    state = state.copyWith(
        callRate: callRate, ctypeId: catid, purohithId: purohithId);
  }

  void setCallDetails() {}
}

var zegeoCloudNotifierProvider =
    StateNotifierProvider<ZegeoCloudNotifier, Call>(
        (ref) => ZegeoCloudNotifier());
