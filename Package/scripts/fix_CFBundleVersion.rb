#!/usr/bin/ruby
if File.exist?("#{ENV['HOME']}/Library/Internet Plug-Ins/ClickToFlash.plugin/Contents/Info.plist")
  bundle_version = `defaults read "$HOME/Library/Internet Plug-Ins/ClickToFlash.plugin/Contents/Info" CFBundleVersion`.chomp
  if bundle_version == "700"
    short_version_string = `defaults read "$HOME/Library/Internet Plug-Ins/ClickToFlash.plugin/Contents/Info" CFBundleShortVersionString`.chomp
    `defaults write "$HOME/Library/Internet Plug-Ins/ClickToFlash.plugin/Contents/Info" CFBundleVersion #{short_version_string}`
  end
end
