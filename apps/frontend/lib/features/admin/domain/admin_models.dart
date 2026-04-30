class AdminEntityField {
  const AdminEntityField({
    required this.key,
    required this.label,
    required this.fieldType,
    required this.required,
    required this.readOnly,
    required this.listVisible,
    required this.formVisible,
    this.optionEntity,
    this.helpText,
  });

  final String key;
  final String label;
  final String fieldType;
  final bool required;
  final bool readOnly;
  final bool listVisible;
  final bool formVisible;
  final String? optionEntity;
  final String? helpText;

  factory AdminEntityField.fromJson(Map<String, Object?> json) {
    return AdminEntityField(
      key: json['key'] as String,
      label: json['label'] as String,
      fieldType: json['field_type'] as String? ?? 'text',
      required: json['required'] as bool? ?? false,
      readOnly: json['read_only'] as bool? ?? false,
      listVisible: json['list_visible'] as bool? ?? true,
      formVisible: json['form_visible'] as bool? ?? true,
      optionEntity: json['option_entity'] as String?,
      helpText: json['help_text'] as String?,
    );
  }
}

class AdminEntityDefinition {
  const AdminEntityDefinition({
    required this.key,
    required this.label,
    required this.group,
    required this.description,
    required this.idField,
    required this.titleField,
    required this.fields,
    required this.supportsCreate,
    required this.supportsUpdate,
    required this.supportsDelete,
    required this.supportsImport,
  });

  final String key;
  final String label;
  final String group;
  final String description;
  final String idField;
  final String titleField;
  final List<AdminEntityField> fields;
  final bool supportsCreate;
  final bool supportsUpdate;
  final bool supportsDelete;
  final bool supportsImport;

  List<AdminEntityField> get listFields =>
      fields.where((field) => field.listVisible).toList(growable: false);

  List<AdminEntityField> get formFields => fields
      .where((field) => field.formVisible && !field.readOnly)
      .toList(growable: false);

  factory AdminEntityDefinition.fromJson(Map<String, Object?> json) {
    return AdminEntityDefinition(
      key: json['key'] as String,
      label: json['label'] as String,
      group: json['group'] as String,
      description: json['description'] as String? ?? '',
      idField: json['id_field'] as String,
      titleField: json['title_field'] as String,
      fields: _listOfMaps(
        json['fields'],
      ).map(AdminEntityField.fromJson).toList(growable: false),
      supportsCreate: json['supports_create'] as bool? ?? true,
      supportsUpdate: json['supports_update'] as bool? ?? true,
      supportsDelete: json['supports_delete'] as bool? ?? true,
      supportsImport: json['supports_import'] as bool? ?? true,
    );
  }
}

class AdminRecordListResponse {
  const AdminRecordListResponse({
    required this.entity,
    required this.rows,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final AdminEntityDefinition entity;
  final List<Map<String, Object?>> rows;
  final int total;
  final int page;
  final int pageSize;

  factory AdminRecordListResponse.fromJson(Map<String, Object?> json) {
    return AdminRecordListResponse(
      entity: AdminEntityDefinition.fromJson(_jsonMap(json['entity'])),
      rows: _listOfMaps(json['rows']),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 25,
    );
  }
}

class AdminMetric {
  const AdminMetric({
    required this.key,
    required this.label,
    required this.value,
    required this.description,
  });

  final String key;
  final String label;
  final int value;
  final String description;

  factory AdminMetric.fromJson(Map<String, Object?> json) {
    return AdminMetric(
      key: json['key'] as String,
      label: json['label'] as String,
      value: json['value'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }
}

class AdminActivity {
  const AdminActivity({
    required this.label,
    required this.value,
    required this.status,
    this.createdAt,
  });

  final String label;
  final String value;
  final String status;
  final String? createdAt;

  factory AdminActivity.fromJson(Map<String, Object?> json) {
    return AdminActivity(
      label: json['label'] as String? ?? '-',
      value: json['value'] as String? ?? '-',
      status: json['status'] as String? ?? '-',
      createdAt: json['created_at'] as String?,
    );
  }
}

class AdminOverview {
  const AdminOverview({
    required this.metrics,
    required this.recentActivity,
    required this.masterEntities,
  });

  final List<AdminMetric> metrics;
  final List<AdminActivity> recentActivity;
  final List<AdminEntityDefinition> masterEntities;

  factory AdminOverview.fromJson(Map<String, Object?> json) {
    return AdminOverview(
      metrics: _listOfMaps(
        json['metrics'],
      ).map(AdminMetric.fromJson).toList(growable: false),
      recentActivity: _listOfMaps(
        json['recent_activity'],
      ).map(AdminActivity.fromJson).toList(growable: false),
      masterEntities: _listOfMaps(
        json['master_entities'],
      ).map(AdminEntityDefinition.fromJson).toList(growable: false),
    );
  }
}

class AdminAuditLogEntry {
  const AdminAuditLogEntry({
    required this.auditLogId,
    required this.actionCode,
    required this.resourceType,
    required this.beforeData,
    required this.afterData,
    required this.metadata,
    required this.createdAt,
    this.actorName,
    this.resourceId,
    this.resourceLabel,
  });

  final int auditLogId;
  final String actionCode;
  final String resourceType;
  final Map<String, Object?> beforeData;
  final Map<String, Object?> afterData;
  final Map<String, Object?> metadata;
  final String createdAt;
  final String? actorName;
  final String? resourceId;
  final String? resourceLabel;

  factory AdminAuditLogEntry.fromJson(Map<String, Object?> json) {
    return AdminAuditLogEntry(
      auditLogId: json['audit_log_id'] as int,
      actionCode: json['action_code'] as String,
      resourceType: json['resource_type'] as String,
      beforeData: _jsonMap(json['before_data']),
      afterData: _jsonMap(json['after_data']),
      metadata: _jsonMap(json['metadata']),
      createdAt: json['created_at'] as String? ?? '',
      actorName: json['actor_name'] as String?,
      resourceId: json['resource_id'] as String?,
      resourceLabel: json['resource_label'] as String?,
    );
  }
}

class AdminAuditLogListResponse {
  const AdminAuditLogListResponse({
    required this.rows,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<AdminAuditLogEntry> rows;
  final int total;
  final int page;
  final int pageSize;

  factory AdminAuditLogListResponse.fromJson(Map<String, Object?> json) {
    return AdminAuditLogListResponse(
      rows: _listOfMaps(
        json['rows'],
      ).map(AdminAuditLogEntry.fromJson).toList(growable: false),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 25,
    );
  }
}

class AdminImportResponse {
  const AdminImportResponse({
    required this.importJobId,
    required this.entityKey,
    required this.statusCode,
    required this.totalRows,
    required this.successRows,
    required this.failedRows,
  });

  final int importJobId;
  final String entityKey;
  final String statusCode;
  final int totalRows;
  final int successRows;
  final int failedRows;

  factory AdminImportResponse.fromJson(Map<String, Object?> json) {
    return AdminImportResponse(
      importJobId: json['import_job_id'] as int,
      entityKey: json['entity_key'] as String,
      statusCode: json['status_code'] as String,
      totalRows: json['total_rows'] as int? ?? 0,
      successRows: json['success_rows'] as int? ?? 0,
      failedRows: json['failed_rows'] as int? ?? 0,
    );
  }
}

class AdminFailure implements Exception {
  const AdminFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, Object?> _jsonMap(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  return {};
}

List<Map<String, Object?>> _listOfMaps(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList(growable: false);
  }
  return const [];
}
