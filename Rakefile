desc "Build the Release configuration of the plugin and install for the current user."
task :default do
  system('xcodebuild -configuration Release -target "Install plugin for user"')
end

desc "Build the Debug configuration of the plugin and install for the current user."
task :debug do
  system('xcodebuild -configuration Debug -target "Install plugin for user"')
end
