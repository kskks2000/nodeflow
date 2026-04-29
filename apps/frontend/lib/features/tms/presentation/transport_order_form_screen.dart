import 'package:flutter/material.dart';

import '../../../app/nodeflow_theme.dart';
import '../../auth/domain/auth_models.dart';
import '../data/transport_order_api_client.dart';
import '../domain/transport_order_models.dart';

class TransportOrderFormScreen extends StatefulWidget {
  const TransportOrderFormScreen({super.key});

  @override
  State<TransportOrderFormScreen> createState() =>
      _TransportOrderFormScreenState();
}

class _TransportOrderFormScreenState extends State<TransportOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = TransportOrderApiClient();

  final _orderNoController = TextEditingController();
  final _customerController = TextEditingController(text: 'KCASTLE 부산센터');
  final _customerOrderNoController = TextEditingController(
    text: 'KC-REQ-240429',
  );
  final _orderDateController = TextEditingController(text: '2026-04-29');
  final _pickupTimeController = TextEditingController(text: '2026-04-29 09:00');
  final _deliveryTimeController = TextEditingController(
    text: '2026-04-29 16:00',
  );
  final _pickupNameController = TextEditingController(text: '서울 강서 물류센터');
  final _pickupAddressController = TextEditingController(
    text: '서울특별시 강서구 공항대로 247',
  );
  final _pickupContactController = TextEditingController(text: '상차 담당자');
  final _pickupPhoneController = TextEditingController(text: '010-1000-2401');
  final _deliveryNameController = TextEditingController(text: '부산 사상 터미널');
  final _deliveryAddressController = TextEditingController(
    text: '부산광역시 사상구 낙동대로 910',
  );
  final _deliveryContactController = TextEditingController(text: '하차 담당자');
  final _deliveryPhoneController = TextEditingController(text: '010-2000-2401');
  final _itemNameController = TextEditingController(text: '일반 공산품');
  final _qtyController = TextEditingController(text: '1');
  final _weightController = TextEditingController(text: '600');
  final _volumeController = TextEditingController(text: '3.2');
  final _palletController = TextEditingController(text: '1');
  final _tonClassController = TextEditingController(text: '5');
  final _instructionController = TextEditingController(text: '상차 전 고객 연락 필수');

  LoginResponse? _session;
  bool _didReadArguments = false;
  bool _isExclusive = false;
  bool _isEmergency = false;
  bool _isSubmitting = false;
  String _orderType = 'ONE_WAY';
  String _serviceLevel = 'STANDARD';
  String _vehicleType = 'WING';
  String _temperatureType = 'AMBIENT';
  String? _message;
  bool _messageIsError = false;
  TransportOrderResponse? _createdOrder;

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
    } else if (arguments is Map && arguments['session'] is LoginResponse) {
      _session = arguments['session'] as LoginResponse;
    }
  }

  @override
  void dispose() {
    _apiClient.close();
    _orderNoController.dispose();
    _customerController.dispose();
    _customerOrderNoController.dispose();
    _orderDateController.dispose();
    _pickupTimeController.dispose();
    _deliveryTimeController.dispose();
    _pickupNameController.dispose();
    _pickupAddressController.dispose();
    _pickupContactController.dispose();
    _pickupPhoneController.dispose();
    _deliveryNameController.dispose();
    _deliveryAddressController.dispose();
    _deliveryContactController.dispose();
    _deliveryPhoneController.dispose();
    _itemNameController.dispose();
    _qtyController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _palletController.dispose();
    _tonClassController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1120;
            return Column(
              children: [
                _OrderTopBar(wide: wide, session: _session),
                Expanded(
                  child: Form(
                    key: _formKey,
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
                            wide: wide,
                            orderNoController: _orderNoController,
                          ),
                          const SizedBox(height: 16),
                          _TmsOrderProcess(wide: wide),
                          const SizedBox(height: 16),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    children: [
                                      _BasicOrderPanel(
                                        customerController: _customerController,
                                        customerOrderNoController:
                                            _customerOrderNoController,
                                        orderDateController:
                                            _orderDateController,
                                        orderType: _orderType,
                                        serviceLevel: _serviceLevel,
                                        onOrderTypeChanged: (value) {
                                          setState(() => _orderType = value);
                                        },
                                        onServiceLevelChanged: (value) {
                                          setState(() => _serviceLevel = value);
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _StopPanel(
                                        pickupNameController:
                                            _pickupNameController,
                                        pickupAddressController:
                                            _pickupAddressController,
                                        pickupContactController:
                                            _pickupContactController,
                                        pickupPhoneController:
                                            _pickupPhoneController,
                                        pickupTimeController:
                                            _pickupTimeController,
                                        deliveryNameController:
                                            _deliveryNameController,
                                        deliveryAddressController:
                                            _deliveryAddressController,
                                        deliveryContactController:
                                            _deliveryContactController,
                                        deliveryPhoneController:
                                            _deliveryPhoneController,
                                        deliveryTimeController:
                                            _deliveryTimeController,
                                        compact: false,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _CargoRequirementPanel(
                                        itemNameController: _itemNameController,
                                        qtyController: _qtyController,
                                        weightController: _weightController,
                                        volumeController: _volumeController,
                                        palletController: _palletController,
                                        tonClassController: _tonClassController,
                                        instructionController:
                                            _instructionController,
                                        vehicleType: _vehicleType,
                                        temperatureType: _temperatureType,
                                        isExclusive: _isExclusive,
                                        isEmergency: _isEmergency,
                                        onVehicleTypeChanged: (value) {
                                          setState(() => _vehicleType = value);
                                        },
                                        onTemperatureTypeChanged: (value) {
                                          setState(
                                            () => _temperatureType = value,
                                          );
                                        },
                                        onExclusiveChanged: (value) {
                                          setState(
                                            () => _isExclusive = value ?? false,
                                          );
                                        },
                                        onEmergencyChanged: (value) {
                                          setState(
                                            () => _isEmergency = value ?? false,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _OrderReviewPanel(
                                        customerName: _customerController.text
                                            .trim(),
                                        pickupName: _pickupNameController.text
                                            .trim(),
                                        deliveryName: _deliveryNameController
                                            .text
                                            .trim(),
                                        vehicleType: _vehicleType,
                                        tonClass: _tonClassController.text
                                            .trim(),
                                        weight: _weightController.text.trim(),
                                        statusText:
                                            _createdOrder?.statusCode ?? '작성중',
                                        message: _message,
                                        messageIsError: _messageIsError,
                                        createdOrder: _createdOrder,
                                        isSubmitting: _isSubmitting,
                                        onSaveDraft: () =>
                                            _submit(confirm: false),
                                        onConfirm: () => _submit(confirm: true),
                                        onDispatch: _createdOrder == null
                                            ? null
                                            : () => Navigator.of(context)
                                                  .pushNamed(
                                                    '/dispatch/new',
                                                    arguments: _session,
                                                  ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _BasicOrderPanel(
                                  customerController: _customerController,
                                  customerOrderNoController:
                                      _customerOrderNoController,
                                  orderDateController: _orderDateController,
                                  orderType: _orderType,
                                  serviceLevel: _serviceLevel,
                                  onOrderTypeChanged: (value) {
                                    setState(() => _orderType = value);
                                  },
                                  onServiceLevelChanged: (value) {
                                    setState(() => _serviceLevel = value);
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StopPanel(
                                  pickupNameController: _pickupNameController,
                                  pickupAddressController:
                                      _pickupAddressController,
                                  pickupContactController:
                                      _pickupContactController,
                                  pickupPhoneController: _pickupPhoneController,
                                  pickupTimeController: _pickupTimeController,
                                  deliveryNameController:
                                      _deliveryNameController,
                                  deliveryAddressController:
                                      _deliveryAddressController,
                                  deliveryContactController:
                                      _deliveryContactController,
                                  deliveryPhoneController:
                                      _deliveryPhoneController,
                                  deliveryTimeController:
                                      _deliveryTimeController,
                                  compact: true,
                                ),
                                const SizedBox(height: 16),
                                _CargoRequirementPanel(
                                  itemNameController: _itemNameController,
                                  qtyController: _qtyController,
                                  weightController: _weightController,
                                  volumeController: _volumeController,
                                  palletController: _palletController,
                                  tonClassController: _tonClassController,
                                  instructionController: _instructionController,
                                  vehicleType: _vehicleType,
                                  temperatureType: _temperatureType,
                                  isExclusive: _isExclusive,
                                  isEmergency: _isEmergency,
                                  onVehicleTypeChanged: (value) {
                                    setState(() => _vehicleType = value);
                                  },
                                  onTemperatureTypeChanged: (value) {
                                    setState(() => _temperatureType = value);
                                  },
                                  onExclusiveChanged: (value) {
                                    setState(
                                      () => _isExclusive = value ?? false,
                                    );
                                  },
                                  onEmergencyChanged: (value) {
                                    setState(
                                      () => _isEmergency = value ?? false,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _OrderReviewPanel(
                                  customerName: _customerController.text.trim(),
                                  pickupName: _pickupNameController.text.trim(),
                                  deliveryName: _deliveryNameController.text
                                      .trim(),
                                  vehicleType: _vehicleType,
                                  tonClass: _tonClassController.text.trim(),
                                  weight: _weightController.text.trim(),
                                  statusText:
                                      _createdOrder?.statusCode ?? '작성중',
                                  message: _message,
                                  messageIsError: _messageIsError,
                                  createdOrder: _createdOrder,
                                  isSubmitting: _isSubmitting,
                                  onSaveDraft: () => _submit(confirm: false),
                                  onConfirm: () => _submit(confirm: true),
                                  onDispatch: _createdOrder == null
                                      ? null
                                      : () => Navigator.of(context).pushNamed(
                                          '/dispatch/new',
                                          arguments: _session,
                                        ),
                                ),
                              ],
                            ),
                        ],
                      ),
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

  Future<void> _submit({required bool confirm}) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) {
      return;
    }

    final session = _session;
    if (session == null) {
      setState(() {
        _message = '로그인 세션을 찾을 수 없습니다. 다시 로그인한 뒤 등록해 주세요.';
        _messageIsError = true;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final response = await _apiClient.createOrder(
        _buildRequest(confirm: confirm),
        accessToken: session.accessToken,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _createdOrder = response;
        _orderNoController.text = response.orderNo;
        _message = '${response.orderNo} 운송오더가 ${confirm ? '확정' : '임시저장'}되었습니다.';
        _messageIsError = false;
        _isSubmitting = false;
      });
    } on TransportOrderFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error.message;
        _messageIsError = true;
        _isSubmitting = false;
      });
    }
  }

  TransportOrderCreateRequest _buildRequest({required bool confirm}) {
    final pickupDateTime = _parseDateTime(_pickupTimeController.text);
    final deliveryDateTime = _parseDateTime(_deliveryTimeController.text);
    final qty = _number(_qtyController);
    final weight = _number(_weightController);
    final volume = _number(_volumeController);
    final pallets = _number(_palletController);

    return TransportOrderCreateRequest(
      orderNo: _optionalText(_orderNoController),
      customerName: _customerController.text.trim(),
      customerOrderNo: _optionalText(_customerOrderNoController),
      orderType: _orderType,
      serviceLevel: _serviceLevel,
      confirm: confirm,
      orderDate: _parseDate(_orderDateController.text) ?? DateTime.now(),
      requestedPickupAt: pickupDateTime,
      requestedDeliveryAt: deliveryDateTime,
      requiredVehicleType: _vehicleType,
      requiredTonClass: _numberOrNull(_tonClassController),
      temperatureType: _temperatureType,
      isExclusive: _isExclusive,
      isEmergency: _isEmergency,
      totalQty: qty,
      totalWeightKg: weight,
      totalVolumeCbm: volume,
      totalPallets: pallets,
      specialInstructions: _optionalText(_instructionController),
      pickup: TransportOrderStopRequest(
        locationName: _pickupNameController.text.trim(),
        address1: _pickupAddressController.text.trim(),
        contactName: _optionalText(_pickupContactController),
        contactPhone: _optionalText(_pickupPhoneController),
        requestedArrivalFrom: pickupDateTime,
        requestedArrivalTo: pickupDateTime,
        workNote: '상차',
      ),
      delivery: TransportOrderStopRequest(
        locationName: _deliveryNameController.text.trim(),
        address1: _deliveryAddressController.text.trim(),
        contactName: _optionalText(_deliveryContactController),
        contactPhone: _optionalText(_deliveryPhoneController),
        requestedArrivalFrom: deliveryDateTime,
        requestedArrivalTo: deliveryDateTime,
        workNote: '하차',
      ),
      item: TransportOrderItemRequest(
        itemName: _itemNameController.text.trim(),
        qty: qty,
        weightKg: weight,
        volumeCbm: volume,
        pallets: pallets,
        temperatureType: _temperatureType,
      ),
    );
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  double _number(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '')) ?? 0;
  }

  double? _numberOrNull(TextEditingController controller) {
    final value = controller.text.trim().replaceAll(',', '');
    if (value.isEmpty) {
      return null;
    }
    return double.tryParse(value);
  }

  DateTime? _parseDate(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return DateTime.tryParse(normalized);
  }

  DateTime? _parseDateTime(String value) {
    final normalized = value.trim().replaceFirst(' ', 'T');
    if (normalized.isEmpty) {
      return null;
    }
    return DateTime.tryParse(normalized);
  }
}

class _OrderTopBar extends StatelessWidget {
  const _OrderTopBar({required this.wide, required this.session});

  final bool wide;
  final LoginResponse? session;

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
                navigator.pushReplacementNamed('/main', arguments: session);
              }
            },
          ),
          const SizedBox(width: 12),
          const Expanded(child: _BrandCompact()),
          if (wide) ...[
            const _TopBarChip(
              icon: Icons.table_rows_rounded,
              label: 'ord.orders',
            ),
            const SizedBox(width: 8),
            const _TopBarChip(
              icon: Icons.pin_drop_rounded,
              label: 'ord.order_stops',
            ),
            const SizedBox(width: 8),
            const _TopBarChip(
              icon: Icons.inventory_2_rounded,
              label: 'ord.order_items',
            ),
          ],
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.wide, required this.orderNoController});

  final bool wide;
  final TextEditingController orderNoController;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: EdgeInsets.all(wide ? 22 : 18),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: _PageTitle()),
                const SizedBox(width: 16),
                SizedBox(
                  width: 280,
                  child: TextFormField(
                    controller: orderNoController,
                    decoration: const InputDecoration(
                      labelText: '오더번호',
                      hintText: '자동 생성',
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
                TextFormField(
                  controller: orderNoController,
                  decoration: const InputDecoration(
                    labelText: '오더번호',
                    hintText: '자동 생성',
                    prefixIcon: Icon(Icons.confirmation_number_rounded),
                  ),
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
              label: '운송오더',
              color: NodeFlowColors.deepBlue,
              background: Color(0xFFEFF6FF),
            ),
            _StatusPill(
              label: '등록 및 확정',
              color: NodeFlowColors.mint,
              background: Color(0xFFECFDF5),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          '운송오더 등록 및 확정',
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '수기 접수 오더를 등록하고 확정하면 편성, 운송사 배정, 배차 단계로 이어집니다.',
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TmsOrderProcess extends StatelessWidget {
  const _TmsOrderProcess({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final steps = [
      const _ProcessStepData('1', '오더 등록/확정', Icons.assignment_rounded),
      const _ProcessStepData('2', '편성', Icons.account_tree_rounded),
      const _ProcessStepData('3', '운송사 배정', Icons.handshake_rounded),
      const _ProcessStepData('4', '배차', Icons.route_rounded),
      const _ProcessStepData('5', '실행', Icons.local_shipping_rounded),
      const _ProcessStepData('6', '실적', Icons.fact_check_rounded),
      const _ProcessStepData('7', '정산', Icons.payments_rounded),
    ];

    return _Panel(
      padding: const EdgeInsets.all(14),
      child: wide
          ? Row(
              children: [
                for (var index = 0; index < steps.length; index++) ...[
                  Expanded(
                    child: _ProcessStep(data: steps[index], active: index == 0),
                  ),
                  if (index != steps.length - 1) const SizedBox(width: 8),
                ],
              ],
            )
          : GridView.builder(
              itemCount: steps.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: 68,
              ),
              itemBuilder: (context, index) {
                return _ProcessStep(data: steps[index], active: index == 0);
              },
            ),
    );
  }
}

class _ProcessStepData {
  const _ProcessStepData(this.number, this.label, this.icon);

  final String number;
  final String label;
  final IconData icon;
}

class _ProcessStep extends StatelessWidget {
  const _ProcessStep({required this.data, required this.active});

  final _ProcessStepData data;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? NodeFlowColors.deepBlue : NodeFlowColors.slate;
    return Container(
      height: 68,
      padding: const EdgeInsets.all(10),
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
          Icon(data.icon, color: color, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${data.number}. ${data.label}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: active ? NodeFlowColors.deepBlue : NodeFlowColors.ink,
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

class _BasicOrderPanel extends StatelessWidget {
  const _BasicOrderPanel({
    required this.customerController,
    required this.customerOrderNoController,
    required this.orderDateController,
    required this.orderType,
    required this.serviceLevel,
    required this.onOrderTypeChanged,
    required this.onServiceLevelChanged,
  });

  final TextEditingController customerController;
  final TextEditingController customerOrderNoController;
  final TextEditingController orderDateController;
  final String orderType;
  final String serviceLevel;
  final ValueChanged<String> onOrderTypeChanged;
  final ValueChanged<String> onServiceLevelChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.assignment_rounded,
            title: '기본 정보',
            trailing: 'ord.orders',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: customerController,
            decoration: const InputDecoration(
              labelText: '화주/고객사',
              prefixIcon: Icon(Icons.business_rounded),
            ),
            validator: _requiredValidator('화주/고객사를 입력해 주세요.'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: customerOrderNoController,
                  decoration: const InputDecoration(
                    labelText: '고객 오더번호',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: orderDateController,
                  decoration: const InputDecoration(
                    labelText: '오더일자',
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: Icon(Icons.today_rounded),
                  ),
                  validator: _requiredValidator('오더일자를 입력해 주세요.'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: orderType,
                  decoration: const InputDecoration(
                    labelText: '오더 유형',
                    prefixIcon: Icon(Icons.compare_arrows_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ONE_WAY', child: Text('편도')),
                    DropdownMenuItem(value: 'ROUND', child: Text('왕복')),
                    DropdownMenuItem(value: 'MILK_RUN', child: Text('순회')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onOrderTypeChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: serviceLevel,
                  decoration: const InputDecoration(
                    labelText: '서비스 레벨',
                    prefixIcon: Icon(Icons.workspace_premium_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'STANDARD', child: Text('일반')),
                    DropdownMenuItem(value: 'EXPRESS', child: Text('긴급')),
                    DropdownMenuItem(value: 'RESERVED', child: Text('예약')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onServiceLevelChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StopPanel extends StatelessWidget {
  const _StopPanel({
    required this.pickupNameController,
    required this.pickupAddressController,
    required this.pickupContactController,
    required this.pickupPhoneController,
    required this.pickupTimeController,
    required this.deliveryNameController,
    required this.deliveryAddressController,
    required this.deliveryContactController,
    required this.deliveryPhoneController,
    required this.deliveryTimeController,
    required this.compact,
  });

  final TextEditingController pickupNameController;
  final TextEditingController pickupAddressController;
  final TextEditingController pickupContactController;
  final TextEditingController pickupPhoneController;
  final TextEditingController pickupTimeController;
  final TextEditingController deliveryNameController;
  final TextEditingController deliveryAddressController;
  final TextEditingController deliveryContactController;
  final TextEditingController deliveryPhoneController;
  final TextEditingController deliveryTimeController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.pin_drop_rounded,
            title: '상하차 정보',
            trailing: 'ord.order_stops',
          ),
          const SizedBox(height: 16),
          if (compact)
            Column(
              children: [
                _StopEditor(
                  title: '상차지',
                  icon: Icons.file_upload_rounded,
                  nameController: pickupNameController,
                  addressController: pickupAddressController,
                  contactController: pickupContactController,
                  phoneController: pickupPhoneController,
                  timeController: pickupTimeController,
                ),
                const SizedBox(height: 12),
                _StopEditor(
                  title: '하차지',
                  icon: Icons.file_download_rounded,
                  nameController: deliveryNameController,
                  addressController: deliveryAddressController,
                  contactController: deliveryContactController,
                  phoneController: deliveryPhoneController,
                  timeController: deliveryTimeController,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StopEditor(
                    title: '상차지',
                    icon: Icons.file_upload_rounded,
                    nameController: pickupNameController,
                    addressController: pickupAddressController,
                    contactController: pickupContactController,
                    phoneController: pickupPhoneController,
                    timeController: pickupTimeController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StopEditor(
                    title: '하차지',
                    icon: Icons.file_download_rounded,
                    nameController: deliveryNameController,
                    addressController: deliveryAddressController,
                    contactController: deliveryContactController,
                    phoneController: deliveryPhoneController,
                    timeController: deliveryTimeController,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StopEditor extends StatelessWidget {
  const _StopEditor({
    required this.title,
    required this.icon,
    required this.nameController,
    required this.addressController,
    required this.contactController,
    required this.phoneController,
    required this.timeController,
  });

  final String title;
  final IconData icon;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController contactController;
  final TextEditingController phoneController;
  final TextEditingController timeController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NodeFlowColors.softSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: NodeFlowColors.deepBlue, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: '장소명'),
            validator: _requiredValidator('장소명을 입력해 주세요.'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: addressController,
            decoration: const InputDecoration(labelText: '주소'),
            validator: _requiredValidator('주소를 입력해 주세요.'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: timeController,
            decoration: const InputDecoration(
              labelText: '요청 일시',
              hintText: 'YYYY-MM-DD HH:mm',
            ),
            validator: _requiredValidator('요청 일시를 입력해 주세요.'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: '담당자'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: '연락처'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CargoRequirementPanel extends StatelessWidget {
  const _CargoRequirementPanel({
    required this.itemNameController,
    required this.qtyController,
    required this.weightController,
    required this.volumeController,
    required this.palletController,
    required this.tonClassController,
    required this.instructionController,
    required this.vehicleType,
    required this.temperatureType,
    required this.isExclusive,
    required this.isEmergency,
    required this.onVehicleTypeChanged,
    required this.onTemperatureTypeChanged,
    required this.onExclusiveChanged,
    required this.onEmergencyChanged,
  });

  final TextEditingController itemNameController;
  final TextEditingController qtyController;
  final TextEditingController weightController;
  final TextEditingController volumeController;
  final TextEditingController palletController;
  final TextEditingController tonClassController;
  final TextEditingController instructionController;
  final String vehicleType;
  final String temperatureType;
  final bool isExclusive;
  final bool isEmergency;
  final ValueChanged<String> onVehicleTypeChanged;
  final ValueChanged<String> onTemperatureTypeChanged;
  final ValueChanged<bool?> onExclusiveChanged;
  final ValueChanged<bool?> onEmergencyChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.inventory_2_rounded,
            title: '화물 및 차량 조건',
            trailing: 'ord.order_items',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: itemNameController,
            decoration: const InputDecoration(
              labelText: '화물명',
              prefixIcon: Icon(Icons.inventory_rounded),
            ),
            validator: _requiredValidator('화물명을 입력해 주세요.'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '수량'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '중량 kg'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: volumeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CBM'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: palletController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'PLT'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: vehicleType,
                  decoration: const InputDecoration(
                    labelText: '차종',
                    prefixIcon: Icon(Icons.local_shipping_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CARGO', child: Text('카고')),
                    DropdownMenuItem(value: 'WING', child: Text('윙바디')),
                    DropdownMenuItem(value: 'TOP', child: Text('탑차')),
                    DropdownMenuItem(value: 'REFRIGERATED', child: Text('냉장')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onVehicleTypeChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: tonClassController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '톤급'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: temperatureType,
            decoration: const InputDecoration(
              labelText: '온도 조건',
              prefixIcon: Icon(Icons.device_thermostat_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'AMBIENT', child: Text('상온')),
              DropdownMenuItem(value: 'CHILLED', child: Text('냉장')),
              DropdownMenuItem(value: 'FROZEN', child: Text('냉동')),
            ],
            onChanged: (value) {
              if (value != null) {
                onTemperatureTypeChanged(value);
              }
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: isExclusive,
                  onChanged: onExclusiveChanged,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('독차'),
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  value: isEmergency,
                  onChanged: onEmergencyChanged,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('긴급'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: instructionController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '특이사항',
              prefixIcon: Icon(Icons.notes_rounded),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderReviewPanel extends StatelessWidget {
  const _OrderReviewPanel({
    required this.customerName,
    required this.pickupName,
    required this.deliveryName,
    required this.vehicleType,
    required this.tonClass,
    required this.weight,
    required this.statusText,
    required this.message,
    required this.messageIsError,
    required this.createdOrder,
    required this.isSubmitting,
    required this.onSaveDraft,
    required this.onConfirm,
    required this.onDispatch,
  });

  final String customerName;
  final String pickupName;
  final String deliveryName;
  final String vehicleType;
  final String tonClass;
  final String weight;
  final String statusText;
  final String? message;
  final bool messageIsError;
  final TransportOrderResponse? createdOrder;
  final bool isSubmitting;
  final VoidCallback onSaveDraft;
  final VoidCallback onConfirm;
  final VoidCallback? onDispatch;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.fact_check_rounded,
            title: '등록 검토',
            trailing: 'CONFIRM',
          ),
          const SizedBox(height: 14),
          _ReviewStatus(
            statusText: statusText,
            confirmed: createdOrder != null,
          ),
          const SizedBox(height: 14),
          _ReviewRow(
            label: '화주',
            value: customerName.isEmpty ? '-' : customerName,
          ),
          _ReviewRow(label: '상차', value: pickupName.isEmpty ? '-' : pickupName),
          _ReviewRow(
            label: '하차',
            value: deliveryName.isEmpty ? '-' : deliveryName,
          ),
          _ReviewRow(
            label: '차량',
            value: '$vehicleType ${tonClass.isEmpty ? '' : '$tonClass톤'}',
          ),
          _ReviewRow(label: '중량', value: weight.isEmpty ? '-' : '${weight}kg'),
          if (createdOrder != null)
            _ReviewRow(label: '오더번호', value: createdOrder!.orderNo),
          if (message != null) ...[
            const SizedBox(height: 10),
            _MessageBox(message: message!, isError: messageIsError),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSubmitting ? null : onSaveDraft,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('임시저장'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NodeFlowColors.deepBlue,
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: NodeFlowColors.softSlate),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onConfirm,
                  icon: isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_rounded),
                  label: Text(isSubmitting ? '등록 중' : '등록 및 확정'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: onDispatch,
            icon: const Icon(Icons.add_road_rounded),
            label: const Text('확정 오더로 신규 배차'),
            style: ElevatedButton.styleFrom(
              backgroundColor: NodeFlowColors.mint,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStatus extends StatelessWidget {
  const _ReviewStatus({required this.statusText, required this.confirmed});

  final String statusText;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    final color = confirmed ? NodeFlowColors.mint : NodeFlowColors.deepBlue;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(
            confirmed ? Icons.check_circle_rounded : Icons.edit_note_rounded,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              confirmed ? '오더가 등록되었습니다' : '입력값 검토 후 등록할 수 있습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NodeFlowColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _StatusPill(
            label: statusText,
            color: color,
            background: Colors.white,
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
            width: 72,
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

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB91C1C) : NodeFlowColors.mint;
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
            isError ? Icons.error_rounded : Icons.verified_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isError ? color : NodeFlowColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? Function(String?) _requiredValidator(String message) {
  return (value) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  };
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
              'Order Console',
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
