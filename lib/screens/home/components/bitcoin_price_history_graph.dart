import 'package:Satsails/providers/coingecko_provider.dart';
import 'package:coingecko_api/data/market_chart_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

final interactiveModeProvider = StateProvider<bool>((ref) => false);

class LineChartSample extends StatelessWidget {
  final List<MarketChartData> marketData;
  final bool isInteractive;

  const LineChartSample({
    super.key,
    required this.marketData,
    required this.isInteractive,
  });

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: const DateTimeAxis(
        isVisible: true,
        majorGridLines: MajorGridLines(width: 0),
        minorGridLines: MinorGridLines(width: 0),
        axisLine: AxisLine(width: 0),
        labelStyle: TextStyle(color: Colors.white),
      ),
      primaryYAxis: const NumericAxis(
        isVisible: true,
        majorGridLines: MajorGridLines(width: 0),
        minorGridLines: MinorGridLines(width: 0),
        axisLine: AxisLine(width: 0),
        labelStyle: TextStyle(color: Colors.white),
      ),
      plotAreaBorderWidth: 0,
      trackballBehavior: TrackballBehavior(
        enable: isInteractive,
        activationMode: ActivationMode.singleTap,
        lineType: TrackballLineType.none,
        tooltipSettings: const InteractiveTooltip(
          enable: true,
          color: Colors.orangeAccent,
          textStyle: TextStyle(color: Colors.white),
          borderWidth: 0,
          decimalPlaces: 8,
        ),
        builder: (BuildContext context, TrackballDetails trackballDetails) {
          final DateFormat formatter = DateFormat('dd/MM/yyyy');
          final DateTime date = trackballDetails.point!.x;
          final num? value = trackballDetails.point!.y;
          final String formattedDate = formatter.format(date);
          final String bitcoinValue = value!.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);

          return Text(
            '$formattedDate\n $bitcoinValue',
            style: const TextStyle(color: Colors.white),
          );
        },
      ),
      series: _chartSeries(),
    );
  }

  List<SplineSeries<MarketChartData, DateTime>> _chartSeries() {
    return [
      SplineSeries<MarketChartData, DateTime>(
        name: 'Market Data',
        dataSource: marketData,
        xValueMapper: (MarketChartData data, _) => data.date,
        yValueMapper: (MarketChartData data, _) => data.price,
        color: Colors.orangeAccent,
        markerSettings: const MarkerSettings(isVisible: false),
        animationDuration: 0,
      ),
    ];
  }
}

class BitcoinPriceHistoryGraph extends ConsumerWidget {
  const BitcoinPriceHistoryGraph({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketData = ref.watch(coinGeckoBitcoinMarketDataProvider);
    final isInteractiveMode = ref.watch(interactiveModeProvider);

    return marketData.when(
      data: (data) {
        return Column(
          children: [
            _buildDateRangeButtons(ref),
            Expanded(
              child: LineChartSample(marketData: data, isInteractive: isInteractiveMode),
            ),
          ],
        );
      },
      loading: () {
        return Center(
          child: LoadingAnimationWidget.threeArchedCircle(size: 100, color: Colors.orange),
        );
      },
      error: (error, stack) {
        return Center(
          child: Text('Error: $error'),
        );
      },
    );
  }

  Widget _buildDateRangeButtons(WidgetRef ref) {
    final isInteractiveMode = ref.watch(interactiveModeProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildDateRangeButton(ref, 1, '1D'),
        _buildDateRangeButton(ref, 7, '7D'),
        _buildDateRangeButton(ref, 30, '1M'),
        _buildDateRangeButton(ref, 365, '1Y'),
        Column(
          children: [
            TextButton(
              onPressed: () {
                ref.read(interactiveModeProvider.notifier).state = !isInteractiveMode;
              },
              style: TextButton.styleFrom(
                foregroundColor: isInteractiveMode ? Colors.orangeAccent : Colors.grey,
              ),
              child: Icon(Icons.touch_app, color: isInteractiveMode ? Colors.orangeAccent : Colors.white),
            ),
          ],
        )

      ],
    );
  }

  Widget _buildDateRangeButton(WidgetRef ref, int range, String text) {
    final selectedDateRange = ref.watch(selectedDateRangeProvider);

    return TextButton(
      onPressed: () => ref.read(selectedDateRangeProvider.notifier).state = range,
      child: Text(
        text,
        style: TextStyle(
          color: selectedDateRange == range ? Colors.orangeAccent : Colors.white,
        ),
      ),
    );
  }
}

