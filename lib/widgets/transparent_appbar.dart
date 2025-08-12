import 'package:flutter/material.dart';
import 'package:street_buddy/widgets/buttons/custom_leading_button.dart';

PreferredSizeWidget TransparentAppbar(
    {required BuildContext context, String? title}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    leadingWidth: 75,
    leading: const CustomLeadingButton(),
    title: Text(title ?? ''),
  );
}
