#!/usr/bin/env ruby
require 'xcodeproj'

# Xcode project and file paths
project_path = 'ios/Runner.xcodeproj'
file_path = 'ios/GoogleService-Info.plist'

# The group in the Xcode project where the file will be added
group_name = 'Runner'

# Open the Xcode project
project = Xcodeproj::Project.open(project_path)

# Find the group
group = project.main_group.find_subpath(group_name, true)

# Check if the file reference already exists
file_ref = group.files.find { |file| file.path == 'GoogleService-Info.plist' }

if file_ref
  puts "File '#{file_path}' already exists in the project."
else
  # Add the file reference to the group
  file_ref = group.new_file(file_path)

  # Get the main target
  main_target = project.targets.first

  # Add the file to the resources build phase
  main_target.add_resources([file_ref])

  # Save the project
  project.save

  puts "Added '#{file_path}' to the Xcode project."
end