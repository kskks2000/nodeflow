import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/nodeflow_theme.dart';
import '../../auth/domain/auth_models.dart';
import '../data/admin_api_client.dart';
import '../domain/admin_models.dart';

enum _AdminSection {
  dashboard,
  codes,
  masters,
  rules,
  security,
  imports,
  audit,
  settings,
}

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  final _apiClient = AdminApiClient();
  final _searchController = TextEditingController();

  LoginResponse? _session;
  bool _didReadArguments = false;
  bool _isLoading = true;
  bool _activeOnly = false;
  String? _errorMessage;
  _AdminSection _section = _AdminSection.dashboard;
  String? _selectedEntityKey;
  List<AdminEntityDefinition> _entities = const [];
  AdminOverview? _overview;
  AdminRecordListResponse? _records;
  AdminAuditLogListResponse? _auditLogs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArguments) {
      return;
    }
    _didReadArguments = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is LoginResponse) {
      _session = arguments;
      _loadInitial();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = '로그인 세션이 없습니다.';
      });
    }
  }

  @override
  void dispose() {
    _apiClient.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final session = _session;
    if (session == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final entities = await _apiClient.fetchEntities(
        accessToken: session.accessToken,
      );
      final overview = await _apiClient.fetchOverview(
        accessToken: session.accessToken,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _entities = entities;
        _overview = overview;
        _selectedEntityKey = _defaultEntityForSection(_section);
        _isLoading = false;
      });
      await _loadCurrentContent();
    } on AdminFailure catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _loadCurrentContent() async {
    final session = _session;
    if (session == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_section == _AdminSection.dashboard) {
        final overview = await _apiClient.fetchOverview(
          accessToken: session.accessToken,
        );
        if (!mounted) {
          return;
        }
        setState(() => _overview = overview);
      } else if (_section == _AdminSection.audit) {
        final auditLogs = await _apiClient.fetchAuditLogs(
          accessToken: session.accessToken,
          search: _searchController.text,
        );
        if (!mounted) {
          return;
        }
        setState(() => _auditLogs = auditLogs);
      } else if (_selectedEntityKey != null) {
        final records = await _apiClient.fetchRecords(
          accessToken: session.accessToken,
          entityKey: _selectedEntityKey!,
          search: _searchController.text,
          activeOnly: _activeOnly,
        );
        if (!mounted) {
          return;
        }
        setState(() => _records = records);
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } on AdminFailure catch (error) {
      _showError(error.message);
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  void _selectSection(_AdminSection section) {
    setState(() {
      _section = section;
      _selectedEntityKey = _defaultEntityForSection(section);
      _records = null;
      _auditLogs = null;
      _searchController.clear();
    });
    _loadCurrentContent();
  }

  String? _defaultEntityForSection(_AdminSection section) {
    final group = _groupForSection(section);
    if (group == null) {
      return null;
    }
    final items = _entities.where((entity) => entity.group == group);
    if (items.isEmpty) {
      return null;
    }
    if (section == _AdminSection.codes) {
      return 'common_code_groups';
    }
    if (section == _AdminSection.settings) {
      return 'system_settings';
    }
    return items.first.key;
  }

  String? _groupForSection(_AdminSection section) {
    return switch (section) {
      _AdminSection.codes => 'codes',
      _AdminSection.masters => 'masters',
      _AdminSection.rules => 'rules',
      _AdminSection.security => 'security',
      _AdminSection.imports => 'masters',
      _AdminSection.settings => 'settings',
      _ => null,
    };
  }

  AdminEntityDefinition? get _selectedEntity {
    final key = _selectedEntityKey;
    if (key == null) {
      return null;
    }
    for (final entity in _entities) {
      if (entity.key == key) {
        return entity;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return Scaffold(
        backgroundColor: NodeFlowColors.cloud,
        body: Center(
          child: _EmptyState(
            icon: Icons.lock_rounded,
            title: '관리자 세션 없음',
            body: _errorMessage ?? '로그인 후 다시 접근해 주세요.',
            actionLabel: '로그인',
            onAction: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: NodeFlowColors.cloud,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1080;
            final shell = Column(
              children: [
                _AdminTopBar(
                  session: session,
                  isLoading: _isLoading,
                  onRefresh: _loadCurrentContent,
                  onBackToTms: () =>
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/main',
                        (route) => false,
                        arguments: session,
                      ),
                  onLogout: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false),
                ),
                Expanded(child: _buildBody(wide: wide)),
              ],
            );
            if (!wide) {
              return shell;
            }
            return Row(
              children: [
                _AdminSidebar(
                  section: _section,
                  session: session,
                  onSectionSelected: _selectSection,
                ),
                Expanded(child: shell),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 1080
          ? null
          : _MobileAdminNav(
              section: _section,
              onSectionSelected: _selectSection,
            ),
    );
  }

  Widget _buildBody({required bool wide}) {
    if (_errorMessage != null) {
      return Center(
        child: _EmptyState(
          icon: Icons.error_rounded,
          title: '요청 실패',
          body: _errorMessage!,
          actionLabel: '다시 시도',
          onAction: _loadCurrentContent,
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(wide ? 26 : 16, 18, wide ? 26 : 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageHeader(
            title: _sectionTitle(_section),
            subtitle: _sectionSubtitle(_section),
          ),
          const SizedBox(height: 16),
          if (_section == _AdminSection.dashboard)
            _OverviewView(overview: _overview, isLoading: _isLoading)
          else if (_section == _AdminSection.audit)
            _AuditLogView(
              logs: _auditLogs,
              searchController: _searchController,
              isLoading: _isLoading,
              onSearch: _loadCurrentContent,
            )
          else if (_section == _AdminSection.imports)
            _ImportView(
              entities: _entities
                  .where((entity) => entity.supportsImport)
                  .toList(),
              selectedEntityKey: _selectedEntityKey,
              onEntityChanged: (key) =>
                  setState(() => _selectedEntityKey = key),
              onImport: _importRows,
              isLoading: _isLoading,
            )
          else
            _EntityRecordsView(
              entities: _entities
                  .where((entity) => entity.group == _groupForSection(_section))
                  .toList(growable: false),
              selectedEntity: _selectedEntity,
              selectedEntityKey: _selectedEntityKey,
              records: _records,
              searchController: _searchController,
              activeOnly: _activeOnly,
              isLoading: _isLoading,
              onActiveOnlyChanged: (value) {
                setState(() => _activeOnly = value);
                _loadCurrentContent();
              },
              onEntityChanged: (key) {
                setState(() {
                  _selectedEntityKey = key;
                  _records = null;
                  _searchController.clear();
                });
                _loadCurrentContent();
              },
              onSearch: _loadCurrentContent,
              onCreate: _openCreateDialog,
              onEdit: _openEditDialog,
              onDelete: _confirmDelete,
              onExport: _exportCsv,
            ),
        ],
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final entity = _selectedEntity;
    final session = _session;
    if (entity == null || session == null) {
      return;
    }
    final referenceOptions = await _loadReferenceOptions(entity, session);
    if (!mounted) {
      return;
    }
    final data = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => _RecordEditorDialog(
        entity: entity,
        referenceOptions: referenceOptions,
      ),
    );
    if (data == null) {
      return;
    }
    try {
      await _apiClient.createRecord(
        accessToken: session.accessToken,
        entityKey: entity.key,
        data: data,
      );
      await _loadCurrentContent();
      _showSnack('${entity.label} 등록 완료');
    } on AdminFailure catch (error) {
      _showSnack(error.message, isError: true);
    }
  }

  Future<void> _openEditDialog(Map<String, Object?> row) async {
    final entity = _selectedEntity;
    final session = _session;
    if (entity == null || session == null) {
      return;
    }
    final id = _intValue(row[entity.idField]);
    if (id == null) {
      return;
    }
    final referenceOptions = await _loadReferenceOptions(entity, session);
    if (!mounted) {
      return;
    }
    final data = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => _RecordEditorDialog(
        entity: entity,
        initialData: row,
        referenceOptions: referenceOptions,
      ),
    );
    if (data == null) {
      return;
    }
    try {
      await _apiClient.updateRecord(
        accessToken: session.accessToken,
        entityKey: entity.key,
        recordId: id,
        data: data,
      );
      await _loadCurrentContent();
      _showSnack('${entity.label} 수정 완료');
    } on AdminFailure catch (error) {
      _showSnack(error.message, isError: true);
    }
  }

  Future<Map<String, List<_ReferenceOption>>> _loadReferenceOptions(
    AdminEntityDefinition entity,
    LoginResponse session,
  ) async {
    final optionEntityKeys = entity.formFields
        .map((field) => field.optionEntity)
        .whereType<String>()
        .toSet();
    if (optionEntityKeys.isEmpty) {
      return const {};
    }

    try {
      final entries = await Future.wait(
        optionEntityKeys.map((entityKey) async {
          final records = await _apiClient.fetchRecords(
            accessToken: session.accessToken,
            entityKey: entityKey,
            pageSize: 200,
            activeOnly: true,
          );
          final options = records.rows
              .map((row) => _ReferenceOption.fromRow(records.entity, row))
              .whereType<_ReferenceOption>()
              .toList(growable: false);
          return MapEntry(entityKey, options);
        }),
      );
      return Map<String, List<_ReferenceOption>>.fromEntries(entries);
    } on AdminFailure catch (error) {
      _showSnack(error.message, isError: true);
      return const {};
    }
  }

  Future<void> _confirmDelete(Map<String, Object?> row) async {
    final entity = _selectedEntity;
    final session = _session;
    if (entity == null || session == null) {
      return;
    }
    final id = _intValue(row[entity.idField]);
    if (id == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${entity.label} 비활성화'),
          content: Text('${row[entity.titleField] ?? id} 항목을 비활성화할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _apiClient.deleteRecord(
        accessToken: session.accessToken,
        entityKey: entity.key,
        recordId: id,
      );
      await _loadCurrentContent();
      _showSnack('${entity.label} 비활성화 완료');
    } on AdminFailure catch (error) {
      _showSnack(error.message, isError: true);
    }
  }

  Future<void> _exportCsv() async {
    final entity = _selectedEntity;
    final session = _session;
    if (entity == null || session == null) {
      return;
    }
    try {
      final csv = await _apiClient.exportCsv(
        accessToken: session.accessToken,
        entityKey: entity.key,
        search: _searchController.text,
        activeOnly: _activeOnly,
      );
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) =>
            _CsvExportDialog(title: '${entity.label}.csv', csv: csv),
      );
    } on AdminFailure catch (error) {
      _showSnack(error.message, isError: true);
    }
  }

  Future<void> _importRows(AdminEntityDefinition entity, String csvText) async {
    final session = _session;
    if (session == null) {
      return;
    }
    try {
      final rows = _parseCsv(csvText);
      final response = await _apiClient.importRows(
        accessToken: session.accessToken,
        entityKey: entity.key,
        fileName: '${entity.key}.csv',
        rows: rows,
      );
      await _loadCurrentContent();
      _showSnack(
        '업로드 ${response.successRows}/${response.totalRows}건 완료, 실패 ${response.failedRows}건',
        isError: response.failedRows > 0,
      );
    } on Object catch (error) {
      _showSnack(error.toString(), isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFB91C1C) : NodeFlowColors.ink,
        content: Text(message),
      ),
    );
  }

  String _sectionTitle(_AdminSection section) {
    return switch (section) {
      _AdminSection.dashboard => '관리자 대시보드',
      _AdminSection.codes => '공통코드',
      _AdminSection.masters => '마스터 데이터',
      _AdminSection.rules => '운영 규칙',
      _AdminSection.security => '사용자 및 권한',
      _AdminSection.imports => '일괄 업로드',
      _AdminSection.audit => '감사로그',
      _AdminSection.settings => '시스템 설정',
    };
  }

  String _sectionSubtitle(_AdminSection section) {
    return switch (section) {
      _AdminSection.dashboard => '운영 기준정보와 최근 변경 현황',
      _AdminSection.codes => '상태, 유형, 정책 코드 관리',
      _AdminSection.masters => '고객사, 운송사, 기사, 차량, 거점 관리',
      _AdminSection.rules => '계약, 요율, 서비스 기준 관리',
      _AdminSection.security => '계정, 역할, 권한 기준 관리',
      _AdminSection.imports => 'CSV 기반 기준정보 등록',
      _AdminSection.audit => '관리자 변경 이력 추적',
      _AdminSection.settings => '테넌트별 운영 기본값 관리',
    };
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.session,
    required this.isLoading,
    required this.onRefresh,
    required this.onBackToTms,
    required this.onLogout,
  });

  final LoginResponse session;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onBackToTms;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: NodeFlowColors.softSlate)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.admin_panel_settings_rounded,
            color: NodeFlowColors.deepBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${session.tenant.name} · ${session.user.name}',
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isLoading)
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          const SizedBox(width: 10),
          _IconAction(
            icon: Icons.refresh_rounded,
            tooltip: '새로고침',
            onPressed: onRefresh,
          ),
          const SizedBox(width: 8),
          _IconAction(
            icon: Icons.local_shipping_rounded,
            tooltip: 'TMS',
            onPressed: onBackToTms,
          ),
          const SizedBox(width: 8),
          _IconAction(
            icon: Icons.logout_rounded,
            tooltip: '로그아웃',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.section,
    required this.session,
    required this.onSectionSelected,
  });

  final _AdminSection section;
  final LoginResponse session;
  final ValueChanged<_AdminSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 276,
      color: const Color(0xFF172554),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandBlock(),
          const SizedBox(height: 22),
          _TenantBlock(session: session),
          const SizedBox(height: 24),
          const _SidebarLabel('ADMIN'),
          const SizedBox(height: 8),
          for (final item in _navItems)
            _SidebarItem(
              item: item,
              selected: section == item.section,
              onTap: () => onSectionSelected(item.section),
            ),
          const Spacer(),
          const _AdminHealthBlock(),
        ],
      ),
    );
  }
}

