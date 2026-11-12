import 'package:flutter_test/flutter_test.dart';
import 'package:hrzones/data/database.dart';
import 'package:hrzones/data/template_repository.dart';
import 'package:hrzones/workout/next_template.dart';

TemplateWithSlots t(String id, String? folder) => TemplateWithSlots(
  template: Template(id: id, name: id, folder: folder, notes: '', position: 0, updatedAt: DateTime(2026)),
  slots: const [],
);

void main() {
  test('next template follows the last one in its folder, wrapping round', () {
    final all = [t('UA', 'UL'), t('LA', 'UL'), t('UB', 'UL'), t('Push', 'PPL'), t('Pull', 'PPL')];
    expect(nextTemplate(const [], null), isNull);
    expect(nextTemplate(all, null)!.template.id, 'UA');
    expect(nextTemplate(all, 'UA')!.template.id, 'LA');
    expect(nextTemplate(all, 'UB')!.template.id, 'UA');
    expect(nextTemplate(all, 'Push')!.template.id, 'Pull');
    expect(nextTemplate(all, 'deleted')!.template.id, 'UA');
  });
}
