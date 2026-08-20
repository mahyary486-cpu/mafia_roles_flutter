import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/role_data.dart';
import '../logic/custom_roles_store.dart';
import '../logic/game_state.dart';
import '../models/role.dart';
import '../models/role_type.dart';
import '../models/team.dart';
import '../widgets/app_background.dart';
import '../widgets/custom_role_dialog.dart';
import '../widgets/edit_role_dialog.dart';
import '../widgets/role_emoji_badge.dart';
import '../widgets/tr_text.dart';
import 'game_screen.dart';

/// Lets the game master hand-pick which named roles are in play for each
/// side, plus write any custom roles. Custom roles are saved on the
/// device (see [CustomRolesStore]) so they show up as reusable, checkable
/// options in every future game too - just like the built-in roles. Any
/// slots left over after their picks are automatically filled with the
/// plain role for that team (plain Citizen / plain Mafia).
///
/// Mafia / Citizen / Independent are shown as swipeable tabs (rather than
/// one long stacked scroll) since the role list has grown quite large, and
/// each tab has its own search box to jump straight to a role by name.
class RoleSelectionScreen extends StatefulWidget {
  final int totalPlayers;
  final int mafiaCount;
  final int citizenCount;
  final int independentCount;
  final GameState gameState;

  const RoleSelectionScreen({
    super.key,
    required this.totalPlayers,
    required this.mafiaCount,
    required this.citizenCount,
    required this.independentCount,
    required this.gameState,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _selectedIds = {};
  List<Role> _savedCustomRoles = [];
  bool _loadingCustomRoles = true;
  late final TabController _tabController;
  String _searchQuery = '';

  bool get _hasIndependent => widget.independentCount > 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.mafiaCount > 0) {
      _selectedIds.add(RoleType.godfather.name); // on by default
    }
    _loadCustomRoles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomRoles() async {
    final saved = await CustomRolesStore.loadAll();
    if (!mounted) return;
    setState(() {
      _savedCustomRoles = saved;
      _loadingCustomRoles = false;
    });
  }

  List<Role> _rolesFor(Team team) => [
        ...RoleData.forTeam(team).where(
          (r) => r.type != RoleType.mafia && r.type != RoleType.citizen,
        ),
        ..._savedCustomRoles.where((r) => r.team == team),
      ];

  List<Role> _filteredRolesFor(Team team) {
    final all = _rolesFor(team);
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where((r) =>
            r.name.toLowerCase().contains(q) || r.nameFa.contains(_searchQuery))
        .toList();
  }

  int _pickedFor(Team team) =>
      _rolesFor(team).where((r) => _selectedIds.contains(r.id)).length;

  int get _mafiaPicked => _pickedFor(Team.mafia);
  int get _citizenPicked => _pickedFor(Team.citizen);
  int get _independentPicked => _pickedFor(Team.independent);

  Future<void> _addCustomRole() async {
    final role = await showCustomRoleDialog(context);
    if (role == null) return;
    await CustomRolesStore.add(role);
    if (!mounted) return;
    setState(() {
      _savedCustomRoles.add(role);
      _selectedIds.add(role.id); // include it in this game right away
    });
  }

  Future<void> _deleteCustomRole(Role role) async {
    await CustomRolesStore.remove(role.id);
    if (!mounted) return;
    setState(() {
      _savedCustomRoles.removeWhere((r) => r.id == role.id);
      _selectedIds.remove(role.id);
    });
  }

  Future<void> _editBuiltInRole(Role role) async {
    final saved = await showEditRoleDialog(context, role);
    if (saved && mounted) setState(() {}); // re-read through RoleData
  }

  void _onStart() {
    final pool = <Role>[];

    void fillTeam(Team team, int slots, RoleType plainType) {
      final picked =
          _rolesFor(team).where((r) => _selectedIds.contains(r.id)).toList();
      pool.addAll(picked);
      final filler = slots - picked.length;
      if (filler > 0) {
        pool.addAll(List.filled(filler, RoleData.of(plainType)));
      }
    }

    fillTeam(Team.mafia, widget.mafiaCount, RoleType.mafia);
    fillTeam(Team.citizen, widget.citizenCount, RoleType.citizen);
    pool.addAll(
      _rolesFor(Team.independent).where((r) => _selectedIds.contains(r.id)),
    );

    widget.gameState.startGame(pool);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(gameState: widget.gameState),
      ),
    );
  }

  bool get _canStart =>
      _mafiaPicked <= widget.mafiaCount &&
      _citizenPicked <= widget.citizenCount &&
      _independentPicked <= widget.independentCount;

  Widget _tab(Team team, int picked, int slots, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _TeamSection(
        color: color,
        picked: picked,
        slots: slots,
        roles: _filteredRolesFor(team),
        selectedIds: _selectedIds,
        onToggle: (id, value) => setState(() {
          value ? _selectedIds.add(id) : _selectedIds.remove(id);
        }),
        onDeleteCustom: _deleteCustomRole,
        onEditBuiltIn: _editBuiltInRole,
        canPickMore: picked < slots,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: TrText('Select Roles (${widget.totalPlayers})'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Text(
                  'Mafia ($_mafiaPicked/${widget.mafiaCount})',
                  style: const TextStyle(color: AppColors.mafiaTeam),
                ),
              ),
              Tab(
                child: Text(
                  'Citizen ($_citizenPicked/${widget.citizenCount})',
                  style: const TextStyle(color: AppColors.citizenTeam),
                ),
              ),
              Tab(
                child: Text(
                  'Independent ($_independentPicked/${widget.independentCount})',
                  style: const TextStyle(color: AppColors.independentTeam),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: _loadingCustomRoles
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search role',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _tab(Team.mafia, _mafiaPicked, widget.mafiaCount,
                              AppColors.mafiaTeam),
                          _tab(Team.citizen, _citizenPicked, widget.citizenCount,
                              AppColors.citizenTeam),
                          _hasIndependent
                              ? _tab(Team.independent, _independentPicked,
                                  widget.independentCount, AppColors.independentTeam)
                              : const _NoIndependentSlotsMessage(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textGold,
                                side: const BorderSide(color: AppColors.textGold, width: 2),
                                backgroundColor: AppColors.textGold.withOpacity(0.08),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _addCustomRole,
                              icon: const Icon(Icons.add_circle, size: 22),
                              label: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Add Custom Role')]),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _canStart ? _onStart : null,
                              style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                              child: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Start Game', style: TextStyle(fontSize: 14))]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _NoIndependentSlotsMessage extends StatelessWidget {
  const _NoIndependentSlotsMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: AppColors.textSecondary, size: 32),
            SizedBox(height: 12),
            Text(
              'To pick an independent role, go back and set an independent '
              'count on the previous screen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

void _showRoleInfo(BuildContext context, Role role) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: TrText(role.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TrText(role.description),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const TrText('Close'),
        ),
      ],
    ),
  );
}

