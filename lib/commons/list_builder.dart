import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:moto_dash/commons/config_provider.dart';
import 'package:moto_dash/commons/constants.dart';
import 'package:moto_dash/commons/dash_action.dart';

class DashWidgets {
  Color? backgroundColor = ConfigProvider.dashboardBackgroundColor;
  Color? fontColor = ConfigProvider.dashboardFontColor;
  Color? borderColor = ConfigProvider.dashboardBorderColor;

  bool showIcons = ConfigProvider.dashboardIcons;
  bool showLabel = ConfigProvider.dashboardLabels;
  bool showMasked = ConfigProvider.dashboardMasked;

  bool isSplitScreen = false;

  Future<void> init() async {
    isSplitScreen = await MethodChannel('assistant.launcher').invokeMethod<bool>('getSplitScreenState') ?? false;
  }

  Widget dashView(bool isSplitScreen, List<Widget> children) {
    if (isSplitScreen) {
      return dashGridView(children);
    }
    return dashListView(children);
  }

  ListView dashListView(List<Widget> children) =>
      ListView(padding: EdgeInsets.zero, physics: const NeverScrollableScrollPhysics(), children: children);

  Widget dashGridView(List<Widget> children) {
    final bool isOdd = children.length.isOdd;

    final List<Widget> gridItems = isOdd ? children.sublist(0, children.length - 1) : children;

    final Widget? lastItem = isOdd ? children.last : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 2;
        const spacing = 10.0;
        const padding = 10.0;

        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;

        // Number of visual rows (including last full-width tile if odd)
        final totalItems = children.length;
        final totalRows = (totalItems / columns).ceil();

        // Available height after padding & spacing
        final usableHeight = totalHeight - padding * 2 - spacing * (totalRows - 1);

        // ONE canonical tile height
        final tileHeight = usableHeight / totalRows;
        final tileWidth = (totalWidth - padding * 2 - spacing) / columns;
        final aspectRatio = tileWidth / tileHeight;

        return SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (gridItems.isNotEmpty)
                  SizedBox(
                    height: tileHeight * (totalRows - (isOdd ? 1 : 0)) + spacing * (totalRows - (isOdd ? 1 : 0) - 1),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: gridItems.length,
                      itemBuilder: (_, index) => gridItems[index],
                    ),
                  ),
                if (lastItem != null) ...[
                  const SizedBox(height: spacing),
                  SizedBox(width: double.infinity, height: tileHeight, child: lastItem),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget dashCardAction(DashAction action, BuildContext context, int itemCount, {bool isSelected = false}) {
    return dashCardFunc(action.label, action.icons, action.action, context, itemCount, isSelected: isSelected);
  }

  Widget dashCardRoute(
    String title,
    List<IconData> icons,
    String route,
    BuildContext context,
    int itemCount, {
    bool isSelected = false,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (route != AppRoutes.dashboard) {
          Navigator.pushNamed(context, route);
        } else {
          Navigator.pop(context);
        }
      },
      child: SizedBox(
        height: (screenHeight - 30 - (itemCount - 1) * 10) / itemCount,
        child: Card(
          color: backgroundColor ?? Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: (borderColor ?? Colors.grey), width: isSelected ? 3 : 1),
          ),
          child: Center(child: dashListTile(icons, title, null, null)),
        ),
      ),
    );
  }

  Widget dashCardFunc(
    String title,
    List<IconData> icons,
    Function() onTap,
    BuildContext context,
    int itemCount, {
    bool? overrideShowIcons,
    bool? overrideShowLabel,
    bool isSelected = false,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        onTap();
      },
      child: SizedBox(
        height: (screenHeight - 30 - (itemCount - 1) * 10) / itemCount,
        child: Card(
          color: backgroundColor ?? Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: (borderColor ?? Colors.grey), width: isSelected ? 3 : 1),
          ),
          child: Center(child: dashListTile(icons, title, overrideShowIcons, overrideShowLabel)),
        ),
      ),
    );
  }

  ListTile dashListTile(List<IconData> icons, String title, bool? overrideShowIcons, bool? overrideShowLabel) {
    // Resolve final behavior
    final bool showIconsFinal = overrideShowIcons ?? showIcons;
    final bool showLabelFinal = overrideShowLabel ?? showLabel;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0), // Add padding
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the row
        children: [
          if (showIconsFinal)
            for (IconData icon in icons) Icon(icon, color: fontColor ?? Colors.white, size: 40), // Show icon if enabled
          SizedBox(width: 8.0), // Space between icon and text
          if (showLabelFinal)
            Text(
              showMasked ? title.substring(0, 1) : title, // FIXME: Get the canMask attribute here
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(color: fontColor ?? Colors.white, fontSize: ConfigProvider.dashboardFontSize),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
