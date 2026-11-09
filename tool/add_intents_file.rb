# Adds ios/WorkoutWidget/WorkoutIntents.swift to the Runner and WorkoutWidget
# targets and weak-links AppIntents in Runner (it still runs on iOS 15).
require 'xcodeproj'

project = Xcodeproj::Project.open(File.expand_path('../ios/Runner.xcodeproj', __dir__))
runner = project.targets.find { |t| t.name == 'Runner' }
widget = project.targets.find { |t| t.name == 'WorkoutWidget' }
group = project.main_group['WorkoutWidget']
abort 'already added' if group.files.any? { |f| f.path == 'WorkoutIntents.swift' }
ref = group.new_reference('WorkoutIntents.swift')
runner.source_build_phase.add_file_reference(ref)
widget.source_build_phase.add_file_reference(ref)
runner.build_configuration_list.build_configurations.each do |c|
  flags = c.build_settings['OTHER_LDFLAGS'] || ['$(inherited)']
  flags = [flags] if flags.is_a?(String)
  c.build_settings['OTHER_LDFLAGS'] = flags + ['-weak_framework', 'AppIntents'] unless flags.include?('AppIntents')
end
project.save
puts 'added'
