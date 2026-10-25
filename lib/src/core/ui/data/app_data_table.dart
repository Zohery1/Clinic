import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../feedback/app_empty_state.dart';
import '../feedback/app_skeleton.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

enum AppDataTableAlign { start, center, end }

class AppDataTableColumn {
  final String key;
  final String label;
  final AppDataTableAlign align;
  final double? width;
  final String? format;
  final bool sortable;

  const AppDataTableColumn({
    required this.key,
    required this.label,
    this.align = AppDataTableAlign.start,
    this.width,
    this.format,
    this.sortable = true,
  });
}

class AppDataTable extends StatefulWidget {
  final List<AppDataTableColumn> columns;
  final List<Map<String, dynamic>> rows;
  final void Function(Map<String, dynamic> row)? onRowTap;
  final bool isLoading;
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final IconData emptyIcon;
  final bool sortable;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.isLoading = false,
    this.emptyMessage = 'لا توجد بيانات متاحة حالياً',
    this.emptyActionLabel,
    this.onEmptyAction,
    this.emptyIcon = Icons.inbox_rounded,
    this.sortable = true,
  });

  @override
  State<AppDataTable> createState() => _AppDataTableState();
}

class _AppDataTableState extends State<AppDataTable> {
  int? _sortColIndex;
  bool _sortAsc = false;

  List<Map<String, dynamic>> get _sorted {
    if (_sortColIndex == null || !widget.sortable) return widget.rows;
    final col = widget.columns[_sortColIndex!];
    final list = [...widget.rows];
    list.sort((a, b) {
      final av = a[col.key];
      final bv = b[col.key];
      if (av is num && bv is num) {
        return _sortAsc ? av.compareTo(bv) : bv.compareTo(av);
      }
      final as_ = av?.toString() ?? '';
      final bs_ = bv?.toString() ?? '';
      return _sortAsc ? as_.compareTo(bs_) : bs_.compareTo(as_);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildLoading(context);
    if (widget.rows.isEmpty) return _buildEmpty(context);

    final border = AppColors.borderSubtle(context);
    final headerBg = AppColors.subtle(context);
    final hoverBg = AppColors.subtle(context).withValues(alpha: 0.5);

    final columns = widget.columns;
    final rows = _sorted;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.brMd,
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.radiusMd),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            child: Row(
              children: [
                for (var i = 0; i < columns.length; i++)
                  columns[i].width != null
                      ? SizedBox(
                          width: columns[i].width,
                          child: _HeaderCell(
                            column: columns[i],
                            isActive: _sortColIndex == i,
                            isAsc: _sortAsc,
                            onTap: widget.sortable
                                ? () => setState(() {
                                      if (_sortColIndex == i) {
                                        _sortAsc = !_sortAsc;
                                      } else {
                                        _sortColIndex = i;
                                        _sortAsc = true;
                                      }
                                    })
                                : null,
                          ),
                        )
                      : Expanded(
                          child: _HeaderCell(
                            column: columns[i],
                            isActive: _sortColIndex == i,
                            isAsc: _sortAsc,
                            onTap: widget.sortable
                                ? () => setState(() {
                                      if (_sortColIndex == i) {
                                        _sortAsc = !_sortAsc;
                                      } else {
                                        _sortColIndex = i;
                                        _sortAsc = true;
                                      }
                                    })
                                : null,
                          ),
                        ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: border),
          for (var i = 0; i < rows.length; i++) ...[
            _Row(
              columns: columns,
              row: rows[i],
              hoverBg: hoverBg,
              onTap: widget.onRowTap == null
                  ? null
                  : () => widget.onRowTap!(rows[i]),
            ),
            if (i < rows.length - 1)
              Divider(height: 1, thickness: 1, color: border),
          ],
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final border = AppColors.borderSubtle(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.brMd,
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  for (final col in widget.columns)
                    col.width != null
                        ? SizedBox(
                            width: col.width,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: AppSkeleton(
                                height: 14,
                                radius: AppRadii.radiusXs,
                                width: col.width ?? double.infinity,
                              ),
                            ),
                          )
                        : const Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: AppSkeleton(height: 14, radius: AppRadii.radiusXs),
                            ),
                          ),
                ],
              ),
            ),
            if (i < 4) Divider(height: 1, thickness: 1, color: border),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.brMd,
        border: Border.all(color: AppColors.borderSubtle(context), width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
      child: AppEmptyState(
        icon: widget.emptyIcon,
        title: widget.emptyMessage,
        actionLabel: widget.emptyActionLabel,
        onAction: widget.onEmptyAction,
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final AppDataTableColumn column;
  final bool isActive;
  final bool isAsc;
  final VoidCallback? onTap;

  const _HeaderCell({
    required this.column,
    required this.isActive,
    required this.isAsc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      column.label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: switch (column.align) {
        AppDataTableAlign.center => TextAlign.center,
        AppDataTableAlign.end => TextAlign.end,
        _ => TextAlign.start,
      },
      style: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: AppColors.textMuted(context),
        height: 1.3,
      ),
    );

    final content = onTap == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: _resolveMainAxis(column.align),
            children: [
              Flexible(child: text),
              if (column.sortable) ...[
                const SizedBox(width: 4),
                Icon(
                  isActive
                      ? (isAsc
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded)
                      : Icons.unfold_more_rounded,
                  size: 12,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textMuted(context),
                ),
              ],
            ],
          );

    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          child: SizedBox(
            width: column.width,
            child: content,
          ),
        ),
      ),
    );
  }

  MainAxisAlignment _resolveMainAxis(AppDataTableAlign align) {
    switch (align) {
      case AppDataTableAlign.center:
        return MainAxisAlignment.center;
      case AppDataTableAlign.end:
        return MainAxisAlignment.end;
      case AppDataTableAlign.start:
        return MainAxisAlignment.start;
    }
  }
}

class _Row extends StatefulWidget {
  final List<AppDataTableColumn> columns;
  final Map<String, dynamic> row;
  final Color hoverBg;
  final VoidCallback? onTap;

  const _Row({
    required this.columns,
    required this.row,
    required this.hoverBg,
    required this.onTap,
  });

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered ? widget.hoverBg : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.md,
          ),
          child: Row(
            children: [
              for (final col in widget.columns)
                col.width != null
                    ? SizedBox(
                        width: col.width,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _BodyCell(column: col, value: row[col.key]),
                        ),
                      )
                    : Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _BodyCell(column: col, value: row[col.key]),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final AppDataTableColumn column;
  final dynamic value;

  const _BodyCell({required this.column, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = _formatValue(value, column.format);
    final isMono = column.format == 'currency' || column.format == 'number';

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: switch (column.align) {
        AppDataTableAlign.center => TextAlign.center,
        AppDataTableAlign.end => TextAlign.end,
        _ => TextAlign.start,
      },
      style: isMono
          ? GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: column.format == 'currency'
                  ? AppColors.primary
                  : AppColors.textPrimary(context),
              height: 1.3,
            )
          : GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
              height: 1.3,
            ),
    );
  }

  String _formatValue(dynamic v, String? format) {
    if (v == null) return '';
    switch (format) {
      case 'currency':
        final n = (v as num).toDouble();
        return '${n.toStringAsFixed(0)} ج.م';
      case 'number':
        final n = v as num;
        if (n is double && n == n.truncateToDouble()) {
          return n.toInt().toString();
        }
        return n.toString();
      case 'date':
      default:
        return v.toString();
    }
  }
}
