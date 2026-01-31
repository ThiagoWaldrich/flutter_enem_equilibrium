import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> saveData(String key, dynamic data) async {
    try {
      final jsonString = jsonEncode(data);
      return await _prefs!.setString(key, jsonString);
    } catch (e) {
      debugPrint('Erro ao salvar dados: $e');
      return false;
    }
  }

  dynamic getData(String key) {
    try {
      final jsonString = _prefs!.getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      return null;
    }
  }
  Future<bool> removeData(String key) async {
    try {
      return await _prefs!.remove(key);
    } catch (e) {
      debugPrint('Erro ao remover dados: $e');
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      return await _prefs!.clear();
    } catch (e) {
      debugPrint('Erro ao limpar dados: $e');
      return false;
    }
  }
}