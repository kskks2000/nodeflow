import 'package:flutter/material.dart';

import '../../../app/nodeflow_theme.dart';
import '../../auth/domain/auth_models.dart';

class TmsMainScreen extends StatelessWidget {
  const TmsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = _sessionFromRoute(context);
    final tenantCode = session?.tenant.code ?? 'TEN001';
    final tenantName = session?.tenant.name ?? 'NodeFlow Logistics';
    final userName = session?.user.name ?? 'TMS Manager';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            if (wide) {
              return Row(
                children: [
                  _Sidebar(
                    tenantCode: tenantCode,
                    tenantName: tenantName,
                    userName: userName,
                  ),
                  Expanded(
                    child: _MainWorkspace(
                      tenantCode: tenantCode,
                      tenantName: tenantName,
                      userName: userName,
                      session: session,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _MobileHeader(
                  tenantCode: tenantCode,
                  tenantName: tenantName,
                  userName: userName,
                ),
                Expanded(
                  child: _MainWorkspace(
                    tenantCode: tenantCode,
                    tenantName: tenantName,
                    userName: userName,
                    session: session,
                    compact: true,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  LoginResponse? _sessionFromRoute(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is LoginResponse) {
      return arguments;
    }
    return null;
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.tenantCode,
    required this.tenantName,
    required this.userName,
  });

  final String tenantCode;
  final String tenantName;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      color: const Color(0xFF172554),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandHeader(onDark: true),
          const SizedBox(height: 26),
          _AccountTile(
            tenantCode: tenantCode,
            tenantName: tenantName,
            userName: userName,
          ),
          const SizedBox(height: 26),
          const _NavSectionLabel('OPERATIONS'),
          const SizedBox(height: 8),
          const _NavItem(
            icon: Icons.dashboard_rounded,
            label: '운영 대시보드',
            selected: true,
          ),
          const _NavItem(icon: Icons.assignment_rounded, label: '운송오더'),
          const _NavItem(icon: Icons.account_tree_rounded, label: '편성 관리'),
          const _NavItem(icon: Icons.handshake_rounded, label: '운송사 배정'),
          const _NavItem(icon: Icons.route_rounded, label: '배차 관리'),
          const _NavItem(icon: Icons.local_shipping_rounded, label: '실행 관리'),
          const SizedBox(height: 18),
          const _NavSectionLabel('BACK OFFICE'),
          const SizedBox(height: 8),
          const _NavItem(icon: Icons.fact_check_rounded, label: '실적 관리'),
          const _NavItem(icon: Icons.fact_check_rounded, label: '정산 관리'),
          const _NavItem(icon: Icons.analytics_rounded, label: '리포트'),
          const _NavItem(icon: Icons.settings_rounded, label: '환경 설정'),
          const Spacer(),
          const _SystemHealth(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('로그아웃'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.tenantCode,
    required this.tenantName,
    required this.userName,
  });

  final String tenantCode;
  final String tenantName;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF172554),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: _BrandHeader(onDark: true)),
              _HeaderIconButton(
                icon: Icons.logout_rounded,
                tooltip: '로그아웃',
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
                onDark: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AccountTile(
            tenantCode: tenantCode,
            tenantName: tenantName,
            userName: userName,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _MainWorkspace extends StatelessWidget {
  const _MainWorkspace({
    required this.tenantCode,
    required this.tenantName,
    required this.userName,
    required this.session,
    this.compact = false,
  });

  final String tenantCode;
  final String tenantName;
  final String userName;
  final LoginResponse? session;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!compact)
          _TopBar(
            tenantCode: tenantCode,
            tenantName: tenantName,
            userName: userName,
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 26,
              compact ? 18 : 22,
              compact ? 16 : 26,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CommandHeader(
                  tenantCode: tenantCode,
                  tenantName: tenantName,
                  userName: userName,
                  session: session,
                  compact: compact,
                ),
                const SizedBox(height: 16),
                _ProcessFlowPanel(compact: compact),
                const SizedBox(height: 16),
                _KpiRibbon(compact: compact),
                const SizedBox(height: 16),
                if (compact)
                  const Column(
                    children: [
                      _DispatchWorkbench(compact: true),
                      SizedBox(height: 16),
                      _RightStack(),
                    ],
                  )
                else
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 8, child: _DispatchWorkbench()),
                      SizedBox(width: 16),
                      Expanded(flex: 4, child: _RightStack()),
                    ],
                  ),
                const SizedBox(height: 16),
                if (compact)
                  const Column(
                    children: [
                      _ShipmentList(compact: true),
                      SizedBox(height: 16),
                      _RouteBoard(compact: true),
                    ],
                  )
                else
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: _ShipmentList()),
                      SizedBox(width: 16),
                      Expanded(flex: 5, child: _RouteBoard()),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.tenantCode,
    required this.tenantName,
    required this.userName,
  });

