import 'package:flutter/material.dart';
import 'websocket_service.dart';

class GridRenderer extends StatelessWidget {
  final WebSocketService webSocketService;
  final Map<String, dynamic> pageConfig;

  const GridRenderer({
    super.key,
    required this.webSocketService,
    required this.pageConfig,
  });

  @override
  Widget build(BuildContext context) {
    final headers = pageConfig['headers'] as List<dynamic>? ?? [];
    final table = pageConfig['table'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Headers
            Row(
              children: headers.map((header) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      header.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  final availableWidth = constraints.maxWidth;
                  final crossAxisCount = headers.length;
                  final spacing = 8.0;
                  final totalSpacing = (crossAxisCount - 1) * spacing;
                  final cellWidth = (availableWidth - totalSpacing) / crossAxisCount;
                  
                  // Calculate how many rows we have
                  final totalCells = _getTotalCells(table);
                  final rowCount = (totalCells / crossAxisCount).ceil();
                  final totalRowSpacing = (rowCount - 1) * spacing;
                  final cellHeight = (availableHeight - totalRowSpacing) / rowCount;
                  
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: cellWidth / cellHeight,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    itemCount: _getTotalCells(table),
                    itemBuilder: (context, index) {
                      final (row, col) = _getRowCol(index, table);
                      final cell = _getCell(table, row, col);
                      print('table: $table');
                      print('cell: $cell');
                      print('row: $row');
                      print('col: $col');
                      print('index: $index');
                      print('total cells: ${_getTotalCells(table)}');
                      if (cell == null) {
                        return Container();
                      }

                      final buttonKey = '${row}_${col}';
                      final isPressed = webSocketService.pressedButtons.contains(buttonKey);
                      final isEnabled = webSocketService.enabledTeam == webSocketService.mode && webSocketService.enabledTeam != 'none';
                      
                      // Team colors
                      final teamColor = webSocketService.mode == 'team_red' ? Colors.red : 
                                      webSocketService.mode == 'team_blue' ? Colors.blue :
                                      webSocketService.mode == 'team_yellow' ? Colors.yellow :
                                      webSocketService.mode == 'team_green' ? Colors.green : Colors.grey;
                      final backgroundColor = isPressed 
                          ? Colors.grey[600]! 
                          : (isEnabled ? teamColor.withOpacity(0.3) : Colors.transparent);
                      final borderColor = isPressed ? Colors.grey[400]! : teamColor;
                      
                      return GestureDetector(
                        onTap: (isPressed || !isEnabled) ? null : () {
                          webSocketService.sendGridClick(row, col);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: borderColor, 
                              width: 2
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cell['titel'] ?? 'Unknown',
                              style: TextStyle(
                                color: isPressed ? Colors.grey[300] : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getTotalCells(List<dynamic> table) {
    if (table.isEmpty) return 0;
    // Outer list = columns
    final cols = table.length;
    final rows = (table[0] as List<dynamic>).length;
    return rows * cols;
  }

  // Converts linear index into (row, col) in column-major order
  (int, int) _getRowCol(int index, List<dynamic> table) {
    if (table.isEmpty || (table[0] as List).isEmpty) return (0, 0);
    final cols = table.length;
    
    final row = index ~/ cols;
    final col = index % cols;

    return (row.toInt(), col.toInt());
  }

  // Safe getter: table is column-major
  Map<String, dynamic>? _getCell(List<dynamic> table, int row, int col) {
    if (col >= table.length) return null;
    final colData = table[col] as List<dynamic>;
    if (row >= colData.length) return null;
    return colData[row] as Map<String, dynamic>;
  }
} 