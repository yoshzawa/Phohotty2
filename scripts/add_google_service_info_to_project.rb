#!/usr/bin/env ruby
require 'xcodeproj'

# Define paths
project_path = 'ios/Runner.xcodeproj'
# The name of the file to be added to the Xcode project.
# This should be just the filename, not the full path.
file_to_add = 'GoogleService-Info.plist'
# The group within the Xcode project (e.g., the 'Runner' folder).
group_name = 'Runner'

# --- Script Start ---
puts "INFO: Checking Xcode project for GoogleService-Info.plist..."

# Open the Xcode project
project = Xcodeproj::Project.open(project_path)

# Find the target group (e.g., 'Runner')
target_group = project.main_group.find_subpath(group_name, true)
raise "Group '#{group_name}' not found in project" unless target_group

# --- 1. Clean up old incorrect references ---
# The build error showed Xcode looking for 'ios/Runner/ios/Runner/GoogleService-Info.plist'.
# This happened because a previous version of this script added a bad reference.
# We will find and remove any reference that has a path containing '/'.

invalid_file_references = target_group.files.select do |file|
  file.path.include?('/') && file.path.end_with?(file_to_add)
end

if invalid_file_references.any?
  puts "WARN: Found invalid, nested path references to '#{file_to_add}'. Removing them."
  invalid_file_references.each do |file_ref|
    # Remove from group
    target_group.remove_reference(file_ref)
    # Remove from all build phases in all targets
    project.targets.each do |target|
      target.resources_build_phase.remove_file_reference(file_ref)
    end
    puts "Removed invalid reference: '#{file_ref.path}'"
  end
else
  puts "INFO: No invalid path references found. Clean."
end

# --- 2. Add the correct file reference if it doesn't exist ---

# Check if a *correct* file reference already exists.
# The path should be just the filename, as it's relative to the group.
existing_file_ref = target_group.files.find { |file| file.path == file_to_add }

if existing_file_ref
  puts "INFO: Correct reference to '#{file_to_add}' already exists in group '#{group_name}'."
else
  puts "INFO: No reference to '#{file_to_add}' found. Adding it now."
  # The path given to `new_file` should be relative to the group's path.
  # Since the file is *in* the Runner folder, and the group *is* the Runner folder,
  # the relative path is just the filename.
  file_ref = target_group.new_file(file_to_add)

  # Add the new file reference to the main target's resources build phase
  main_target = project.targets.find { |target| target.name == 'Runner' }
  raise "Main target 'Runner' not found" unless main_target
  
  main_target.resources_build_phase.add_file_reference(file_ref)
  puts "INFO: Successfully added '#{file_to_add}' to target '#{main_target.name}'."
end

# Save the project file
project.save

puts "INFO: Xcode project updated successfully."