  final String tenantCode;
  final String tenantName;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: NodeFlowColors.softSlate)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SearchBox(tenantCode: tenantCode, tenantName: tenantName),
          ),
          const SizedBox(width: 18),
          const _TopBarChip(icon: Icons.today_rounded, label: '2026.04.29'),
          const SizedBox(width: 10),
          const _TopBarChip(icon: Icons.sync_rounded, label: 'Live Sync'),
          const SizedBox(width: 12),
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: '알림',
            onPressed: () {},
          ),
          const SizedBox(width: 10),
          _UserCompact(userName: userName),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.tenantCode, required this.tenantName});

  final String tenantCode;
  final String tenantName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NodeFlowColors.softSlate),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: NodeFlowColors.slate,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '운송번호, 차량, 거래처 검색',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _TinyCode(label: tenantCode),
        ],
      ),
    );
  }
}

class _CommandHeader extends StatelessWidget {
  const _CommandHeader({
    required this.tenantCode,
    required this.tenantName,
    required this.userName,
    required this.session,
    required this.compact,
  });

  final String tenantCode;
  final String tenantName;
  final String userName;
  final LoginResponse? session;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: EdgeInsets.all(compact ? 18 : 22),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CommandTitle(
                  tenantCode: tenantCode,
                  tenantName: tenantName,
                  userName: userName,
                ),
                const SizedBox(height: 16),
                _CommandActions(session: session),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _CommandTitle(
                    tenantCode: tenantCode,
                    tenantName: tenantName,
                    userName: userName,
                  ),
                ),
                const SizedBox(width: 16),
                _CommandActions(session: session),
              ],
            ),
    );
  }
}

class _CommandTitle extends StatelessWidget {
  const _CommandTitle({
    required this.tenantCode,
    required this.tenantName,
    required this.userName,
  });

