// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _openingBalanceMeta =
      const VerificationMeta('openingBalance');
  @override
  late final GeneratedColumn<double> openingBalance = GeneratedColumn<double>(
      'opening_balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, kind, openingBalance, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
          _openingBalanceMeta,
          openingBalance.isAcceptableOrUnknown(
              data['opening_balance']!, _openingBalanceMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      openingBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}opening_balance'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String name;
  final String kind;
  final double openingBalance;
  final String? note;
  final DateTime createdAt;
  const Account(
      {required this.id,
      required this.name,
      required this.kind,
      required this.openingBalance,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['opening_balance'] = Variable<double>(openingBalance);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      openingBalance: Value(openingBalance),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      openingBalance: serializer.fromJson<double>(json['openingBalance']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'openingBalance': serializer.toJson<double>(openingBalance),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Account copyWith(
          {String? id,
          String? name,
          String? kind,
          double? openingBalance,
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      Account(
        id: id ?? this.id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        openingBalance: openingBalance ?? this.openingBalance,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, kind, openingBalance, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.openingBalance == this.openingBalance &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<double> openingBalance;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String name,
    this.kind = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<double>? openingBalance,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? kind,
      Value<double>? openingBalance,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      openingBalance: openingBalance ?? this.openingBalance,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<double>(openingBalance.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actualMeta = const VerificationMeta('actual');
  @override
  late final GeneratedColumn<double> actual = GeneratedColumn<double>(
      'actual', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _budgetImpactMeta =
      const VerificationMeta('budgetImpact');
  @override
  late final GeneratedColumn<double> budgetImpact = GeneratedColumn<double>(
      'budget_impact', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _categoryRawMeta =
      const VerificationMeta('categoryRaw');
  @override
  late final GeneratedColumn<String> categoryRaw = GeneratedColumn<String>(
      'category_raw', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _level0Meta = const VerificationMeta('level0');
  @override
  late final GeneratedColumn<String> level0 = GeneratedColumn<String>(
      'level0', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _level1Meta = const VerificationMeta('level1');
  @override
  late final GeneratedColumn<String> level1 = GeneratedColumn<String>(
      'level1', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _level2Meta = const VerificationMeta('level2');
  @override
  late final GeneratedColumn<String> level2 = GeneratedColumn<String>(
      'level2', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _itemMeta = const VerificationMeta('item');
  @override
  late final GeneratedColumn<String> item = GeneratedColumn<String>(
      'item', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bucketMeta = const VerificationMeta('bucket');
  @override
  late final GeneratedColumn<String> bucket = GeneratedColumn<String>(
      'bucket', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _absorbedMeta =
      const VerificationMeta('absorbed');
  @override
  late final GeneratedColumn<int> absorbed = GeneratedColumn<int>(
      'absorbed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _personMeta = const VerificationMeta('person');
  @override
  late final GeneratedColumn<String> person = GeneratedColumn<String>(
      'person', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _linkIdMeta = const VerificationMeta('linkId');
  @override
  late final GeneratedColumn<String> linkId = GeneratedColumn<String>(
      'link_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _linkTypeMeta =
      const VerificationMeta('linkType');
  @override
  late final GeneratedColumn<String> linkType = GeneratedColumn<String>(
      'link_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        actual,
        budgetImpact,
        occurredAt,
        categoryRaw,
        level0,
        level1,
        level2,
        item,
        bucket,
        absorbed,
        person,
        note,
        accountId,
        linkId,
        linkType,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('actual')) {
      context.handle(_actualMeta,
          actual.isAcceptableOrUnknown(data['actual']!, _actualMeta));
    } else if (isInserting) {
      context.missing(_actualMeta);
    }
    if (data.containsKey('budget_impact')) {
      context.handle(
          _budgetImpactMeta,
          budgetImpact.isAcceptableOrUnknown(
              data['budget_impact']!, _budgetImpactMeta));
    } else if (isInserting) {
      context.missing(_budgetImpactMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('category_raw')) {
      context.handle(
          _categoryRawMeta,
          categoryRaw.isAcceptableOrUnknown(
              data['category_raw']!, _categoryRawMeta));
    } else if (isInserting) {
      context.missing(_categoryRawMeta);
    }
    if (data.containsKey('level0')) {
      context.handle(_level0Meta,
          level0.isAcceptableOrUnknown(data['level0']!, _level0Meta));
    }
    if (data.containsKey('level1')) {
      context.handle(_level1Meta,
          level1.isAcceptableOrUnknown(data['level1']!, _level1Meta));
    }
    if (data.containsKey('level2')) {
      context.handle(_level2Meta,
          level2.isAcceptableOrUnknown(data['level2']!, _level2Meta));
    }
    if (data.containsKey('item')) {
      context.handle(
          _itemMeta, item.isAcceptableOrUnknown(data['item']!, _itemMeta));
    }
    if (data.containsKey('bucket')) {
      context.handle(_bucketMeta,
          bucket.isAcceptableOrUnknown(data['bucket']!, _bucketMeta));
    }
    if (data.containsKey('absorbed')) {
      context.handle(_absorbedMeta,
          absorbed.isAcceptableOrUnknown(data['absorbed']!, _absorbedMeta));
    }
    if (data.containsKey('person')) {
      context.handle(_personMeta,
          person.isAcceptableOrUnknown(data['person']!, _personMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('link_id')) {
      context.handle(_linkIdMeta,
          linkId.isAcceptableOrUnknown(data['link_id']!, _linkIdMeta));
    }
    if (data.containsKey('link_type')) {
      context.handle(_linkTypeMeta,
          linkType.isAcceptableOrUnknown(data['link_type']!, _linkTypeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      actual: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}actual'])!,
      budgetImpact: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}budget_impact'])!,
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      categoryRaw: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_raw'])!,
      level0: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level0']),
      level1: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level1']),
      level2: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level2']),
      item: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item']),
      bucket: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bucket']),
      absorbed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}absorbed'])!,
      person: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}person']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id']),
      linkId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}link_id']),
      linkType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}link_type']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;

  /// Freeform: in / out / neutral / lend / borrow / split / settle / transfer / invest.
  final String kind;

  /// Statement truth: what entered/left the account.
  final double actual;

  /// Planning truth: what counts toward the monthly budget.
  final double budgetImpact;

  /// When the money moved (user-picked date/time, not insertion time).
  final DateTime occurredAt;
  final String categoryRaw;
  final String? level0;
  final String? level1;
  final String? level2;

  /// Exact item token incl. hyphen part, e.g. `gobi-65`. Null when none.
  final String? item;

  /// Budget bucket this entry belongs to (need/want/invest or custom).
  /// Freeform text, null = unassigned. UX-feedback batch.
  final String? bucket;

  /// 1 when the owner chose to absorb this neutral row (a lend/borrow or its
  /// payoff) into the month's budget. Neutral rows stay out of month math
  /// until this flips — owner rule 2026-09-27.
  final int absorbed;

  /// Counterparty on lend/borrow/settle rows, so a plain front-screen entry
  /// can be routed to the right person's contract. Owner rule 2026-09-27.
  final String? person;
  final String? note;

  /// Owning account id. Plain text, no DB-level FK (keeps drift codegen
  /// robust across analyzer versions; repositories own the discipline).
  final String? accountId;
  final String? linkId;
  final String? linkType;
  final DateTime createdAt;
  const Transaction(
      {required this.id,
      required this.kind,
      required this.actual,
      required this.budgetImpact,
      required this.occurredAt,
      required this.categoryRaw,
      this.level0,
      this.level1,
      this.level2,
      this.item,
      this.bucket,
      required this.absorbed,
      this.person,
      this.note,
      this.accountId,
      this.linkId,
      this.linkType,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['actual'] = Variable<double>(actual);
    map['budget_impact'] = Variable<double>(budgetImpact);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['category_raw'] = Variable<String>(categoryRaw);
    if (!nullToAbsent || level0 != null) {
      map['level0'] = Variable<String>(level0);
    }
    if (!nullToAbsent || level1 != null) {
      map['level1'] = Variable<String>(level1);
    }
    if (!nullToAbsent || level2 != null) {
      map['level2'] = Variable<String>(level2);
    }
    if (!nullToAbsent || item != null) {
      map['item'] = Variable<String>(item);
    }
    if (!nullToAbsent || bucket != null) {
      map['bucket'] = Variable<String>(bucket);
    }
    map['absorbed'] = Variable<int>(absorbed);
    if (!nullToAbsent || person != null) {
      map['person'] = Variable<String>(person);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || linkId != null) {
      map['link_id'] = Variable<String>(linkId);
    }
    if (!nullToAbsent || linkType != null) {
      map['link_type'] = Variable<String>(linkType);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      kind: Value(kind),
      actual: Value(actual),
      budgetImpact: Value(budgetImpact),
      occurredAt: Value(occurredAt),
      categoryRaw: Value(categoryRaw),
      level0:
          level0 == null && nullToAbsent ? const Value.absent() : Value(level0),
      level1:
          level1 == null && nullToAbsent ? const Value.absent() : Value(level1),
      level2:
          level2 == null && nullToAbsent ? const Value.absent() : Value(level2),
      item: item == null && nullToAbsent ? const Value.absent() : Value(item),
      bucket:
          bucket == null && nullToAbsent ? const Value.absent() : Value(bucket),
      absorbed: Value(absorbed),
      person:
          person == null && nullToAbsent ? const Value.absent() : Value(person),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      linkId:
          linkId == null && nullToAbsent ? const Value.absent() : Value(linkId),
      linkType: linkType == null && nullToAbsent
          ? const Value.absent()
          : Value(linkType),
      createdAt: Value(createdAt),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      actual: serializer.fromJson<double>(json['actual']),
      budgetImpact: serializer.fromJson<double>(json['budgetImpact']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      categoryRaw: serializer.fromJson<String>(json['categoryRaw']),
      level0: serializer.fromJson<String?>(json['level0']),
      level1: serializer.fromJson<String?>(json['level1']),
      level2: serializer.fromJson<String?>(json['level2']),
      item: serializer.fromJson<String?>(json['item']),
      bucket: serializer.fromJson<String?>(json['bucket']),
      absorbed: serializer.fromJson<int>(json['absorbed']),
      person: serializer.fromJson<String?>(json['person']),
      note: serializer.fromJson<String?>(json['note']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      linkId: serializer.fromJson<String?>(json['linkId']),
      linkType: serializer.fromJson<String?>(json['linkType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'actual': serializer.toJson<double>(actual),
      'budgetImpact': serializer.toJson<double>(budgetImpact),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'categoryRaw': serializer.toJson<String>(categoryRaw),
      'level0': serializer.toJson<String?>(level0),
      'level1': serializer.toJson<String?>(level1),
      'level2': serializer.toJson<String?>(level2),
      'item': serializer.toJson<String?>(item),
      'bucket': serializer.toJson<String?>(bucket),
      'absorbed': serializer.toJson<int>(absorbed),
      'person': serializer.toJson<String?>(person),
      'note': serializer.toJson<String?>(note),
      'accountId': serializer.toJson<String?>(accountId),
      'linkId': serializer.toJson<String?>(linkId),
      'linkType': serializer.toJson<String?>(linkType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Transaction copyWith(
          {String? id,
          String? kind,
          double? actual,
          double? budgetImpact,
          DateTime? occurredAt,
          String? categoryRaw,
          Value<String?> level0 = const Value.absent(),
          Value<String?> level1 = const Value.absent(),
          Value<String?> level2 = const Value.absent(),
          Value<String?> item = const Value.absent(),
          Value<String?> bucket = const Value.absent(),
          int? absorbed,
          Value<String?> person = const Value.absent(),
          Value<String?> note = const Value.absent(),
          Value<String?> accountId = const Value.absent(),
          Value<String?> linkId = const Value.absent(),
          Value<String?> linkType = const Value.absent(),
          DateTime? createdAt}) =>
      Transaction(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        actual: actual ?? this.actual,
        budgetImpact: budgetImpact ?? this.budgetImpact,
        occurredAt: occurredAt ?? this.occurredAt,
        categoryRaw: categoryRaw ?? this.categoryRaw,
        level0: level0.present ? level0.value : this.level0,
        level1: level1.present ? level1.value : this.level1,
        level2: level2.present ? level2.value : this.level2,
        item: item.present ? item.value : this.item,
        bucket: bucket.present ? bucket.value : this.bucket,
        absorbed: absorbed ?? this.absorbed,
        person: person.present ? person.value : this.person,
        note: note.present ? note.value : this.note,
        accountId: accountId.present ? accountId.value : this.accountId,
        linkId: linkId.present ? linkId.value : this.linkId,
        linkType: linkType.present ? linkType.value : this.linkType,
        createdAt: createdAt ?? this.createdAt,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      actual: data.actual.present ? data.actual.value : this.actual,
      budgetImpact: data.budgetImpact.present
          ? data.budgetImpact.value
          : this.budgetImpact,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      categoryRaw:
          data.categoryRaw.present ? data.categoryRaw.value : this.categoryRaw,
      level0: data.level0.present ? data.level0.value : this.level0,
      level1: data.level1.present ? data.level1.value : this.level1,
      level2: data.level2.present ? data.level2.value : this.level2,
      item: data.item.present ? data.item.value : this.item,
      bucket: data.bucket.present ? data.bucket.value : this.bucket,
      absorbed: data.absorbed.present ? data.absorbed.value : this.absorbed,
      person: data.person.present ? data.person.value : this.person,
      note: data.note.present ? data.note.value : this.note,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      linkId: data.linkId.present ? data.linkId.value : this.linkId,
      linkType: data.linkType.present ? data.linkType.value : this.linkType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('actual: $actual, ')
          ..write('budgetImpact: $budgetImpact, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('categoryRaw: $categoryRaw, ')
          ..write('level0: $level0, ')
          ..write('level1: $level1, ')
          ..write('level2: $level2, ')
          ..write('item: $item, ')
          ..write('bucket: $bucket, ')
          ..write('absorbed: $absorbed, ')
          ..write('person: $person, ')
          ..write('note: $note, ')
          ..write('accountId: $accountId, ')
          ..write('linkId: $linkId, ')
          ..write('linkType: $linkType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      kind,
      actual,
      budgetImpact,
      occurredAt,
      categoryRaw,
      level0,
      level1,
      level2,
      item,
      bucket,
      absorbed,
      person,
      note,
      accountId,
      linkId,
      linkType,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.actual == this.actual &&
          other.budgetImpact == this.budgetImpact &&
          other.occurredAt == this.occurredAt &&
          other.categoryRaw == this.categoryRaw &&
          other.level0 == this.level0 &&
          other.level1 == this.level1 &&
          other.level2 == this.level2 &&
          other.item == this.item &&
          other.bucket == this.bucket &&
          other.absorbed == this.absorbed &&
          other.person == this.person &&
          other.note == this.note &&
          other.accountId == this.accountId &&
          other.linkId == this.linkId &&
          other.linkType == this.linkType &&
          other.createdAt == this.createdAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> kind;
  final Value<double> actual;
  final Value<double> budgetImpact;
  final Value<DateTime> occurredAt;
  final Value<String> categoryRaw;
  final Value<String?> level0;
  final Value<String?> level1;
  final Value<String?> level2;
  final Value<String?> item;
  final Value<String?> bucket;
  final Value<int> absorbed;
  final Value<String?> person;
  final Value<String?> note;
  final Value<String?> accountId;
  final Value<String?> linkId;
  final Value<String?> linkType;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.actual = const Value.absent(),
    this.budgetImpact = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.categoryRaw = const Value.absent(),
    this.level0 = const Value.absent(),
    this.level1 = const Value.absent(),
    this.level2 = const Value.absent(),
    this.item = const Value.absent(),
    this.bucket = const Value.absent(),
    this.absorbed = const Value.absent(),
    this.person = const Value.absent(),
    this.note = const Value.absent(),
    this.accountId = const Value.absent(),
    this.linkId = const Value.absent(),
    this.linkType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String kind,
    required double actual,
    required double budgetImpact,
    required DateTime occurredAt,
    required String categoryRaw,
    this.level0 = const Value.absent(),
    this.level1 = const Value.absent(),
    this.level2 = const Value.absent(),
    this.item = const Value.absent(),
    this.bucket = const Value.absent(),
    this.absorbed = const Value.absent(),
    this.person = const Value.absent(),
    this.note = const Value.absent(),
    this.accountId = const Value.absent(),
    this.linkId = const Value.absent(),
    this.linkType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        actual = Value(actual),
        budgetImpact = Value(budgetImpact),
        occurredAt = Value(occurredAt),
        categoryRaw = Value(categoryRaw);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<double>? actual,
    Expression<double>? budgetImpact,
    Expression<DateTime>? occurredAt,
    Expression<String>? categoryRaw,
    Expression<String>? level0,
    Expression<String>? level1,
    Expression<String>? level2,
    Expression<String>? item,
    Expression<String>? bucket,
    Expression<int>? absorbed,
    Expression<String>? person,
    Expression<String>? note,
    Expression<String>? accountId,
    Expression<String>? linkId,
    Expression<String>? linkType,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (actual != null) 'actual': actual,
      if (budgetImpact != null) 'budget_impact': budgetImpact,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (categoryRaw != null) 'category_raw': categoryRaw,
      if (level0 != null) 'level0': level0,
      if (level1 != null) 'level1': level1,
      if (level2 != null) 'level2': level2,
      if (item != null) 'item': item,
      if (bucket != null) 'bucket': bucket,
      if (absorbed != null) 'absorbed': absorbed,
      if (person != null) 'person': person,
      if (note != null) 'note': note,
      if (accountId != null) 'account_id': accountId,
      if (linkId != null) 'link_id': linkId,
      if (linkType != null) 'link_type': linkType,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<double>? actual,
      Value<double>? budgetImpact,
      Value<DateTime>? occurredAt,
      Value<String>? categoryRaw,
      Value<String?>? level0,
      Value<String?>? level1,
      Value<String?>? level2,
      Value<String?>? item,
      Value<String?>? bucket,
      Value<int>? absorbed,
      Value<String?>? person,
      Value<String?>? note,
      Value<String?>? accountId,
      Value<String?>? linkId,
      Value<String?>? linkType,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      actual: actual ?? this.actual,
      budgetImpact: budgetImpact ?? this.budgetImpact,
      occurredAt: occurredAt ?? this.occurredAt,
      categoryRaw: categoryRaw ?? this.categoryRaw,
      level0: level0 ?? this.level0,
      level1: level1 ?? this.level1,
      level2: level2 ?? this.level2,
      item: item ?? this.item,
      bucket: bucket ?? this.bucket,
      absorbed: absorbed ?? this.absorbed,
      person: person ?? this.person,
      note: note ?? this.note,
      accountId: accountId ?? this.accountId,
      linkId: linkId ?? this.linkId,
      linkType: linkType ?? this.linkType,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (actual.present) {
      map['actual'] = Variable<double>(actual.value);
    }
    if (budgetImpact.present) {
      map['budget_impact'] = Variable<double>(budgetImpact.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (categoryRaw.present) {
      map['category_raw'] = Variable<String>(categoryRaw.value);
    }
    if (level0.present) {
      map['level0'] = Variable<String>(level0.value);
    }
    if (level1.present) {
      map['level1'] = Variable<String>(level1.value);
    }
    if (level2.present) {
      map['level2'] = Variable<String>(level2.value);
    }
    if (item.present) {
      map['item'] = Variable<String>(item.value);
    }
    if (bucket.present) {
      map['bucket'] = Variable<String>(bucket.value);
    }
    if (absorbed.present) {
      map['absorbed'] = Variable<int>(absorbed.value);
    }
    if (person.present) {
      map['person'] = Variable<String>(person.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (linkId.present) {
      map['link_id'] = Variable<String>(linkId.value);
    }
    if (linkType.present) {
      map['link_type'] = Variable<String>(linkType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('actual: $actual, ')
          ..write('budgetImpact: $budgetImpact, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('categoryRaw: $categoryRaw, ')
          ..write('level0: $level0, ')
          ..write('level1: $level1, ')
          ..write('level2: $level2, ')
          ..write('item: $item, ')
          ..write('bucket: $bucket, ')
          ..write('absorbed: $absorbed, ')
          ..write('person: $person, ')
          ..write('note: $note, ')
          ..write('accountId: $accountId, ')
          ..write('linkId: $linkId, ')
          ..write('linkType: $linkType, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
      'month', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
      'total', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _bucketsJsonMeta =
      const VerificationMeta('bucketsJson');
  @override
  late final GeneratedColumn<String> bucketsJson = GeneratedColumn<String>(
      'buckets_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [month, total, bucketsJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<Budget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('buckets_json')) {
      context.handle(
          _bucketsJsonMeta,
          bucketsJson.isAcceptableOrUnknown(
              data['buckets_json']!, _bucketsJsonMeta));
    } else if (isInserting) {
      context.missing(_bucketsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {month};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
      bucketsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}buckets_json'])!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  /// `YYYY-MM`.
  final String month;
  final double total;
  final String bucketsJson;
  const Budget(
      {required this.month, required this.total, required this.bucketsJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month'] = Variable<String>(month);
    map['total'] = Variable<double>(total);
    map['buckets_json'] = Variable<String>(bucketsJson);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      month: Value(month),
      total: Value(total),
      bucketsJson: Value(bucketsJson),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      month: serializer.fromJson<String>(json['month']),
      total: serializer.fromJson<double>(json['total']),
      bucketsJson: serializer.fromJson<String>(json['bucketsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'month': serializer.toJson<String>(month),
      'total': serializer.toJson<double>(total),
      'bucketsJson': serializer.toJson<String>(bucketsJson),
    };
  }

  Budget copyWith({String? month, double? total, String? bucketsJson}) =>
      Budget(
        month: month ?? this.month,
        total: total ?? this.total,
        bucketsJson: bucketsJson ?? this.bucketsJson,
      );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      month: data.month.present ? data.month.value : this.month,
      total: data.total.present ? data.total.value : this.total,
      bucketsJson:
          data.bucketsJson.present ? data.bucketsJson.value : this.bucketsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('month: $month, ')
          ..write('total: $total, ')
          ..write('bucketsJson: $bucketsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(month, total, bucketsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.month == this.month &&
          other.total == this.total &&
          other.bucketsJson == this.bucketsJson);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> month;
  final Value<double> total;
  final Value<String> bucketsJson;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.month = const Value.absent(),
    this.total = const Value.absent(),
    this.bucketsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String month,
    required double total,
    required String bucketsJson,
    this.rowid = const Value.absent(),
  })  : month = Value(month),
        total = Value(total),
        bucketsJson = Value(bucketsJson);
  static Insertable<Budget> custom({
    Expression<String>? month,
    Expression<double>? total,
    Expression<String>? bucketsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (month != null) 'month': month,
      if (total != null) 'total': total,
      if (bucketsJson != null) 'buckets_json': bucketsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith(
      {Value<String>? month,
      Value<double>? total,
      Value<String>? bucketsJson,
      Value<int>? rowid}) {
    return BudgetsCompanion(
      month: month ?? this.month,
      total: total ?? this.total,
      bucketsJson: bucketsJson ?? this.bucketsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (bucketsJson.present) {
      map['buckets_json'] = Variable<String>(bucketsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('month: $month, ')
          ..write('total: $total, ')
          ..write('bucketsJson: $bucketsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtsTable extends Debts with TableInfo<$DebtsTable, Debt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _counterpartyMeta =
      const VerificationMeta('counterparty');
  @override
  late final GeneratedColumn<String> counterparty = GeneratedColumn<String>(
      'counterparty', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _principalMeta =
      const VerificationMeta('principal');
  @override
  late final GeneratedColumn<double> principal = GeneratedColumn<double>(
      'principal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paidMeta = const VerificationMeta('paid');
  @override
  late final GeneratedColumn<double> paid = GeneratedColumn<double>(
      'paid', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _nudgeDateMeta =
      const VerificationMeta('nudgeDate');
  @override
  late final GeneratedColumn<DateTime> nudgeDate = GeneratedColumn<DateTime>(
      'nudge_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        counterparty,
        direction,
        principal,
        paid,
        note,
        dueDate,
        nudgeDate,
        status,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debts';
  @override
  VerificationContext validateIntegrity(Insertable<Debt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('counterparty')) {
      context.handle(
          _counterpartyMeta,
          counterparty.isAcceptableOrUnknown(
              data['counterparty']!, _counterpartyMeta));
    } else if (isInserting) {
      context.missing(_counterpartyMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('principal')) {
      context.handle(_principalMeta,
          principal.isAcceptableOrUnknown(data['principal']!, _principalMeta));
    } else if (isInserting) {
      context.missing(_principalMeta);
    }
    if (data.containsKey('paid')) {
      context.handle(
          _paidMeta, paid.isAcceptableOrUnknown(data['paid']!, _paidMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('nudge_date')) {
      context.handle(_nudgeDateMeta,
          nudgeDate.isAcceptableOrUnknown(data['nudge_date']!, _nudgeDateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Debt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Debt(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      counterparty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}counterparty'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      principal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}principal'])!,
      paid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}paid'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      nudgeDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}nudge_date']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DebtsTable createAlias(String alias) {
    return $DebtsTable(attachedDatabase, alias);
  }
}

class Debt extends DataClass implements Insertable<Debt> {
  final String id;
  final String counterparty;

  /// 'lent' (I gave money) or 'borrowed' (I took money).
  final String direction;
  final double principal;
  final double paid;
  final String? note;
  final DateTime? dueDate;
  final DateTime? nudgeDate;

  /// 'open' or 'settled'. Auto-settled by DebtRepository; never edited by UI.
  final String status;
  final DateTime createdAt;
  const Debt(
      {required this.id,
      required this.counterparty,
      required this.direction,
      required this.principal,
      required this.paid,
      this.note,
      this.dueDate,
      this.nudgeDate,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['counterparty'] = Variable<String>(counterparty);
    map['direction'] = Variable<String>(direction);
    map['principal'] = Variable<double>(principal);
    map['paid'] = Variable<double>(paid);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || nudgeDate != null) {
      map['nudge_date'] = Variable<DateTime>(nudgeDate);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DebtsCompanion toCompanion(bool nullToAbsent) {
    return DebtsCompanion(
      id: Value(id),
      counterparty: Value(counterparty),
      direction: Value(direction),
      principal: Value(principal),
      paid: Value(paid),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      nudgeDate: nudgeDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nudgeDate),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Debt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Debt(
      id: serializer.fromJson<String>(json['id']),
      counterparty: serializer.fromJson<String>(json['counterparty']),
      direction: serializer.fromJson<String>(json['direction']),
      principal: serializer.fromJson<double>(json['principal']),
      paid: serializer.fromJson<double>(json['paid']),
      note: serializer.fromJson<String?>(json['note']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      nudgeDate: serializer.fromJson<DateTime?>(json['nudgeDate']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'counterparty': serializer.toJson<String>(counterparty),
      'direction': serializer.toJson<String>(direction),
      'principal': serializer.toJson<double>(principal),
      'paid': serializer.toJson<double>(paid),
      'note': serializer.toJson<String?>(note),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'nudgeDate': serializer.toJson<DateTime?>(nudgeDate),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Debt copyWith(
          {String? id,
          String? counterparty,
          String? direction,
          double? principal,
          double? paid,
          Value<String?> note = const Value.absent(),
          Value<DateTime?> dueDate = const Value.absent(),
          Value<DateTime?> nudgeDate = const Value.absent(),
          String? status,
          DateTime? createdAt}) =>
      Debt(
        id: id ?? this.id,
        counterparty: counterparty ?? this.counterparty,
        direction: direction ?? this.direction,
        principal: principal ?? this.principal,
        paid: paid ?? this.paid,
        note: note.present ? note.value : this.note,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        nudgeDate: nudgeDate.present ? nudgeDate.value : this.nudgeDate,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  Debt copyWithCompanion(DebtsCompanion data) {
    return Debt(
      id: data.id.present ? data.id.value : this.id,
      counterparty: data.counterparty.present
          ? data.counterparty.value
          : this.counterparty,
      direction: data.direction.present ? data.direction.value : this.direction,
      principal: data.principal.present ? data.principal.value : this.principal,
      paid: data.paid.present ? data.paid.value : this.paid,
      note: data.note.present ? data.note.value : this.note,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      nudgeDate: data.nudgeDate.present ? data.nudgeDate.value : this.nudgeDate,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Debt(')
          ..write('id: $id, ')
          ..write('counterparty: $counterparty, ')
          ..write('direction: $direction, ')
          ..write('principal: $principal, ')
          ..write('paid: $paid, ')
          ..write('note: $note, ')
          ..write('dueDate: $dueDate, ')
          ..write('nudgeDate: $nudgeDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, counterparty, direction, principal, paid,
      note, dueDate, nudgeDate, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Debt &&
          other.id == this.id &&
          other.counterparty == this.counterparty &&
          other.direction == this.direction &&
          other.principal == this.principal &&
          other.paid == this.paid &&
          other.note == this.note &&
          other.dueDate == this.dueDate &&
          other.nudgeDate == this.nudgeDate &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class DebtsCompanion extends UpdateCompanion<Debt> {
  final Value<String> id;
  final Value<String> counterparty;
  final Value<String> direction;
  final Value<double> principal;
  final Value<double> paid;
  final Value<String?> note;
  final Value<DateTime?> dueDate;
  final Value<DateTime?> nudgeDate;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DebtsCompanion({
    this.id = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.direction = const Value.absent(),
    this.principal = const Value.absent(),
    this.paid = const Value.absent(),
    this.note = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.nudgeDate = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtsCompanion.insert({
    required String id,
    required String counterparty,
    required String direction,
    required double principal,
    this.paid = const Value.absent(),
    this.note = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.nudgeDate = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        counterparty = Value(counterparty),
        direction = Value(direction),
        principal = Value(principal);
  static Insertable<Debt> custom({
    Expression<String>? id,
    Expression<String>? counterparty,
    Expression<String>? direction,
    Expression<double>? principal,
    Expression<double>? paid,
    Expression<String>? note,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? nudgeDate,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (counterparty != null) 'counterparty': counterparty,
      if (direction != null) 'direction': direction,
      if (principal != null) 'principal': principal,
      if (paid != null) 'paid': paid,
      if (note != null) 'note': note,
      if (dueDate != null) 'due_date': dueDate,
      if (nudgeDate != null) 'nudge_date': nudgeDate,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtsCompanion copyWith(
      {Value<String>? id,
      Value<String>? counterparty,
      Value<String>? direction,
      Value<double>? principal,
      Value<double>? paid,
      Value<String?>? note,
      Value<DateTime?>? dueDate,
      Value<DateTime?>? nudgeDate,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DebtsCompanion(
      id: id ?? this.id,
      counterparty: counterparty ?? this.counterparty,
      direction: direction ?? this.direction,
      principal: principal ?? this.principal,
      paid: paid ?? this.paid,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
      nudgeDate: nudgeDate ?? this.nudgeDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (counterparty.present) {
      map['counterparty'] = Variable<String>(counterparty.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (principal.present) {
      map['principal'] = Variable<double>(principal.value);
    }
    if (paid.present) {
      map['paid'] = Variable<double>(paid.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (nudgeDate.present) {
      map['nudge_date'] = Variable<DateTime>(nudgeDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtsCompanion(')
          ..write('id: $id, ')
          ..write('counterparty: $counterparty, ')
          ..write('direction: $direction, ')
          ..write('principal: $principal, ')
          ..write('paid: $paid, ')
          ..write('note: $note, ')
          ..write('dueDate: $dueDate, ')
          ..write('nudgeDate: $nudgeDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SplitsTable extends Splits with TableInfo<$SplitsTable, Split> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalPaidMeta =
      const VerificationMeta('totalPaid');
  @override
  late final GeneratedColumn<double> totalPaid = GeneratedColumn<double>(
      'total_paid', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _myShareMeta =
      const VerificationMeta('myShare');
  @override
  late final GeneratedColumn<double> myShare = GeneratedColumn<double>(
      'my_share', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _receivedMeta =
      const VerificationMeta('received');
  @override
  late final GeneratedColumn<double> received = GeneratedColumn<double>(
      'received', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _absorbedMeta =
      const VerificationMeta('absorbed');
  @override
  late final GeneratedColumn<double> absorbed = GeneratedColumn<double>(
      'absorbed', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _membersJsonMeta =
      const VerificationMeta('membersJson');
  @override
  late final GeneratedColumn<String> membersJson = GeneratedColumn<String>(
      'members_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        code,
        totalPaid,
        myShare,
        received,
        absorbed,
        membersJson,
        note,
        status,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'splits';
  @override
  VerificationContext validateIntegrity(Insertable<Split> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    }
    if (data.containsKey('total_paid')) {
      context.handle(_totalPaidMeta,
          totalPaid.isAcceptableOrUnknown(data['total_paid']!, _totalPaidMeta));
    } else if (isInserting) {
      context.missing(_totalPaidMeta);
    }
    if (data.containsKey('my_share')) {
      context.handle(_myShareMeta,
          myShare.isAcceptableOrUnknown(data['my_share']!, _myShareMeta));
    } else if (isInserting) {
      context.missing(_myShareMeta);
    }
    if (data.containsKey('received')) {
      context.handle(_receivedMeta,
          received.isAcceptableOrUnknown(data['received']!, _receivedMeta));
    }
    if (data.containsKey('absorbed')) {
      context.handle(_absorbedMeta,
          absorbed.isAcceptableOrUnknown(data['absorbed']!, _absorbedMeta));
    }
    if (data.containsKey('members_json')) {
      context.handle(
          _membersJsonMeta,
          membersJson.isAcceptableOrUnknown(
              data['members_json']!, _membersJsonMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Split map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Split(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code']),
      totalPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_paid'])!,
      myShare: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}my_share'])!,
      received: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}received'])!,
      absorbed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}absorbed'])!,
      membersJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}members_json'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SplitsTable createAlias(String alias) {
    return $SplitsTable(attachedDatabase, alias);
  }
}

class Split extends DataClass implements Insertable<Split> {
  final String id;
  final String title;

  /// Short share code (e.g. `SP-7K2Q`) so the people in the split can be
  /// named and see the same split. Owner rule 2026-09-27.
  final String? code;
  final double totalPaid;
  final double myShare;
  final double received;
  final double absorbed;

  /// JSON list of member names for display, e.g. ["Ravi","Asha"].
  final String membersJson;
  final String? note;

  /// 'open' or 'closed'. Auto-closed when received+absorbed covers receivable.
  final String status;
  final DateTime createdAt;
  const Split(
      {required this.id,
      required this.title,
      this.code,
      required this.totalPaid,
      required this.myShare,
      required this.received,
      required this.absorbed,
      required this.membersJson,
      this.note,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['total_paid'] = Variable<double>(totalPaid);
    map['my_share'] = Variable<double>(myShare);
    map['received'] = Variable<double>(received);
    map['absorbed'] = Variable<double>(absorbed);
    map['members_json'] = Variable<String>(membersJson);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SplitsCompanion toCompanion(bool nullToAbsent) {
    return SplitsCompanion(
      id: Value(id),
      title: Value(title),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      totalPaid: Value(totalPaid),
      myShare: Value(myShare),
      received: Value(received),
      absorbed: Value(absorbed),
      membersJson: Value(membersJson),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Split.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Split(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      code: serializer.fromJson<String?>(json['code']),
      totalPaid: serializer.fromJson<double>(json['totalPaid']),
      myShare: serializer.fromJson<double>(json['myShare']),
      received: serializer.fromJson<double>(json['received']),
      absorbed: serializer.fromJson<double>(json['absorbed']),
      membersJson: serializer.fromJson<String>(json['membersJson']),
      note: serializer.fromJson<String?>(json['note']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'code': serializer.toJson<String?>(code),
      'totalPaid': serializer.toJson<double>(totalPaid),
      'myShare': serializer.toJson<double>(myShare),
      'received': serializer.toJson<double>(received),
      'absorbed': serializer.toJson<double>(absorbed),
      'membersJson': serializer.toJson<String>(membersJson),
      'note': serializer.toJson<String?>(note),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Split copyWith(
          {String? id,
          String? title,
          Value<String?> code = const Value.absent(),
          double? totalPaid,
          double? myShare,
          double? received,
          double? absorbed,
          String? membersJson,
          Value<String?> note = const Value.absent(),
          String? status,
          DateTime? createdAt}) =>
      Split(
        id: id ?? this.id,
        title: title ?? this.title,
        code: code.present ? code.value : this.code,
        totalPaid: totalPaid ?? this.totalPaid,
        myShare: myShare ?? this.myShare,
        received: received ?? this.received,
        absorbed: absorbed ?? this.absorbed,
        membersJson: membersJson ?? this.membersJson,
        note: note.present ? note.value : this.note,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  Split copyWithCompanion(SplitsCompanion data) {
    return Split(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      code: data.code.present ? data.code.value : this.code,
      totalPaid: data.totalPaid.present ? data.totalPaid.value : this.totalPaid,
      myShare: data.myShare.present ? data.myShare.value : this.myShare,
      received: data.received.present ? data.received.value : this.received,
      absorbed: data.absorbed.present ? data.absorbed.value : this.absorbed,
      membersJson:
          data.membersJson.present ? data.membersJson.value : this.membersJson,
      note: data.note.present ? data.note.value : this.note,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Split(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('code: $code, ')
          ..write('totalPaid: $totalPaid, ')
          ..write('myShare: $myShare, ')
          ..write('received: $received, ')
          ..write('absorbed: $absorbed, ')
          ..write('membersJson: $membersJson, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, code, totalPaid, myShare, received,
      absorbed, membersJson, note, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Split &&
          other.id == this.id &&
          other.title == this.title &&
          other.code == this.code &&
          other.totalPaid == this.totalPaid &&
          other.myShare == this.myShare &&
          other.received == this.received &&
          other.absorbed == this.absorbed &&
          other.membersJson == this.membersJson &&
          other.note == this.note &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class SplitsCompanion extends UpdateCompanion<Split> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> code;
  final Value<double> totalPaid;
  final Value<double> myShare;
  final Value<double> received;
  final Value<double> absorbed;
  final Value<String> membersJson;
  final Value<String?> note;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SplitsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.code = const Value.absent(),
    this.totalPaid = const Value.absent(),
    this.myShare = const Value.absent(),
    this.received = const Value.absent(),
    this.absorbed = const Value.absent(),
    this.membersJson = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SplitsCompanion.insert({
    required String id,
    required String title,
    this.code = const Value.absent(),
    required double totalPaid,
    required double myShare,
    this.received = const Value.absent(),
    this.absorbed = const Value.absent(),
    this.membersJson = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        totalPaid = Value(totalPaid),
        myShare = Value(myShare);
  static Insertable<Split> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? code,
    Expression<double>? totalPaid,
    Expression<double>? myShare,
    Expression<double>? received,
    Expression<double>? absorbed,
    Expression<String>? membersJson,
    Expression<String>? note,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (code != null) 'code': code,
      if (totalPaid != null) 'total_paid': totalPaid,
      if (myShare != null) 'my_share': myShare,
      if (received != null) 'received': received,
      if (absorbed != null) 'absorbed': absorbed,
      if (membersJson != null) 'members_json': membersJson,
      if (note != null) 'note': note,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SplitsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? code,
      Value<double>? totalPaid,
      Value<double>? myShare,
      Value<double>? received,
      Value<double>? absorbed,
      Value<String>? membersJson,
      Value<String?>? note,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SplitsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      code: code ?? this.code,
      totalPaid: totalPaid ?? this.totalPaid,
      myShare: myShare ?? this.myShare,
      received: received ?? this.received,
      absorbed: absorbed ?? this.absorbed,
      membersJson: membersJson ?? this.membersJson,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (totalPaid.present) {
      map['total_paid'] = Variable<double>(totalPaid.value);
    }
    if (myShare.present) {
      map['my_share'] = Variable<double>(myShare.value);
    }
    if (received.present) {
      map['received'] = Variable<double>(received.value);
    }
    if (absorbed.present) {
      map['absorbed'] = Variable<double>(absorbed.value);
    }
    if (membersJson.present) {
      map['members_json'] = Variable<String>(membersJson.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('code: $code, ')
          ..write('totalPaid: $totalPaid, ')
          ..write('myShare: $myShare, ')
          ..write('received: $received, ')
          ..write('absorbed: $absorbed, ')
          ..write('membersJson: $membersJson, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstrumentsTable extends Instruments
    with TableInfo<$InstrumentsTable, Instrument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstrumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('stock'));
  static const VerificationMeta _investedMeta =
      const VerificationMeta('invested');
  @override
  late final GeneratedColumn<double> invested = GeneratedColumn<double>(
      'invested', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentMeta =
      const VerificationMeta('current');
  @override
  late final GeneratedColumn<double> current = GeneratedColumn<double>(
      'current', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, kind, invested, current, note, status, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instruments';
  @override
  VerificationContext validateIntegrity(Insertable<Instrument> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('invested')) {
      context.handle(_investedMeta,
          invested.isAcceptableOrUnknown(data['invested']!, _investedMeta));
    }
    if (data.containsKey('current')) {
      context.handle(_currentMeta,
          current.isAcceptableOrUnknown(data['current']!, _currentMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Instrument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Instrument(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      invested: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}invested'])!,
      current: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}current'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InstrumentsTable createAlias(String alias) {
    return $InstrumentsTable(attachedDatabase, alias);
  }
}

class Instrument extends DataClass implements Insertable<Instrument> {
  final String id;
  final String name;
  final String kind;

  /// Money put in (principal / buy cost).
  final double invested;

  /// Latest marked value (manual update — vault is offline-first).
  final double current;
  final String? note;

  /// 'open' or 'archived'. Archived rows leave totals and history intact.
  final String status;
  final DateTime createdAt;
  const Instrument(
      {required this.id,
      required this.name,
      required this.kind,
      required this.invested,
      required this.current,
      this.note,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['invested'] = Variable<double>(invested);
    map['current'] = Variable<double>(current);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InstrumentsCompanion toCompanion(bool nullToAbsent) {
    return InstrumentsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      invested: Value(invested),
      current: Value(current),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Instrument.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Instrument(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      invested: serializer.fromJson<double>(json['invested']),
      current: serializer.fromJson<double>(json['current']),
      note: serializer.fromJson<String?>(json['note']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'invested': serializer.toJson<double>(invested),
      'current': serializer.toJson<double>(current),
      'note': serializer.toJson<String?>(note),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Instrument copyWith(
          {String? id,
          String? name,
          String? kind,
          double? invested,
          double? current,
          Value<String?> note = const Value.absent(),
          String? status,
          DateTime? createdAt}) =>
      Instrument(
        id: id ?? this.id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        invested: invested ?? this.invested,
        current: current ?? this.current,
        note: note.present ? note.value : this.note,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  Instrument copyWithCompanion(InstrumentsCompanion data) {
    return Instrument(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      invested: data.invested.present ? data.invested.value : this.invested,
      current: data.current.present ? data.current.value : this.current,
      note: data.note.present ? data.note.value : this.note,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Instrument(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('invested: $invested, ')
          ..write('current: $current, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, kind, invested, current, note, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Instrument &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.invested == this.invested &&
          other.current == this.current &&
          other.note == this.note &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class InstrumentsCompanion extends UpdateCompanion<Instrument> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<double> invested;
  final Value<double> current;
  final Value<String?> note;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const InstrumentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.invested = const Value.absent(),
    this.current = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstrumentsCompanion.insert({
    required String id,
    required String name,
    this.kind = const Value.absent(),
    this.invested = const Value.absent(),
    this.current = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Instrument> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<double>? invested,
    Expression<double>? current,
    Expression<String>? note,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (invested != null) 'invested': invested,
      if (current != null) 'current': current,
      if (note != null) 'note': note,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstrumentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? kind,
      Value<double>? invested,
      Value<double>? current,
      Value<String?>? note,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return InstrumentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      invested: invested ?? this.invested,
      current: current ?? this.current,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (invested.present) {
      map['invested'] = Variable<double>(invested.value);
    }
    if (current.present) {
      map['current'] = Variable<double>(current.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('invested: $invested, ')
          ..write('current: $current, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SnapshotsTable extends Snapshots
    with TableInfo<$SnapshotsTable, Snapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
      'month', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _openBalanceMeta =
      const VerificationMeta('openBalance');
  @override
  late final GeneratedColumn<double> openBalance = GeneratedColumn<double>(
      'open_balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _countedCloseMeta =
      const VerificationMeta('countedClose');
  @override
  late final GeneratedColumn<double> countedClose = GeneratedColumn<double>(
      'counted_close', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _hasCloseMeta =
      const VerificationMeta('hasClose');
  @override
  late final GeneratedColumn<int> hasClose = GeneratedColumn<int>(
      'has_close', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [month, accountId, openBalance, countedClose, hasClose, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<Snapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('open_balance')) {
      context.handle(
          _openBalanceMeta,
          openBalance.isAcceptableOrUnknown(
              data['open_balance']!, _openBalanceMeta));
    }
    if (data.containsKey('counted_close')) {
      context.handle(
          _countedCloseMeta,
          countedClose.isAcceptableOrUnknown(
              data['counted_close']!, _countedCloseMeta));
    }
    if (data.containsKey('has_close')) {
      context.handle(_hasCloseMeta,
          hasClose.isAcceptableOrUnknown(data['has_close']!, _hasCloseMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {month, accountId};
  @override
  Snapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Snapshot(
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      openBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}open_balance'])!,
      countedClose: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}counted_close'])!,
      hasClose: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}has_close'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SnapshotsTable createAlias(String alias) {
    return $SnapshotsTable(attachedDatabase, alias);
  }
}

class Snapshot extends DataClass implements Insertable<Snapshot> {
  /// `YYYY-MM`.
  final String month;
  final String accountId;
  final double openBalance;
  final double countedClose;
  final int hasClose;
  final DateTime createdAt;
  const Snapshot(
      {required this.month,
      required this.accountId,
      required this.openBalance,
      required this.countedClose,
      required this.hasClose,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month'] = Variable<String>(month);
    map['account_id'] = Variable<String>(accountId);
    map['open_balance'] = Variable<double>(openBalance);
    map['counted_close'] = Variable<double>(countedClose);
    map['has_close'] = Variable<int>(hasClose);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SnapshotsCompanion toCompanion(bool nullToAbsent) {
    return SnapshotsCompanion(
      month: Value(month),
      accountId: Value(accountId),
      openBalance: Value(openBalance),
      countedClose: Value(countedClose),
      hasClose: Value(hasClose),
      createdAt: Value(createdAt),
    );
  }

  factory Snapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Snapshot(
      month: serializer.fromJson<String>(json['month']),
      accountId: serializer.fromJson<String>(json['accountId']),
      openBalance: serializer.fromJson<double>(json['openBalance']),
      countedClose: serializer.fromJson<double>(json['countedClose']),
      hasClose: serializer.fromJson<int>(json['hasClose']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'month': serializer.toJson<String>(month),
      'accountId': serializer.toJson<String>(accountId),
      'openBalance': serializer.toJson<double>(openBalance),
      'countedClose': serializer.toJson<double>(countedClose),
      'hasClose': serializer.toJson<int>(hasClose),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Snapshot copyWith(
          {String? month,
          String? accountId,
          double? openBalance,
          double? countedClose,
          int? hasClose,
          DateTime? createdAt}) =>
      Snapshot(
        month: month ?? this.month,
        accountId: accountId ?? this.accountId,
        openBalance: openBalance ?? this.openBalance,
        countedClose: countedClose ?? this.countedClose,
        hasClose: hasClose ?? this.hasClose,
        createdAt: createdAt ?? this.createdAt,
      );
  Snapshot copyWithCompanion(SnapshotsCompanion data) {
    return Snapshot(
      month: data.month.present ? data.month.value : this.month,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      openBalance:
          data.openBalance.present ? data.openBalance.value : this.openBalance,
      countedClose: data.countedClose.present
          ? data.countedClose.value
          : this.countedClose,
      hasClose: data.hasClose.present ? data.hasClose.value : this.hasClose,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Snapshot(')
          ..write('month: $month, ')
          ..write('accountId: $accountId, ')
          ..write('openBalance: $openBalance, ')
          ..write('countedClose: $countedClose, ')
          ..write('hasClose: $hasClose, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      month, accountId, openBalance, countedClose, hasClose, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Snapshot &&
          other.month == this.month &&
          other.accountId == this.accountId &&
          other.openBalance == this.openBalance &&
          other.countedClose == this.countedClose &&
          other.hasClose == this.hasClose &&
          other.createdAt == this.createdAt);
}

class SnapshotsCompanion extends UpdateCompanion<Snapshot> {
  final Value<String> month;
  final Value<String> accountId;
  final Value<double> openBalance;
  final Value<double> countedClose;
  final Value<int> hasClose;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SnapshotsCompanion({
    this.month = const Value.absent(),
    this.accountId = const Value.absent(),
    this.openBalance = const Value.absent(),
    this.countedClose = const Value.absent(),
    this.hasClose = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnapshotsCompanion.insert({
    required String month,
    required String accountId,
    this.openBalance = const Value.absent(),
    this.countedClose = const Value.absent(),
    this.hasClose = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : month = Value(month),
        accountId = Value(accountId);
  static Insertable<Snapshot> custom({
    Expression<String>? month,
    Expression<String>? accountId,
    Expression<double>? openBalance,
    Expression<double>? countedClose,
    Expression<int>? hasClose,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (month != null) 'month': month,
      if (accountId != null) 'account_id': accountId,
      if (openBalance != null) 'open_balance': openBalance,
      if (countedClose != null) 'counted_close': countedClose,
      if (hasClose != null) 'has_close': hasClose,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnapshotsCompanion copyWith(
      {Value<String>? month,
      Value<String>? accountId,
      Value<double>? openBalance,
      Value<double>? countedClose,
      Value<int>? hasClose,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SnapshotsCompanion(
      month: month ?? this.month,
      accountId: accountId ?? this.accountId,
      openBalance: openBalance ?? this.openBalance,
      countedClose: countedClose ?? this.countedClose,
      hasClose: hasClose ?? this.hasClose,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (openBalance.present) {
      map['open_balance'] = Variable<double>(openBalance.value);
    }
    if (countedClose.present) {
      map['counted_close'] = Variable<double>(countedClose.value);
    }
    if (hasClose.present) {
      map['has_close'] = Variable<int>(hasClose.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotsCompanion(')
          ..write('month: $month, ')
          ..write('accountId: $accountId, ')
          ..write('openBalance: $openBalance, ')
          ..write('countedClose: $countedClose, ')
          ..write('hasClose: $hasClose, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) => Setting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthOpenTable extends MonthOpen
    with TableInfo<$MonthOpenTable, MonthOpenData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthOpenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
      'month', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _budgetInMeta =
      const VerificationMeta('budgetIn');
  @override
  late final GeneratedColumn<double> budgetIn = GeneratedColumn<double>(
      'budget_in', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _budgetOutMeta =
      const VerificationMeta('budgetOut');
  @override
  late final GeneratedColumn<double> budgetOut = GeneratedColumn<double>(
      'budget_out', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bankBalanceMeta =
      const VerificationMeta('bankBalance');
  @override
  late final GeneratedColumn<double> bankBalance = GeneratedColumn<double>(
      'bank_balance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _cashBalanceMeta =
      const VerificationMeta('cashBalance');
  @override
  late final GeneratedColumn<double> cashBalance = GeneratedColumn<double>(
      'cash_balance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _cardLimitMeta =
      const VerificationMeta('cardLimit');
  @override
  late final GeneratedColumn<double> cardLimit = GeneratedColumn<double>(
      'card_limit', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [month, budgetIn, budgetOut, bankBalance, cashBalance, cardLimit];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'month_open';
  @override
  VerificationContext validateIntegrity(Insertable<MonthOpenData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('budget_in')) {
      context.handle(_budgetInMeta,
          budgetIn.isAcceptableOrUnknown(data['budget_in']!, _budgetInMeta));
    }
    if (data.containsKey('budget_out')) {
      context.handle(_budgetOutMeta,
          budgetOut.isAcceptableOrUnknown(data['budget_out']!, _budgetOutMeta));
    }
    if (data.containsKey('bank_balance')) {
      context.handle(
          _bankBalanceMeta,
          bankBalance.isAcceptableOrUnknown(
              data['bank_balance']!, _bankBalanceMeta));
    }
    if (data.containsKey('cash_balance')) {
      context.handle(
          _cashBalanceMeta,
          cashBalance.isAcceptableOrUnknown(
              data['cash_balance']!, _cashBalanceMeta));
    }
    if (data.containsKey('card_limit')) {
      context.handle(_cardLimitMeta,
          cardLimit.isAcceptableOrUnknown(data['card_limit']!, _cardLimitMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {month};
  @override
  MonthOpenData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthOpenData(
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month'])!,
      budgetIn: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}budget_in']),
      budgetOut: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}budget_out']),
      bankBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bank_balance']),
      cashBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cash_balance']),
      cardLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}card_limit']),
    );
  }

  @override
  $MonthOpenTable createAlias(String alias) {
    return $MonthOpenTable(attachedDatabase, alias);
  }
}

class MonthOpenData extends DataClass implements Insertable<MonthOpenData> {
  /// `YYYY-MM`.
  final String month;
  final double? budgetIn;
  final double? budgetOut;
  final double? bankBalance;
  final double? cashBalance;
  final double? cardLimit;
  const MonthOpenData(
      {required this.month,
      this.budgetIn,
      this.budgetOut,
      this.bankBalance,
      this.cashBalance,
      this.cardLimit});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month'] = Variable<String>(month);
    if (!nullToAbsent || budgetIn != null) {
      map['budget_in'] = Variable<double>(budgetIn);
    }
    if (!nullToAbsent || budgetOut != null) {
      map['budget_out'] = Variable<double>(budgetOut);
    }
    if (!nullToAbsent || bankBalance != null) {
      map['bank_balance'] = Variable<double>(bankBalance);
    }
    if (!nullToAbsent || cashBalance != null) {
      map['cash_balance'] = Variable<double>(cashBalance);
    }
    if (!nullToAbsent || cardLimit != null) {
      map['card_limit'] = Variable<double>(cardLimit);
    }
    return map;
  }

  MonthOpenCompanion toCompanion(bool nullToAbsent) {
    return MonthOpenCompanion(
      month: Value(month),
      budgetIn: budgetIn == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetIn),
      budgetOut: budgetOut == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetOut),
      bankBalance: bankBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(bankBalance),
      cashBalance: cashBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(cashBalance),
      cardLimit: cardLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(cardLimit),
    );
  }

  factory MonthOpenData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthOpenData(
      month: serializer.fromJson<String>(json['month']),
      budgetIn: serializer.fromJson<double?>(json['budgetIn']),
      budgetOut: serializer.fromJson<double?>(json['budgetOut']),
      bankBalance: serializer.fromJson<double?>(json['bankBalance']),
      cashBalance: serializer.fromJson<double?>(json['cashBalance']),
      cardLimit: serializer.fromJson<double?>(json['cardLimit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'month': serializer.toJson<String>(month),
      'budgetIn': serializer.toJson<double?>(budgetIn),
      'budgetOut': serializer.toJson<double?>(budgetOut),
      'bankBalance': serializer.toJson<double?>(bankBalance),
      'cashBalance': serializer.toJson<double?>(cashBalance),
      'cardLimit': serializer.toJson<double?>(cardLimit),
    };
  }

  MonthOpenData copyWith(
          {String? month,
          Value<double?> budgetIn = const Value.absent(),
          Value<double?> budgetOut = const Value.absent(),
          Value<double?> bankBalance = const Value.absent(),
          Value<double?> cashBalance = const Value.absent(),
          Value<double?> cardLimit = const Value.absent()}) =>
      MonthOpenData(
        month: month ?? this.month,
        budgetIn: budgetIn.present ? budgetIn.value : this.budgetIn,
        budgetOut: budgetOut.present ? budgetOut.value : this.budgetOut,
        bankBalance: bankBalance.present ? bankBalance.value : this.bankBalance,
        cashBalance: cashBalance.present ? cashBalance.value : this.cashBalance,
        cardLimit: cardLimit.present ? cardLimit.value : this.cardLimit,
      );
  MonthOpenData copyWithCompanion(MonthOpenCompanion data) {
    return MonthOpenData(
      month: data.month.present ? data.month.value : this.month,
      budgetIn: data.budgetIn.present ? data.budgetIn.value : this.budgetIn,
      budgetOut: data.budgetOut.present ? data.budgetOut.value : this.budgetOut,
      bankBalance:
          data.bankBalance.present ? data.bankBalance.value : this.bankBalance,
      cashBalance:
          data.cashBalance.present ? data.cashBalance.value : this.cashBalance,
      cardLimit: data.cardLimit.present ? data.cardLimit.value : this.cardLimit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthOpenData(')
          ..write('month: $month, ')
          ..write('budgetIn: $budgetIn, ')
          ..write('budgetOut: $budgetOut, ')
          ..write('bankBalance: $bankBalance, ')
          ..write('cashBalance: $cashBalance, ')
          ..write('cardLimit: $cardLimit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      month, budgetIn, budgetOut, bankBalance, cashBalance, cardLimit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthOpenData &&
          other.month == this.month &&
          other.budgetIn == this.budgetIn &&
          other.budgetOut == this.budgetOut &&
          other.bankBalance == this.bankBalance &&
          other.cashBalance == this.cashBalance &&
          other.cardLimit == this.cardLimit);
}

class MonthOpenCompanion extends UpdateCompanion<MonthOpenData> {
  final Value<String> month;
  final Value<double?> budgetIn;
  final Value<double?> budgetOut;
  final Value<double?> bankBalance;
  final Value<double?> cashBalance;
  final Value<double?> cardLimit;
  final Value<int> rowid;
  const MonthOpenCompanion({
    this.month = const Value.absent(),
    this.budgetIn = const Value.absent(),
    this.budgetOut = const Value.absent(),
    this.bankBalance = const Value.absent(),
    this.cashBalance = const Value.absent(),
    this.cardLimit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthOpenCompanion.insert({
    required String month,
    this.budgetIn = const Value.absent(),
    this.budgetOut = const Value.absent(),
    this.bankBalance = const Value.absent(),
    this.cashBalance = const Value.absent(),
    this.cardLimit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : month = Value(month);
  static Insertable<MonthOpenData> custom({
    Expression<String>? month,
    Expression<double>? budgetIn,
    Expression<double>? budgetOut,
    Expression<double>? bankBalance,
    Expression<double>? cashBalance,
    Expression<double>? cardLimit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (month != null) 'month': month,
      if (budgetIn != null) 'budget_in': budgetIn,
      if (budgetOut != null) 'budget_out': budgetOut,
      if (bankBalance != null) 'bank_balance': bankBalance,
      if (cashBalance != null) 'cash_balance': cashBalance,
      if (cardLimit != null) 'card_limit': cardLimit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthOpenCompanion copyWith(
      {Value<String>? month,
      Value<double?>? budgetIn,
      Value<double?>? budgetOut,
      Value<double?>? bankBalance,
      Value<double?>? cashBalance,
      Value<double?>? cardLimit,
      Value<int>? rowid}) {
    return MonthOpenCompanion(
      month: month ?? this.month,
      budgetIn: budgetIn ?? this.budgetIn,
      budgetOut: budgetOut ?? this.budgetOut,
      bankBalance: bankBalance ?? this.bankBalance,
      cashBalance: cashBalance ?? this.cashBalance,
      cardLimit: cardLimit ?? this.cardLimit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (budgetIn.present) {
      map['budget_in'] = Variable<double>(budgetIn.value);
    }
    if (budgetOut.present) {
      map['budget_out'] = Variable<double>(budgetOut.value);
    }
    if (bankBalance.present) {
      map['bank_balance'] = Variable<double>(bankBalance.value);
    }
    if (cashBalance.present) {
      map['cash_balance'] = Variable<double>(cashBalance.value);
    }
    if (cardLimit.present) {
      map['card_limit'] = Variable<double>(cardLimit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthOpenCompanion(')
          ..write('month: $month, ')
          ..write('budgetIn: $budgetIn, ')
          ..write('budgetOut: $budgetOut, ')
          ..write('bankBalance: $bankBalance, ')
          ..write('cashBalance: $cashBalance, ')
          ..write('cardLimit: $cardLimit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringRulesTable extends RecurringRules
    with TableInfo<$RecurringRulesTable, RecurringRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _categoryRawMeta =
      const VerificationMeta('categoryRaw');
  @override
  late final GeneratedColumn<String> categoryRaw = GeneratedColumn<String>(
      'category_raw', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bucketMeta = const VerificationMeta('bucket');
  @override
  late final GeneratedColumn<String> bucket = GeneratedColumn<String>(
      'bucket', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dayOfMonthMeta =
      const VerificationMeta('dayOfMonth');
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
      'day_of_month', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _monthsMeta = const VerificationMeta('months');
  @override
  late final GeneratedColumn<int> months = GeneratedColumn<int>(
      'months', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _startMonthMeta =
      const VerificationMeta('startMonth');
  @override
  late final GeneratedColumn<String> startMonth = GeneratedColumn<String>(
      'start_month', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastAppliedMonthMeta =
      const VerificationMeta('lastAppliedMonth');
  @override
  late final GeneratedColumn<String> lastAppliedMonth = GeneratedColumn<String>(
      'last_applied_month', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        amount,
        categoryRaw,
        bucket,
        accountId,
        dayOfMonth,
        months,
        startMonth,
        lastAppliedMonth,
        note,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_rules';
  @override
  VerificationContext validateIntegrity(Insertable<RecurringRule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_raw')) {
      context.handle(
          _categoryRawMeta,
          categoryRaw.isAcceptableOrUnknown(
              data['category_raw']!, _categoryRawMeta));
    } else if (isInserting) {
      context.missing(_categoryRawMeta);
    }
    if (data.containsKey('bucket')) {
      context.handle(_bucketMeta,
          bucket.isAcceptableOrUnknown(data['bucket']!, _bucketMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
          _dayOfMonthMeta,
          dayOfMonth.isAcceptableOrUnknown(
              data['day_of_month']!, _dayOfMonthMeta));
    }
    if (data.containsKey('months')) {
      context.handle(_monthsMeta,
          months.isAcceptableOrUnknown(data['months']!, _monthsMeta));
    }
    if (data.containsKey('start_month')) {
      context.handle(
          _startMonthMeta,
          startMonth.isAcceptableOrUnknown(
              data['start_month']!, _startMonthMeta));
    } else if (isInserting) {
      context.missing(_startMonthMeta);
    }
    if (data.containsKey('last_applied_month')) {
      context.handle(
          _lastAppliedMonthMeta,
          lastAppliedMonth.isAcceptableOrUnknown(
              data['last_applied_month']!, _lastAppliedMonthMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringRule(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      categoryRaw: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_raw'])!,
      bucket: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bucket']),
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id']),
      dayOfMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_of_month'])!,
      months: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}months'])!,
      startMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_month'])!,
      lastAppliedMonth: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_applied_month']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RecurringRulesTable createAlias(String alias) {
    return $RecurringRulesTable(attachedDatabase, alias);
  }
}

class RecurringRule extends DataClass implements Insertable<RecurringRule> {
  final String id;

  /// 'in' or 'out'.
  final String kind;
  final double amount;
  final String categoryRaw;
  final String? bucket;
  final String? accountId;

  /// Day of month the entry lands on (1–28 keeps it month-safe).
  final int dayOfMonth;

  /// How many months to apply, counting from [startMonth].
  final int months;

  /// `YYYY-MM` the rule counts forward from.
  final String startMonth;

  /// `YYYY-MM` of the last month this rule filled in (null = not applied yet).
  final String? lastAppliedMonth;

  /// Freeform note on the rule itself.
  final String? note;
  final DateTime createdAt;
  const RecurringRule(
      {required this.id,
      required this.kind,
      required this.amount,
      required this.categoryRaw,
      this.bucket,
      this.accountId,
      required this.dayOfMonth,
      required this.months,
      required this.startMonth,
      this.lastAppliedMonth,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['amount'] = Variable<double>(amount);
    map['category_raw'] = Variable<String>(categoryRaw);
    if (!nullToAbsent || bucket != null) {
      map['bucket'] = Variable<String>(bucket);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['day_of_month'] = Variable<int>(dayOfMonth);
    map['months'] = Variable<int>(months);
    map['start_month'] = Variable<String>(startMonth);
    if (!nullToAbsent || lastAppliedMonth != null) {
      map['last_applied_month'] = Variable<String>(lastAppliedMonth);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RecurringRulesCompanion toCompanion(bool nullToAbsent) {
    return RecurringRulesCompanion(
      id: Value(id),
      kind: Value(kind),
      amount: Value(amount),
      categoryRaw: Value(categoryRaw),
      bucket:
          bucket == null && nullToAbsent ? const Value.absent() : Value(bucket),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      dayOfMonth: Value(dayOfMonth),
      months: Value(months),
      startMonth: Value(startMonth),
      lastAppliedMonth: lastAppliedMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAppliedMonth),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory RecurringRule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringRule(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      amount: serializer.fromJson<double>(json['amount']),
      categoryRaw: serializer.fromJson<String>(json['categoryRaw']),
      bucket: serializer.fromJson<String?>(json['bucket']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      dayOfMonth: serializer.fromJson<int>(json['dayOfMonth']),
      months: serializer.fromJson<int>(json['months']),
      startMonth: serializer.fromJson<String>(json['startMonth']),
      lastAppliedMonth: serializer.fromJson<String?>(json['lastAppliedMonth']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'amount': serializer.toJson<double>(amount),
      'categoryRaw': serializer.toJson<String>(categoryRaw),
      'bucket': serializer.toJson<String?>(bucket),
      'accountId': serializer.toJson<String?>(accountId),
      'dayOfMonth': serializer.toJson<int>(dayOfMonth),
      'months': serializer.toJson<int>(months),
      'startMonth': serializer.toJson<String>(startMonth),
      'lastAppliedMonth': serializer.toJson<String?>(lastAppliedMonth),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RecurringRule copyWith(
          {String? id,
          String? kind,
          double? amount,
          String? categoryRaw,
          Value<String?> bucket = const Value.absent(),
          Value<String?> accountId = const Value.absent(),
          int? dayOfMonth,
          int? months,
          String? startMonth,
          Value<String?> lastAppliedMonth = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      RecurringRule(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        amount: amount ?? this.amount,
        categoryRaw: categoryRaw ?? this.categoryRaw,
        bucket: bucket.present ? bucket.value : this.bucket,
        accountId: accountId.present ? accountId.value : this.accountId,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        months: months ?? this.months,
        startMonth: startMonth ?? this.startMonth,
        lastAppliedMonth: lastAppliedMonth.present
            ? lastAppliedMonth.value
            : this.lastAppliedMonth,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  RecurringRule copyWithCompanion(RecurringRulesCompanion data) {
    return RecurringRule(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryRaw:
          data.categoryRaw.present ? data.categoryRaw.value : this.categoryRaw,
      bucket: data.bucket.present ? data.bucket.value : this.bucket,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      dayOfMonth:
          data.dayOfMonth.present ? data.dayOfMonth.value : this.dayOfMonth,
      months: data.months.present ? data.months.value : this.months,
      startMonth:
          data.startMonth.present ? data.startMonth.value : this.startMonth,
      lastAppliedMonth: data.lastAppliedMonth.present
          ? data.lastAppliedMonth.value
          : this.lastAppliedMonth,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringRule(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('categoryRaw: $categoryRaw, ')
          ..write('bucket: $bucket, ')
          ..write('accountId: $accountId, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('months: $months, ')
          ..write('startMonth: $startMonth, ')
          ..write('lastAppliedMonth: $lastAppliedMonth, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      kind,
      amount,
      categoryRaw,
      bucket,
      accountId,
      dayOfMonth,
      months,
      startMonth,
      lastAppliedMonth,
      note,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringRule &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.categoryRaw == this.categoryRaw &&
          other.bucket == this.bucket &&
          other.accountId == this.accountId &&
          other.dayOfMonth == this.dayOfMonth &&
          other.months == this.months &&
          other.startMonth == this.startMonth &&
          other.lastAppliedMonth == this.lastAppliedMonth &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class RecurringRulesCompanion extends UpdateCompanion<RecurringRule> {
  final Value<String> id;
  final Value<String> kind;
  final Value<double> amount;
  final Value<String> categoryRaw;
  final Value<String?> bucket;
  final Value<String?> accountId;
  final Value<int> dayOfMonth;
  final Value<int> months;
  final Value<String> startMonth;
  final Value<String?> lastAppliedMonth;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RecurringRulesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryRaw = const Value.absent(),
    this.bucket = const Value.absent(),
    this.accountId = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.months = const Value.absent(),
    this.startMonth = const Value.absent(),
    this.lastAppliedMonth = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringRulesCompanion.insert({
    required String id,
    required String kind,
    required double amount,
    required String categoryRaw,
    this.bucket = const Value.absent(),
    this.accountId = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.months = const Value.absent(),
    required String startMonth,
    this.lastAppliedMonth = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        amount = Value(amount),
        categoryRaw = Value(categoryRaw),
        startMonth = Value(startMonth);
  static Insertable<RecurringRule> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<double>? amount,
    Expression<String>? categoryRaw,
    Expression<String>? bucket,
    Expression<String>? accountId,
    Expression<int>? dayOfMonth,
    Expression<int>? months,
    Expression<String>? startMonth,
    Expression<String>? lastAppliedMonth,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (categoryRaw != null) 'category_raw': categoryRaw,
      if (bucket != null) 'bucket': bucket,
      if (accountId != null) 'account_id': accountId,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (months != null) 'months': months,
      if (startMonth != null) 'start_month': startMonth,
      if (lastAppliedMonth != null) 'last_applied_month': lastAppliedMonth,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringRulesCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<double>? amount,
      Value<String>? categoryRaw,
      Value<String?>? bucket,
      Value<String?>? accountId,
      Value<int>? dayOfMonth,
      Value<int>? months,
      Value<String>? startMonth,
      Value<String?>? lastAppliedMonth,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return RecurringRulesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      categoryRaw: categoryRaw ?? this.categoryRaw,
      bucket: bucket ?? this.bucket,
      accountId: accountId ?? this.accountId,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      months: months ?? this.months,
      startMonth: startMonth ?? this.startMonth,
      lastAppliedMonth: lastAppliedMonth ?? this.lastAppliedMonth,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (categoryRaw.present) {
      map['category_raw'] = Variable<String>(categoryRaw.value);
    }
    if (bucket.present) {
      map['bucket'] = Variable<String>(bucket.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (months.present) {
      map['months'] = Variable<int>(months.value);
    }
    if (startMonth.present) {
      map['start_month'] = Variable<String>(startMonth.value);
    }
    if (lastAppliedMonth.present) {
      map['last_applied_month'] = Variable<String>(lastAppliedMonth.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringRulesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('categoryRaw: $categoryRaw, ')
          ..write('bucket: $bucket, ')
          ..write('accountId: $accountId, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('months: $months, ')
          ..write('startMonth: $startMonth, ')
          ..write('lastAppliedMonth: $lastAppliedMonth, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _monthKeyMeta =
      const VerificationMeta('monthKey');
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
      'month_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('open'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, code, monthKey, note, status, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(Insertable<Group> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(_monthKeyMeta,
          monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta));
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      monthKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month_key'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  final String id;
  final String name;

  /// Short code the other party types to join, e.g. `ET-4KQ2`.
  final String code;

  /// `YYYY-MM` the group covers (owner asked for a month per group).
  final String monthKey;
  final String? note;

  /// 'open' or 'closed'.
  final String status;
  final DateTime createdAt;
  const Group(
      {required this.id,
      required this.name,
      required this.code,
      required this.monthKey,
      this.note,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['month_key'] = Variable<String>(monthKey);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      name: Value(name),
      code: Value(code),
      monthKey: Value(monthKey),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Group.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      note: serializer.fromJson<String?>(json['note']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'monthKey': serializer.toJson<String>(monthKey),
      'note': serializer.toJson<String?>(note),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Group copyWith(
          {String? id,
          String? name,
          String? code,
          String? monthKey,
          Value<String?> note = const Value.absent(),
          String? status,
          DateTime? createdAt}) =>
      Group(
        id: id ?? this.id,
        name: name ?? this.name,
        code: code ?? this.code,
        monthKey: monthKey ?? this.monthKey,
        note: note.present ? note.value : this.note,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  Group copyWithCompanion(GroupsCompanion data) {
    return Group(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      note: data.note.present ? data.note.value : this.note,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('monthKey: $monthKey, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, code, monthKey, note, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.id == this.id &&
          other.name == this.name &&
          other.code == this.code &&
          other.monthKey == this.monthKey &&
          other.note == this.note &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> code;
  final Value<String> monthKey;
  final Value<String?> note;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String id,
    required String name,
    required String code,
    required String monthKey,
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        code = Value(code),
        monthKey = Value(monthKey);
  static Insertable<Group> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? monthKey,
    Expression<String>? note,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (monthKey != null) 'month_key': monthKey,
      if (note != null) 'note': note,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? code,
      Value<String>? monthKey,
      Value<String?>? note,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return GroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      monthKey: monthKey ?? this.monthKey,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('monthKey: $monthKey, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTable extends GroupMembers
    with TableInfo<$GroupMembersTable, GroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, groupId, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(Insertable<GroupMember> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMember(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GroupMembersTable createAlias(String alias) {
    return $GroupMembersTable(attachedDatabase, alias);
  }
}

class GroupMember extends DataClass implements Insertable<GroupMember> {
  final String id;
  final String groupId;
  final String name;
  final DateTime createdAt;
  const GroupMember(
      {required this.id,
      required this.groupId,
      required this.name,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory GroupMember.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMember(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GroupMember copyWith(
          {String? id, String? groupId, String? name, DateTime? createdAt}) =>
      GroupMember(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  GroupMember copyWithCompanion(GroupMembersCompanion data) {
    return GroupMember(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMember(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMember &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMember> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required String id,
    required String groupId,
    required String name,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        name = Value(name);
  static Insertable<GroupMember> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String>? name,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return GroupMembersCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupExpensesTable extends GroupExpenses
    with TableInfo<$GroupExpensesTable, GroupExpense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paidByMeta = const VerificationMeta('paidBy');
  @override
  late final GeneratedColumn<String> paidBy = GeneratedColumn<String>(
      'paid_by', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, groupId, title, amount, paidBy, occurredAt, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_expenses';
  @override
  VerificationContext validateIntegrity(Insertable<GroupExpense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('paid_by')) {
      context.handle(_paidByMeta,
          paidBy.isAcceptableOrUnknown(data['paid_by']!, _paidByMeta));
    } else if (isInserting) {
      context.missing(_paidByMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupExpense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupExpense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      paidBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}paid_by'])!,
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $GroupExpensesTable createAlias(String alias) {
    return $GroupExpensesTable(attachedDatabase, alias);
  }
}

class GroupExpense extends DataClass implements Insertable<GroupExpense> {
  final String id;
  final String groupId;
  final String title;
  final double amount;

  /// Participant name who paid.
  final String paidBy;
  final DateTime occurredAt;
  final String? note;
  const GroupExpense(
      {required this.id,
      required this.groupId,
      required this.title,
      required this.amount,
      required this.paidBy,
      required this.occurredAt,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['title'] = Variable<String>(title);
    map['amount'] = Variable<double>(amount);
    map['paid_by'] = Variable<String>(paidBy);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  GroupExpensesCompanion toCompanion(bool nullToAbsent) {
    return GroupExpensesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      title: Value(title),
      amount: Value(amount),
      paidBy: Value(paidBy),
      occurredAt: Value(occurredAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory GroupExpense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupExpense(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      title: serializer.fromJson<String>(json['title']),
      amount: serializer.fromJson<double>(json['amount']),
      paidBy: serializer.fromJson<String>(json['paidBy']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'title': serializer.toJson<String>(title),
      'amount': serializer.toJson<double>(amount),
      'paidBy': serializer.toJson<String>(paidBy),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  GroupExpense copyWith(
          {String? id,
          String? groupId,
          String? title,
          double? amount,
          String? paidBy,
          DateTime? occurredAt,
          Value<String?> note = const Value.absent()}) =>
      GroupExpense(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        paidBy: paidBy ?? this.paidBy,
        occurredAt: occurredAt ?? this.occurredAt,
        note: note.present ? note.value : this.note,
      );
  GroupExpense copyWithCompanion(GroupExpensesCompanion data) {
    return GroupExpense(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      title: data.title.present ? data.title.value : this.title,
      amount: data.amount.present ? data.amount.value : this.amount,
      paidBy: data.paidBy.present ? data.paidBy.value : this.paidBy,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupExpense(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('paidBy: $paidBy, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, groupId, title, amount, paidBy, occurredAt, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupExpense &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.title == this.title &&
          other.amount == this.amount &&
          other.paidBy == this.paidBy &&
          other.occurredAt == this.occurredAt &&
          other.note == this.note);
}

class GroupExpensesCompanion extends UpdateCompanion<GroupExpense> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> title;
  final Value<double> amount;
  final Value<String> paidBy;
  final Value<DateTime> occurredAt;
  final Value<String?> note;
  final Value<int> rowid;
  const GroupExpensesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.title = const Value.absent(),
    this.amount = const Value.absent(),
    this.paidBy = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupExpensesCompanion.insert({
    required String id,
    required String groupId,
    required String title,
    required double amount,
    required String paidBy,
    required DateTime occurredAt,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        title = Value(title),
        amount = Value(amount),
        paidBy = Value(paidBy),
        occurredAt = Value(occurredAt);
  static Insertable<GroupExpense> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? title,
    Expression<double>? amount,
    Expression<String>? paidBy,
    Expression<DateTime>? occurredAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (title != null) 'title': title,
      if (amount != null) 'amount': amount,
      if (paidBy != null) 'paid_by': paidBy,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupExpensesCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String>? title,
      Value<double>? amount,
      Value<String>? paidBy,
      Value<DateTime>? occurredAt,
      Value<String?>? note,
      Value<int>? rowid}) {
    return GroupExpensesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      occurredAt: occurredAt ?? this.occurredAt,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paidBy.present) {
      map['paid_by'] = Variable<String>(paidBy.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupExpensesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('paidBy: $paidBy, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupPaymentsTable extends GroupPayments
    with TableInfo<$GroupPaymentsTable, GroupPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _paidByMeta = const VerificationMeta('paidBy');
  @override
  late final GeneratedColumn<String> paidBy = GeneratedColumn<String>(
      'paid_by', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _paidToMeta = const VerificationMeta('paidTo');
  @override
  late final GeneratedColumn<String> paidTo = GeneratedColumn<String>(
      'paid_to', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, groupId, paidBy, paidTo, amount, occurredAt, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_payments';
  @override
  VerificationContext validateIntegrity(Insertable<GroupPayment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('paid_by')) {
      context.handle(_paidByMeta,
          paidBy.isAcceptableOrUnknown(data['paid_by']!, _paidByMeta));
    } else if (isInserting) {
      context.missing(_paidByMeta);
    }
    if (data.containsKey('paid_to')) {
      context.handle(_paidToMeta,
          paidTo.isAcceptableOrUnknown(data['paid_to']!, _paidToMeta));
    } else if (isInserting) {
      context.missing(_paidToMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupPayment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      paidBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}paid_by'])!,
      paidTo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}paid_to'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $GroupPaymentsTable createAlias(String alias) {
    return $GroupPaymentsTable(attachedDatabase, alias);
  }
}

class GroupPayment extends DataClass implements Insertable<GroupPayment> {
  final String id;
  final String groupId;

  /// Who paid back.
  final String paidBy;

  /// Who received it (empty string = into the pot, e.g. me).
  final String paidTo;
  final double amount;
  final DateTime occurredAt;
  final String? note;
  const GroupPayment(
      {required this.id,
      required this.groupId,
      required this.paidBy,
      required this.paidTo,
      required this.amount,
      required this.occurredAt,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['paid_by'] = Variable<String>(paidBy);
    map['paid_to'] = Variable<String>(paidTo);
    map['amount'] = Variable<double>(amount);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  GroupPaymentsCompanion toCompanion(bool nullToAbsent) {
    return GroupPaymentsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      paidBy: Value(paidBy),
      paidTo: Value(paidTo),
      amount: Value(amount),
      occurredAt: Value(occurredAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory GroupPayment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupPayment(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      paidBy: serializer.fromJson<String>(json['paidBy']),
      paidTo: serializer.fromJson<String>(json['paidTo']),
      amount: serializer.fromJson<double>(json['amount']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'paidBy': serializer.toJson<String>(paidBy),
      'paidTo': serializer.toJson<String>(paidTo),
      'amount': serializer.toJson<double>(amount),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  GroupPayment copyWith(
          {String? id,
          String? groupId,
          String? paidBy,
          String? paidTo,
          double? amount,
          DateTime? occurredAt,
          Value<String?> note = const Value.absent()}) =>
      GroupPayment(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        paidBy: paidBy ?? this.paidBy,
        paidTo: paidTo ?? this.paidTo,
        amount: amount ?? this.amount,
        occurredAt: occurredAt ?? this.occurredAt,
        note: note.present ? note.value : this.note,
      );
  GroupPayment copyWithCompanion(GroupPaymentsCompanion data) {
    return GroupPayment(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      paidBy: data.paidBy.present ? data.paidBy.value : this.paidBy,
      paidTo: data.paidTo.present ? data.paidTo.value : this.paidTo,
      amount: data.amount.present ? data.amount.value : this.amount,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupPayment(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('paidBy: $paidBy, ')
          ..write('paidTo: $paidTo, ')
          ..write('amount: $amount, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, groupId, paidBy, paidTo, amount, occurredAt, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupPayment &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.paidBy == this.paidBy &&
          other.paidTo == this.paidTo &&
          other.amount == this.amount &&
          other.occurredAt == this.occurredAt &&
          other.note == this.note);
}

class GroupPaymentsCompanion extends UpdateCompanion<GroupPayment> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> paidBy;
  final Value<String> paidTo;
  final Value<double> amount;
  final Value<DateTime> occurredAt;
  final Value<String?> note;
  final Value<int> rowid;
  const GroupPaymentsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.paidBy = const Value.absent(),
    this.paidTo = const Value.absent(),
    this.amount = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupPaymentsCompanion.insert({
    required String id,
    required String groupId,
    required String paidBy,
    required String paidTo,
    required double amount,
    required DateTime occurredAt,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        paidBy = Value(paidBy),
        paidTo = Value(paidTo),
        amount = Value(amount),
        occurredAt = Value(occurredAt);
  static Insertable<GroupPayment> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? paidBy,
    Expression<String>? paidTo,
    Expression<double>? amount,
    Expression<DateTime>? occurredAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (paidBy != null) 'paid_by': paidBy,
      if (paidTo != null) 'paid_to': paidTo,
      if (amount != null) 'amount': amount,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupPaymentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String>? paidBy,
      Value<String>? paidTo,
      Value<double>? amount,
      Value<DateTime>? occurredAt,
      Value<String?>? note,
      Value<int>? rowid}) {
    return GroupPaymentsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      paidBy: paidBy ?? this.paidBy,
      paidTo: paidTo ?? this.paidTo,
      amount: amount ?? this.amount,
      occurredAt: occurredAt ?? this.occurredAt,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (paidBy.present) {
      map['paid_by'] = Variable<String>(paidBy.value);
    }
    if (paidTo.present) {
      map['paid_to'] = Variable<String>(paidTo.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('paidBy: $paidBy, ')
          ..write('paidTo: $paidTo, ')
          ..write('amount: $amount, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $DebtsTable debts = $DebtsTable(this);
  late final $SplitsTable splits = $SplitsTable(this);
  late final $InstrumentsTable instruments = $InstrumentsTable(this);
  late final $SnapshotsTable snapshots = $SnapshotsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $MonthOpenTable monthOpen = $MonthOpenTable(this);
  late final $RecurringRulesTable recurringRules = $RecurringRulesTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $GroupMembersTable groupMembers = $GroupMembersTable(this);
  late final $GroupExpensesTable groupExpenses = $GroupExpensesTable(this);
  late final $GroupPaymentsTable groupPayments = $GroupPaymentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        accounts,
        transactions,
        budgets,
        debts,
        splits,
        instruments,
        snapshots,
        settings,
        monthOpen,
        recurringRules,
        groups,
        groupMembers,
        groupExpenses,
        groupPayments
      ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String name,
  Value<String> kind,
  Value<double> openingBalance,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> kind,
  Value<double> openingBalance,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get openingBalance => $composableBuilder(
      column: $table.openingBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get openingBalance => $composableBuilder(
      column: $table.openingBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get openingBalance => $composableBuilder(
      column: $table.openingBalance, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
    Account,
    PrefetchHooks Function()> {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<double> openingBalance = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion(
            id: id,
            name: name,
            kind: kind,
            openingBalance: openingBalance,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> kind = const Value.absent(),
            Value<double> openingBalance = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            id: id,
            name: name,
            kind: kind,
            openingBalance: openingBalance,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AccountsTable, Account>(table),
                    BaseReferences<_$AppDatabase, $AccountsTable, Account>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
    Account,
    PrefetchHooks Function()>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  required String id,
  required String kind,
  required double actual,
  required double budgetImpact,
  required DateTime occurredAt,
  required String categoryRaw,
  Value<String?> level0,
  Value<String?> level1,
  Value<String?> level2,
  Value<String?> item,
  Value<String?> bucket,
  Value<int> absorbed,
  Value<String?> person,
  Value<String?> note,
  Value<String?> accountId,
  Value<String?> linkId,
  Value<String?> linkType,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> id,
  Value<String> kind,
  Value<double> actual,
  Value<double> budgetImpact,
  Value<DateTime> occurredAt,
  Value<String> categoryRaw,
  Value<String?> level0,
  Value<String?> level1,
  Value<String?> level2,
  Value<String?> item,
  Value<String?> bucket,
  Value<int> absorbed,
  Value<String?> person,
  Value<String?> note,
  Value<String?> accountId,
  Value<String?> linkId,
  Value<String?> linkType,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get actual => $composableBuilder(
      column: $table.actual, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get budgetImpact => $composableBuilder(
      column: $table.budgetImpact, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryRaw => $composableBuilder(
      column: $table.categoryRaw, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get level0 => $composableBuilder(
      column: $table.level0, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get level1 => $composableBuilder(
      column: $table.level1, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get level2 => $composableBuilder(
      column: $table.level2, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get item => $composableBuilder(
      column: $table.item, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bucket => $composableBuilder(
      column: $table.bucket, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get absorbed => $composableBuilder(
      column: $table.absorbed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get person => $composableBuilder(
      column: $table.person, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get linkId => $composableBuilder(
      column: $table.linkId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get linkType => $composableBuilder(
      column: $table.linkType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get actual => $composableBuilder(
      column: $table.actual, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get budgetImpact => $composableBuilder(
      column: $table.budgetImpact,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryRaw => $composableBuilder(
      column: $table.categoryRaw, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get level0 => $composableBuilder(
      column: $table.level0, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get level1 => $composableBuilder(
      column: $table.level1, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get level2 => $composableBuilder(
      column: $table.level2, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get item => $composableBuilder(
      column: $table.item, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bucket => $composableBuilder(
      column: $table.bucket, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get absorbed => $composableBuilder(
      column: $table.absorbed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get person => $composableBuilder(
      column: $table.person, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkId => $composableBuilder(
      column: $table.linkId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkType => $composableBuilder(
      column: $table.linkType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get actual =>
      $composableBuilder(column: $table.actual, builder: (column) => column);

  GeneratedColumn<double> get budgetImpact => $composableBuilder(
      column: $table.budgetImpact, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<String> get categoryRaw => $composableBuilder(
      column: $table.categoryRaw, builder: (column) => column);

  GeneratedColumn<String> get level0 =>
      $composableBuilder(column: $table.level0, builder: (column) => column);

  GeneratedColumn<String> get level1 =>
      $composableBuilder(column: $table.level1, builder: (column) => column);

  GeneratedColumn<String> get level2 =>
      $composableBuilder(column: $table.level2, builder: (column) => column);

  GeneratedColumn<String> get item =>
      $composableBuilder(column: $table.item, builder: (column) => column);

  GeneratedColumn<String> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => column);

  GeneratedColumn<int> get absorbed =>
      $composableBuilder(column: $table.absorbed, builder: (column) => column);

  GeneratedColumn<String> get person =>
      $composableBuilder(column: $table.person, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get linkId =>
      $composableBuilder(column: $table.linkId, builder: (column) => column);

  GeneratedColumn<String> get linkType =>
      $composableBuilder(column: $table.linkType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      Transaction,
      BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>
    ),
    Transaction,
    PrefetchHooks Function()> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<double> actual = const Value.absent(),
            Value<double> budgetImpact = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<String> categoryRaw = const Value.absent(),
            Value<String?> level0 = const Value.absent(),
            Value<String?> level1 = const Value.absent(),
            Value<String?> level2 = const Value.absent(),
            Value<String?> item = const Value.absent(),
            Value<String?> bucket = const Value.absent(),
            Value<int> absorbed = const Value.absent(),
            Value<String?> person = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<String?> linkId = const Value.absent(),
            Value<String?> linkType = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            kind: kind,
            actual: actual,
            budgetImpact: budgetImpact,
            occurredAt: occurredAt,
            categoryRaw: categoryRaw,
            level0: level0,
            level1: level1,
            level2: level2,
            item: item,
            bucket: bucket,
            absorbed: absorbed,
            person: person,
            note: note,
            accountId: accountId,
            linkId: linkId,
            linkType: linkType,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            required double actual,
            required double budgetImpact,
            required DateTime occurredAt,
            required String categoryRaw,
            Value<String?> level0 = const Value.absent(),
            Value<String?> level1 = const Value.absent(),
            Value<String?> level2 = const Value.absent(),
            Value<String?> item = const Value.absent(),
            Value<String?> bucket = const Value.absent(),
            Value<int> absorbed = const Value.absent(),
            Value<String?> person = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<String?> linkId = const Value.absent(),
            Value<String?> linkType = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            kind: kind,
            actual: actual,
            budgetImpact: budgetImpact,
            occurredAt: occurredAt,
            categoryRaw: categoryRaw,
            level0: level0,
            level1: level1,
            level2: level2,
            item: item,
            bucket: bucket,
            absorbed: absorbed,
            person: person,
            note: note,
            accountId: accountId,
            linkId: linkId,
            linkType: linkType,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TransactionsTable, Transaction>(table),
                    BaseReferences<_$AppDatabase, $TransactionsTable,
                        Transaction>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      Transaction,
      BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>
    ),
    Transaction,
    PrefetchHooks Function()>;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  required String month,
  required double total,
  required String bucketsJson,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> month,
  Value<double> total,
  Value<String> bucketsJson,
  Value<int> rowid,
});

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bucketsJson => $composableBuilder(
      column: $table.bucketsJson, builder: (column) => ColumnFilters(column));
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bucketsJson => $composableBuilder(
      column: $table.bucketsJson, builder: (column) => ColumnOrderings(column));
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get bucketsJson => $composableBuilder(
      column: $table.bucketsJson, builder: (column) => column);
}

class $$BudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
    Budget,
    PrefetchHooks Function()> {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> month = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<String> bucketsJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion(
            month: month,
            total: total,
            bucketsJson: bucketsJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String month,
            required double total,
            required String bucketsJson,
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion.insert(
            month: month,
            total: total,
            bucketsJson: bucketsJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$BudgetsTable, Budget>(table),
                    BaseReferences<_$AppDatabase, $BudgetsTable, Budget>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BudgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
    Budget,
    PrefetchHooks Function()>;
typedef $$DebtsTableCreateCompanionBuilder = DebtsCompanion Function({
  required String id,
  required String counterparty,
  required String direction,
  required double principal,
  Value<double> paid,
  Value<String?> note,
  Value<DateTime?> dueDate,
  Value<DateTime?> nudgeDate,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$DebtsTableUpdateCompanionBuilder = DebtsCompanion Function({
  Value<String> id,
  Value<String> counterparty,
  Value<String> direction,
  Value<double> principal,
  Value<double> paid,
  Value<String?> note,
  Value<DateTime?> dueDate,
  Value<DateTime?> nudgeDate,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DebtsTableFilterComposer extends Composer<_$AppDatabase, $DebtsTable> {
  $$DebtsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get counterparty => $composableBuilder(
      column: $table.counterparty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get principal => $composableBuilder(
      column: $table.principal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get paid => $composableBuilder(
      column: $table.paid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nudgeDate => $composableBuilder(
      column: $table.nudgeDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DebtsTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtsTable> {
  $$DebtsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get counterparty => $composableBuilder(
      column: $table.counterparty,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get principal => $composableBuilder(
      column: $table.principal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get paid => $composableBuilder(
      column: $table.paid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nudgeDate => $composableBuilder(
      column: $table.nudgeDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DebtsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtsTable> {
  $$DebtsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get counterparty => $composableBuilder(
      column: $table.counterparty, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<double> get principal =>
      $composableBuilder(column: $table.principal, builder: (column) => column);

  GeneratedColumn<double> get paid =>
      $composableBuilder(column: $table.paid, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get nudgeDate =>
      $composableBuilder(column: $table.nudgeDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DebtsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DebtsTable,
    Debt,
    $$DebtsTableFilterComposer,
    $$DebtsTableOrderingComposer,
    $$DebtsTableAnnotationComposer,
    $$DebtsTableCreateCompanionBuilder,
    $$DebtsTableUpdateCompanionBuilder,
    (Debt, BaseReferences<_$AppDatabase, $DebtsTable, Debt>),
    Debt,
    PrefetchHooks Function()> {
  $$DebtsTableTableManager(_$AppDatabase db, $DebtsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> counterparty = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<double> principal = const Value.absent(),
            Value<double> paid = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<DateTime?> nudgeDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DebtsCompanion(
            id: id,
            counterparty: counterparty,
            direction: direction,
            principal: principal,
            paid: paid,
            note: note,
            dueDate: dueDate,
            nudgeDate: nudgeDate,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String counterparty,
            required String direction,
            required double principal,
            Value<double> paid = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<DateTime?> nudgeDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DebtsCompanion.insert(
            id: id,
            counterparty: counterparty,
            direction: direction,
            principal: principal,
            paid: paid,
            note: note,
            dueDate: dueDate,
            nudgeDate: nudgeDate,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DebtsTable, Debt>(table),
                    BaseReferences<_$AppDatabase, $DebtsTable, Debt>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DebtsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DebtsTable,
    Debt,
    $$DebtsTableFilterComposer,
    $$DebtsTableOrderingComposer,
    $$DebtsTableAnnotationComposer,
    $$DebtsTableCreateCompanionBuilder,
    $$DebtsTableUpdateCompanionBuilder,
    (Debt, BaseReferences<_$AppDatabase, $DebtsTable, Debt>),
    Debt,
    PrefetchHooks Function()>;
typedef $$SplitsTableCreateCompanionBuilder = SplitsCompanion Function({
  required String id,
  required String title,
  Value<String?> code,
  required double totalPaid,
  required double myShare,
  Value<double> received,
  Value<double> absorbed,
  Value<String> membersJson,
  Value<String?> note,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$SplitsTableUpdateCompanionBuilder = SplitsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> code,
  Value<double> totalPaid,
  Value<double> myShare,
  Value<double> received,
  Value<double> absorbed,
  Value<String> membersJson,
  Value<String?> note,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SplitsTableFilterComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalPaid => $composableBuilder(
      column: $table.totalPaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get myShare => $composableBuilder(
      column: $table.myShare, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get received => $composableBuilder(
      column: $table.received, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get absorbed => $composableBuilder(
      column: $table.absorbed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get membersJson => $composableBuilder(
      column: $table.membersJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SplitsTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalPaid => $composableBuilder(
      column: $table.totalPaid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get myShare => $composableBuilder(
      column: $table.myShare, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get received => $composableBuilder(
      column: $table.received, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get absorbed => $composableBuilder(
      column: $table.absorbed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get membersJson => $composableBuilder(
      column: $table.membersJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SplitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<double> get totalPaid =>
      $composableBuilder(column: $table.totalPaid, builder: (column) => column);

  GeneratedColumn<double> get myShare =>
      $composableBuilder(column: $table.myShare, builder: (column) => column);

  GeneratedColumn<double> get received =>
      $composableBuilder(column: $table.received, builder: (column) => column);

  GeneratedColumn<double> get absorbed =>
      $composableBuilder(column: $table.absorbed, builder: (column) => column);

  GeneratedColumn<String> get membersJson => $composableBuilder(
      column: $table.membersJson, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SplitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SplitsTable,
    Split,
    $$SplitsTableFilterComposer,
    $$SplitsTableOrderingComposer,
    $$SplitsTableAnnotationComposer,
    $$SplitsTableCreateCompanionBuilder,
    $$SplitsTableUpdateCompanionBuilder,
    (Split, BaseReferences<_$AppDatabase, $SplitsTable, Split>),
    Split,
    PrefetchHooks Function()> {
  $$SplitsTableTableManager(_$AppDatabase db, $SplitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> code = const Value.absent(),
            Value<double> totalPaid = const Value.absent(),
            Value<double> myShare = const Value.absent(),
            Value<double> received = const Value.absent(),
            Value<double> absorbed = const Value.absent(),
            Value<String> membersJson = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SplitsCompanion(
            id: id,
            title: title,
            code: code,
            totalPaid: totalPaid,
            myShare: myShare,
            received: received,
            absorbed: absorbed,
            membersJson: membersJson,
            note: note,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> code = const Value.absent(),
            required double totalPaid,
            required double myShare,
            Value<double> received = const Value.absent(),
            Value<double> absorbed = const Value.absent(),
            Value<String> membersJson = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SplitsCompanion.insert(
            id: id,
            title: title,
            code: code,
            totalPaid: totalPaid,
            myShare: myShare,
            received: received,
            absorbed: absorbed,
            membersJson: membersJson,
            note: note,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SplitsTable, Split>(table),
                    BaseReferences<_$AppDatabase, $SplitsTable, Split>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SplitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SplitsTable,
    Split,
    $$SplitsTableFilterComposer,
    $$SplitsTableOrderingComposer,
    $$SplitsTableAnnotationComposer,
    $$SplitsTableCreateCompanionBuilder,
    $$SplitsTableUpdateCompanionBuilder,
    (Split, BaseReferences<_$AppDatabase, $SplitsTable, Split>),
    Split,
    PrefetchHooks Function()>;
typedef $$InstrumentsTableCreateCompanionBuilder = InstrumentsCompanion
    Function({
  required String id,
  required String name,
  Value<String> kind,
  Value<double> invested,
  Value<double> current,
  Value<String?> note,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$InstrumentsTableUpdateCompanionBuilder = InstrumentsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> kind,
  Value<double> invested,
  Value<double> current,
  Value<String?> note,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$InstrumentsTableFilterComposer
    extends Composer<_$AppDatabase, $InstrumentsTable> {
  $$InstrumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get invested => $composableBuilder(
      column: $table.invested, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get current => $composableBuilder(
      column: $table.current, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$InstrumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstrumentsTable> {
  $$InstrumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get invested => $composableBuilder(
      column: $table.invested, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get current => $composableBuilder(
      column: $table.current, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$InstrumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstrumentsTable> {
  $$InstrumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get invested =>
      $composableBuilder(column: $table.invested, builder: (column) => column);

  GeneratedColumn<double> get current =>
      $composableBuilder(column: $table.current, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$InstrumentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InstrumentsTable,
    Instrument,
    $$InstrumentsTableFilterComposer,
    $$InstrumentsTableOrderingComposer,
    $$InstrumentsTableAnnotationComposer,
    $$InstrumentsTableCreateCompanionBuilder,
    $$InstrumentsTableUpdateCompanionBuilder,
    (Instrument, BaseReferences<_$AppDatabase, $InstrumentsTable, Instrument>),
    Instrument,
    PrefetchHooks Function()> {
  $$InstrumentsTableTableManager(_$AppDatabase db, $InstrumentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstrumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstrumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstrumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<double> invested = const Value.absent(),
            Value<double> current = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InstrumentsCompanion(
            id: id,
            name: name,
            kind: kind,
            invested: invested,
            current: current,
            note: note,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> kind = const Value.absent(),
            Value<double> invested = const Value.absent(),
            Value<double> current = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InstrumentsCompanion.insert(
            id: id,
            name: name,
            kind: kind,
            invested: invested,
            current: current,
            note: note,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$InstrumentsTable, Instrument>(table),
                    BaseReferences<_$AppDatabase, $InstrumentsTable,
                        Instrument>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InstrumentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InstrumentsTable,
    Instrument,
    $$InstrumentsTableFilterComposer,
    $$InstrumentsTableOrderingComposer,
    $$InstrumentsTableAnnotationComposer,
    $$InstrumentsTableCreateCompanionBuilder,
    $$InstrumentsTableUpdateCompanionBuilder,
    (Instrument, BaseReferences<_$AppDatabase, $InstrumentsTable, Instrument>),
    Instrument,
    PrefetchHooks Function()>;
typedef $$SnapshotsTableCreateCompanionBuilder = SnapshotsCompanion Function({
  required String month,
  required String accountId,
  Value<double> openBalance,
  Value<double> countedClose,
  Value<int> hasClose,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$SnapshotsTableUpdateCompanionBuilder = SnapshotsCompanion Function({
  Value<String> month,
  Value<String> accountId,
  Value<double> openBalance,
  Value<double> countedClose,
  Value<int> hasClose,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $SnapshotsTable> {
  $$SnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get openBalance => $composableBuilder(
      column: $table.openBalance, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get countedClose => $composableBuilder(
      column: $table.countedClose, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hasClose => $composableBuilder(
      column: $table.hasClose, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $SnapshotsTable> {
  $$SnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get openBalance => $composableBuilder(
      column: $table.openBalance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get countedClose => $composableBuilder(
      column: $table.countedClose,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hasClose => $composableBuilder(
      column: $table.hasClose, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SnapshotsTable> {
  $$SnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<double> get openBalance => $composableBuilder(
      column: $table.openBalance, builder: (column) => column);

  GeneratedColumn<double> get countedClose => $composableBuilder(
      column: $table.countedClose, builder: (column) => column);

  GeneratedColumn<int> get hasClose =>
      $composableBuilder(column: $table.hasClose, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SnapshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SnapshotsTable,
    Snapshot,
    $$SnapshotsTableFilterComposer,
    $$SnapshotsTableOrderingComposer,
    $$SnapshotsTableAnnotationComposer,
    $$SnapshotsTableCreateCompanionBuilder,
    $$SnapshotsTableUpdateCompanionBuilder,
    (Snapshot, BaseReferences<_$AppDatabase, $SnapshotsTable, Snapshot>),
    Snapshot,
    PrefetchHooks Function()> {
  $$SnapshotsTableTableManager(_$AppDatabase db, $SnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> month = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<double> openBalance = const Value.absent(),
            Value<double> countedClose = const Value.absent(),
            Value<int> hasClose = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SnapshotsCompanion(
            month: month,
            accountId: accountId,
            openBalance: openBalance,
            countedClose: countedClose,
            hasClose: hasClose,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String month,
            required String accountId,
            Value<double> openBalance = const Value.absent(),
            Value<double> countedClose = const Value.absent(),
            Value<int> hasClose = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SnapshotsCompanion.insert(
            month: month,
            accountId: accountId,
            openBalance: openBalance,
            countedClose: countedClose,
            hasClose: hasClose,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SnapshotsTable, Snapshot>(table),
                    BaseReferences<_$AppDatabase, $SnapshotsTable, Snapshot>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SnapshotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SnapshotsTable,
    Snapshot,
    $$SnapshotsTableFilterComposer,
    $$SnapshotsTableOrderingComposer,
    $$SnapshotsTableAnnotationComposer,
    $$SnapshotsTableCreateCompanionBuilder,
    $$SnapshotsTableUpdateCompanionBuilder,
    (Snapshot, BaseReferences<_$AppDatabase, $SnapshotsTable, Snapshot>),
    Snapshot,
    PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SettingsTable, Setting>(table),
                    BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;
typedef $$MonthOpenTableCreateCompanionBuilder = MonthOpenCompanion Function({
  required String month,
  Value<double?> budgetIn,
  Value<double?> budgetOut,
  Value<double?> bankBalance,
  Value<double?> cashBalance,
  Value<double?> cardLimit,
  Value<int> rowid,
});
typedef $$MonthOpenTableUpdateCompanionBuilder = MonthOpenCompanion Function({
  Value<String> month,
  Value<double?> budgetIn,
  Value<double?> budgetOut,
  Value<double?> bankBalance,
  Value<double?> cashBalance,
  Value<double?> cardLimit,
  Value<int> rowid,
});

class $$MonthOpenTableFilterComposer
    extends Composer<_$AppDatabase, $MonthOpenTable> {
  $$MonthOpenTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get budgetIn => $composableBuilder(
      column: $table.budgetIn, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get budgetOut => $composableBuilder(
      column: $table.budgetOut, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bankBalance => $composableBuilder(
      column: $table.bankBalance, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cashBalance => $composableBuilder(
      column: $table.cashBalance, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cardLimit => $composableBuilder(
      column: $table.cardLimit, builder: (column) => ColumnFilters(column));
}

class $$MonthOpenTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthOpenTable> {
  $$MonthOpenTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get budgetIn => $composableBuilder(
      column: $table.budgetIn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get budgetOut => $composableBuilder(
      column: $table.budgetOut, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bankBalance => $composableBuilder(
      column: $table.bankBalance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cashBalance => $composableBuilder(
      column: $table.cashBalance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cardLimit => $composableBuilder(
      column: $table.cardLimit, builder: (column) => ColumnOrderings(column));
}

class $$MonthOpenTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthOpenTable> {
  $$MonthOpenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<double> get budgetIn =>
      $composableBuilder(column: $table.budgetIn, builder: (column) => column);

  GeneratedColumn<double> get budgetOut =>
      $composableBuilder(column: $table.budgetOut, builder: (column) => column);

  GeneratedColumn<double> get bankBalance => $composableBuilder(
      column: $table.bankBalance, builder: (column) => column);

  GeneratedColumn<double> get cashBalance => $composableBuilder(
      column: $table.cashBalance, builder: (column) => column);

  GeneratedColumn<double> get cardLimit =>
      $composableBuilder(column: $table.cardLimit, builder: (column) => column);
}

class $$MonthOpenTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MonthOpenTable,
    MonthOpenData,
    $$MonthOpenTableFilterComposer,
    $$MonthOpenTableOrderingComposer,
    $$MonthOpenTableAnnotationComposer,
    $$MonthOpenTableCreateCompanionBuilder,
    $$MonthOpenTableUpdateCompanionBuilder,
    (
      MonthOpenData,
      BaseReferences<_$AppDatabase, $MonthOpenTable, MonthOpenData>
    ),
    MonthOpenData,
    PrefetchHooks Function()> {
  $$MonthOpenTableTableManager(_$AppDatabase db, $MonthOpenTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthOpenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthOpenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthOpenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> month = const Value.absent(),
            Value<double?> budgetIn = const Value.absent(),
            Value<double?> budgetOut = const Value.absent(),
            Value<double?> bankBalance = const Value.absent(),
            Value<double?> cashBalance = const Value.absent(),
            Value<double?> cardLimit = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MonthOpenCompanion(
            month: month,
            budgetIn: budgetIn,
            budgetOut: budgetOut,
            bankBalance: bankBalance,
            cashBalance: cashBalance,
            cardLimit: cardLimit,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String month,
            Value<double?> budgetIn = const Value.absent(),
            Value<double?> budgetOut = const Value.absent(),
            Value<double?> bankBalance = const Value.absent(),
            Value<double?> cashBalance = const Value.absent(),
            Value<double?> cardLimit = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MonthOpenCompanion.insert(
            month: month,
            budgetIn: budgetIn,
            budgetOut: budgetOut,
            bankBalance: bankBalance,
            cashBalance: cashBalance,
            cardLimit: cardLimit,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MonthOpenTable, MonthOpenData>(table),
                    BaseReferences<_$AppDatabase, $MonthOpenTable,
                        MonthOpenData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MonthOpenTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MonthOpenTable,
    MonthOpenData,
    $$MonthOpenTableFilterComposer,
    $$MonthOpenTableOrderingComposer,
    $$MonthOpenTableAnnotationComposer,
    $$MonthOpenTableCreateCompanionBuilder,
    $$MonthOpenTableUpdateCompanionBuilder,
    (
      MonthOpenData,
      BaseReferences<_$AppDatabase, $MonthOpenTable, MonthOpenData>
    ),
    MonthOpenData,
    PrefetchHooks Function()>;
typedef $$RecurringRulesTableCreateCompanionBuilder = RecurringRulesCompanion
    Function({
  required String id,
  required String kind,
  required double amount,
  required String categoryRaw,
  Value<String?> bucket,
  Value<String?> accountId,
  Value<int> dayOfMonth,
  Value<int> months,
  required String startMonth,
  Value<String?> lastAppliedMonth,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$RecurringRulesTableUpdateCompanionBuilder = RecurringRulesCompanion
    Function({
  Value<String> id,
  Value<String> kind,
  Value<double> amount,
  Value<String> categoryRaw,
  Value<String?> bucket,
  Value<String?> accountId,
  Value<int> dayOfMonth,
  Value<int> months,
  Value<String> startMonth,
  Value<String?> lastAppliedMonth,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$RecurringRulesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryRaw => $composableBuilder(
      column: $table.categoryRaw, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bucket => $composableBuilder(
      column: $table.bucket, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get months => $composableBuilder(
      column: $table.months, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startMonth => $composableBuilder(
      column: $table.startMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastAppliedMonth => $composableBuilder(
      column: $table.lastAppliedMonth,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$RecurringRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryRaw => $composableBuilder(
      column: $table.categoryRaw, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bucket => $composableBuilder(
      column: $table.bucket, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get months => $composableBuilder(
      column: $table.months, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startMonth => $composableBuilder(
      column: $table.startMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastAppliedMonth => $composableBuilder(
      column: $table.lastAppliedMonth,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$RecurringRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get categoryRaw => $composableBuilder(
      column: $table.categoryRaw, builder: (column) => column);

  GeneratedColumn<String> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => column);

  GeneratedColumn<int> get months =>
      $composableBuilder(column: $table.months, builder: (column) => column);

  GeneratedColumn<String> get startMonth => $composableBuilder(
      column: $table.startMonth, builder: (column) => column);

  GeneratedColumn<String> get lastAppliedMonth => $composableBuilder(
      column: $table.lastAppliedMonth, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RecurringRulesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurringRulesTable,
    RecurringRule,
    $$RecurringRulesTableFilterComposer,
    $$RecurringRulesTableOrderingComposer,
    $$RecurringRulesTableAnnotationComposer,
    $$RecurringRulesTableCreateCompanionBuilder,
    $$RecurringRulesTableUpdateCompanionBuilder,
    (
      RecurringRule,
      BaseReferences<_$AppDatabase, $RecurringRulesTable, RecurringRule>
    ),
    RecurringRule,
    PrefetchHooks Function()> {
  $$RecurringRulesTableTableManager(
      _$AppDatabase db, $RecurringRulesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> categoryRaw = const Value.absent(),
            Value<String?> bucket = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<int> dayOfMonth = const Value.absent(),
            Value<int> months = const Value.absent(),
            Value<String> startMonth = const Value.absent(),
            Value<String?> lastAppliedMonth = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurringRulesCompanion(
            id: id,
            kind: kind,
            amount: amount,
            categoryRaw: categoryRaw,
            bucket: bucket,
            accountId: accountId,
            dayOfMonth: dayOfMonth,
            months: months,
            startMonth: startMonth,
            lastAppliedMonth: lastAppliedMonth,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            required double amount,
            required String categoryRaw,
            Value<String?> bucket = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<int> dayOfMonth = const Value.absent(),
            Value<int> months = const Value.absent(),
            required String startMonth,
            Value<String?> lastAppliedMonth = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurringRulesCompanion.insert(
            id: id,
            kind: kind,
            amount: amount,
            categoryRaw: categoryRaw,
            bucket: bucket,
            accountId: accountId,
            dayOfMonth: dayOfMonth,
            months: months,
            startMonth: startMonth,
            lastAppliedMonth: lastAppliedMonth,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RecurringRulesTable, RecurringRule>(table),
                    BaseReferences<_$AppDatabase, $RecurringRulesTable,
                        RecurringRule>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecurringRulesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecurringRulesTable,
    RecurringRule,
    $$RecurringRulesTableFilterComposer,
    $$RecurringRulesTableOrderingComposer,
    $$RecurringRulesTableAnnotationComposer,
    $$RecurringRulesTableCreateCompanionBuilder,
    $$RecurringRulesTableUpdateCompanionBuilder,
    (
      RecurringRule,
      BaseReferences<_$AppDatabase, $RecurringRulesTable, RecurringRule>
    ),
    RecurringRule,
    PrefetchHooks Function()>;
typedef $$GroupsTableCreateCompanionBuilder = GroupsCompanion Function({
  required String id,
  required String name,
  required String code,
  required String monthKey,
  Value<String?> note,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$GroupsTableUpdateCompanionBuilder = GroupsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> code,
  Value<String> monthKey,
  Value<String?> note,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get monthKey => $composableBuilder(
      column: $table.monthKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get monthKey => $composableBuilder(
      column: $table.monthKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GroupsTable,
    Group,
    $$GroupsTableFilterComposer,
    $$GroupsTableOrderingComposer,
    $$GroupsTableAnnotationComposer,
    $$GroupsTableCreateCompanionBuilder,
    $$GroupsTableUpdateCompanionBuilder,
    (Group, BaseReferences<_$AppDatabase, $GroupsTable, Group>),
    Group,
    PrefetchHooks Function()> {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> monthKey = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupsCompanion(
            id: id,
            name: name,
            code: code,
            monthKey: monthKey,
            note: note,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String code,
            required String monthKey,
            Value<String?> note = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupsCompanion.insert(
            id: id,
            name: name,
            code: code,
            monthKey: monthKey,
            note: note,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$GroupsTable, Group>(table),
                    BaseReferences<_$AppDatabase, $GroupsTable, Group>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GroupsTable,
    Group,
    $$GroupsTableFilterComposer,
    $$GroupsTableOrderingComposer,
    $$GroupsTableAnnotationComposer,
    $$GroupsTableCreateCompanionBuilder,
    $$GroupsTableUpdateCompanionBuilder,
    (Group, BaseReferences<_$AppDatabase, $GroupsTable, Group>),
    Group,
    PrefetchHooks Function()>;
typedef $$GroupMembersTableCreateCompanionBuilder = GroupMembersCompanion
    Function({
  required String id,
  required String groupId,
  required String name,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$GroupMembersTableUpdateCompanionBuilder = GroupMembersCompanion
    Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$GroupMembersTableFilterComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$GroupMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$GroupMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GroupMembersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GroupMembersTable,
    GroupMember,
    $$GroupMembersTableFilterComposer,
    $$GroupMembersTableOrderingComposer,
    $$GroupMembersTableAnnotationComposer,
    $$GroupMembersTableCreateCompanionBuilder,
    $$GroupMembersTableUpdateCompanionBuilder,
    (
      GroupMember,
      BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMember>
    ),
    GroupMember,
    PrefetchHooks Function()> {
  $$GroupMembersTableTableManager(_$AppDatabase db, $GroupMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupMembersCompanion(
            id: id,
            groupId: groupId,
            name: name,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String groupId,
            required String name,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupMembersCompanion.insert(
            id: id,
            groupId: groupId,
            name: name,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$GroupMembersTable, GroupMember>(table),
                    BaseReferences<_$AppDatabase, $GroupMembersTable,
                        GroupMember>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GroupMembersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GroupMembersTable,
    GroupMember,
    $$GroupMembersTableFilterComposer,
    $$GroupMembersTableOrderingComposer,
    $$GroupMembersTableAnnotationComposer,
    $$GroupMembersTableCreateCompanionBuilder,
    $$GroupMembersTableUpdateCompanionBuilder,
    (
      GroupMember,
      BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMember>
    ),
    GroupMember,
    PrefetchHooks Function()>;
typedef $$GroupExpensesTableCreateCompanionBuilder = GroupExpensesCompanion
    Function({
  required String id,
  required String groupId,
  required String title,
  required double amount,
  required String paidBy,
  required DateTime occurredAt,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$GroupExpensesTableUpdateCompanionBuilder = GroupExpensesCompanion
    Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> title,
  Value<double> amount,
  Value<String> paidBy,
  Value<DateTime> occurredAt,
  Value<String?> note,
  Value<int> rowid,
});

class $$GroupExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $GroupExpensesTable> {
  $$GroupExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paidBy => $composableBuilder(
      column: $table.paidBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));
}

class $$GroupExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupExpensesTable> {
  $$GroupExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paidBy => $composableBuilder(
      column: $table.paidBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));
}

class $$GroupExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupExpensesTable> {
  $$GroupExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get paidBy =>
      $composableBuilder(column: $table.paidBy, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$GroupExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GroupExpensesTable,
    GroupExpense,
    $$GroupExpensesTableFilterComposer,
    $$GroupExpensesTableOrderingComposer,
    $$GroupExpensesTableAnnotationComposer,
    $$GroupExpensesTableCreateCompanionBuilder,
    $$GroupExpensesTableUpdateCompanionBuilder,
    (
      GroupExpense,
      BaseReferences<_$AppDatabase, $GroupExpensesTable, GroupExpense>
    ),
    GroupExpense,
    PrefetchHooks Function()> {
  $$GroupExpensesTableTableManager(_$AppDatabase db, $GroupExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> paidBy = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupExpensesCompanion(
            id: id,
            groupId: groupId,
            title: title,
            amount: amount,
            paidBy: paidBy,
            occurredAt: occurredAt,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String groupId,
            required String title,
            required double amount,
            required String paidBy,
            required DateTime occurredAt,
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupExpensesCompanion.insert(
            id: id,
            groupId: groupId,
            title: title,
            amount: amount,
            paidBy: paidBy,
            occurredAt: occurredAt,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$GroupExpensesTable, GroupExpense>(table),
                    BaseReferences<_$AppDatabase, $GroupExpensesTable,
                        GroupExpense>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GroupExpensesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GroupExpensesTable,
    GroupExpense,
    $$GroupExpensesTableFilterComposer,
    $$GroupExpensesTableOrderingComposer,
    $$GroupExpensesTableAnnotationComposer,
    $$GroupExpensesTableCreateCompanionBuilder,
    $$GroupExpensesTableUpdateCompanionBuilder,
    (
      GroupExpense,
      BaseReferences<_$AppDatabase, $GroupExpensesTable, GroupExpense>
    ),
    GroupExpense,
    PrefetchHooks Function()>;
typedef $$GroupPaymentsTableCreateCompanionBuilder = GroupPaymentsCompanion
    Function({
  required String id,
  required String groupId,
  required String paidBy,
  required String paidTo,
  required double amount,
  required DateTime occurredAt,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$GroupPaymentsTableUpdateCompanionBuilder = GroupPaymentsCompanion
    Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> paidBy,
  Value<String> paidTo,
  Value<double> amount,
  Value<DateTime> occurredAt,
  Value<String?> note,
  Value<int> rowid,
});

class $$GroupPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupPaymentsTable> {
  $$GroupPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paidBy => $composableBuilder(
      column: $table.paidBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paidTo => $composableBuilder(
      column: $table.paidTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));
}

class $$GroupPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupPaymentsTable> {
  $$GroupPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paidBy => $composableBuilder(
      column: $table.paidBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paidTo => $composableBuilder(
      column: $table.paidTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));
}

class $$GroupPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupPaymentsTable> {
  $$GroupPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get paidBy =>
      $composableBuilder(column: $table.paidBy, builder: (column) => column);

  GeneratedColumn<String> get paidTo =>
      $composableBuilder(column: $table.paidTo, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$GroupPaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GroupPaymentsTable,
    GroupPayment,
    $$GroupPaymentsTableFilterComposer,
    $$GroupPaymentsTableOrderingComposer,
    $$GroupPaymentsTableAnnotationComposer,
    $$GroupPaymentsTableCreateCompanionBuilder,
    $$GroupPaymentsTableUpdateCompanionBuilder,
    (
      GroupPayment,
      BaseReferences<_$AppDatabase, $GroupPaymentsTable, GroupPayment>
    ),
    GroupPayment,
    PrefetchHooks Function()> {
  $$GroupPaymentsTableTableManager(_$AppDatabase db, $GroupPaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> paidBy = const Value.absent(),
            Value<String> paidTo = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupPaymentsCompanion(
            id: id,
            groupId: groupId,
            paidBy: paidBy,
            paidTo: paidTo,
            amount: amount,
            occurredAt: occurredAt,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String groupId,
            required String paidBy,
            required String paidTo,
            required double amount,
            required DateTime occurredAt,
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupPaymentsCompanion.insert(
            id: id,
            groupId: groupId,
            paidBy: paidBy,
            paidTo: paidTo,
            amount: amount,
            occurredAt: occurredAt,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$GroupPaymentsTable, GroupPayment>(table),
                    BaseReferences<_$AppDatabase, $GroupPaymentsTable,
                        GroupPayment>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GroupPaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GroupPaymentsTable,
    GroupPayment,
    $$GroupPaymentsTableFilterComposer,
    $$GroupPaymentsTableOrderingComposer,
    $$GroupPaymentsTableAnnotationComposer,
    $$GroupPaymentsTableCreateCompanionBuilder,
    $$GroupPaymentsTableUpdateCompanionBuilder,
    (
      GroupPayment,
      BaseReferences<_$AppDatabase, $GroupPaymentsTable, GroupPayment>
    ),
    GroupPayment,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$DebtsTableTableManager get debts =>
      $$DebtsTableTableManager(_db, _db.debts);
  $$SplitsTableTableManager get splits =>
      $$SplitsTableTableManager(_db, _db.splits);
  $$InstrumentsTableTableManager get instruments =>
      $$InstrumentsTableTableManager(_db, _db.instruments);
  $$SnapshotsTableTableManager get snapshots =>
      $$SnapshotsTableTableManager(_db, _db.snapshots);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$MonthOpenTableTableManager get monthOpen =>
      $$MonthOpenTableTableManager(_db, _db.monthOpen);
  $$RecurringRulesTableTableManager get recurringRules =>
      $$RecurringRulesTableTableManager(_db, _db.recurringRules);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db, _db.groupMembers);
  $$GroupExpensesTableTableManager get groupExpenses =>
      $$GroupExpensesTableTableManager(_db, _db.groupExpenses);
  $$GroupPaymentsTableTableManager get groupPayments =>
      $$GroupPaymentsTableTableManager(_db, _db.groupPayments);
}
