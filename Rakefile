desc "Restart Safari"
task :restart do
  system("osascript -e 'tell application \"Safari\"' -e 'quit' -e 'end tell' && osascript -e 'tell application \"Safari\"' -e 'activate' -e 'end tell'")
end

desc "Build the Release configuration of the plugin and install for the current user."
task :release do
  system('xcodebuild -configuration Release -target "Install plugin for user"')
end

desc "Build the Debug configuration of the plugin and install for the current user."
task :debug do
  system('xcodebuild -configuration Debug -target "Install plugin for user"')
end

task :default => [:release, :restart]