  final String tenantCode;
  final String tenantName;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusPill(
              label: '운영 대시보드',
              color: NodeFlowColors.deepBlue,
              background: const Color(0xFFEFF6FF),
            ),
            const _StatusPill(
              label: 'TMS Main',
              color: NodeFlowColors.mint,
              background: Color(0xFFECFDF5),
            ),
            _StatusPill(
              label: tenantCode,
              color: const Color(0xFF2563EB),
              background: const Color(0xFFEFF6FF),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          '운영 관제',
          style: textTheme.headlineLarge?.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$tenantName · $userName · 오더 등록부터 정산까지 한 화면에서 진행',
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _CommandActions extends StatelessWidget {
  const _CommandActions({required this.session});

  final LoginResponse? session;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        _HeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: '새로고침',
          onPressed: () {},
        ),
        _HeaderIconButton(
          icon: Icons.tune_rounded,
          tooltip: '필터',
          onPressed: () {},
        ),
        SizedBox(
          width: 168,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).pushNamed('/orders/new', arguments: session),
            icon: const Icon(Icons.assignment_rounded),
            label: const Text('오더 등록'),
          ),
        ),
        SizedBox(
          width: 150,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).pushNamed('/dispatch/new', arguments: session),
            icon: const Icon(Icons.add_road_rounded),
            label: const Text('신규 배차'),
            style: OutlinedButton.styleFrom(
              foregroundColor: NodeFlowColors.deepBlue,
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: NodeFlowColors.softSlate),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProcessFlowPanel extends StatelessWidget {
  const _ProcessFlowPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final steps = [
      const _ProcessData(
        number: '1',
        title: '오더 등록/확정',
        icon: Icons.assignment_turned_in_rounded,
        color: NodeFlowColors.deepBlue,
      ),
      const _ProcessData(
        number: '2',
        title: '편성',
        icon: Icons.account_tree_rounded,
        color: Color(0xFF2563EB),
      ),
      const _ProcessData(
        number: '3',
        title: '운송사 배정',
        icon: Icons.handshake_rounded,
        color: NodeFlowColors.mint,
      ),
      const _ProcessData(
        number: '4',
        title: '배차',
        icon: Icons.route_rounded,
        color: NodeFlowColors.amber,
      ),
      const _ProcessData(
        number: '5',
        title: '실행',
        icon: Icons.local_shipping_rounded,
        color: Color(0xFF0F766E),
      ),
      const _ProcessData(
        number: '6',
        title: '실적',
        icon: Icons.fact_check_rounded,
        color: Color(0xFF7C3AED),
      ),
      const _ProcessData(
        number: '7',
        title: '정산',
        icon: Icons.payments_rounded,
        color: Color(0xFF334155),
      ),
    ];

    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.schema_rounded,
            title: 'TMS 프로세스',
            trailing: 'End-to-End',
          ),
          const SizedBox(height: 14),
          if (compact)
            GridView.builder(
              itemCount: steps.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 74,
              ),
              itemBuilder: (context, index) {
                return _ProcessTile(data: steps[index], active: index == 0);
              },
            )
          else
            Row(
              children: [
                for (var index = 0; index < steps.length; index++) ...[
                  Expanded(
                    child: _ProcessTile(data: steps[index], active: index == 0),
                  ),
                  if (index != steps.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ProcessData {
  const _ProcessData({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
  });

  final String number;
  final String title;
  final IconData icon;
  final Color color;
}

class _ProcessTile extends StatelessWidget {
  const _ProcessTile({required this.data, required this.active});

  final _ProcessData data;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? data.color : NodeFlowColors.slate;

    return Container(
      height: 74,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active
            ? data.color.withValues(alpha: 0.09)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? data.color.withValues(alpha: 0.22)
              : NodeFlowColors.softSlate,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Icon(data.icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STEP ${data.number}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NodeFlowColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiRibbon extends StatelessWidget {
  const _KpiRibbon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _KpiData(
        label: '오늘 주문',
        value: '128',
        sub: '+12.4%',
        icon: Icons.assignment_turned_in_rounded,
        color: NodeFlowColors.deepBlue,
      ),
      const _KpiData(
        label: '배차 완료',
        value: '86',
        sub: '67%',
        icon: Icons.route_rounded,
        color: NodeFlowColors.mint,
      ),
      const _KpiData(
        label: '운행 차량',
        value: '42',
        sub: '8 대기',
        icon: Icons.local_shipping_rounded,
        color: Color(0xFF2563EB),
      ),
      const _KpiData(
        label: '정시율',
        value: '96.8%',
        sub: '+2.1%',
        icon: Icons.timer_rounded,
        color: NodeFlowColors.amber,
      ),
      const _KpiData(
        label: '예외 알림',
        value: '3',
        sub: '확인 필요',
        icon: Icons.priority_high_rounded,
        color: Color(0xFFDC2626),
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 124,
      ),
      itemBuilder: (context, index) => _KpiCard(data: items[index]),
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, color: data.color, size: 19),
              ),
              const Spacer(),
              Text(
                data.sub,
                style: textTheme.bodyMedium?.copyWith(
                  color: data.color,
                  fontWeight: FontWeight.w900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            style: textTheme.headlineSmall?.copyWith(
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DispatchWorkbench extends StatelessWidget {
  const _DispatchWorkbench({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rows = [
      const _DispatchData(
        no: 'NF-24024',
        client: 'KCASTLE 부산센터',
        route: '서울 강서 → 부산 사상',
        window: '13:40-14:30',
        vehicle: '11톤 윙바디',
        status: '운송중',
        priority: 'High',
      ),
      const _DispatchData(
        no: 'NF-24023',
        client: '인천 남동 허브',
        route: '인천 남동 → 대전 유성',
        window: '14:20-15:10',
        vehicle: '5톤 냉장',
        status: '상차',
        priority: 'Normal',
      ),
      const _DispatchData(
        no: 'NF-24022',
        client: '평택 포승 CY',
        route: '평택 포승 → 광주 하남',
        window: '15:30-16:20',
        vehicle: '25톤 카고',
        status: '배차중',
        priority: 'Medium',
      ),
      const _DispatchData(
        no: 'NF-24021',
        client: '창원 성산 공장',
        route: '창원 성산 → 용인 처인',
        window: '16:10-17:05',
        vehicle: '8톤 탑차',
        status: '하차',
        priority: 'Normal',
      ),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.table_rows_rounded,
            title: '배차 워크벤치',
            trailing: 'Live',
          ),
          const SizedBox(height: 14),
          if (compact)
            Column(
              children: [
                for (final row in rows) ...[
                  _DispatchMobileTile(data: row),
                  if (row != rows.last) const SizedBox(height: 10),
                ],
              ],
            )
          else
            Column(
              children: [
                const _DispatchHeaderRow(),
                const SizedBox(height: 8),
                for (final row in rows) ...[
                  _DispatchTableRow(data: row),
                  if (row != rows.last) const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _DispatchData {
  const _DispatchData({
    required this.no,
    required this.client,
    required this.route,
    required this.window,
    required this.vehicle,
    required this.status,
    required this.priority,
  });

  final String no;
  final String client;
  final String route;
  final String window;
  final String vehicle;
  final String status;
  final String priority;
}

class _DispatchHeaderRow extends StatelessWidget {
  const _DispatchHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: _HeaderCell('운송번호')),
          Expanded(flex: 3, child: _HeaderCell('거래처')),
          Expanded(flex: 4, child: _HeaderCell('운송구간')),
          Expanded(flex: 2, child: _HeaderCell('시간')),
          Expanded(flex: 2, child: _HeaderCell('차량')),
          Expanded(flex: 2, child: _HeaderCell('상태')),
        ],
      ),
    );
  }
}

class _DispatchTableRow extends StatelessWidget {
  const _DispatchTableRow({required this.data});

  final _DispatchData data;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: NodeFlowColors.ink,
      fontWeight: FontWeight.w800,
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NodeFlowColors.softSlate),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(data.no, style: textStyle)),
          Expanded(
            flex: 3,
            child: Text(
              data.client,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              data.route,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 2, child: Text(data.window, style: textStyle)),
          Expanded(
            flex: 2,
            child: Text(
              data.vehicle,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 2, child: _ShipmentStatus(status: data.status)),
        ],
      ),
    );
  }
}

class _DispatchMobileTile extends StatelessWidget {
  const _DispatchMobileTile({required this.data});

  final _DispatchData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NodeFlowColors.softSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(data.no, style: textTheme.titleMedium)),
              _ShipmentStatus(status: data.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.route,
            style: textTheme.bodyMedium?.copyWith(
              color: NodeFlowColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${data.client} · ${data.vehicle} · ${data.window}',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RightStack extends StatelessWidget {
  const _RightStack();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [_FleetStatus(), SizedBox(height: 16), _ExceptionPanel()],
    );
  }
}

class _FleetStatus extends StatelessWidget {
  const _FleetStatus();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.local_shipping_rounded,
            title: '차량 상태',
            trailing: '42대',
          ),
          const SizedBox(height: 16),
          const _UtilRow(label: '운송중', value: 0.62, count: '26'),
          const SizedBox(height: 12),
          const _UtilRow(label: '상차 대기', value: 0.19, count: '8'),
          const SizedBox(height: 12),
          const _UtilRow(label: '하차 대기', value: 0.12, count: '5'),
          const SizedBox(height: 12),
          const _UtilRow(label: '정비/휴무', value: 0.07, count: '3'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.speed_rounded,
                  color: NodeFlowColors.deepBlue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '평균 배차 리드타임 18분',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: NodeFlowColors.deepBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExceptionPanel extends StatelessWidget {
  const _ExceptionPanel();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.notification_important_rounded,
            title: '운영 알림',
            trailing: '3건',
          ),
          SizedBox(height: 14),
          _AlertItem(
            icon: Icons.schedule_rounded,
            title: 'ETA 지연 위험',
            body: 'NF-24018 부산 구간 교통 정체',
            color: NodeFlowColors.amber,
          ),
          SizedBox(height: 10),
          _AlertItem(
            icon: Icons.inventory_rounded,
            title: '상차 확인 대기',
            body: '평택 포승 2건 POD 미수신',
            color: Color(0xFF2563EB),
          ),
          SizedBox(height: 10),
          _AlertItem(
            icon: Icons.verified_rounded,
            title: '정산 데이터 동기화',
            body: '오늘 운송 완료 34건 반영',
            color: NodeFlowColors.mint,
          ),
        ],
      ),
    );
  }
}

class _UtilRow extends StatelessWidget {
  const _UtilRow({
    required this.label,
    required this.value,
    required this.count,
  });

  final String label;
  final double value;
  final String count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: NodeFlowColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              count,
              style: textTheme.bodyMedium?.copyWith(
                color: NodeFlowColors.deepBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            color: NodeFlowColors.mint,
            backgroundColor: NodeFlowColors.softSlate,
          ),
        ),
      ],
    );
  }
}

