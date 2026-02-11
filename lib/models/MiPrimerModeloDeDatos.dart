/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;


/** This is an auto generated class representing the MiPrimerModeloDeDatos type in your schema. */
class MiPrimerModeloDeDatos extends amplify_core.Model {
  static const classType = const _MiPrimerModeloDeDatosModelType();
  final String id;
  final amplify_core.TemporalTimestamp? _timestamp;
  final int? _Agua;
  final int? _AguaR;
  final int? _Diesel;
  final int? _gLP;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  MiPrimerModeloDeDatosModelIdentifier get modelIdentifier {
      return MiPrimerModeloDeDatosModelIdentifier(
        id: id
      );
  }
  
  amplify_core.TemporalTimestamp? get timestamp {
    return _timestamp;
  }
  
  int? get Agua {
    return _Agua;
  }
  
  int? get AguaR {
    return _AguaR;
  }
  
  int? get Diesel {
    return _Diesel;
  }
  
  int? get gLP {
    return _gLP;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const MiPrimerModeloDeDatos._internal({required this.id, timestamp, Agua, AguaR, Diesel, gLP, createdAt, updatedAt}): _timestamp = timestamp, _Agua = Agua, _AguaR = AguaR, _Diesel = Diesel, _gLP = gLP, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory MiPrimerModeloDeDatos({String? id, amplify_core.TemporalTimestamp? timestamp, int? Agua, int? AguaR, int? Diesel, int? gLP}) {
    return MiPrimerModeloDeDatos._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      timestamp: timestamp,
      Agua: Agua,
      AguaR: AguaR,
      Diesel: Diesel,
      gLP: gLP);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MiPrimerModeloDeDatos &&
      id == other.id &&
      _timestamp == other._timestamp &&
      _Agua == other._Agua &&
      _AguaR == other._AguaR &&
      _Diesel == other._Diesel &&
      _gLP == other._gLP;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("MiPrimerModeloDeDatos {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("timestamp=" + (_timestamp != null ? _timestamp!.toString() : "null") + ", ");
    buffer.write("Agua=" + (_Agua != null ? _Agua!.toString() : "null") + ", ");
    buffer.write("AguaR=" + (_AguaR != null ? _AguaR!.toString() : "null") + ", ");
    buffer.write("Diesel=" + (_Diesel != null ? _Diesel!.toString() : "null") + ", ");
    buffer.write("gLP=" + (_gLP != null ? _gLP!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  MiPrimerModeloDeDatos copyWith({amplify_core.TemporalTimestamp? timestamp, int? Agua, int? AguaR, int? Diesel, int? gLP}) {
    return MiPrimerModeloDeDatos._internal(
      id: id,
      timestamp: timestamp ?? this.timestamp,
      Agua: Agua ?? this.Agua,
      AguaR: AguaR ?? this.AguaR,
      Diesel: Diesel ?? this.Diesel,
      gLP: gLP ?? this.gLP);
  }
  
  MiPrimerModeloDeDatos copyWithModelFieldValues({
    ModelFieldValue<amplify_core.TemporalTimestamp?>? timestamp,
    ModelFieldValue<int?>? Agua,
    ModelFieldValue<int?>? AguaR,
    ModelFieldValue<int?>? Diesel,
    ModelFieldValue<int?>? gLP
  }) {
    return MiPrimerModeloDeDatos._internal(
      id: id,
      timestamp: timestamp == null ? this.timestamp : timestamp.value,
      Agua: Agua == null ? this.Agua : Agua.value,
      AguaR: AguaR == null ? this.AguaR : AguaR.value,
      Diesel: Diesel == null ? this.Diesel : Diesel.value,
      gLP: gLP == null ? this.gLP : gLP.value
    );
  }
  
  MiPrimerModeloDeDatos.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _timestamp = json['timestamp'] != null ? amplify_core.TemporalTimestamp.fromSeconds(json['timestamp']) : null,
      _Agua = (json['Agua'] as num?)?.toInt(),
      _AguaR = (json['AguaR'] as num?)?.toInt(),
      _Diesel = (json['Diesel'] as num?)?.toInt(),
      _gLP = (json['gLP'] as num?)?.toInt(),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'timestamp': _timestamp?.toSeconds(), 'Agua': _Agua, 'AguaR': _AguaR, 'Diesel': _Diesel, 'gLP': _gLP, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'timestamp': _timestamp,
    'Agua': _Agua,
    'AguaR': _AguaR,
    'Diesel': _Diesel,
    'gLP': _gLP,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<MiPrimerModeloDeDatosModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<MiPrimerModeloDeDatosModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TIMESTAMP = amplify_core.QueryField(fieldName: "timestamp");
  static final AGUA = amplify_core.QueryField(fieldName: "Agua");
  static final AGUAR = amplify_core.QueryField(fieldName: "AguaR");
  static final DIESEL = amplify_core.QueryField(fieldName: "Diesel");
  static final GLP = amplify_core.QueryField(fieldName: "gLP");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "MiPrimerModeloDeDatos";
    modelSchemaDefinition.pluralName = "MiPrimerModeloDeDatos";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: MiPrimerModeloDeDatos.TIMESTAMP,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.timestamp)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: MiPrimerModeloDeDatos.AGUA,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: MiPrimerModeloDeDatos.AGUAR,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: MiPrimerModeloDeDatos.DIESEL,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: MiPrimerModeloDeDatos.GLP,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _MiPrimerModeloDeDatosModelType extends amplify_core.ModelType<MiPrimerModeloDeDatos> {
  const _MiPrimerModeloDeDatosModelType();
  
  @override
  MiPrimerModeloDeDatos fromJson(Map<String, dynamic> jsonData) {
    return MiPrimerModeloDeDatos.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'MiPrimerModeloDeDatos';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [MiPrimerModeloDeDatos] in your schema.
 */
class MiPrimerModeloDeDatosModelIdentifier implements amplify_core.ModelIdentifier<MiPrimerModeloDeDatos> {
  final String id;

  /** Create an instance of MiPrimerModeloDeDatosModelIdentifier using [id] the primary key. */
  const MiPrimerModeloDeDatosModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'MiPrimerModeloDeDatosModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is MiPrimerModeloDeDatosModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}