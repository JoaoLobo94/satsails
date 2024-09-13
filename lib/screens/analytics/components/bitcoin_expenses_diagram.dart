import 'package:Satsails/providers/analytics_provider.dart';
import 'package:Satsails/providers/balance_provider.dart';
import 'package:Satsails/screens/analytics/components/bitcoin_expenses_graph.dart';
import 'package:Satsails/translations/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Satsails/models/expenses_model.dart';
import 'package:Satsails/providers/settings_provider.dart';
import 'package:Satsails/providers/transactions_provider.dart';

class BitcoinExpensesDiagram extends ConsumerWidget {
  const BitcoinExpensesDiagram({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bitcoinTransactions = ref.watch(bitcoinTransactionsByDate);
    final btcFormat = ref.watch(settingsProvider).btcFormat;
    final btcBalanceInFormat = ref.watch(btcBalanceInFormatProvider(btcFormat));
    final screenWidth = MediaQuery.of(context).size.width;

    return Expanded(
      child: Column(
        children: [
          Text('Current Balance'.i18n(ref), style: TextStyle(fontSize: screenWidth / 20, color: Colors.white)),
          Text(
            '$btcBalanceInFormat $btcFormat',
            style: TextStyle(fontSize: screenWidth / 20, color: Colors.white),
          ),
          if (ref.watch(oneDayProvider))
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCard(
                  'Sent'.i18n(ref),
                  _calculateBitcoinExpenses(bitcoinTransactions).convertToDenomination(btcFormat).sent,
                  [Colors.orange, Colors.orange],
                  context,
                  btcFormat,
                ),
                _buildCard(
                  'Received'.i18n(ref),
                  _calculateBitcoinExpenses(bitcoinTransactions).convertToDenomination(btcFormat).received,
                  [Colors.orange, Colors.orange],
                  context,
                  btcFormat,
                ),
                _buildCard(
                  'Fee'.i18n(ref),
                  _calculateBitcoinExpenses(bitcoinTransactions).convertToDenomination(btcFormat).fee,
                  [Colors.orange, Colors.orange],
                  context,
                  btcFormat,
                ),
              ],
            ),
          if (!ref.watch(oneDayProvider))
            const Expanded(  // Ensure ExpensesGraph expands to take all available space
              child: ExpensesGraph(),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, double value, List<Color> gradientColors, BuildContext context, String btcFormat) {
    final dynamicHeight = MediaQuery.of(context).size.height;
    final dynamicWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: dynamicWidth / 3.5,
      height: dynamicHeight / 7,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.black, fontSize: dynamicWidth / 23, fontWeight: FontWeight.bold),
              ),
              Text(
                btcFormat == 'sats' ? value.toStringAsFixed(0) : value.toString(),
                style: TextStyle(color: Colors.black, fontSize: dynamicWidth / 25),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BitcoinExpenses _calculateBitcoinExpenses(List<dynamic> transactions) {
    int received = 0;
    int sent = 0;
    int fee = 0;
    for (var transaction in transactions) {
      received += transaction.received as int;
      sent += transaction.sent as int;
      if (transaction.sent > 0) {
        fee += transaction.fee as int;
      }
    }
    return BitcoinExpenses(received: received, sent: sent, fee: fee);
  }
}
