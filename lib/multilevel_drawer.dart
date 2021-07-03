library multilevel_drawer;
import 'package:flutter/material.dart';

class MultiLevelDrawer extends StatefulWidget {
  final Widget header;
  final List<MLMenuItem> children;
  final Color? backgroundColor;
  final Color? subMenuBackgroundColor;
  final Color? divisionColor;
  final LinearGradient? gradient;
  final Color? rippleColor;
  final double? itemHeight;

  const MultiLevelDrawer(
      {required this.header,
      required this.children,
      this.backgroundColor = Colors.white,
      this.gradient,
      this.divisionColor = Colors.grey,
      this.rippleColor = Colors.grey,
      this.subMenuBackgroundColor = Colors.white,
      this.itemHeight = 70});

  @override
  _MultiLevelDrawerState createState() => _MultiLevelDrawerState();
}

class _MultiLevelDrawerState extends State<MultiLevelDrawer> {
  ScrollController scrollController = ScrollController();
  GlobalKey globalKey = GlobalKey();
  List<double> positions = [];
  List<MLMenuItem> drawerItems = [];
  double itemHeight = 0;

  int selectedPosition = -1, lastPosition = 0;
  bool openSubMenu = false;

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
    double dy = renderBox.localToGlobal(Offset.zero).dy;
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
    Size size = MediaQuery.of(context).size;
    bool drawUp = false;
    double boxHeight = 0.0;
    if(selectedPosition != -1){
      boxHeight = itemHeight * drawerItems[selectedPosition].subMenuItems!.length;
      drawUp = size.height - positions[selectedPosition] < boxHeight;
    }
    return Container(
      width: size.width,
      child: Stack(
        children: <Widget>[
          if (selectedPosition != -1 && drawerItems[selectedPosition].subMenuItems != null) ...[
            AnimatedPositioned(
                duration: Duration(milliseconds: 200),
                left: selectedPosition == -1 ? 0 : size.width / 2,
                top: selectedPosition != -1 ? (positions[selectedPosition] - (drawUp?(boxHeight - itemHeight):0)) : positions[lastPosition],
                child: Stack(
                  children: <Widget>[
                    Container(
                      width: size.width / 2,
                      height: itemHeight * drawerItems[selectedPosition].subMenuItems!.length,
                    ),
                    Positioned(
                      top: 0,
                      left: 10,
                      child: Container(
                        width: size.width / 2 - 10,
                        child: Column(
                          children: drawerItems[selectedPosition].subMenuItems!.map<Widget>((subMenuItem) {
                            return _MLChoiceItem(
                              height:itemHeight,
                              color: widget.subMenuBackgroundColor,
                              divisionColor: widget.divisionColor,
                              rippleColor: widget.rippleColor,
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
                        top: drawUp?(boxHeight-itemHeight):0,
                        left: 0,
                        child: CustomPaint(
                          size: Size(10, itemHeight),
                          painter: _ArrowPainter(arrowColor: widget.subMenuBackgroundColor),
                        ))
                  ],
                )),
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
                      height: drawerItems.length * 70,
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
  final double? width,height;

  const _MLChoiceItem(
      {required this.onTap, required this.child, this.leading, this.trailing, this.color = Colors.white, this.rippleColor = Colors.grey, this.divisionColor = Colors.grey, this.width = 0.0,this.height = 0.0});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      child: InkWell(
        highlightColor: rippleColor,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: divisionColor!, width: 1.0))),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              if (leading != null) ...[
                Container(
                  child: leading,
                ),
              ],
              Expanded(child: child),
              if (trailing != null) ...[
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

  _ArrowPainter({this.arrowColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = arrowColor!.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    Path path = Path();
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
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
  final Function onClick;

  MLSubmenu({required this.submenuContent, required this.onClick});
}
