import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const TTDApp());
}

class TTDApp extends StatefulWidget {
  const TTDApp({super.key});
  @override
  State<TTDApp> createState() => _TTDAppState();
}

class _TTDAppState extends State<TTDApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TTD Trading Dashboard',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        cardColor: Colors.grey[200],
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.grey[100],
          filled: true,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          backgroundColor: Colors.black,
        ),
        cardColor: Colors.grey[900],
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.grey[800],
          filled: true,
        ),
      ),
      home: TradeDashboard(
        isDarkMode: isDarkMode,
        onThemeToggle: () => setState(() => isDarkMode = !isDarkMode),
      ),
    );
  }
}

class Trade {
  final String tradeNumber;
  final double pnl;
  final String note;
  final DateTime date;

  Trade({
    required this.tradeNumber,
    required this.pnl,
    required this.note,
    required this.date,
  });

  bool get isWin => pnl >= 0;
}

class TradingObjective {
  String description;
  bool isCompleted;

  TradingObjective({
    required this.description,
    this.isCompleted = false,
  });
}

class TradeSettings {
  double startingBalance;
  double profitTarget;
  double lossLimit;
  bool isTrailingStop;
  double highestBalance; // Track highest balance for trailing stop

  TradeSettings({
    required this.startingBalance,
    required this.profitTarget,
    required this.lossLimit,
    this.isTrailingStop = false,
    this.highestBalance = 0,
  });
}

