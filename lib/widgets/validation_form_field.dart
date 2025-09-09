import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/validation_utils.dart';

/// A reusable form field with built-in validation
class ValidationFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String labelText;
  final String? hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLength;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? helperText;
  final AutovalidateMode autovalidateMode;

  const ValidationFormField({
    super.key,
    this.controller,
    this.initialValue,
    required this.labelText,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 1,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.prefixIcon,
    this.suffixIcon,
    this.helperText,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  State<ValidationFormField> createState() => _ValidationFormFieldState();
}

class _ValidationFormFieldState extends State<ValidationFormField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      inputFormatters: widget.inputFormatters,
      autovalidateMode: widget.autovalidateMode,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        counterText: '', // Hide character counter
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
    );
  }
}

/// Pre-configured validation form fields for common use cases
class EmailFormField extends ValidationFormField {
  EmailFormField({
    super.key,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onSaved,
    super.enabled = true,
  }) : super(
          labelText: 'Email',
          hintText: 'Enter your email address',
          keyboardType: TextInputType.emailAddress,
          validator: ValidationUtils.validateEmail,
        );
}

class PasswordFormField extends ValidationFormField {
  PasswordFormField({
    super.key,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onSaved,
    super.enabled = true,
  }) : super(
          labelText: 'Password',
          hintText: 'Enter your password',
          obscureText: true,
          validator: ValidationUtils.validatePassword,
        );
}

class ConfirmPasswordFormField extends ValidationFormField {
  final String? originalPassword;

  ConfirmPasswordFormField({
    super.key,
    super.controller,
    super.onChanged,
    super.onSaved,
    super.enabled = true,
    this.originalPassword,
  }) : super(
          labelText: 'Confirm Password',
          hintText: 'Re-enter your password',
          obscureText: true,
          validator: (value) => ValidationUtils.validatePasswordConfirmation(
              value, originalPassword),
        );
}

class NameFormField extends ValidationFormField {
  final String fieldName;

  NameFormField({
    super.key,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onSaved,
    super.enabled = true,
    required this.fieldName,
  }) : super(
          labelText: fieldName,
          hintText: 'Enter $fieldName',
          validator: (value) => ValidationUtils.validateName(value, fieldName),
        );
}

class PhoneFormField extends ValidationFormField {
  PhoneFormField({
    super.key,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onSaved,
    super.enabled = true,
  }) : super(
          labelText: 'Phone Number',
          hintText: '(555) 123-4567',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: ValidationUtils.validatePhone,
        );
}

class ZipCodeFormField extends ValidationFormField {
  ZipCodeFormField({
    super.key,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onSaved,
    super.enabled = true,
  }) : super(
          labelText: 'ZIP Code',
          hintText: '12345',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: ValidationUtils.validateZipCode,
        );
}

