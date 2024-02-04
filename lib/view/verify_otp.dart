import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/otp_field_style.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:users/providers/PhoneAuthNotifier.dart';
import 'package:users/providers/loader.dart';

import '../widgets/button.dart';

class VerifyOtp extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  const VerifyOtp({super.key, this.scaffoldMessengerKey});
  @override
  ConsumerState<VerifyOtp> createState() => _VerifyOtpState();
}

class _VerifyOtpState extends ConsumerState<VerifyOtp> {
  String? smsCode;
  String button = 'SUBMIT';

  @override
  void initState() {
    super.initState();
    ref.read(phoneAuthProvider.notifier).startTimer();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double imageWidth = screenSize.width * 0.5;
    double imageHeight = screenSize.height * 0.4;
    var mobileno = ModalRoute.of(context)!.settings.arguments;
    final ScaffoldMessengerState scaffoldKey =
        widget.scaffoldMessengerKey!.currentState as ScaffoldMessengerState;
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.black,
              ),
              onPressed: () {}),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Wrong Phone Number?",
                style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenSize.height * 0.9),
            child: IntrinsicHeight(
              child: Center(
                child: Container(
                  width: screenSize.width * 0.95,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/icon.png",
                        width: imageWidth,
                        height: imageHeight,
                      ),
                      const Text(
                        "Enter OTP",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        ),
                      ),
                      const Text(
                        "OTP send to +91-234567890",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: PinCodeTextField(
                          showCursor: true,
                          appContext: context,
                          length: 6,
                          keyboardType: TextInputType.number,
                          enableActiveFill: false,
                          cursorHeight: 20,
                          cursorWidth: 1,
                          cursorColor: Colors.black,
                          pinTheme: PinTheme(
                            activeColor: Color.fromARGB(255, 113, 112, 112),
                            selectedColor: Color.fromARGB(255, 113, 112, 112),
                            inactiveColor: Color.fromARGB(255, 113, 112, 112),
                            shape: PinCodeFieldShape.box,
                            fieldWidth: MediaQuery.of(context).size.width / 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (pin) {
                            setState(() {
                              smsCode = pin;
                            });
                          },
                          onCompleted: (pin) {
                            setState(() {
                              smsCode = pin;
                            });
                          },
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Consumer(
                          builder: (context, value, child) {
                            final phoneAuthState =
                                value.watch(phoneAuthProvider);

                            return phoneAuthState.wait == true
                                ? Column(
                                    children: [
                                      Text(
                                        "Resend OTP",
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            decoration:
                                                TextDecoration.underline),
                                      ),
                                      Text(
                                        "Available in ${phoneAuthState.countdown}s",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      )
                                    ],
                                  )
                                : TextButton(
                                    onPressed: () {
                                      value
                                          .read(phoneAuthProvider.notifier)
                                          .waitTime();

                                      value
                                          .read(phoneAuthProvider.notifier)
                                          .phoneAuth(context,
                                              mobileno.toString(), value);
                                      value
                                          .read(phoneAuthProvider.notifier)
                                          .restartTimer();
                                    },
                                    child: const Text(
                                      "Resend OTP",
                                      style: TextStyle(
                                          color: Color(0xFFF5C662),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700),
                                    ));
                          },
                        ),
                      ),
                      Consumer(
                        builder: (cont, value, child) {
                          final isLoading = value.watch(loadingProvider);

                          return isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      backgroundColor: Colors.blueAccent),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Button(
                                      buttonname: button,
                                      width: double.infinity,
                                      onTap: isLoading
                                          ? null
                                          : () {
                                              if (smsCode == null) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                        const SnackBar(
                                                  duration:
                                                      Duration(seconds: 5),
                                                  content:
                                                      Text("Please Enter OTP "),
                                                ));
                                              } else {
                                                value
                                                    .read(phoneAuthProvider
                                                        .notifier)
                                                    .signInWithPhoneNumber(
                                                        smsCode!,
                                                        context,
                                                        value,
                                                        mobileno.toString(),
                                                        scaffoldKey);
                                              }
                                            },
                                    ),
                                    Divider(
                                      thickness: screenSize.height * 0.006,
                                      indent: screenSize.width * 0.3,
                                      endIndent: screenSize.width * 0.3,
                                      color: Colors.black,
                                    )
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
