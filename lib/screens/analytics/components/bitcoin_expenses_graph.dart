import 'package:Satsails/providers/analytics_provider.dart';
import 'package:Satsails/providers/currency_conversions_provider.dart';
import 'package:Satsails/providers/settings_provider.dart';
import 'package:Satsails/screens/analytics/components/calendar.dart';
import 'package:Satsails/translations/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class LineChartSample extends StatelessWidget {
  final List<DateTime> selectedDays;
  final Map<DateTime, num> feeData;
  final Map<DateTime, num> incomeData;
  final Map<DateTime, num> spendingData;
  final Map<DateTime, num>? mainData;
  final Map<DateTime, num> balanceInCurrency;
  final String selectedCurrency;
  final bool isShowingMainData;

  const LineChartSample({
    super.key,
    required this.selectedDays,
    required this.feeData,
    required this.incomeData,
    required this.spendingData,
    this.mainData,
    required this.balanceInCurrency,
    required this.selectedCurrency,
    required this.isShowingMainData,
  });

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: const DateTimeAxis(
        isVisible: true,
        labelStyle: TextStyle(color: Colors.white),
        majorGridLines: MajorGridLines(width: 0),
        minorGridLines: MinorGridLines(width: 0),
        axisLine: AxisLine(width: 0),
      ),
      primaryYAxis: NumericAxis(
        isVisible: true,
        decimalPlaces: balanceInCurrency.values.isNotEmpty
            ? decimalPlacesBtcFormat(balanceInCurrency.values.reduce((value, element) => value > element ? value : element))
            : 0, // Default value when balanceInCurrency.values is empty
        majorGridLines: const MajorGridLines(width: 0),
        minorGridLines: const MinorGridLines(width: 0),
        labelStyle: const TextStyle(color: Colors.white),
      ),
      plotAreaBorderWidth: 0,
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineType: TrackballLineType.vertical,
        tooltipSettings: const InteractiveTooltip(
          enable: true,
          color: Colors.orangeAccent,
          textStyle: TextStyle(color: Colors.white),
          borderWidth: 0,
          decimalPlaces: 8,
        ),
        builder: (BuildContext context, TrackballDetails trackballDetails) {
          final DateFormat formatter = DateFormat('dd/MM');
          final DateTime date = trackballDetails.point!.x;
          final num? value = trackballDetails.point!.y;
          final String formattedDate = formatter.format(date);
          final String bitcoinValue = value!.toStringAsFixed(value == value.roundToDouble() ? 0 : 8);
          final String currencyValue = balanceInCurrency[date]?.toStringAsFixed(balanceInCurrency[date] == balanceInCurrency[date]!.roundToDouble() ? 0 : 2) ?? '0.00';
          final displayString = '$formattedDate\nBitcoin: $bitcoinValue\n$selectedCurrency: $currencyValue';
          final displayStringIfNotMainData = bitcoinValue;

          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              isShowingMainData ? displayString : displayStringIfNotMainData,
              style: const TextStyle(color: Colors.black),
            ),
          );
        },
      ),
      series: _chartSeries(),
    );
  }

  List<LineSeries<MapEntry<DateTime, num>, DateTime>> _chartSeries() {
    final seriesList = <LineSeries<MapEntry<DateTime, num>, DateTime>>[];

    if (mainData != null && isShowingMainData) {
      seriesList.add(LineSeries<MapEntry<DateTime, num>, DateTime>(
        name: 'Main Data',
        dataSource: mainData!.entries.toList(),
        xValueMapper: (MapEntry<DateTime, num> entry, _) => entry.key,
        yValueMapper: (MapEntry<DateTime, num> entry, _) => entry.value,
        color: Colors.orangeAccent,
        markerSettings: const MarkerSettings(isVisible: false),
        animationDuration: 0,
      ));
    } else {
      seriesList.add(LineSeries<MapEntry<DateTime, num>, DateTime>(
        name: 'Spending',
        dataSource: spendingData.entries.toList(),
        xValueMapper: (MapEntry<DateTime, num> entry, _) => entry.key,
        yValueMapper: (MapEntry<DateTime, num> entry, _) => entry.value,
        color: Colors.blueAccent,
        markerSettings: const MarkerSettings(isVisible: false),
        animationDuration: 0,
      ));
      seriesList.add(LineSeries<MapEntry<DateTime, num>, DateTime>(
        name: 'Income',
        dataSource: incomeData.entries.toList(),
        xValueMapper: (MapEntry<DateTime, num> entry, _) => entry.key,
        yValueMapper: (MapEntry<DateTime, num> entry, _) => entry.value,
        color: Colors.greenAccent,
        markerSettings: const MarkerSettings(isVisible: false),
        animationDuration: 0,
      ));
      seriesList.add(LineSeries<MapEntry<DateTime, num>, DateTime>(
        name: 'Fee',
        dataSource: feeData.entries.toList(),
        xValueMapper: (MapEntry<DateTime, num> entry, _) => entry.key,
        yValueMapper: (MapEntry<DateTime, num> entry, _) => entry.value.toDouble(),
        color: Colors.orangeAccent,
        markerSettings: const MarkerSettings(isVisible: false),
        animationDuration: 0,
      ));
    }

    return seriesList;
  }
}


