library multilevel_drawer;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MultiLevelDrawer extends StatefulWidget {
  final Widget header;
  final List<MLMenuItem> children;
  final Color? backgroundColor;
  final Color? subMenuBackgroundColor;
  final Color? divisionColor;
  final LinearGradient? gradient;
  final Color? rippleColor;
  final double? itemHeight;
  final double ? vPadding, hPadding;

  const MultiLevelDrawer({required this.header,
    required this.children,
    this.backgroundColor = Colors.white,
    this.gradient,
    this.divisionColor = Colors.grey,
    this.rippleColor = Colors.grey,
    this.subMenuBackgroundColor = Colors.white,
    this.itemHeight = 70,
    this.vPadding = 20.0,
    this.hPadding = 5.0});

  @override
  _MultiLevelDrawerState createState() => _MultiLevelDrawerState();
}

class _MultiLevelDrawerState extends State<MultiLevelDrawer> {
  ScrollController scrollController = ScrollController();
  GlobalKey globalKey = GlobalKey();
  List<double> positions = [];
  List<MLMenuItem> drawerItems = [];
  double itemHeight = 0;

  int selectedPosition = -1,
      lastPosition = 0;
  bool openSubMenu = false;

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  @override
  void initState() {
    itemHeight = widget.itemHeight!;
    positions = [0, 0, 0, 0];
    drawerItems = widget.children;
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback(getPositions);
    scrollController.addListener(() {
      selectedPosition = -1;
      getPositions(Duration(milliseconds: 0));
    });
  }

  getPositions(duration) {
    RenderBox? renderBox = globalKey.currentContext!.findRenderObject() as RenderBox;
    double dy = renderBox
        .localToGlobal(Offset.zero)
        .dy;
    double start = dy - 0;
    double end = renderBox.size.height + start;
    double step = itemHeight;
    positions = [];
    for (double x = start; x < end; x = x + step) {
      positions.add(x);
    }
    setState(() {});
  }

