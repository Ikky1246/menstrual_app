import 'package:flutter/material.dart';

enum ButtonType {
  primary,
  secondary,
  outline,
  danger,
  success,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? customColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (type) {
      case ButtonType.primary:
        return _buildPrimaryButton();
      case ButtonType.secondary:
        return _buildSecondaryButton();
      case ButtonType.outline:
        return _buildOutlineButton();
      case ButtonType.danger:
        return _buildDangerButton();
      case ButtonType.success:
        return _buildSuccessButton();
    }
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: customColor ?? Colors.pink,
        foregroundColor: Colors.white,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        minimumSize: _getMinimumSize(),
      ),
      child: _buildChild(),
    );
  }

  Widget _buildSecondaryButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink.shade50,
        foregroundColor: Colors.pink,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        minimumSize: _getMinimumSize(),
      ),
      child: _buildChild(),
    );
  }

  Widget _buildOutlineButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: customColor ?? Colors.pink,
        side: BorderSide(color: customColor ?? Colors.pink, width: 2),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        minimumSize: _getMinimumSize(),
      ),
      child: _buildChild(),
    );
  }

  Widget _buildDangerButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        minimumSize: _getMinimumSize(),
      ),
      child: _buildChild(),
    );
  }

  Widget _buildSuccessButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        minimumSize: _getMinimumSize(),
      ),
      child: _buildChild(),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == ButtonType.outline ? Colors.pink : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: _getFontSize(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: _getFontSize(),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  Size _getMinimumSize() {
    switch (size) {
      case ButtonSize.small:
        return const Size(100, 36);
      case ButtonSize.medium:
        return const Size(120, 45);
      case ButtonSize.large:
        return const Size(140, 55);
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }
}

// Custom FAB Button
class CustomFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final String? tooltip;

  const CustomFloatingButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? Colors.pink,
      tooltip: tooltip,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

// Custom Icon Button
class CustomIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? color;
  final double size;
  final String? tooltip;

  const CustomIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.size = 24,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color ?? Colors.pink, size: size),
      tooltip: tooltip,
    );
  }
}

// Custom Text Button
class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;

  const CustomTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.pink,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}