// dart format width=80
// ignore_for_file: type=lint
part of 'settings_dao.dart';

mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SettingsTableTable get settingsTable => attachedDatabase.settingsTable;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db.attachedDatabase, _db.settingsTable);
}