class _ShipmentList extends StatelessWidget {
  const _ShipmentList({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rows = [
      const _ShipmentData(
        no: 'NF-24024',
        route: '서울 강서 → 부산 사상',
        driver: '김도현',
        eta: '14:30',
        status: '운송중',
      ),
      const _ShipmentData(
        no: 'NF-24023',
        route: '인천 남동 → 대전 유성',
        driver: '박민재',
        eta: '15:10',
        status: '상차',
      ),
      const _ShipmentData(
        no: 'NF-24022',
        route: '평택 포승 → 광주 하남',
        driver: '이서준',
        eta: '16:20',
        status: '배차중',
      ),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.view_list_rounded,
            title: '운송 리스트',
            trailing: '최근 3건',
          ),
          const SizedBox(height: 14),
          for (final row in rows) ...[
            _ShipmentTile(data: row),
            if (row != rows.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ShipmentData {
  const _ShipmentData({
    required this.no,
    required this.route,
    required this.driver,
    required this.eta,
    required this.status,
  });

  final String no;
  final String route;
  final String driver;
  final String eta;
  final String status;
}

class _ShipmentTile extends StatelessWidget {
  const _ShipmentTile({required this.data});

  final _ShipmentData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NodeFlowColors.softSlate),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.no, style: textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  data.route,
                  style: textTheme.bodyMedium?.copyWith(
                    color: NodeFlowColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.driver} · ETA ${data.eta}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _ShipmentStatus(status: data.status),
        ],
      ),
    );
  }
}

