require 'xcodeproj'

PROJECT_PATH = File.expand_path('Elevate/Elevate.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJECT_PATH)

app_target = project.targets.find { |t| t.name == 'Elevate' }

# Remove the "Embed Watch Content" copy-files phase from Elevate target
app_target.build_phases.delete_if do |phase|
  phase.respond_to?(:name) && phase.name == 'Embed Watch Content'
end

# Remove the ElevateWatch dependency from Elevate target
watch_target = project.targets.find { |t| t.name == 'ElevateWatch' }
app_target.dependencies.delete_if do |dep|
  dep.target == watch_target
end

project.save
puts "Removed Embed Watch Content phase and dependency from Elevate target."
puts "The ElevateWatch target still exists and builds via its own scheme."