class TradeDashboard extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  
  const TradeDashboard({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<TradeDashboard> createState() => _TradeDashboardState();
}

class _TradeDashboardState extends State<TradeDashboard> {
  late TradeSettings settings = TradeSettings(
    startingBalance: 50000.0,
    profitTarget: 2000.0,
    lossLimit: 3000.0,
    isTrailingStop: false,
    highestBalance: 50000.0,
  );

  final List<Trade> trades = [];
  final List<TradingObjective> objectives = [
    TradingObjective(description: "10% monthly return"),
    TradingObjective(description: "3:1 reward/risk"),
    TradingObjective(description: "5 trades/day"),
  ];

  final _tradeNumberController = TextEditingController();
  final _pnlController = TextEditingController();
  final _noteController = TextEditingController();
  final _newObjectiveController = TextEditingController();
  final _startingBalanceController = TextEditingController();

  final _tradeNumberFocus = FocusNode();
  final _pnlFocus = FocusNode();
  final _noteFocus = FocusNode();

  double get currentBalance => settings.startingBalance + 
      trades.fold(0, (sum, trade) => sum + trade.pnl);

  @override
  void initState() {
    super.initState();
    _startingBalanceController.text = settings.startingBalance.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _tradeNumberFocus.dispose();
    _pnlFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  void _addTrade() {
    final pnl = double.tryParse(_pnlController.text);
    final tradeNumber = _tradeNumberController.text.trim();
    
    if (pnl == null || tradeNumber.isEmpty) return;
    
    setState(() {
      // Add the new trade
      trades.insert(0, Trade(
        tradeNumber: tradeNumber,
        pnl: pnl,
        note: _noteController.text.trim(),
        date: DateTime.now(),
      ));
      
      // Update highest balance for trailing stop
      if (currentBalance + pnl > settings.highestBalance) {
        settings.highestBalance = currentBalance + pnl;
      }
      
      _tradeNumberController.clear();
      _pnlController.clear();
      _noteController.clear();
      _tradeNumberFocus.requestFocus();
    });
  }

  void _showEditStartingBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Starting Balance'),
        content: TextField(
          controller: _startingBalanceController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newBalance = double.tryParse(_startingBalanceController.text);
              if (newBalance != null) {
                setState(() {
                  settings.startingBalance = newBalance;
                  // Reset highest balance when starting balance changes
                  settings.highestBalance = newBalance;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditObjectivesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Objectives'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...objectives.map((obj) {
                      return CheckboxListTile(
                        title: Text(obj.description),
                        value: obj.isCompleted,
                        onChanged: (value) {
                          setState(() {
                            obj.isCompleted = value ?? false;
                          });
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newObjectiveController,
                      decoration: const InputDecoration(
                        labelText: 'Add new objective',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_newObjectiveController.text.trim().isNotEmpty) {
                      setState(() {
                        objectives.add(TradingObjective(
                          description: _newObjectiveController.text.trim(),
                        ));
                        _newObjectiveController.clear();
                      });
                    }
                  },
                  child: const Text('Add'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSettingsDialog() {
    final profitTargetController = TextEditingController(
      text: settings.profitTarget.toStringAsFixed(2));
    final lossLimitController = TextEditingController(
      text: settings.lossLimit.toStringAsFixed(2));
    bool isTrailingStop = settings.isTrailingStop;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Trading Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: profitTargetController,
                      decoration: const InputDecoration(
                        labelText: 'Profit Target',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: lossLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Loss Limit',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Trailing Stop'),
                      value: isTrailingStop,
                      onChanged: (value) {
                        setState(() {
                          isTrailingStop = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final newProfitTarget = double.tryParse(
                      profitTargetController.text);
                    final newLossLimit = double.tryParse(
                      lossLimitController.text);

                    if (newProfitTarget != null && newLossLimit != null) {
                      setState(() {
                        settings.profitTarget = newProfitTarget;
                        settings.lossLimit = newLossLimit;
                        settings.isTrailingStop = isTrailingStop;
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double _getCurrentLossLimit() {
    if (!settings.isTrailingStop) {
      return -settings.lossLimit;
    }
    
    // For trailing stop, calculate based on highest balance
    final trailingStopLevel = settings.highestBalance - settings.lossLimit;
    return trailingStopLevel - settings.startingBalance;
  }

  Widget _buildChart() {
    if (trades.isEmpty) {
      return Center(
        child: Text(
          'No trades to display',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      );
    }

    // Calculate min/max values for Y axis
    double minY = trades.map((t) => t.pnl).reduce((a, b) => a < b ? a : b);
    double maxY = trades.map((t) => t.pnl).reduce((a, b) => a > b ? a : b);
    
    // Add some padding
    minY = minY * 1.2;
    maxY = maxY * 1.2;
    
    // Get current profit target and loss limit
    final profitTargetLine = settings.profitTarget;
    final lossLimitLine = _getCurrentLossLimit();
    
    // Adjust chart range if needed
    if (profitTargetLine > maxY) maxY = profitTargetLine * 1.1;
    if (lossLimitLine < minY) minY = lossLimitLine * 1.1;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt() - 1;
                  if (index < 0 || index >= trades.length) return Container();
                  
                  final trade = trades[index];
                  final date = '${trade.date.day}/${trade.date.month}';
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: [
                        Text(
                          '#${trade.tradeNumber}',
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 8,
                            color: widget.isDarkMode ? Colors.white54 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text('\$${value.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  )),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: trades.asMap().entries.map((entry) {
                return FlSpot(
                  (entry.key + 1).toDouble(),
                  entry.value.pnl,
                );
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          minX: 1,
          maxX: trades.length.toDouble(),
          minY: minY,
          maxY: maxY,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              // Profit target line (green dotted)
              HorizontalLine(
                y: profitTargetLine,
                color: Colors.green,
                strokeWidth: 1,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                  ),
                  labelResolver: (value) => 'Target: \$${(settings.startingBalance + profitTargetLine).toStringAsFixed(0)}',
                ),
              ),
              // Loss limit line (red dotted)
              HorizontalLine(
                y: lossLimitLine,
                color: Colors.red,
                strokeWidth: 1,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.bottomRight,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                  ),
                  labelResolver: (value) => settings.isTrailingStop 
                      ? 'Trailing Stop: \$${(settings.startingBalance + lossLimitLine).toStringAsFixed(0)}'
                      : 'Stop Loss: \$${(settings.startingBalance + lossLimitLine).toStringAsFixed(0)}',
                ),
              ),
              // Zero line
              HorizontalLine(
                y: 0,
                color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                strokeWidth: 1,
                dashArray: [2, 2],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final currentLossLimit = _getCurrentLossLimit();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: widget.isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.black,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.white,
            ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TTD Trading Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.flag),
              onPressed: _showEditObjectivesDialog,
              tooltip: 'Edit Objectives',
            ),
            IconButton(
              icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
              onPressed: widget.onThemeToggle,
              tooltip: 'Toggle Theme',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsDialog,
              tooltip: 'Settings',
            ),
          ],
        ),
        body: Column(
          children: [
            // Balance Display
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Current Balance: \$${currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isLargeScreen ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: currentBalance >= settings.startingBalance
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: _showEditStartingBalanceDialog,
                        tooltip: 'Edit Starting Balance',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Starting: \$${settings.startingBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 14 : 12,
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target: \$${(settings.startingBalance + settings.profitTarget).toStringAsFixed(0)} | '
                    '${settings.isTrailingStop ? 'Trailing Stop' : 'Stop Loss'}: \$${(settings.startingBalance + currentLossLimit).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 14 : 12,
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            
            // Chart
            Expanded(
              flex: 2,
              child: _buildChart(),
            ),
            
            // Trade List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: trades.isEmpty
                    ? Center(
                        child: Text(
                          'No trades yet',
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: trades.length,
                        itemBuilder: (context, index) {
                          final trade = trades[index];
                          final date = '${trade.date.day}/${trade.date.month}';
                          
                          return Card(
                            color: widget.isDarkMode ? Colors.grey[900] : Colors.grey[200],
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Text('#${trade.tradeNumber}'),
                              title: Text(
                                'PnL: \$${trade.pnl.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: trade.isWin ? Colors.green : Colors.red,
                                ),
                              ),
                              subtitle: Text(trade.note),
                              trailing: Text(
                                date,
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            
            // Add Trade Form
            Container(
              padding: const EdgeInsets.all(16),
              color: widget.isDarkMode ? Colors.grey[900] : Colors.grey[200],
              child: isLargeScreen
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tradeNumberController,
                            focusNode: _tradeNumberFocus,
                            decoration: InputDecoration(
                              labelText: 'Trade #',
                              border: const OutlineInputBorder(),
                              labelStyle: TextStyle(
                                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                            ),
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _pnlFocus.requestFocus(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _pnlController,
                            focusNode: _pnlFocus,
                            decoration: InputDecoration(
                              labelText: 'PnL',
                              border: const OutlineInputBorder(),
                              labelStyle: TextStyle(
                                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                            ),
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _noteFocus.requestFocus(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _noteController,
                            focusNode: _noteFocus,
                            decoration: InputDecoration(
                              labelText: 'Note',
                              border: const OutlineInputBorder(),
                              labelStyle: TextStyle(
                                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addTrade(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _addTrade,
                          child: const Text('Add'),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextField(
                          controller: _tradeNumberController,
                          focusNode: _tradeNumberFocus,
                          decoration: InputDecoration(
                            labelText: 'Trade #',
                            border: const OutlineInputBorder(),
                            labelStyle: TextStyle(
                              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _pnlFocus.requestFocus(),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _pnlController,
                          focusNode: _pnlFocus,
                          decoration: InputDecoration(
                            labelText: 'PnL',
                            border: const OutlineInputBorder(),
                            labelStyle: TextStyle(
                              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _noteFocus.requestFocus(),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _noteController,
                          focusNode: _noteFocus,
                          decoration: InputDecoration(
                            labelText: 'Note',
                            border: const OutlineInputBorder(),
                            labelStyle: TextStyle(
                              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addTrade(),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addTrade,
                            child: const Text('Add Trade'),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}