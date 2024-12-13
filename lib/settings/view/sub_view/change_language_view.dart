import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ChangeLanguageView extends StatelessWidget {
  const ChangeLanguageView({super.key});

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'it':
        return 'Italiano';
      default:
        return languageCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportedLocales = context.supportedLocales;

    return Scaffold(
      appBar: AppBar(title: const Text('t_changeLanguage').tr()),
      body: ListView.builder(
        itemCount: supportedLocales.length,
        itemBuilder: (context, index) {
          final locale = supportedLocales[index];
          final isSelected =
              context.locale.languageCode == locale.languageCode;
          return ListTile(
            title: Text(_getLanguageName(locale.languageCode)),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: () {
              context.setLocale(locale);
            },
          );
        },
      ),
    );
  }
}