  openSubDrawer(position) {
    bool isSamePosition = selectedPosition == position;
    setState(() {
      lastPosition = selectedPosition != -1 ? selectedPosition : 0;
      selectedPosition = isSamePosition ? -1 : position;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery
        .of(context)
        .size;
    bool drawUp = false;
    double boxHeight = 0.0;
    if (selectedPosition != -1) {
      boxHeight = itemHeight * drawerItems[selectedPosition].subMenuItems!.length;
      drawUp = size.height - positions[selectedPosition] < boxHeight;
    }
    return OrientationBuilder(
      builder: (context, orientation) =>
          Container(
            width: size.width,
            child: Stack(
              children: <Widget>[
                if (selectedPosition != -1 && drawerItems[selectedPosition].subMenuItems != null) ...[
                  AnimatedPositioned(
                      duration: Duration(milliseconds: 200),
                      left: selectedPosition == -1 || Bidi.isRtlLanguage(Localizations
                          .localeOf(context)
                          .languageCode) ? 0 : size.width / 2,
                      top: selectedPosition != -1
                          ? max(0, positions[selectedPosition] - (drawUp ? (boxHeight - itemHeight) : 0))
                          : positions[lastPosition],
                      child: Container(
                          decoration: BoxDecoration(color: widget.backgroundColor, gradient: widget.gradient),
                          width: size.width / 2,
                          height: min(size.height - (selectedPosition != -1
                              ? max(0, positions[selectedPosition] - (drawUp ? (boxHeight - itemHeight) : 0))
                              : positions[lastPosition]), // height - top
                              itemHeight * drawerItems[selectedPosition].subMenuItems!.length),
                          child: SingleChildScrollView(
                              child: Container(
                                  width: size.width / 2,
                                  height: itemHeight * drawerItems[selectedPosition].subMenuItems!.length,
                                  child: Stack(
                                    children: <Widget>[
                                      Positioned(
                                        top: 0,
                                        left: Bidi.isRtlLanguage(Localizations
                                            .localeOf(context)
                                            .languageCode) ? 0 : 10,
                                        child: Container(
                                          width: size.width / 2 - 10,
                                          child: Column(
                                            children: drawerItems[selectedPosition].subMenuItems!.map<Widget>((subMenuItem) {
                                              return _MLChoiceItem(
                                                leading: subMenuItem.leading,
                                                trailing: subMenuItem.trailing,
                                                height: itemHeight,
                                                width: size.width / 2 - 10,
                                                color: widget.gradient == null ? widget.backgroundColor : Colors.transparent,
                                                divisionColor: widget.divisionColor,
                                                rippleColor: widget.rippleColor,
                                                vPadding: widget.vPadding,
                                                hPadding: widget.hPadding,
                                                onTap: () {
                                                  subMenuItem.onClick();
                                                },
                                                child: subMenuItem.submenuContent,
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                          top: drawUp ? boxHeight - itemHeight : 0,
                                          left: Bidi.isRtlLanguage(Localizations
                                              .localeOf(context)
                                              .languageCode) ? size.width / 2 - 10 : 0,
                                          child: CustomPaint(
                                            size: Size(10, itemHeight),
                                            painter: _ArrowPainter(context, arrowColor: widget.subMenuBackgroundColor),
                                          ))
                                    ],
                                  ))))),
                ],
                Container(
                  decoration: BoxDecoration(color: widget.backgroundColor, gradient: widget.gradient),
                  width: size.width / 2,
                  height: size.height,
                  child: Column(
                    children: <Widget>[
                      widget.header,
                      Expanded(
                        flex: 7,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Container(
                            key: globalKey,
                            // height: drawerItems.length * itemHeight, no height here, otherwise you cannot scroll to the bottom in landscape orientation
                            child: ListView.builder(
                              itemCount: drawerItems.length,
                              shrinkWrap: true,
                              primary: false,
                              itemBuilder: (BuildContext context, int index) {
                                MLMenuItem item = drawerItems[index];
                                return _MLChoiceItem(
                                  leading: item.leading,
                                  trailing: item.trailing,
                                  width: size.width / 2,
                                  height: itemHeight,
                                  divisionColor: widget.divisionColor,
                                  color: widget.gradient == null ? widget.backgroundColor : Colors.transparent,
                                  rippleColor: widget.rippleColor,
                                  vPadding: widget.vPadding,
                                  hPadding: widget.hPadding,
                                  child: item.content,
                                  onTap: () {
                                    if (item.subMenuItems != null) {
                                      openSubDrawer(index);
                                    } else {
                                      item.onClick();
                                      openSubDrawer(selectedPosition);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
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

class _MLChoiceItem extends StatelessWidget {
  final Function() onTap;
  final Widget? leading;
  final Widget child;
  final Widget? trailing;
  final Color? color;
  final Color? rippleColor;
  final Color? divisionColor;
  final double? width, height;
  final double? vPadding, hPadding;

  const _MLChoiceItem({required this.onTap, required this.child, this.leading, this.trailing, this.color = Colors.white, this.rippleColor = Colors
      .grey, this.divisionColor = Colors.grey, this.width = 0.0, this.height = 0.0, this.vPadding = 20.0, this.hPadding = 5.0});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      child: InkWell(
        highlightColor: rippleColor,
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: divisionColor!, width: 1.0))),
          padding: EdgeInsets.symmetric(vertical: vPadding!, horizontal: hPadding!),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (leading != null) ...[
                Container(
                  child: leading,
                ),
                SizedBox(width: hPadding),
              ],
              Expanded(child: child),
              if (trailing != null) ...[
                SizedBox(width: hPadding),
                Container(
                  child: trailing,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color? arrowColor;
  final BuildContext context;

  _ArrowPainter(this.context, {this.arrowColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = arrowColor!.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    Path path = Path();
    if (Bidi.isRtlLanguage(Localizations
        .localeOf(context)
        .languageCode)) {
      path.moveTo(size.width, size.height / 2);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
}

class MLMenuItem {
  final Widget content;
  final Widget? leading, trailing;
  final Function onClick;
  final List<MLSubmenu>? subMenuItems;

  const MLMenuItem({required this.content, required this.onClick, this.subMenuItems, this.leading, this.trailing});
}

class MLSubmenu {
  final Widget submenuContent;
  final Widget? leading, trailing;
  final Function onClick;

  MLSubmenu({required this.submenuContent, required this.onClick, this.leading, this.trailing});
}
