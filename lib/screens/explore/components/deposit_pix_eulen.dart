import 'dart:async';
import 'package:Satsails/providers/currency_conversions_provider.dart';
import 'package:Satsails/providers/purchase_provider.dart';
import 'package:Satsails/screens/shared/message_display.dart';
import 'package:Satsails/translations/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:Satsails/screens/shared/custom_button.dart';
import 'package:Satsails/screens/shared/qr_code.dart';
import 'package:Satsails/screens/shared/copy_text.dart';
import 'package:msh_checkbox/msh_checkbox.dart';

class DepositPixEulen extends ConsumerStatefulWidget {
  const DepositPixEulen({Key? key}) : super(key: key);

  @override
  _DepositPixState createState() => _DepositPixState();
}

class _DepositPixState extends ConsumerState<DepositPixEulen> {
  final TextEditingController _amountController = TextEditingController();
  String _pixQRCode = '';
  bool _isLoading = false;
  double _amountToReceive = 0;
  double feePercentage = 0;
  String amountPurchasedToday = '0';
  bool pixPayed = false;
  bool _infoExpanded = false;
  Timer? _paymentCheckTimer;

  @override
  void initState() {
    super.initState();
    _fetchAmountPurchasedToday();
  }

  Future<void> _fetchAmountPurchasedToday() async {
    try {
      final result = await ref.read(getAmountPurchasedProvider.future);
      setState(() {
        amountPurchasedToday = result;
      });
    } catch (e) {
      setState(() {
        amountPurchasedToday = '0';
      });
    }
  }

  Future<void> _checkPixPayment(String transactionId) async {
    _paymentCheckTimer =
        Timer.periodic(const Duration(seconds: 6), (timer) async {
          if (!mounted) {
            timer.cancel();
            return;
          }
          try {
            final result =
            await ref.read(getPixPaymentStateProvider(transactionId).future);
            if (mounted) {
              setState(() {
                pixPayed = result;
              });
            }
            if (pixPayed) {
              timer.cancel();
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                pixPayed = false;
              });
            }
          }
        });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paymentCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQRCode() async {
    final amount = _amountController.text;

    if (amount.isEmpty) {
      showMessageSnackBar(
        context: context,
        message: 'Amount cannot be empty'.i18n(ref),
        error: true,
      );
      return;
    }

    final int? amountInInt = int.tryParse(amount);

    if (amountInInt == null || amountInInt <= 0) {
      showMessageSnackBar(
        context: context,
        message: 'Please enter a valid amount.'.i18n(ref),
        error: true,
      );
      return;
    }

    if (amountInInt > 5000) {
      showMessageSnackBar(
        context: context,
        message: 'The maximum allowed transfer amount is 5000 BRL'.i18n(ref),
        error: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final purchase =
      await ref.read(createPurchaseRequestProvider(amountInInt).future);
      _checkPixPayment(purchase.transferId);

      setState(() {
        _pixQRCode = purchase.pixKey;
        _isLoading = false;
        _amountToReceive = purchase.receivedAmount;
        feePercentage =
            (1 - (purchase.receivedAmount / purchase.originalAmount)) * 100;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showMessageSnackBar(
        context: context,
        message: e.toString().i18n(ref),
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the currency conversion provider to calculate minimum purchase in BRL.
    final currencyConversions = ref.watch(currencyNotifierProvider);
    // Calculate the required BRL amount for 0.001 BTC.
    final minBtcInBRL =
    (0.001 / currencyConversions.brlToBtc).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Pix',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: KeyboardDismissOnTap(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Amount input when no QR code is generated.
                if (_pixQRCode.isEmpty)
                  Padding(
                    padding:
                    EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.sp,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide:
                          BorderSide(color: Colors.grey[600]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide:
                          BorderSide(color: Colors.transparent, width: 2.0),
                        ),
                        labelText: 'Insert amount'.i18n(ref),
                        labelStyle: TextStyle(
                          fontSize: 20.sp,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                // Show QR code (and related text) if generated and payment is pending.
                if (_pixQRCode.isNotEmpty && !pixPayed)
                  buildQrCode(_pixQRCode, context),
                SizedBox(height: 16.h),
                if (_pixQRCode.isNotEmpty && !pixPayed)
                  buildAddressText(_pixQRCode, context, ref),
                // Show a success check when payment is received.
                if (pixPayed)
                  Column(
                    children: [
                      MSHCheckbox(
                        size: 100,
                        value: pixPayed,
                        colorConfig:
                        MSHColorConfig.fromCheckedUncheckedDisabled(
                          checkedColor: Colors.green,
                          uncheckedColor: Colors.white,
                          disabledColor: Colors.grey,
                        ),
                        style: MSHCheckboxStyle.stroke,
                        duration: const Duration(milliseconds: 500),
                        onChanged: (_) {},
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                // Payment details when QR code is generated.
                if (_pixQRCode.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Amount to Receive'.i18n(ref),
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                    vertical: 16.h, horizontal: 8.w),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  '$_amountToReceive Depix',
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Service Fee'.i18n(ref),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${feePercentage.toStringAsFixed(2)} %',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              if (!pixPayed)
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Payment Status'.i18n(ref),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.grey[400],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Pending'.i18n(ref),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Loading indicator while generating QR code.
                if (_isLoading)
                  Center(
                    child: LoadingAnimationWidget.threeArchedCircle(
                      size: 0.1.sh,
                      color: Colors.orange,
                    ),
                  )
                // If no QR code is generated, show the bottom unified info card.
                else if (_pixQRCode.isEmpty)
                  Column(
                    children: [
                      // Generate QR code button.
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0.2.sw),
                        child: CustomButton(
                          onPressed: _generateQRCode,
                          primaryColor: Colors.orange,
                          secondaryColor: Colors.orange,
                          text: 'Generate QR Code'.i18n(ref),
                          textColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Unified information card styled with the provided container decoration.
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 16.h, horizontal: 8.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Transfer limit.
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.info,
                                      color: Colors.grey, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'Transfer limit: R\$ 6000 per 24h per person'
                                          .i18n(ref),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              // Row 2: Refund policy.
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.money_off,
                                      color: Colors.grey, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      "Purchases above R\$ 6000 from the same person will be refunded to the sender's bank account"
                                          .i18n(ref),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              // Row 3: Amount purchased today.
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.attach_money,
                                      color: Colors.grey, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'Amount Purchased Today:'.i18n(ref) + 'R\$ $amountPurchasedToday',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              // Row 4: Minimum purchase for on-chain BTC conversion.
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.currency_bitcoin,
                                      color: Colors.grey, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'Min purchase for on-chain BTC conversion:'.i18n(ref) +' R\$ $minBtcInBRL',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Toggle "See details" button.
                              SizedBox(height: 12.h),
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _infoExpanded = !_infoExpanded;
                                    });
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _infoExpanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: Colors.grey,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        _infoExpanded
                                            ? 'Hide details'.i18n(ref)
                                            : 'See details'.i18n(ref),
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Expanded details section.
                              if (_infoExpanded) ...[
                                SizedBox(height: 12.h),
                                Divider(color: Colors.grey.shade600),
                                SizedBox(height: 12.h),
                                Text(
                                  'Additional Information:'.i18n(ref),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Each person can only transfer up to R\$6000 within a 24-hour period to ensure fair usage.'.i18n(ref),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'If a purchase exceeds R\$6000 from the same person, the excess amount will be refunded automatically to the sender\'s bank account.'.i18n(ref),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'The amount purchased today is aggregated from all transfers made in the current day.'.i18n(ref),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                // Discreet "Back to Home" button (always shown).
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Back to Home'.i18n(ref),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