class _TeamSection extends StatelessWidget {
  final Color color;
  final int picked;
  final int slots;
  final List<Role> roles;
  final Set<String> selectedIds;
  final void Function(String id, bool value) onToggle;
  final void Function(Role role) onDeleteCustom;
  final void Function(Role role) onEditBuiltIn;
  final bool canPickMore;

  const _TeamSection({
    required this.color,
    required this.picked,
    required this.slots,
    required this.roles,
    required this.selectedIds,
    required this.onToggle,
    required this.onDeleteCustom,
    required this.onEditBuiltIn,
    required this.canPickMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (roles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No roles match',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ...roles.map((role) {
            final isSelected = selectedIds.contains(role.id);
            final enabled = isSelected || canPickMore;
            final isCustom = role.type == RoleType.custom;
            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: role.color,
              value: isSelected,
              onChanged: enabled
                  ? (value) => onToggle(role.id, value ?? false)
                  : null,
              title: Row(
                children: [
                  RoleEmojiBadge(emoji: role.emoji, color: role.color, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCustom
                          ? '${role.name} (Custom)'
                          : '${role.name} / ${role.nameFa}',
                      style: TextStyle(color: role.color),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: () => _showRoleInfo(context, role),
                  ),
                  if (isCustom)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: AppColors.mafiaTeam,
                      tooltip: 'Delete permanently',
                      onPressed: () => onDeleteCustom(role),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: AppColors.textSecondary,
                      tooltip: 'Edit name/ability',
                      onPressed: () => onEditBuiltIn(role),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
