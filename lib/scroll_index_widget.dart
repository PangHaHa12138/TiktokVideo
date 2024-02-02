import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef ViewPortCallback = void Function(int firstIndex, int lastIndex);

class ScrollIndexWidget extends StatelessWidget {
  final ScrollView child;
  final ViewPortCallback callback;

  const ScrollIndexWidget(
      {Key? key, required this.child, required this.callback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationListener(child: child, onNotification: _onNotification);
  }

  bool _onNotification(ScrollNotification notice) {
    final SliverMultiBoxAdaptorElement sliverMultiBoxAdaptorElement =
    findSliverMultiBoxAdaptorElement(notice.context! as Element)!;

    final viewportDimension = notice.metrics.viewportDimension;

    int firstIndex = 0;
    int lastIndex = 0;
    void onVisitChildren(Element element) {
      final SliverMultiBoxAdaptorParentData oldParentData =
      element.renderObject?.parentData as SliverMultiBoxAdaptorParentData;
      double layoutOffset = oldParentData.layoutOffset!;
      double pixels = notice.metrics.pixels;
      double all = pixels + viewportDimension;
      if (layoutOffset >= pixels) {
        ///first和last是不同item
        firstIndex = min(firstIndex, oldParentData.index! - 1);
        if (layoutOffset <= all) {
          lastIndex = max(lastIndex, oldParentData.index!);
        }
        firstIndex = max(firstIndex, 0);
      } else {
        ///first和last是同一个item
        lastIndex = firstIndex = oldParentData.index!;
      }
    }

    sliverMultiBoxAdaptorElement.visitChildren(onVisitChildren);

    callback(
      firstIndex,
      lastIndex,
    );

    return false;
  }

  SliverMultiBoxAdaptorElement? findSliverMultiBoxAdaptorElement(
      Element element) {
    if (element is SliverMultiBoxAdaptorElement) {
      return element;
    }
    SliverMultiBoxAdaptorElement? target;
    element.visitChildElements((child) {
      target = findSliverMultiBoxAdaptorElement(child);
    });
    return target;
  }
}