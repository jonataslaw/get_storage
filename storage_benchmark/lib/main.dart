import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:benchmark/benchmark.dart';

void main() => runApp(App());

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin {
  TabController controller;

  @override
  void initState() {
    super.initState();

    controller = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: <Widget>[
                Center(
                  child: Text(
                    "Storage Benchmark",
                    style: TextStyle(fontSize: 33),
                  ),
                ),
                SizedBox(height: 15),
                TabBar(
                  tabs: <Widget>[
                    Tab(text: "read"),
                    Tab(text: "write"),
                    Tab(text: "delete"),
                  ],
                  labelColor: const Color(0xff7589a2),
                  controller: controller,
                  onTap: (index) {
                    setState(() {});
                  },
                ),
                SizedBox(height: 25),
                Expanded(
                  child:
                      BenchmarkWidget(BenchmarkType.values[controller.index]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum BenchmarkType { read, write, delete }

class BenchmarkWidget extends StatefulWidget {
  final BenchmarkType type;

  BenchmarkWidget(this.type);

  @override
  _BenchmarkWidgetState createState() => _BenchmarkWidgetState();
}

class _BenchmarkWidgetState extends State<BenchmarkWidget> {
  static const entrySteps = [10, 20, 50, 100, 200, 500, 1000];

  var entryValue = 0.0;
  int get entries => entrySteps[entryValue.round()];

  var benchmarkRunning = false;
  List<Result> benchmarkResults;

  @override
  void didChangeDependencies() {
    benchmarkResults = null;
    benchmarkRunning = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (benchmarkResults == null)
          Expanded(
            child: Center(
              child: Text('Run benchmark to show data'),
            ),
          )
        else
          Expanded(
            child: Center(
              child: BenchmarkResult(benchmarkResults),
            ),
          ),
        SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: Slider(
                value: entryValue,
                min: 0,
                max: (entrySteps.length - 1).toDouble(),
                divisions: entrySteps.length - 2,
                onChanged: (newValue) {
                  setState(() {
                    entryValue = newValue;
                  });
                },
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(entries.toString() + " Entries"),
            ),
          ],
        ),
        Center(
          child: RaisedButton(
            onPressed: !benchmarkRunning ? _performBenchmark : null,
            child: Text("Benchmark"),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  _performBenchmark() async {
    var entries = this.entries;
    setState(() {
      benchmarkRunning = true;
    });

    List<Result> results;
    switch (widget.type) {
      case BenchmarkType.read:
        results = await benchmarkRead(entries);
        break;
      case BenchmarkType.write:
        results = await benchmarkWrite(entries);
        break;
      case BenchmarkType.delete:
        results = await benchmarkDelete(entries);
        break;
    }

    setState(() {
      benchmarkRunning = false;
      benchmarkResults = results;
    });
  }
}

class BenchmarkResult extends StatelessWidget {
  final Color leftBarColor = Color(0xff53fdd7);
  final Color rightBarColor = Color(0xffff5182);
  final double width = 12;

  final List<Result> results;

  BenchmarkResult(this.results);

  List<String> get labels {
    return results.map((r) => r.runner.name).toList();
  }

  int get maxResultTime {
    var max = 0;
    for (var result in results) {
      if (result.intTime > max) {
        max = result.intTime;
      }
      if (result.stringTime > max) {
        max = result.stringTime;
      }
    }
    return max;
  }

  List<BarChartGroupData> get barGroups {
    var x = 0;
    return results.map((result) {
      return BarChartGroupData(
        barsSpace: 4,
        x: x++,
        barRods: [
          BarChartRodData(
            y: max(result.intTime.toDouble(), 1),
            color: leftBarColor,
            width: width,
            isRound: true,
          ),
          BarChartRodData(
            y: max(result.stringTime.toDouble(), 1),
            color: rightBarColor,
            width: width,
            isRound: true,
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: 10),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 15,
                height: 15,
                child: Container(
                  color: leftBarColor,
                ),
              ),
              SizedBox(width: 5),
              Text(
                'Integers',
                style: TextStyle(
                  color: const Color(0xff7589a2),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 15,
                height: 15,
                child: Container(
                  color: rightBarColor,
                ),
              ),
              SizedBox(width: 5),
              Text(
                'Strings',
                style: TextStyle(
                  color: const Color(0xff7589a2),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Expanded(
          child: _buildChart(),
        ),
      ],
    );
  }

  _buildChart() {
    var maxTime = maxResultTime;
    return Container(
      child: FlChart(
        chart: BarChart(
          BarChartData(
            barTouchData: BarTouchData(
              touchTooltipData: TouchTooltipData(
                tooltipBgColor: Colors.grey,
                getTooltipItems: (spots) {
                  return spots.map((TouchedSpot spot) {
                    return null;
                  }).toList();
                },
              ),
            ),
            maxY: maxTime.toDouble(),
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: SideTitles(
                showTitles: true,
                textStyle: TextStyle(
                  color: const Color(0xff7589a2),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                margin: 20,
                getTitles: (double value) {
                  return labels[value.toInt()];
                },
              ),
              leftTitles: SideTitles(
                showTitles: true,
                textStyle: TextStyle(
                  color: const Color(0xff7589a2),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                margin: 32,
                reservedSize: 50,
                getTitles: (value) {
                  if (value % (maxResultTime ~/ 4) == 0) {
                    return value.toInt().toString() + 'ms';
                  }
                  return '';
                },
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }
}
