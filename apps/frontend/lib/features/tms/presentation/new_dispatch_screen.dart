import 'package:flutter/material.dart';

import '../../../app/nodeflow_theme.dart';

class NewDispatchScreen extends StatefulWidget {
  const NewDispatchScreen({super.key});

  @override
  State<NewDispatchScreen> createState() => _NewDispatchScreenState();
}

class _NewDispatchScreenState extends State<NewDispatchScreen> {
  final _dispatchNoController = TextEditingController(text: 'DSP-NEW-001');
  final _startController = TextEditingController(text: '2026-04-29 14:00');
  final _endController = TextEditingController(text: '2026-04-29 18:30');
  final _noteController = TextEditingController(text: '상차 전 고객 연락 필수');

  int _selectedOrder = 0;
  int _selectedResource = 0;
  String _dispatchStatus = 'READY';
  String _assignmentType = 'DIRECT';

  @override
  void initState() {
    super.initState();
    _dispatchNoController.addListener(_refreshReview);
  }

  @override
  void dispose() {
    _dispatchNoController.removeListener(_refreshReview);
    _dispatchNoController.dispose();
    _startController.dispose();
    _endController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedOrder = _orders[_selectedOrder];
    final selectedResource = _resources[_selectedResource];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1120;
            return Column(
              children: [
                _DispatchTopBar(wide: wide),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 26 : 16,
                      wide ? 22 : 18,
                      wide ? 26 : 16,
                      28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PageHeader(
                          dispatchNoController: _dispatchNoController,
                          wide: wide,
                        ),
                        const SizedBox(height: 16),
                        _FlowOverview(wide: wide),
                        const SizedBox(height: 16),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Column(
                                  children: [
                                    _OrderSelectionPanel(
                                      orders: _orders,
                                      selectedIndex: _selectedOrder,
                                      onSelected: (index) {
                                        setState(() => _selectedOrder = index);
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _RoutePlanPanel(order: selectedOrder),
                                    const SizedBox(height: 16),
                                    _ExistingDispatchPanel(
                                      order: selectedOrder,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _ResourcePanel(
                                      resources: _resources,
                                      selectedIndex: _selectedResource,
                                      onSelected: (index) {
                                        setState(
                                          () => _selectedResource = index,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _SchedulePanel(
                                      startController: _startController,
                                      endController: _endController,
                                      noteController: _noteController,
                                      status: _dispatchStatus,
                                      assignmentType: _assignmentType,
                                      onStatusChanged: (value) {
                                        setState(() => _dispatchStatus = value);
                                      },
                                      onAssignmentTypeChanged: (value) {
                                        setState(() => _assignmentType = value);
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _ReviewPanel(
                                      order: selectedOrder,
                                      resource: selectedResource,
                                      dispatchNo: _dispatchNoController.text,
                                      status: _dispatchStatus,
                                      assignmentType: _assignmentType,
                                      onSubmit: _submit,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _OrderSelectionPanel(
                                orders: _orders,
                                selectedIndex: _selectedOrder,
                                onSelected: (index) {
                                  setState(() => _selectedOrder = index);
                                },
                                compact: true,
                              ),
                              const SizedBox(height: 16),
                              _RoutePlanPanel(
                                order: selectedOrder,
                                compact: true,
                              ),
                              const SizedBox(height: 16),
                              _ExistingDispatchPanel(order: selectedOrder),
                              const SizedBox(height: 16),
                              _ResourcePanel(
                                resources: _resources,
                                selectedIndex: _selectedResource,
                                onSelected: (index) {
                                  setState(() => _selectedResource = index);
                                },
                                compact: true,
                              ),
                              const SizedBox(height: 16),
                              _SchedulePanel(
                                startController: _startController,
                                endController: _endController,
                                noteController: _noteController,
                                status: _dispatchStatus,
                                assignmentType: _assignmentType,
                                onStatusChanged: (value) {
                                  setState(() => _dispatchStatus = value);
                                },
                                onAssignmentTypeChanged: (value) {
                                  setState(() => _assignmentType = value);
                                },
                              ),
                              const SizedBox(height: 16),
                              _ReviewPanel(
                                order: selectedOrder,
                                resource: selectedResource,
                                dispatchNo: _dispatchNoController.text,
                                status: _dispatchStatus,
                                assignmentType: _assignmentType,
                                onSubmit: _submit,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: NodeFlowColors.ink,
        content: Text('${_dispatchNoController.text} 배차 생성 요청이 준비되었습니다.'),
      ),
    );
  }

  void _refreshReview() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _DispatchTopBar extends StatelessWidget {
  const _DispatchTopBar({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: wide ? 70 : null,
      padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 14, wide ? 24 : 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: NodeFlowColors.softSlate)),
      ),
      child: Row(
        children: [
          _IconButtonFrame(
            icon: Icons.arrow_back_rounded,
            tooltip: '뒤로가기',
            onPressed: () {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              } else {
                navigator.pushReplacementNamed('/main');
              }
            },
          ),
          const SizedBox(width: 12),
          const Expanded(child: _BrandCompact()),
          if (wide) ...[
            const _TopBarChip(icon: Icons.storage_rounded, label: 'ord.orders'),
            const SizedBox(width: 8),
            const _TopBarChip(icon: Icons.hub_rounded, label: 'dsp.dispatches'),
            const SizedBox(width: 8),
            const _TopBarChip(
              icon: Icons.sync_rounded,
              label: 'PostgreSQL Live',
            ),
          ],
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.dispatchNoController, required this.wide});

  final TextEditingController dispatchNoController;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: EdgeInsets.all(wide ? 22 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: _PageTitle()),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 270,
                      child: TextField(
                        controller: dispatchNoController,
                        decoration: const InputDecoration(
                          labelText: '배차번호',
                          prefixIcon: Icon(Icons.confirmation_number_rounded),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PageTitle(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dispatchNoController,
                      decoration: const InputDecoration(
                        labelText: '배차번호',
                        prefixIcon: Icon(Icons.confirmation_number_rounded),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderStat(
                icon: Icons.assignment_turned_in_rounded,
                label: '배차 가능 오더',
                value: '18',
              ),
              _HeaderStat(
                icon: Icons.local_shipping_rounded,
                label: '가용 차량',
                value: '42',
              ),
              _HeaderStat(
                icon: Icons.warning_amber_rounded,
                label: '중복 배차 위험',
                value: '0',
              ),
              _HeaderStat(
                icon: Icons.storage_rounded,
                label: '대상 테이블',
                value: 'ord/dsp',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusPill(
              label: '신규 배차',
              color: NodeFlowColors.deepBlue,
              background: Color(0xFFEFF6FF),
            ),
            _StatusPill(
              label: 'READY',
              color: NodeFlowColors.mint,
              background: Color(0xFFECFDF5),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          '신규 배차 생성',
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '운송오더를 선택하고 차량, 기사, 운송사를 매칭해 배차를 생성합니다.',
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NodeFlowColors.softSlate),
      ),
      child: Row(
        children: [
          Icon(icon, color: NodeFlowColors.deepBlue, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

class _FlowOverview extends StatelessWidget {
  const _FlowOverview({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final steps = [
      const _FlowStepData(
        icon: Icons.assignment_rounded,
        title: '오더 확인',
        body: 'ord.orders / ord.order_stops',
      ),
      const _FlowStepData(
        icon: Icons.alt_route_rounded,
        title: '계획 검토',
        body: 'plan.transport_plans',
      ),
      const _FlowStepData(
        icon: Icons.manage_accounts_rounded,
        title: '자원 매칭',
        body: 'mdm.vehicles / drivers',
      ),
      const _FlowStepData(
        icon: Icons.fact_check_rounded,
        title: '배차 생성',
        body: 'dsp.assignments / dispatches',
      ),
    ];

    return _Panel(
      padding: const EdgeInsets.all(14),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < steps.length; index++) ...[
                  Expanded(
                    child: _FlowStep(
                      data: steps[index],
                      stepNumber: index + 1,
                      active: index <= 2,
                    ),
                  ),
                  if (index != steps.length - 1) const SizedBox(width: 10),
                ],
              ],
            )
          : Column(
              children: [
                for (var index = 0; index < steps.length; index++) ...[
                  _FlowStep(
                    data: steps[index],
                    stepNumber: index + 1,
                    active: index <= 2,
                  ),
                  if (index != steps.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _FlowStepData {
  const _FlowStepData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.data,
    required this.stepNumber,
    required this.active,
  });

  final _FlowStepData data;
  final int stepNumber;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? NodeFlowColors.deepBlue : NodeFlowColors.slate;
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? NodeFlowColors.deepBlue.withValues(alpha: 0.20)
              : NodeFlowColors.softSlate,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Icon(data.icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$stepNumber. ${data.title}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: NodeFlowColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data.body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
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

class _OrderSelectionPanel extends StatelessWidget {
  const _OrderSelectionPanel({
    required this.orders,
    required this.selectedIndex,
    required this.onSelected,
    this.compact = false,
  });

  final List<_OrderCandidate> orders;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.assignment_rounded,
            title: '운송오더 선택',
            trailing: 'ord.orders',
          ),
          const SizedBox(height: 14),
          if (compact)
            Column(
              children: [
                for (var index = 0; index < orders.length; index++) ...[
                  _OrderMobileTile(
                    order: orders[index],
                    selected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
                  if (index != orders.length - 1) const SizedBox(height: 10),
                ],
              ],
            )
          else
            Column(
              children: [
                const _OrderHeaderRow(),
                const SizedBox(height: 8),
                for (var index = 0; index < orders.length; index++) ...[
                  _OrderTableRow(
                    order: orders[index],
                    selected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
                  if (index != orders.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _OrderHeaderRow extends StatelessWidget {
  const _OrderHeaderRow();

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
          Expanded(flex: 2, child: _HeaderCell('오더번호')),
          Expanded(flex: 3, child: _HeaderCell('화주')),
          Expanded(flex: 4, child: _HeaderCell('구간')),
          Expanded(flex: 2, child: _HeaderCell('차종/톤급')),
          Expanded(flex: 2, child: _HeaderCell('중량')),
          Expanded(flex: 2, child: _HeaderCell('상태')),
        ],
      ),
    );
  }
}

class _OrderTableRow extends StatelessWidget {
  const _OrderTableRow({
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final _OrderCandidate order;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: NodeFlowColors.ink,
      fontWeight: FontWeight.w800,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? NodeFlowColors.deepBlue
                : NodeFlowColors.softSlate,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(order.orderNo, style: textStyle)),
            Expanded(
              flex: 3,
              child: Text(
                order.customer,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                order.route,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                order.vehicleSpec,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(flex: 2, child: Text(order.weight, style: textStyle)),
            Expanded(flex: 2, child: _StatusPill.fromStatus(order.status)),
          ],
        ),
      ),
    );
  }
}

class _OrderMobileTile extends StatelessWidget {
  const _OrderMobileTile({
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final _OrderCandidate order;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? NodeFlowColors.deepBlue
                : NodeFlowColors.softSlate,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.orderNo, style: textTheme.titleMedium),
                ),
                _StatusPill.fromStatus(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.route,
              style: textTheme.bodyMedium?.copyWith(
                color: NodeFlowColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${order.customer} · ${order.vehicleSpec} · ${order.weight}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePlanPanel extends StatelessWidget {
  const _RoutePlanPanel({required this.order, this.compact = false});

  final _OrderCandidate order;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.alt_route_rounded,
            title: '운송 계획',
            trailing: 'plan.transport_plans',
          ),
          const SizedBox(height: 16),
          if (compact)
            Column(
              children: [
                _RouteStopCard(
                  label: 'PICKUP',
                  name: order.pickup,
                  time: order.pickupTime,
                  icon: Icons.file_upload_rounded,
                ),
                const SizedBox(height: 10),
                _RouteStopCard(
                  label: 'DELIVERY',
                  name: order.delivery,
                  time: order.deliveryTime,
                  icon: Icons.file_download_rounded,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _RouteStopCard(
                    label: 'PICKUP',
                    name: order.pickup,
                    time: order.pickupTime,
                    icon: Icons.file_upload_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                const _RouteConnector(),
                const SizedBox(width: 12),
                Expanded(
                  child: _RouteStopCard(
                    label: 'DELIVERY',
                    name: order.delivery,
                    time: order.deliveryTime,
                    icon: Icons.file_download_rounded,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          _LoadSummary(order: order, compact: compact),
        ],
      ),
    );
  }
}

class _RouteStopCard extends StatelessWidget {
  const _RouteStopCard({
    required this.label,
    required this.name,
    required this.time,
    required this.icon,
  });

  final String label;
  final String name;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NodeFlowColors.softSlate),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: NodeFlowColors.deepBlue, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NodeFlowColors.deepBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  time,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Row(
        children: [
          Expanded(
            child: Container(height: 2, color: NodeFlowColors.softSlate),
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            color: NodeFlowColors.deepBlue,
          ),
          Expanded(
            child: Container(height: 2, color: NodeFlowColors.softSlate),
          ),
        ],
      ),
    );
  }
}

class _LoadSummary extends StatelessWidget {
  const _LoadSummary({required this.order, required this.compact});

  final _OrderCandidate order;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('차종', order.vehicleSpec),
      ('중량', order.weight),
      ('팔레트', order.pallets),
      ('온도', order.temperature),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        mainAxisExtent: 66,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: NodeFlowColors.softSlate),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.$1,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                item.$2,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: NodeFlowColors.ink,
                  fontWeight: FontWeight.w900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExistingDispatchPanel extends StatelessWidget {
  const _ExistingDispatchPanel({required this.order});

  final _OrderCandidate order;

  @override
  Widget build(BuildContext context) {
    final color = order.hasExistingDispatch
        ? NodeFlowColors.amber
        : NodeFlowColors.mint;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.rule_rounded,
            title: '기존 배차 확인',
            trailing: 'dsp.dispatches',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.20)),
                  ),
                  child: Icon(
                    order.hasExistingDispatch
                        ? Icons.warning_amber_rounded
                        : Icons.verified_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.hasExistingDispatch
                            ? '기존 배차가 있어 변경 검토가 필요합니다'
                            : '현재 오더 기준 중복 배차가 없습니다',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        order.hasExistingDispatch
                            ? '${order.existingDispatchNo} · ${order.existingVehicleNo} · ${order.existingDispatchStatus}'
                            : '${order.orderNo}는 신규 배차 생성 가능 상태입니다.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (order.hasExistingDispatch) ...[
            _CheckRow(
              label: '마지막 갱신',
              value: order.lastDispatchUpdate ?? '-',
              icon: Icons.update_rounded,
            ),
            _CheckRow(
              label: '처리 방향',
              value: '기존 배차 수정 또는 신규 배차 사유 확인',
              icon: Icons.route_rounded,
            ),
          ] else ...[
            const _CheckRow(
              label: '오더 상태',
              value: '계획/확정 오더만 배차 대상으로 표시',
              icon: Icons.assignment_turned_in_rounded,
            ),
            const _CheckRow(
              label: '배차 상태',
              value: 'dsp.dispatches 미생성',
              icon: Icons.playlist_add_check_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, color: NodeFlowColors.deepBlue, size: 18),
          const SizedBox(width: 9),
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NodeFlowColors.ink,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourcePanel extends StatelessWidget {
  const _ResourcePanel({
    required this.resources,
    required this.selectedIndex,
    required this.onSelected,
    this.compact = false,
  });

  final List<_DispatchResource> resources;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.manage_accounts_rounded,
            title: '배차 자원 매칭',
            trailing: 'dsp.assignments',
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < resources.length; index++) ...[
            _ResourceTile(
              resource: resources[index],
              selected: index == selectedIndex,
              onTap: () => onSelected(index),
            ),
            if (index != resources.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({
    required this.resource,
    required this.selected,
    required this.onTap,
  });

  final _DispatchResource resource;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? NodeFlowColors.mint : NodeFlowColors.softSlate,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: NodeFlowColors.deepBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          resource.vehicleNo,
                          style: textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _ScoreBadge(score: resource.score),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${resource.vehicleSpec} · ${resource.driverName} · ${resource.availability}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: NodeFlowColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${resource.carrierName} · ${resource.carrierGrade} · ${resource.capacity}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    resource.matchReason,
                    style: textTheme.bodyMedium?.copyWith(
                      color: NodeFlowColors.deepBlue,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final String score;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      alignment: Alignment.center,
      child: Text(
        score,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: NodeFlowColors.mint,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({
    required this.startController,
    required this.endController,
    required this.noteController,
    required this.status,
    required this.assignmentType,
    required this.onStatusChanged,
    required this.onAssignmentTypeChanged,
  });

  final TextEditingController startController;
  final TextEditingController endController;
  final TextEditingController noteController;
  final String status;
  final String assignmentType;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onAssignmentTypeChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.event_available_rounded,
            title: '스케줄 및 지시사항',
            trailing: 'dsp.dispatches',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: '배차 상태',
                    prefixIcon: Icon(Icons.flag_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'READY', child: Text('READY')),
                    DropdownMenuItem(value: 'SENT', child: Text('SENT')),
                    DropdownMenuItem(
                      value: 'CONFIRMED',
                      child: Text('CONFIRMED'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onStatusChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: assignmentType,
                  decoration: const InputDecoration(
                    labelText: '배정 방식',
                    prefixIcon: Icon(Icons.hub_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'DIRECT', child: Text('직배정')),
                    DropdownMenuItem(value: 'BID', child: Text('입찰')),
                    DropdownMenuItem(value: 'AUTO', child: Text('자동추천')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onAssignmentTypeChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: startController,
            decoration: const InputDecoration(
              labelText: '예정 시작',
              prefixIcon: Icon(Icons.play_circle_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: endController,
            decoration: const InputDecoration(
              labelText: '예정 종료',
              prefixIcon: Icon(Icons.flag_circle_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '배차 메모',
              prefixIcon: Icon(Icons.notes_rounded),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.order,
    required this.resource,
    required this.dispatchNo,
    required this.status,
    required this.assignmentType,
    required this.onSubmit,
  });

  final _OrderCandidate order;
  final _DispatchResource resource;
  final String dispatchNo;
  final String status;
  final String assignmentType;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.fact_check_rounded,
            title: '생성 검토',
            trailing: 'READY',
          ),
          const SizedBox(height: 14),
          _ReviewNotice(hasExistingDispatch: order.hasExistingDispatch),
          const SizedBox(height: 13),
          _ReviewRow(label: '배차번호', value: dispatchNo),
          _ReviewRow(label: '오더', value: order.orderNo),
          _ReviewRow(label: '운송계획', value: order.planNo),
          _ReviewRow(label: '차량', value: resource.vehicleNo),
          _ReviewRow(label: '기사', value: resource.driverName),
          _ReviewRow(label: '상태', value: status),
          _ReviewRow(label: '방식', value: assignmentType),
          _ReviewRow(label: '매출', value: order.salesAmount),
          _ReviewRow(label: '매입', value: order.purchaseAmount),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.send_rounded),
            label: Text(order.hasExistingDispatch ? '배차 변경 검토' : '배차 생성'),
          ),
        ],
      ),
    );
  }
}

class _ReviewNotice extends StatelessWidget {
  const _ReviewNotice({required this.hasExistingDispatch});

  final bool hasExistingDispatch;

  @override
  Widget build(BuildContext context) {
    final color = hasExistingDispatch
        ? NodeFlowColors.amber
        : NodeFlowColors.mint;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(
            hasExistingDispatch
                ? Icons.info_rounded
                : Icons.check_circle_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              hasExistingDispatch
                  ? '기존 배차가 있어 생성 전 운영자 확인이 필요합니다.'
                  : '선택한 오더와 자원으로 신규 배차를 생성할 수 있습니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NodeFlowColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NodeFlowColors.ink,
                fontWeight: FontWeight.w900,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCandidate {
  const _OrderCandidate({
    required this.orderNo,
    required this.planNo,
    required this.customer,
    required this.route,
    required this.pickup,
    required this.delivery,
    required this.pickupTime,
    required this.deliveryTime,
    required this.vehicleSpec,
    required this.weight,
    required this.pallets,
    required this.temperature,
    required this.status,
    required this.salesAmount,
    required this.purchaseAmount,
    this.existingDispatchNo,
    this.existingDispatchStatus,
    this.existingVehicleNo,
    this.lastDispatchUpdate,
  });

  final String orderNo;
  final String planNo;
  final String customer;
  final String route;
  final String pickup;
  final String delivery;
  final String pickupTime;
  final String deliveryTime;
  final String vehicleSpec;
  final String weight;
  final String pallets;
  final String temperature;
  final String status;
  final String salesAmount;
  final String purchaseAmount;
  final String? existingDispatchNo;
  final String? existingDispatchStatus;
  final String? existingVehicleNo;
  final String? lastDispatchUpdate;

  bool get hasExistingDispatch => existingDispatchNo != null;
}

class _DispatchResource {
  const _DispatchResource({
    required this.vehicleNo,
    required this.vehicleSpec,
    required this.driverName,
    required this.phone,
    required this.carrierName,
    required this.score,
    required this.carrierGrade,
    required this.capacity,
    required this.availability,
    required this.matchReason,
  });

  final String vehicleNo;
  final String vehicleSpec;
  final String driverName;
  final String phone;
  final String carrierName;
  final String score;
  final String carrierGrade;
  final String capacity;
  final String availability;
  final String matchReason;
}

const _orders = [
  _OrderCandidate(
    orderNo: 'ORD000100',
    planNo: 'PLN000100',
    customer: 'Test Customer 200',
    route: '서울 강서 → 부산 사상',
    pickup: '서울 강서 물류센터',
    delivery: '부산 사상 터미널',
    pickupTime: '2026-04-29 14:00',
    deliveryTime: '2026-04-29 18:30',
    vehicleSpec: 'WING 5톤',
    weight: '600kg',
    pallets: '1 PLT',
    temperature: '상온',
    status: 'CONFIRMED',
    salesAmount: '520,000원',
    purchaseAmount: '390,000원',
    existingDispatchNo: 'DSP000100',
    existingDispatchStatus: 'SENT',
    existingVehicleNo: 'TEST-0100',
    lastDispatchUpdate: '2026-04-29 10:42',
  ),
  _OrderCandidate(
    orderNo: 'ORD000099',
    planNo: 'PLN000099',
    customer: 'Test Customer 199',
    route: '인천 남동 → 대전 유성',
    pickup: '인천 남동 허브',
    delivery: '대전 유성 센터',
    pickupTime: '2026-04-29 15:00',
    deliveryTime: '2026-04-29 19:10',
    vehicleSpec: 'CARGO 2.5톤',
    weight: '595kg',
    pallets: '10 PLT',
    temperature: '상온',
    status: 'PLANNED',
    salesAmount: '410,000원',
    purchaseAmount: '305,000원',
  ),
  _OrderCandidate(
    orderNo: 'ORD000098',
    planNo: 'PLN000098',
    customer: 'Test Customer 198',
    route: '평택 포승 → 광주 하남',
    pickup: '평택 포승 CY',
    delivery: '광주 하남 창고',
    pickupTime: '2026-04-29 16:00',
    deliveryTime: '2026-04-29 21:00',
    vehicleSpec: 'WING 5톤',
    weight: '590kg',
    pallets: '9 PLT',
    temperature: '상온',
    status: 'READY',
    salesAmount: '455,000원',
    purchaseAmount: '330,000원',
  ),
];

const _resources = [
  _DispatchResource(
    vehicleNo: 'TEST-0098',
    vehicleSpec: 'CARGO 5톤',
    driverName: 'Test Driver 98',
    phone: '010-3000-0098',
    carrierName: 'Test Carrier 198',
    score: '94',
    carrierGrade: 'A등급',
    capacity: '적재 5.0톤',
    availability: '즉시 투입',
    matchReason: '톤급과 상차 권역 일치',
  ),
  _DispatchResource(
    vehicleNo: 'TEST-0097',
    vehicleSpec: 'WING 2.5톤',
    driverName: 'Test Driver 97',
    phone: '010-3000-0097',
    carrierName: 'Test Carrier 197',
    score: '89',
    carrierGrade: 'B등급',
    capacity: '적재 2.5톤',
    availability: '30분 내 투입',
    matchReason: '소형 긴급 배차 적합',
  ),
  _DispatchResource(
    vehicleNo: 'TEST-0099',
    vehicleSpec: 'TOP 11톤',
    driverName: 'Test Driver 99',
    phone: '010-3000-0099',
    carrierName: 'Test Carrier 199',
    score: '83',
    carrierGrade: 'A등급',
    capacity: '적재 11.0톤',
    availability: '회차 후 투입',
    matchReason: '장거리 구간 운행 이력 보유',
  ),
];

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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  factory _StatusPill.fromStatus(String status) {
    final color = switch (status) {
      'CONFIRMED' || 'READY' || '운송중' => NodeFlowColors.mint,
      'PLANNED' || '상차' => const Color(0xFF2563EB),
      '배차중' => NodeFlowColors.amber,
      _ => NodeFlowColors.deepBlue,
    };
    return _StatusPill(
      label: status,
      color: color,
      background: color.withValues(alpha: 0.10),
    );
  }

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

class _IconButtonFrame extends StatelessWidget {
  const _IconButtonFrame({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

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
            foregroundColor: NodeFlowColors.deepBlue,
            side: const BorderSide(color: NodeFlowColors.softSlate),
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
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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

class _BrandCompact extends StatelessWidget {
  const _BrandCompact();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/brand/nodeflow_mark.png',
            width: 38,
            height: 38,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NodeFlow',
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Dispatch Console',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
