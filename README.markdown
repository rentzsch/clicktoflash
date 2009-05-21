#[Download ClickToFlash 1.4.2 here](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.4.2.zip)

**Note: if ClickToFlash installation fails, please issue the following Terminal command.  After doing so, again attempt reinstallation of ClickToFlash:** 

	sudo pkgutil --forget com.github.rentzsch.clicktoflash.pkg

Please note: if you see the following error:

	No receipt for 'com.github.rentzsch.clicktoflash.pkg' found at '/'.

**you do not need to worry about anything.**  If you see this error, then the next time you install ClickToFlash, it should work correctly.

Currently requires Mac OS X 10.5 Leopard.

ClickToFlash is a WebKit plug-in that prevents automatic loading of Adobe Flash content. If you want to see the content, you can opt-in by clicking on it or adding an entire site to the whitelist.

Try control-clicking (or right-clicking) on an unloaded Flash box to access ClickToFlash's contextual menu which allows you to do advanced things like edit its whitelist, specify settings, and load all Flash on the page.

Please [report bugs and request features](http://rentzsch.lighthouseapp.com/projects/24342-clicktoflash/tickets/new) on the [Lighthouse ClickToFlash project site](http://rentzsch.lighthouseapp.com/projects/24342-clicktoflash/tickets?q=all).

Want to chip in? [Here's what needs to be done](http://rentzsch.lighthouseapp.com/projects/24342-clicktoflash/tickets?q=not-tagged%3Abrokensite+state%3Aopen&filter=).

##Version History

* **1.4.2** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.4.2.zip)

	* [CHANGE] Set `WebPluginDescription` to `Shockwave Flash 10.0 r22`. We have to bald-face lie in order to tip-toe around various in-the-wild broken Flash version detection scripts. bugs [176](http://rentzsch.lighthouseapp.com/projects/24342/tickets/176), [177](http://rentzsch.lighthouseapp.com/projects/24342/tickets/177), [178](http://rentzsch.lighthouseapp.com/projects/24342/tickets/178), [180](http://rentzsch.lighthouseapp.com/projects/24342/tickets/180), [185](http://rentzsch.lighthouseapp.com/projects/24342/tickets/185), [187](http://rentzsch.lighthouseapp.com/projects/24342/tickets/187), [188](http://rentzsch.lighthouseapp.com/projects/24342/tickets/188), [192](http://rentzsch.lighthouseapp.com/projects/24342/tickets/192) ([Jeff Johnson](http://github.com/rentzsch/clicktoflash/commit/d470c3dbdf1a1068a6feac4661f09ec380024fbe))

	* [DEV] Start restoring 10.4 compatibility. Currently incomplete. ([Michael Baltaks](http://github.com/rentzsch/clicktoflash/commit/6d1803dfb903e87af13674d4944e4bcbb29df1a4))

* **1.4.1** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.4.1.zip)
	* [FIX] Tweak WebPluginDescription from `9.0.151.0` to `9.0.151`. bugs [161](http://rentzsch.lighthouseapp.com/projects/24342/tickets/161), [162](http://rentzsch.lighthouseapp.com/projects/24342/tickets/162), [163](http://rentzsch.lighthouseapp.com/projects/24342/tickets/163), [168](http://rentzsch.lighthouseapp.com/projects/24342/tickets/168), [171](http://rentzsch.lighthouseapp.com/projects/24342/tickets/171), [174](http://rentzsch.lighthouseapp.com/projects/24342/tickets/174) ([Jeff Johnson](http://github.com/rentzsch/clicktoflash/commit/34897240e80470a36ee7778dd3d62f79891c5c84))

* **1.4** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.4.zip)
	* [CHANGE] Rename WebPluginDescription from `ClickToFlash Flash 9.0 r151` to `Shockwave Flash 9.0 r151 (ClickToFlash)` to better spoof sites (like CNN video) that check for specific flash versions. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/6b60d2d802afe06404725d92d2a121acdb7b4f47))

	* [CHANGE] Version now included in the 'Installed Plug-ins' page; added version number to settings window. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/546ed7d9fef47c5e3821fb7fc10a0c008e81f2c9))

	* [CHANGE] Removed the installation check for Safari, because it was causing problems for people who had moved it from its standard location, and [stupid PackageMaker doesn't have a way to check via bundle identifier](http://homepage.mac.com/simx/.Pictures/PackageMakerOnNotice.jpeg). ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/c91c9ba77396f84c410ce1c42409df0842fc1221))

	* [CHANGE] ClickToFlash's extension to `.webplugin`. Activate GC support in both ClickToFlash and Sparkle. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/e1688f660540b68fc77e91e4524bd54045ef8245))

	* [FIX] Sparkle now correctly relaunches WebKit instead of Safari after installing an update. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/e8dadfdeae394bee6bd7e36bc208390a515f4a5d))

	* [FIX] "Install plugin for user" Xcode target shell script. [bug 153](http://rentzsch.lighthouseapp.com/projects/24342/tickets/153) ([pom](http://github.com/rentzsch/clicktoflash/commit/c0e67b25782d5944e890f078f1c9c9a73a810192))

	* [CHANGE] Use same version numbering scheme as Flash plugin, because stupid web sites check for this. [bug 161](http://rentzsch.lighthouseapp.com/projects/24342/tickets/161) ([Jeff Johnson](http://github.com/rentzsch/clicktoflash/commit/e8dd3001d2247e4cd321d1d154dec90bc1500d99))

	* [FIX] Prevent installation on volumes other than the root volume. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/876bc68257edf3e9a98e53c186301ec73d0467a6))

	* [FIX] Replace use of deprecated methods. ([Jacques Vidrine](http://github.com/rentzsch/clicktoflash/commit/980674374d043dcdd6b745d89d22cf7094fe168a) via [twitter](https://twitter.com/EACCES/status/1697243619))

	* [FIX] Confusing installer UI that says it will install for all users and then only installs for the current user. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/2d74d2b477a76a07dd4bf9d9ac45a69d18d22eee))
	
	* [FIX] Quote pathnames in installation script. ([Cédric Luthi](http://github.com/rentzsch/clicktoflash/commit/80c7687a9b88b7c74afe28e31be791fe50a81ff5))

* **1.4fc6** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.4fc6.zip)
	* **If you've been using any of the 1.4fcX releases, please issue the following Terminal command.  After doing so, again attempt reinstallation of ClickToFlash: `sudo pkgutil --forget com.github.rentzsch.clicktoflash.pkg`** 
	Please note, if you receive this error: `No receipt for 'com.github.rentzsch.clicktoflash.pkg' found at '/'.`, you do not need to worry.  If you see this error, then the next time you install ClickToFlash, it should work correctly.

	* [NEW] Option to disable ClickToFlash globally. [bug 94](http://rentzsch.lighthouseapp.com/projects/24342/tickets/94) ([Patrick McCarron](http://github.com/rentzsch/clicktoflash/commit/b224861719aebaed81e9909c4fd5526d55032454))

	* [NEW] Contextual menu item to download H.264 file from YouTube. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/95cec2c6481772f8d448b4cf98555ea91690b448))

	* [NEW] Contextual menu item that opens the YouTube.com page for embedded YouTube players. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/a055047347d7eebbb1cd69997bee332ac0845966))

	* [NEW] .icns file so the Sparkle update dialog doesn't show the generic document file icon ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/2e5c459ce50999d2d3f96e44cd99be3c05e47305))

	* [NEW] Dynamically loads Sparkle from internally bundled framework when host doesn't already use Sparkle. [bug 99](http://rentzsch.lighthouseapp.com/projects/24342/tickets/99) ([rentzsch]((http://github.com/rentzsch/clicktoflash/commit/41dd9de069fc8f7d4a81d77ee981ece938eaf274))

	* [NEW] Allow host apps that use Sparkle 1.5 or later to update ClickToFlash. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/181c096da517bfb002fa96045f8edbd8a2fb94f6))

	* [FIX] Work-around an [Installer bug](http://openradar.appspot.com/6850710). bugs [95](http://rentzsch.lighthouseapp.com/projects/24342/tickets/95), [96](http://rentzsch.lighthouseapp.com/projects/24342/tickets/96), [113](http://rentzsch.lighthouseapp.com/projects/24342/tickets/113), [122](http://rentzsch.lighthouseapp.com/projects/24342/tickets/122), [125](http://rentzsch.lighthouseapp.com/projects/24342/tickets/125), [126](http://rentzsch.lighthouseapp.com/projects/24342/tickets/126), [128](http://rentzsch.lighthouseapp.com/projects/24342/tickets/128), [133](http://rentzsch.lighthouseapp.com/projects/24342/tickets/133), [144](http://rentzsch.lighthouseapp.com/projects/24342/tickets/144) ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/666f53eaabc0faaa4458e6c71084780650779472))

	* [FIX] Sparkle crasher in scheduleNextUpdateCheck. ([Jeff Johnson](http://github.com/rentzsch/clicktoflash/commit/f7ca07b3e6e6e13de8133d8e237f284f2ccdc066))

	* [FIX] Hang when loading Walmart pages. ([Jeff Johnson](http://github.com/rentzsch/clicktoflash/commit/7503af2d03c07e5b900f01fce5027ebf32a52aa2) and [Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/74584371bdb1391afb3655b8c3113f5cda5afe0f))

	* [FIX] Gear image was drawn in an incorrect position in rare cases. (Peter Hosey and [Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/70055dde3fa378e4440ba0d06180b987e578e148))

	* [FIX] If the gear icon isn't drawn, the contextual menu no longer pops up if you click in the upper-left corner of the view. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/a1a86695294ac7f633a6b6f68b574d18e1ec0926))

	* [FIX] Correct tooltip on "Enable ClickToFlash" checkbox. ([rentzsch](http://github.com/rentzsch/clicktoflash/commit/7c05e6667f464e8e866206d1b489fec9f82f3d46))

	* [CHANGE] Opacity changes are now added to the original styles (instead of replacing) so positioning and other attributes remain unaffected. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/dde839f6c7bc61a6ae8690c95ed4da2e2412a273))

* **1.4fc5** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.4fc5.zip)
	* Removes April Fool's special edition feature, fixes most broken sites.

* **1.4fc4** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.4fc4.zip)
	* *April Fool's special edition. [Simone Manganelli]*

* **1.4fc3** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.4fc3.zip)
	* *This update is exactly the same as 1.4fc2 and only exists to test/demonstrate Sparkle updating.*

* **1.4fc2** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.4fc2.zip)
	* [NEW] Added buttons in settings panel to allow for manual update checking. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/194f2dc1a8da91298d2e79fb426b60ecf4205d2a))

	* [NEW] Nil hosts get whitelisted by default. This effectively disables ClickToFlash in Dashboard and other places where it might be desirable to do so. ([millenomi](http://github.com/rentzsch/clicktoflash/commit/18dbcd3ba312290223ff456dd5a08f0d4bb74cd4))

	* [DEV] Add 1.4fc3 to appcast. It's functionally identical to 1.4fc2 and only exists to test Sparkle updating.

* **1.4fc1** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.4fc1.zip)
	* [NEW] Menu command to load all flash views -- or just invisible ones -- on a page. This should fix a number of sites that don't at first seem to work with ClickToFlash. (Simone Manganelli, et al.)

	* [NEW] "Click To Flash" menu item(s). Installs automatically into Safari and Vienna under their application menus. (Simone Manganelli, Jeff Johnson, et al.)

	* [NEW] Explicit YouTube support. Built-in support for directly loading higher-quality H.264 versions of videos (contextual menu item "Load H.264"). ([Joey Hagedorn](http://www.joeyhagedorn.com/2008/04/16/youtube-in-mp4-via-quicktime-plugin), et al.)

	* [NEW] Explicit [sIFR](http://www.mikeindustries.com/sifr) support: ignore sIFR, always load it or always suppress it. [bug 49](http://rentzsch.lighthouseapp.com/projects/24342/tickets/49) (Ian Wessman, et al.)

	* [NEW] Edit whitelist in Settings panel. [bug 25](http://rentzsch.lighthouseapp.com/projects/24342/tickets/25) (Ben Gottlieb [1](http://github.com/rentzsch/clicktoflash/commit/4e013686359f7a11371e16919f292eb91c249ebb), [2](http://github.com/rentzsch/clicktoflash/commit/d193a728c32af21345af083cc4a22c7a26c97f42), et al. [1](http://github.com/rentzsch/clicktoflash/commit/1da96792eecc4252c90c706576fbfc1f1afd3860), [2](http://github.com/rentzsch/clicktoflash/commit/16b844c96b6423629d6de707ee3fe69257dbd7ce))

	* [NEW] Old custom installer replaced with a standard Installer.app .pkg. [bug 27](http://rentzsch.lighthouseapp.com/projects/24342/tickets/27) ([Alexander Brausewetter](http://github.com/xoob/clicktoflash/commit/2866d8e8415114ae75f60ff8d107e78e5fe40b2c))

	* [NEW] Automatic plugin updating via Sparkle. [bug 28](http://rentzsch.lighthouseapp.com/projects/24342/tickets/28) (rentzsch)

	* [NEW] Whitelisting now takes into account an object's `src` URL, which should allow embedded videos from whitelisted sites to play (e.g. YouTube). [bug 57](http://rentzsch.lighthouseapp.com/projects/24342/tickets/57) ([Ian Wessman](http://github.com/rentzsch/clicktoflash/commit/a4388f32d13f00263d11d9d06f21778bea5724dc))

	* [CHANGE] Badge now renders better on a variety of backgrounds.

	* [FIX] Fixed bugs identified by clang static analyzer. ([Jeff Johnson](http://github.com/rentzsch/clicktoflash/commit/aced770608344960131f58e49457d0a73687d38c))

	* [FIX] Fixed leak that caused all CtF views to not be deallocated by using validateMenuItem to update the Add `<site>` to Whitelist menu item instead of a binding. ([1](http://github.com/rentzsch/clicktoflash/commit/912e28f5befe90db92be971d5899de5cbd3b6a89)) 

	* [DEV] Fix deprecated use of `+stringWithContentsOfFile:`. ([Chris Parker](http://github.com/rentzsch/clicktoflash/commit/7a1e8490737db4734b3e8fc3374fabfdc49ee756))

	* [DEV] Clean up build settings. No need to build universal in Debug or link to Carbon. ([Jeff Johnson](http://github.com/rentzsch/clicktoflash/commit/9a47274242904b8928b17d842137e75c71fe1c73))

	* [DEV] Add build warnings. Fix resulting warnings. Treat warnings as errors. (Jeff Johnson [1](http://github.com/rentzsch/clicktoflash/commit/cf6dfbb4978596961ba232279994a65b00b9e30b), [2](http://github.com/rentzsch/clicktoflash/commit/69c0083117174d05b69a62c164fc1779e5fc55b0))

	* [DEV] Populate CFBundleVersion with ${PRODUCT_VERSION} instead of hard-coding with 700. (Dave Dribin)

* **1.3+tiger** [download tiger/leo version](http://portway-ave.com/clicktoflash/ClickToFlash-1.3+Tiger.zip)
	* [NEW] Universal Tiger/Leo PPC/Intel Compatibility! (Well, its been tested on Tiger/PPC and Leo/Intel, but the plugin is now universal and should work everywhere)
	* [NEW] The installer now also works on Tiger
	* [FIX] Darkened gradient on Tiger for better visibility
	* [FIX] Removed Copy address contextual menu as it was flakey

* **1.3** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.3.zip)
	* [NEW] Flash badge is now drawn in code (vector image), and draws smaller in smaller flash boxes. [bug 12](http://rentzsch.lighthouseapp.com/projects/24342/tickets/12)

	* [NEW] Flash badge rotates counter-clockwise for narrow flash boxes. [bug 12](http://rentzsch.lighthouseapp.com/projects/24342/tickets/12)

	* [NEW] "Add to whitelist" contextual menu item now lists the url that's to be whitelisted. [bug 20](http://rentzsch.lighthouseapp.com/projects/24342/tickets/20-add-to-whitelist-sheet-unnecessary-when-rightclicking) ([Kevin A. Mitchell](http://github.com/kamitchell/clicktoflash/commit/83f121029225b16ae2e4d4f6a2f2bc64d2235b02))

	* [NEW] Extend coverage to `<object>` and `<embed>` tags that lack `type` or `classid` attributes by adding `swf` to the plugin's `WebPluginExtensions` Info.plist key. [bug 19](http://rentzsch.lighthouseapp.com/projects/24342/tickets/19) ([fds](http://rentzsch.lighthouseapp.com/projects/24342/tickets/19#ticket-19-10))

	* [NEW] Kill badge flicker for whitelisted sites ([bug 17](http://rentzsch.lighthouseapp.com/projects/24342/tickets/17)) and load all 
flash boxes when whitelisting one ([bug 10](http://rentzsch.lighthouseapp.com/projects/24342/tickets/10)).

	* [FIX] Remove `-menuForEvent:` as it already returns the NSResponder's `-menu` by default. ([Dave Dribin](http://github.com/ddribin/clicktoflash/commit/5de474bc17332208fd21ec78fe7eaf3a9844d7bf))

	* [FIX] Remove CTFInstaller.m from the bare plugin target. [bug 44](http://rentzsch.lighthouseapp.com/projects/24342-clicktoflash/tickets/44) ([Chris Parker](http://github.com/tgaul/clicktoflash/commit/17d455844a7428471dca018d1461f5c5d1cbb692))

	* [DEV] Make Rakefile honor build products directory. [bug 43](http://rentzsch.lighthouseapp.com/projects/24342/tickets/43) ([Chris Parker](http://github.com/tgaul/clicktoflash/commit/021eebfd274b4e415c31c2ac9e4bb2ffed569ee4))

* **1.2+tiger** [download tiger version](http://portway-ave.com/clicktoflash/ClickToFlashTiger-1.2.zip)
	* [NEW] Added copy address to clipboard ([Peter Hosey](http://github.com/boredzo/clicktoflash/commit/19cc5b9b25f1e9ad2e62e61d795a1b0e5368822b))

* **1.2** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.2.zip)
	* [NEW] Handle `<object>` and `<embed>` that are missing a `type` attribute. That fixes a number of the broken sites. [bug #19](http://rentzsch.lighthouseapp.com/projects/24342/tickets/19-banner-ad-appears-without-whitelisting) ([Jason Foreman](http://github.com/threeve/clicktoflash/commit/e4a7ad83c312bcc3d7400562905122951ae85763))

	* [NEW] Activate on mouse-up, instead of mouse-down. Draw as "pressed in" during mouse-down, tracking the mouse like normal button. (Peter Hosey)

	* [NEW] Added a seperator to the context menu.

	* [FIX] Release build-time script that includes the project's entire build directory. ([Peter Hosey](http://github.com/boredzo/clicktoflash/commit/0b063cd0987254fd61aaa2b317ef2d79f30a44a8))

* **1.1** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.1.zip)
	* [NEW] Tasteful "Flash" icon now drawn on top of the gradient to make it more clear that it's blocked Flash content. ([Ricky Romero, Justin Williams](http://rentzsch.lighthouseapp.com/projects/24342/tickets/3-flash-boxes-are-not-always-obvious))

	* [NEW] Contextual menu and simple whitelist editor. ([Dave Dribin](http://github.com/ddribin/clicktoflash))

	* [NEW] Show the Flash box's source as a tooltip. ([Jason Foreman](http://github.com/threeve/clicktoflash/commit/a54c97c7be43e0adfbb0aad317c6020666d2a2e3))

	* [NEW] Installer can update older versions. (rentzsch)

	* [NEW] Rakefile to compile & upgrade the plugin by running 'rake' in the directory. ([Ale Muñoz](http://github.com/bomberstudios/clicktoflash/commit/2807f05aafe829e942f0c945ab914c0830652f73))

	* [NEW] Localization support. ([Eric Czarny](http://github.com/eczarny/clicktoflash/commit/beefab38bdb881fd78ac6e844e1e1d53206b118c))

	* [DEV] Clean-up. Nonatomic properties, remove unused methods, `unsigned` => `NSUInteger`. (Jim Correia)

	* [DEV] Change CFBundleIdentifier from com.google.code.p.clicktoflash to com.github.rentzsch.clicktoflash. (rentzsch)

	* [FIX] Installer now quits when canceling. (rentzsch)

	* [FIX] Removed the container image from the installer. ([Eric Czarny](http://github.com/eczarny/clicktoflash/commit/d25675cd97e4709b9a794029c06794d87ac8c9af))

* *original Google code project deleted. This fork takes on official-ish mantle.*

* **1.0+rentzsch** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash%2Brentzsch-1.0.zip)

	* Forked from original Google code project (Jonathan 'Wolf' Rentzsch)

	* [NEW] Site whitelisting by holding down option key when clicking a flash box. (Gus Mueller)

	* [FIX] Use `-[NSEvent modifierFlags]` instead of Carbon's `GetCurrentKeyModifiers()`. (Chris Parker)

	* [DEV] Store white-listed sites in an array instead of composite keys. ([Jean-Francois Roy](https://twitter.com/jfroy/status/1150564777))

* **1.0** original Google Code release
