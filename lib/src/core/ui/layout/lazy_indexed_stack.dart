import 'package:flutter/material.dart';

/// مكدس صفحات كسول وعالي الكفاءة (Lazy Indexed Stack).
/// يبني التبويب فقط عند أول زيارة له، ثم يحتفظ بحالته حية في الشجرة
/// دون إعادة تحميل باردة، مما يضمن التبديل اللحظي (0ms) بين الصفحات.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget Function(BuildContext)> itemBuilders;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit sizing;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.itemBuilders,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.sizing = StackFit.loose,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  final Set<int> _activatedIndices = <int>{};

  @override
  void initState() {
    super.initState();
    _activatedIndices.add(widget.index);
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _activatedIndices.add(widget.index);
    if (oldWidget.itemBuilders.length != widget.itemBuilders.length) {
      _activatedIndices.retainAll(
        List.generate(widget.itemBuilders.length, (i) => i),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _activatedIndices.add(widget.index);

    final children = List<Widget>.generate(
      widget.itemBuilders.length,
      (i) => _activatedIndices.contains(i)
          ? widget.itemBuilders[i](context)
          : const SizedBox.shrink(),
    );

    return IndexedStack(
      index: widget.index,
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      sizing: widget.sizing,
      children: children,
    );
  }
}