class _MobileAdminNav extends StatelessWidget {
  const _MobileAdminNav({
    required this.section,
    required this.onSectionSelected,
  });

  final _AdminSection section;
  final ValueChanged<_AdminSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _mobileItems.indexWhere(
      (item) => item.section == section,
    );
    return NavigationBar(
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) =>
          onSectionSelected(_mobileItems[index].section),
      destinations: [
        for (final item in _mobileItems)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
      ],
    );
  }
}

class _OverviewView extends StatelessWidget {
  const _OverviewView({required this.overview, required this.isLoading});

  final AdminOverview? overview;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final data = overview;
    if (data == null && isLoading) {
      return const _LoadingPanel();
    }
    if (data == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 5 : 2;
            return GridView.builder(
              itemCount: data.metrics.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 118,
              ),
              itemBuilder: (context, index) {
                return _MetricTile(metric: data.metrics[index]);
              },
            );
          },
        ),
        const SizedBox(height: 16),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PanelTitle(icon: Icons.history_rounded, title: '최근 변경'),
              const SizedBox(height: 12),
              if (data.recentActivity.isEmpty)
                const _MutedText('최근 변경 이력이 없습니다.')
              else
                for (final activity in data.recentActivity)
                  _ActivityRow(activity: activity),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PanelTitle(icon: Icons.dataset_rounded, title: '관리 대상'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final entity in data.masterEntities)
                    _EntityChip(label: entity.label, group: entity.group),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EntityRecordsView extends StatelessWidget {
  const _EntityRecordsView({
    required this.entities,
    required this.selectedEntity,
    required this.selectedEntityKey,
    required this.records,
    required this.searchController,
    required this.activeOnly,
    required this.isLoading,
    required this.onActiveOnlyChanged,
    required this.onEntityChanged,
    required this.onSearch,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
  });

  final List<AdminEntityDefinition> entities;
  final AdminEntityDefinition? selectedEntity;
  final String? selectedEntityKey;
  final AdminRecordListResponse? records;
  final TextEditingController searchController;
  final bool activeOnly;
  final bool isLoading;
  final ValueChanged<bool> onActiveOnlyChanged;
  final ValueChanged<String> onEntityChanged;
  final VoidCallback onSearch;
  final VoidCallback onCreate;
  final ValueChanged<Map<String, Object?>> onEdit;
  final ValueChanged<Map<String, Object?>> onDelete;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final entity = selectedEntity;
    if (entity == null) {
      return const _EmptyState(
        icon: Icons.inventory_2_rounded,
        title: '대상 없음',
        body: '관리 대상 메타데이터가 없습니다.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedEntityKey,
                  decoration: const InputDecoration(labelText: '관리 대상'),
                  items: [
                    for (final item in entities)
                      DropdownMenuItem(
                        value: item.key,
                        child: Text(item.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onEntityChanged(value);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: '검색',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              FilterChip(
                label: const Text('활성만'),
                selected: activeOnly,
                onSelected: onActiveOnlyChanged,
              ),
              _ToolbarButton(
                icon: Icons.search_rounded,
                label: '조회',
                onPressed: onSearch,
              ),
              _ToolbarButton(
                icon: Icons.download_rounded,
                label: '내보내기',
                onPressed: onExport,
              ),
              if (entity.supportsCreate)
                _ToolbarButton(
                  icon: Icons.add_rounded,
                  label: '등록',
                  filled: true,
                  onPressed: onCreate,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _PanelTitle(
                  icon: Icons.table_chart_rounded,
                  title: '${entity.label} ${records?.total ?? 0}건',
                  trailing: entity.description,
                ),
              ),
              const SizedBox(height: 8),
              if (isLoading && records == null)
                const _LoadingPanel()
              else
                _AdminDataTable(
                  entity: entity,
                  rows: records?.rows ?? const [],
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminDataTable extends StatelessWidget {
  const _AdminDataTable({
    required this.entity,
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminEntityDefinition entity;
  final List<Map<String, Object?>> rows;
  final ValueChanged<Map<String, Object?>> onEdit;
  final ValueChanged<Map<String, Object?>> onDelete;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: _MutedText('데이터가 없습니다.'),
      );
    }
    final fields = entity.listFields.take(9).toList(growable: false);
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: NodeFlowColors.ink,
            fontWeight: FontWeight.w900,
          ),
          columns: [
            for (final field in fields) DataColumn(label: Text(field.label)),
            const DataColumn(label: Text('작업')),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  for (final field in fields)
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 190),
                        child: Text(
                          _displayValue(row[field.key]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _IconAction(
                          icon: Icons.edit_rounded,
                          tooltip: '수정',
                          onPressed: () => onEdit(row),
                        ),
                        const SizedBox(width: 6),
                        _IconAction(
                          icon: Icons.block_rounded,
                          tooltip: '비활성화',
                          onPressed: () => onDelete(row),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AuditLogView extends StatelessWidget {
  const _AuditLogView({
    required this.logs,
    required this.searchController,
    required this.isLoading,
    required this.onSearch,
  });

  final AdminAuditLogListResponse? logs;
  final TextEditingController searchController;
  final bool isLoading;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final rows = logs?.rows ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: '감사로그 검색',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              _ToolbarButton(
                icon: Icons.search_rounded,
                label: '조회',
                onPressed: onSearch,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          padding: EdgeInsets.zero,
          child: isLoading && logs == null
              ? const _LoadingPanel()
              : Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('시각')),
                        DataColumn(label: Text('행위')),
                        DataColumn(label: Text('대상')),
                        DataColumn(label: Text('항목')),
                        DataColumn(label: Text('작업자')),
                      ],
                      rows: [
                        for (final row in rows)
                          DataRow(
                            cells: [
                              DataCell(Text(_compactDateTime(row.createdAt))),
                              DataCell(Text(row.actionCode)),
                              DataCell(Text(row.resourceType)),
                              DataCell(
                                Text(
                                  row.resourceLabel ?? row.resourceId ?? '-',
                                ),
                              ),
                              DataCell(Text(row.actorName ?? '-')),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ImportView extends StatefulWidget {
  const _ImportView({
    required this.entities,
    required this.selectedEntityKey,
    required this.onEntityChanged,
    required this.onImport,
    required this.isLoading,
  });

  final List<AdminEntityDefinition> entities;
  final String? selectedEntityKey;
  final ValueChanged<String> onEntityChanged;
  final Future<void> Function(AdminEntityDefinition entity, String csvText)
  onImport;
  final bool isLoading;

  @override
  State<_ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<_ImportView> {
  final _csvController = TextEditingController();

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AdminEntityDefinition? entity;
    for (final item in widget.entities) {
      if (item.key == widget.selectedEntityKey) {
        entity = item;
        break;
      }
    }
    final selectedEntity = entity;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  initialValue: widget.selectedEntityKey,
                  decoration: const InputDecoration(labelText: '업로드 대상'),
                  items: [
                    for (final item in widget.entities)
                      DropdownMenuItem(
                        value: item.key,
                        child: Text(item.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      widget.onEntityChanged(value);
                    }
                  },
                ),
              ),
              if (selectedEntity != null)
                _ToolbarButton(
                  icon: Icons.content_paste_rounded,
                  label: '샘플 헤더',
                  onPressed: () {
                    _csvController.text = selectedEntity.formFields
                        .where((field) => field.required)
                        .map((field) => field.key)
                        .join(',');
                  },
                ),
              _ToolbarButton(
                icon: Icons.upload_file_rounded,
                label: '업로드',
                filled: true,
                onPressed: selectedEntity == null || widget.isLoading
                    ? null
                    : () =>
                          widget.onImport(selectedEntity, _csvController.text),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _csvController,
            minLines: 14,
            maxLines: 22,
            decoration: const InputDecoration(
              labelText: 'CSV',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.table_rows_rounded),
            ),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

class _RecordEditorDialog extends StatefulWidget {
  const _RecordEditorDialog({
    required this.entity,
    required this.referenceOptions,
    this.initialData,
  });

  final AdminEntityDefinition entity;
  final Map<String, List<_ReferenceOption>> referenceOptions;
  final Map<String, Object?>? initialData;

  @override
  State<_RecordEditorDialog> createState() => _RecordEditorDialogState();
}

class _RecordEditorDialogState extends State<_RecordEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _booleans = {};
  final Map<String, int?> _selectedReferenceIds = {};

  @override
  void initState() {
    super.initState();
    for (final field in widget.entity.formFields) {
      final value = widget.initialData?[field.key];
      if (field.fieldType == 'boolean') {
        _booleans[field.key] = value == true;
      } else if (field.optionEntity != null) {
        _selectedReferenceIds[field.key] = _intValue(value);
      } else {
        _controllers[field.key] = TextEditingController(
          text: field.fieldType == 'json'
              ? const JsonEncoder.withIndent('  ').convert(value ?? {})
              : _displayValue(value),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialData == null
            ? '${widget.entity.label} 등록'
            : '${widget.entity.label} 수정',
      ),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in widget.entity.formFields) ...[
                  _buildField(field),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }

  Widget _buildField(AdminEntityField field) {
    if (field.fieldType == 'boolean') {
      return CheckboxListTile(
        value: _booleans[field.key] ?? false,
        onChanged: (value) =>
            setState(() => _booleans[field.key] = value ?? false),
        title: Text(field.label),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      );
    }
    if (field.optionEntity != null) {
      return _buildReferenceField(field);
    }
    final controller = _controllers[field.key]!;
    final keyboardType = field.fieldType == 'number'
        ? TextInputType.number
        : TextInputType.text;
    return TextFormField(
      controller: controller,
      minLines: field.fieldType == 'json' ? 4 : 1,
      maxLines: field.fieldType == 'json' ? 8 : 1,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: field.required ? '${field.label} *' : field.label,
        helperText: field.optionEntity == null
            ? field.helpText
            : '${field.optionEntity} ID',
      ),
      validator: (value) {
        if (field.required && (value == null || value.trim().isEmpty)) {
          return '${field.label} 필수';
        }
        if (field.fieldType == 'json' &&
            value != null &&
            value.trim().isNotEmpty) {
          try {
            jsonDecode(value);
          } on FormatException {
            return 'JSON 형식을 확인해 주세요.';
          }
        }
        return null;
      },
    );
  }

  Widget _buildReferenceField(AdminEntityField field) {
    final optionEntity = field.optionEntity!;
    final options =
        widget.referenceOptions[optionEntity] ?? const <_ReferenceOption>[];
    final selectedId = _selectedReferenceIds[field.key];
    final items = [...options];
    if (selectedId != null && !items.any((option) => option.id == selectedId)) {
      items.add(_ReferenceOption(id: selectedId, label: 'ID $selectedId'));
    }
    final canSelect = items.isNotEmpty;

    return DropdownButtonFormField<int>(
      key: ValueKey('${field.key}:${selectedId ?? 'none'}:${items.length}'),
      initialValue: selectedId,
      isExpanded: true,
      items: [
        for (final option in items)
          DropdownMenuItem<int>(
            value: option.id,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: canSelect
          ? (value) => setState(() => _selectedReferenceIds[field.key] = value)
          : null,
      decoration: InputDecoration(
        labelText: field.required ? '${field.label} *' : field.label,
        helperText: canSelect ? field.helpText : '$optionEntity 목록이 없습니다.',
        suffixIcon: !field.required && selectedId != null
            ? IconButton(
                tooltip: '선택 해제',
                icon: const Icon(Icons.close_rounded),
                onPressed: () =>
                    setState(() => _selectedReferenceIds[field.key] = null),
              )
            : null,
      ),
      hint: Text('${field.label} 선택'),
      validator: (value) {
        if (field.required && value == null) {
          return '${field.label} 선택';
        }
        return null;
      },
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final data = <String, Object?>{};
    for (final field in widget.entity.formFields) {
      if (field.fieldType == 'boolean') {
        data[field.key] = _booleans[field.key] ?? false;
        continue;
      }
      if (field.optionEntity != null) {
        data[field.key] = _selectedReferenceIds[field.key];
        continue;
      }
      final text = _controllers[field.key]?.text.trim() ?? '';
      if (text.isEmpty) {
        data[field.key] = null;
      } else if (field.fieldType == 'number') {
        data[field.key] = num.tryParse(text) ?? text;
      } else if (field.fieldType == 'json') {
        data[field.key] = jsonDecode(text);
      } else {
        data[field.key] = text;
      }
    }
    Navigator.of(context).pop(data);
  }
}

class _CsvExportDialog extends StatelessWidget {
  const _CsvExportDialog({required this.title, required this.csv});

  final String title;
  final String csv;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 720,
        height: 420,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: NodeFlowColors.field,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: NodeFlowColors.softSlate),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: csv));
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('복사'),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NodeFlowColors.softSlate),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: NodeFlowColors.deepBlue, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (trailing != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              trailing!,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final AdminMetric metric;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            '${metric.value}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: NodeFlowColors.deepBlue,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            metric.description,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final AdminActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NodeFlowColors.softSlate)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.change_circle_rounded,
            color: NodeFlowColors.mint,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${activity.label} · ${activity.value}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NodeFlowColors.ink,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(activity.status, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EntityChip extends StatelessWidget {
  const _EntityChip({required this.label, required this.group});

  final String label;
  final String group;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.storage_rounded, size: 18),
      label: Text('$label · $group'),
      side: const BorderSide(color: NodeFlowColors.softSlate),
      backgroundColor: NodeFlowColors.cloud,
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: NodeFlowColors.deepBlue,
        side: const BorderSide(color: NodeFlowColors.softSlate),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 38,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: NodeFlowColors.deepBlue,
            side: const BorderSide(color: NodeFlowColors.softSlate),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Icon(icon, size: 19),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: _Panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: NodeFlowColors.deepBlue),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/brand/nodeflow_mark.png',
            width: 42,
            height: 42,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NodeFlow',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 21,
                ),
              ),
              Text(
                'Admin Console',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TenantBlock extends StatelessWidget {
  const _TenantBlock({required this.session});

  final LoginResponse session;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.tenant.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${session.tenant.code} · ${session.user.userType}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.white54,
        fontWeight: FontWeight.w900,
        fontSize: 11,
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: Colors.white.withValues(alpha: 0.20))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: selected ? Colors.white : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminHealthBlock extends StatelessWidget {
  const _AdminHealthBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: NodeFlowColors.mint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Audit Ready',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.section,
    required this.icon,
    required this.label,
  });

  final _AdminSection section;
  final IconData icon;
  final String label;
}

const _navItems = [
  _NavItemData(
    section: _AdminSection.dashboard,
    icon: Icons.dashboard_rounded,
    label: '대시보드',
  ),
  _NavItemData(
    section: _AdminSection.codes,
    icon: Icons.hub_rounded,
    label: '공통코드',
  ),
  _NavItemData(
    section: _AdminSection.masters,
    icon: Icons.dataset_rounded,
    label: '마스터',
  ),
  _NavItemData(
    section: _AdminSection.rules,
    icon: Icons.rule_rounded,
    label: '규칙',
  ),
  _NavItemData(
    section: _AdminSection.security,
    icon: Icons.verified_user_rounded,
    label: '사용자/권한',
  ),
  _NavItemData(
    section: _AdminSection.imports,
    icon: Icons.upload_file_rounded,
    label: '일괄 업로드',
  ),
  _NavItemData(
    section: _AdminSection.audit,
    icon: Icons.manage_search_rounded,
    label: '감사로그',
  ),
  _NavItemData(
    section: _AdminSection.settings,
    icon: Icons.settings_rounded,
    label: '시스템 설정',
  ),
];

const _mobileItems = [
  _NavItemData(
    section: _AdminSection.dashboard,
    icon: Icons.dashboard_rounded,
    label: '홈',
  ),
  _NavItemData(
    section: _AdminSection.masters,
    icon: Icons.dataset_rounded,
    label: '마스터',
  ),
  _NavItemData(
    section: _AdminSection.codes,
    icon: Icons.hub_rounded,
    label: '코드',
  ),
  _NavItemData(
    section: _AdminSection.security,
    icon: Icons.verified_user_rounded,
    label: '권한',
  ),
  _NavItemData(
    section: _AdminSection.audit,
    icon: Icons.manage_search_rounded,
    label: '로그',
  ),
];

class _ReferenceOption {
  const _ReferenceOption({required this.id, required this.label});

  final int id;
  final String label;

  static _ReferenceOption? fromRow(
    AdminEntityDefinition entity,
    Map<String, Object?> row,
  ) {
    final id = _intValue(row[entity.idField]);
    if (id == null) {
      return null;
    }
    final title = _displayValue(row[entity.titleField]);
    final code = _displayValue(row[_codeFieldKey(entity)]);
    final primary = title.isEmpty ? 'ID $id' : title;
    final label = code.isEmpty ? primary : '$primary ($code)';
    return _ReferenceOption(id: id, label: label);
  }
}

String _displayValue(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is Map || value is List) {
    return jsonEncode(value);
  }
  return '$value';
}

String? _codeFieldKey(AdminEntityDefinition entity) {
  for (final field in entity.fields) {
    if (field.key.endsWith('_code') || field.key == 'login_id') {
      return field.key;
    }
  }
  return null;
}

String _compactDateTime(String value) {
  if (value.length >= 16) {
    return value.substring(0, 16).replaceFirst('T', ' ');
  }
  return value;
}

int? _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

List<Map<String, Object?>> _parseCsv(String csvText) {
  final lines = csvText
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  if (lines.length < 2) {
    throw const AdminFailure('CSV 헤더와 데이터가 필요합니다.');
  }
  final headers = _splitCsvLine(lines.first);
  final rows = <Map<String, Object?>>[];
  for (final line in lines.skip(1)) {
    final cells = _splitCsvLine(line);
    final row = <String, Object?>{};
    for (var index = 0; index < headers.length; index++) {
      final value = index < cells.length ? cells[index].trim() : '';
      row[headers[index].trim()] = value.isEmpty ? null : value;
    }
    rows.add(row);
  }
  return rows;
}

List<String> _splitCsvLine(String line) {
  final values = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  for (var index = 0; index < line.length; index++) {
    final char = line[index];
    if (char == '"') {
      inQuotes = !inQuotes;
      continue;
    }
    if (char == ',' && !inQuotes) {
      values.add(buffer.toString());
      buffer.clear();
      continue;
    }
    buffer.write(char);
  }
  values.add(buffer.toString());
  return values;
}
