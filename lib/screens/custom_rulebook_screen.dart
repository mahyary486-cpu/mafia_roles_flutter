import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../logic/custom_rulebook_store.dart';
import '../models/custom_rulebook.dart';
import '../widgets/app_background.dart';
import '../widgets/banner_app_bar_background.dart';
import '../widgets/tr_text.dart';

/// A library of the game master's own written rulebooks, each with a
/// long free-form rules description and a simple configurable win
/// condition (default: 3 sides - Citizen, Mafia, Independent). Lets most
/// social-deduction / strategy games be personalized: write the rules
/// once, save it forever, and define exactly how a game like this ends.
class CustomRulebookScreen extends StatefulWidget {
  const CustomRulebookScreen({super.key});

  @override
  State<CustomRulebookScreen> createState() => _CustomRulebookScreenState();
}

class _CustomRulebookScreenState extends State<CustomRulebookScreen> {
  List<CustomRulebook> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final books = await CustomRulebookStore.loadAll();
    if (mounted) setState(() { _books = books; _loading = false; });
  }

  Future<void> _openEditor([CustomRulebook? existing]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _RulebookEditorScreen(existing: existing)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(CustomRulebook book) async {
    await CustomRulebookStore.remove(book.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: const BannerAppBarBackground(),
          title: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Custom Rulebooks'), Text(' / رول‌بوک‌های سفارشی')]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add),
          label: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('New'), Text(' / جدید')]),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _books.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No custom rulebooks yet - tap "New" to write your '
                          'own rules and win condition.\n'
                          'هنوز رول‌بوک سفارشی‌ای نساخته‌اید - برای نوشتن '
                          'قوانین و شرط برد خودتان «جدید» را بزنید.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(book.title,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: book.winRule != null
                                ? Text(
                                    book.winRule!.describeEn(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                            onTap: () => _openEditor(book),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _delete(book),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _RulebookEditorScreen extends StatefulWidget {
  final CustomRulebook? existing;

  const _RulebookEditorScreen({this.existing});

  @override
  State<_RulebookEditorScreen> createState() => _RulebookEditorScreenState();
}

class _RulebookEditorScreenState extends State<_RulebookEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _sideAController;
  late final TextEditingController _sideBController;
  late final TextEditingController _sideCController;
  late final TextEditingController _sideCCountController;
  late final TextEditingController _winnerController;
  bool _includeWinRule = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _bodyController = TextEditingController(text: existing?.bodyText ?? '');
    final rule = existing?.winRule;
    _includeWinRule = rule != null;
    // 3 sides by default, as requested - editable.
    _sideAController = TextEditingController(text: rule?.sideA ?? 'Citizen');
    _sideBController = TextEditingController(text: rule?.sideB ?? 'Mafia');
    _sideCController = TextEditingController(text: rule?.sideC ?? 'Independent');
    _sideCCountController = TextEditingController(text: '${rule?.sideCCount ?? 0}');
    _winnerController = TextEditingController(text: rule?.winner ?? 'Mafia');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _sideAController.dispose();
    _sideBController.dispose();
    _sideCController.dispose();
    _sideCCountController.dispose();
    _winnerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final id = widget.existing?.id ?? 'rulebook_${DateTime.now().microsecondsSinceEpoch}';
    final winRule = _includeWinRule
        ? CustomWinRule(
            sideA: _sideAController.text.trim(),
            sideB: _sideBController.text.trim(),
            sideC: _sideCController.text.trim(),
            sideCCount: int.tryParse(_sideCCountController.text.trim()) ?? 0,
            winner: _winnerController.text.trim(),
          )
        : null;
    await CustomRulebookStore.save(
      CustomRulebook(
        id: id,
        title: title,
        bodyText: _bodyController.text.trim(),
        winRule: winRule,
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Edit Rulebook'), Text(' / ویرایش رول‌بوک')]),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save / ذخیره',
              onPressed: _save,
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Rulebook name / اسم رول‌بوک',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rules / قوانین',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _bodyController,
                maxLines: 12,
                minLines: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write out your full rules here - as long as '
                      'you need. / قوانین کامل خودتان را اینجا بنویسید - '
                      'هر چقدر لازم است.',
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Custom win condition / شرط برد سفارشی',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: _includeWinRule,
                onChanged: (v) => setState(() => _includeWinRule = v),
              ),
              if (_includeWinRule) ...[
                const Text(
                  'When these two sides are equal in count...\n'
                  'وقتی این دو طرف در تعداد برابر باشند...',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _sideAController,
                        decoration: const InputDecoration(labelText: 'Side A'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('='),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _sideBController,
                        decoration: const InputDecoration(labelText: 'Side B'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '...and this side is at exactly this count...\n'
                  '...و این طرف دقیقاً این تعداد باشد...',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _sideCController,
                        decoration: const InputDecoration(labelText: 'Side C'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _sideCCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Count'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '...then this side wins. / ...آنگاه این طرف برنده می‌شود.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _winnerController,
                  decoration: const InputDecoration(labelText: 'Winner'),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Save Rulebook'), Text(' / ذخیره رول‌بوک')]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