class _RouteBoard extends StatelessWidget {
  const _RouteBoard({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final lanes = [
      const _LaneData(label: '접수', count: '18', color: Color(0xFF2563EB)),
      const _LaneData(label: '배차중', count: '12', color: NodeFlowColors.amber),
      const _LaneData(label: '운송중', count: '42', color: NodeFlowColors.mint),
      const _LaneData(label: '완료', count: '34', color: NodeFlowColors.deepBlue),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.route_rounded,
            title: '배차 보드',
            trailing: 'Pipeline',
          ),
          const SizedBox(height: 16),
          if (compact)
            GridView.builder(
              itemCount: lanes.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 92,
              ),
              itemBuilder: (context, index) {
                return _RouteLane(data: lanes[index]);
              },
            )
          else
            Row(
              children: [
                for (var index = 0; index < lanes.length; index++) ...[
                  Expanded(child: _RouteLane(data: lanes[index])),
                  if (index != lanes.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _LaneData {
  const _LaneData({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final String count;
  final Color color;
}

class _RouteLane extends StatelessWidget {
  const _RouteLane({required this.data});

  final _LaneData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 88,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: data.color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 3,
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Spacer(),
          Text(
            data.count,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: data.color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            data.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: NodeFlowColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  const _AlertItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: NodeFlowColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: NodeFlowColors.deepBlue, size: 21),
        const SizedBox(width: 9),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        _StatusPill(
          label: trailing,
          color: NodeFlowColors.deepBlue,
          background: const Color(0xFFEFF6FF),
        ),
      ],
    );
  }
}

class _ShipmentStatus extends StatelessWidget {
  const _ShipmentStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      '운송중' => NodeFlowColors.mint,
      '상차' => const Color(0xFF2563EB),
      '배차중' => NodeFlowColors.amber,
      _ => NodeFlowColors.deepBlue,
    };

    return _StatusPill(
      label: status,
      color: color,
      background: color.withValues(alpha: 0.10),
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
        boxShadow: [
          BoxShadow(
            color: NodeFlowColors.ink.withValues(alpha: 0.045),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.onDark = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 42,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: onDark ? Colors.white : NodeFlowColors.deepBlue,
            backgroundColor: onDark
                ? Colors.white.withValues(alpha: 0.08)
                : null,
            side: BorderSide(
              color: onDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : NodeFlowColors.softSlate,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _TopBarChip extends StatelessWidget {
  const _TopBarChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NodeFlowColors.softSlate),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: NodeFlowColors.deepBlue),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: NodeFlowColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyCode extends StatelessWidget {
  const _TinyCode({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: NodeFlowColors.deepBlue,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _UserCompact extends StatelessWidget {
  const _UserCompact({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.account_circle_rounded,
            color: NodeFlowColors.deepBlue,
            size: 22,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          userName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: NodeFlowColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? Colors.white : NodeFlowColors.ink;
    final subtitle = onDark ? Colors.white70 : NodeFlowColors.slate;

    return Row(
      mainAxisSize: MainAxisSize.min,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NodeFlow',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: foreground,
                  fontSize: 21,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'TMS Console',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: subtitle,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.tenantCode,
    required this.tenantName,
    required this.userName,
    this.compact = false,
  });

  final String tenantCode;
  final String tenantName;
  final String userName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 13 : 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: NodeFlowColors.mint.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_circle_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenantName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$tenantCode · $userName',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSectionLabel extends StatelessWidget {
  const _NavSectionLabel(this.label);

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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 6),
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
          Icon(icon, color: selected ? Colors.white : Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemHealth extends StatelessWidget {
  const _SystemHealth();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LiveDot(),
              const SizedBox(width: 9),
              Text(
                'Gateway Connected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'FastAPI · PostgreSQL',
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

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: NodeFlowColors.mint,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: NodeFlowColors.mint.withValues(alpha: 0.45),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
