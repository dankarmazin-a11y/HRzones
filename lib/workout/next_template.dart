import '../data/template_repository.dart';

/// The template to suggest next: the one after the last template you trained,
/// in the same folder (wrapping round), e.g. Upper A → Lower A → Upper B.
/// No templates → null; never trained one → the first template.
TemplateWithSlots? nextTemplate(List<TemplateWithSlots> all, String? lastTemplateId) {
  if (all.isEmpty) return null;
  final i = all.indexWhere((t) => t.template.id == lastTemplateId);
  if (i < 0) return all.first;
  final folder = all[i].template.folder;
  final group = all.where((t) => t.template.folder == folder).toList();
  final j = group.indexWhere((t) => t.template.id == lastTemplateId);
  return group[(j + 1) % group.length];
}