class ExpensesGraph extends ConsumerStatefulWidget {
  const ExpensesGraph({super.key});

  @override
  _ExpensesGraphState createState() => _ExpensesGraphState();
}

class _ExpensesGraphState extends ConsumerState<ExpensesGraph> {
  bool isShowingMainData = false;

  @override
  Widget build(BuildContext context) {
    final selectedDays = ref.watch(selectedDaysDateArrayProvider);
    final feeData = ref.watch(bitcoinFeeSpentPerDayProvider);
    final incomeData = ref.watch(bitcoinIncomePerDayProvider);
    final spendingData = ref.watch(bitcoinSpentPerDayProvider);
    final bitcoinBalanceByDay = ref.watch(bitcoinBalanceInFormatByDayProvider);
    final bitcoinBalanceByDayUnformatted = ref.watch(bitcoinBalanceInBtcByDayProvider);
    final selectedCurrency = ref.watch(settingsProvider).currency;
    final currencyRate = ref.watch(selectedCurrencyProvider(selectedCurrency));

    return Column(
      children: <Widget>[
        Center(
          child: TextButton(
            child: Text(
              !isShowingMainData ? 'Show Statistics over period'.i18n(ref) : 'Show Balance'.i18n(ref),
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () {
              setState(() {
                isShowingMainData = !isShowingMainData;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: !isShowingMainData
              ? [_buildLegend('Balance'.i18n(ref), Colors.orangeAccent)]
              : [
            _buildLegend('Spending'.i18n(ref), Colors.blueAccent),
            _buildLegend('Income'.i18n(ref), Colors.greenAccent),
            _buildLegend('Fee'.i18n(ref), Colors.orangeAccent),
          ],
        ),
        const Calendar(),
        Expanded(  // This makes the LineChartSample expand to take up available space
          child: LineChartSample(
            selectedDays: selectedDays,
            feeData: feeData,
            incomeData: incomeData,
            spendingData: spendingData,
            mainData: !isShowingMainData ? bitcoinBalanceByDay : null,
            balanceInCurrency: calculateBalanceInCurrency(bitcoinBalanceByDayUnformatted, currencyRate),
            selectedCurrency: selectedCurrency,
            isShowingMainData: !isShowingMainData,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

Map<DateTime, num> calculateBalanceInCurrency(Map<DateTime, num> balanceByDay, num currencyRate) {
  final Map<DateTime, num> balanceInCurrency = {};
  balanceByDay.forEach((day, balance) {
    balanceInCurrency[day] = (balance * currencyRate).toDouble();
  });
  return balanceInCurrency;
}

int decimalPlacesBtcFormat(num value) {
  if (value == value.roundToDouble()) return 0;
  final String valueString = value.toString();
  final int decimalPlaces = valueString.split('.').last.length;
  return decimalPlaces;
}
