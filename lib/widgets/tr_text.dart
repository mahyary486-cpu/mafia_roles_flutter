import 'package:flutter/material.dart';

import '../logic/locale_service.dart';

/// A `Text` that automatically translates [english] into whichever
/// language the game master picked with [LanguagePickerButton], using
/// [LocaleService.translate]. Shows the original English immediately
/// (no blank/loading flash), then swaps in the translation once it
/// arrives. Falls back silently to English if there's no internet.
///
/// This is what makes it practical to wire up the *whole* app (rulebook
/// included) without hand-writing a translation for every single phrase
/// - drop this in anywhere a plain `Text(englishString)` was used.
class TrText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TrText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<TrText> createState() => _TrTextState();
}

class _TrTextState extends State<TrText> {
  String _shown = '';
  String? _lastRequestedFor;

  @override
  void initState() {
    super.initState();
    _shown = widget.text;
    LocaleService.instance.languageCode.addListener(_onLanguageChanged);
    _onLanguageChanged();
  }

  @override
  void didUpdateWidget(covariant TrText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _shown = widget.text;
      _onLanguageChanged();
    }
  }

  @override
  void dispose() {
    LocaleService.instance.languageCode.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() async {
    final lang = LocaleService.instance.languageCode.value;
    final requestKey = '$lang::${widget.text}';
    if (lang == 'en') {
      if (mounted) setState(() => _shown = widget.text);
      return;
    }
    _lastRequestedFor = requestKey;
    final result = await LocaleService.instance.translate(widget.text);
    // Ignore stale results from a language/text change that happened
    // while this request was in flight.
    if (!mounted || _lastRequestedFor != requestKey) return;
    setState(() => _shown = result);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _shown,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
