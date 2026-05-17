import 'package:flutter/material.dart';
import '../config/theme.dart';

Future<bool> showDeleteConfirm(BuildContext context, {String item = '该记录'}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('确认删除'),
      content: Text('确定要删除$item吗？\n此操作不可恢复。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('确认删除'),
        ),
      ],
    ),
  );
  return ok == true;
}
