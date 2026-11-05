# Adds the WorkoutWidget (Live Activity) app extension to ios/Runner.xcodeproj.
# Run once: ruby tool/add_widget_target.rb  (needs `gem install xcodeproj`).
require 'xcodeproj'

path = File.expand_path('../ios/Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(path)
abort 'WorkoutWidget already exists' if project.targets.any? { |t| t.name == 'WorkoutWidget' }

runner = project.targets.find { |t| t.name == 'Runner' }

# Files
runner_group = project.main_group['Runner']
plugin_ref = runner_group.new_reference('LiveActivityPlugin.swift')
runner.source_build_phase.add_file_reference(plugin_ref)

widget_group = project.main_group.new_group('WorkoutWidget', 'WorkoutWidget')
attrs_ref = widget_group.new_reference('WorkoutAttributes.swift')
bundle_ref = widget_group.new_reference('WorkoutWidgetBundle.swift')
activity_ref = widget_group.new_reference('WorkoutLiveActivity.swift')
widget_group.new_reference('Info.plist')

runner.source_build_phase.add_file_reference(attrs_ref)

# Target
widget = project.new_target(:app_extension, 'WorkoutWidget', :ios, '16.2', nil, :swift)
# new_target links Foundation with an SDK-version path; not needed.
widget.frameworks_build_phase.files.to_a.each do |f|
  ref = f.file_ref
  f.remove_from_project
  ref.remove_from_project if ref
end
widget.source_build_phase.add_file_reference(attrs_ref)
widget.source_build_phase.add_file_reference(bundle_ref)
widget.source_build_phase.add_file_reference(activity_ref)
%w[WidgetKit SwiftUI].each do |fw|
  ref = project.frameworks_group.new_file("System/Library/Frameworks/#{fw}.framework", :sdk_root)
  widget.frameworks_build_phase.add_file_reference(ref)
end

runner_configs = runner.build_configuration_list.build_configurations
widget.build_configurations.each do |c|
  base = runner_configs.find { |r| r.name == c.name }
  c.base_configuration_reference = base.base_configuration_reference
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.hrzones.app.WorkoutWidget'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'WorkoutWidget/Info.plist'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.2'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1'
  s['SKIP_INSTALL'] = 'YES'
  s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  s['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  s['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  s.delete('ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME')
  s.delete('ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME')
end

# Runner: weak-link ActivityKit (Runner still runs on iOS 15).
runner_configs.each do |c|
  flags = c.build_settings['OTHER_LDFLAGS'] || ['$(inherited)']
  flags = [flags] if flags.is_a?(String)
  flags += ['-weak_framework', 'ActivityKit']
  c.build_settings['OTHER_LDFLAGS'] = flags
end

# Embed the extension, before Flutter's "Thin Binary" script (avoids a build cycle).
runner.add_dependency(widget)
embed = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
embed.name = 'Embed Foundation Extensions'
embed.symbol_dst_subfolder_spec = :plug_ins
build_file = embed.add_file_reference(widget.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
thin = runner.build_phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
runner.build_phases.insert(thin, embed)

project.save
puts 'WorkoutWidget target added'
