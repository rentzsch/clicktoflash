# Visit the [Official ClickToFlash Site Here](http://rentzsch.github.com/clicktoflash/)

This is the ClickToFlash developer site.

##Version History

* **1.5.4** [download](http://github.com/downloads/rentzsch/clicktoflash/ClickToFlash-1.5.4-upload1.zip)

	* [FIX] YouTube's "Old Flash? Go upgrade!" message. [bug 517](http://rentzsch.lighthouseapp.com/projects/24342/tickets/517) ([Jeff Johnson](http://github.com/rentzsch/clicktoflash/commit/aa05310397e7ffa7b10032254b6347abe226371f))

* **1.5.3** [download](http://cloud.github.com/downloads/rentzsch/clicktoflash/ClickToFlash-1.5.3-golden.zip)

	* [FIX] Crasher where parsed flash variables (such as `video_id`) were being released prematurely. [bug 261](http://rentzsch.lighthouseapp.com/projects/24342/tickets/261) ([Jeff Johnson](http://github.com/rentzsch/clicktoflash/commit/ef9be0b8697a2c88f1eccc5be8502fec1511f07a))

	* [FIX] Duplicate whitelist entries (caused by a bug in 1.5b4) are now detected and removed, fixing slow-downs, hangs and crashes. [bug 264](http://rentzsch.lighthouseapp.com/projects/24342/tickets/264) ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/12ecfb2a7c23e5434054f3f9085a3fcda6374842)).

	* [CHANGE] Disables H.264 YouTube auto-play by default. [bug 276](http://rentzsch.lighthouseapp.com/projects/24342/tickets/276) ([fppzdd](http://github.com/rentzsch/clicktoflash/commit/c9e2bfac1492618c4a92da298af4a4d051ef927f))

	* [FIX] Embedded YouTube videos were showing a question mark when loaded using the VIDEO element. [bug 294](http://rentzsch.lighthouseapp.com/projects/24342/tickets/294) ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/1f9d11d007165bd70abd96d1ff2223c0db183345))

	* [CHANGE] Rename `CTGradient` to `CTFGradient` to reduce namespace collisions. ([roddi](http://github.com/rentzsch/clicktoflash/commit/0f55f2c2c191e80888c906223c0d5362477de660))

	* [FIX] Avoid leaking the original opacity settings dictionary. ([Sven-S. Porst](http://github.com/rentzsch/clicktoflash/commit/16dd94112c715a57d30d9b7f4ff10bb9e166c869))

* **1.5.2** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.5.2.zip)

	* [NEW] Start signing Sparkle updates. ([rentzsch](http://github.com/rentzsch/clicktoflash/commit/c8f4d7f897a039d5d04ea92e178a15238adcacab))

* **1.5.1** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.5.1.zip)

	* [FIX] Was trying to update via Sparkle on every Flash load. ([rentzsch](http://github.com/rentzsch/clicktoflash/commit/330c89e5706f64f5b0073be17112d5bb864ff8bf)).

	* [CHANGE] Change appcast hosting from @rentzsch's personal Amazon S3 to Github. ([rentzsch](http://github.com/rentzsch/clicktoflash/commit/f2e0796f86466cc3f4432ad81a2403e0f21e8bf6))

* *promoted 1.5fc2 to 1.5* [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.5.zip)

* **1.5fc2** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.5fc2.zip)

	* [FIX] Abandon 1.5fc1's Yet Another Installer Rework -- it causes Installer deadlocks that we can't figure out. [bug 214](http://rentzsch.lighthouseapp.com/projects/24342/tickets/214) (rentzsch)

* **1.5fc1** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.5fc1.zip)

	* [NEW] Use HTML5 `<video>` element instead of QuickTime plugin to view H.264 YouTube content on Safari 4. `<video>` plays better with HTML in general, respecting things like CSS's `z-index`.  ([Andreas Fuchs](http://github.com/rentzsch/clicktoflash/commit/66fd859dc187d8928b9c501f1c66e6f73bde16c5))

	* [NEW] Add white border to Flash badge, improving contrast against dark backgrounds. [bug 131](http://rentzsch.lighthouseapp.com/projects/24342/tickets/131) ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/d870653633564040f41f093e7e208af4264ea71d), [rentzsch](http://github.com/rentzsch/clicktoflash/commit/00a3911ee2dda204a64e7e50f2016acac33c497a))

	* [NEW] Only 60% top-bias badge for flickr.com. ([rentzsch](http://github.com/rentzsch/clicktoflash/commit/65e076288b92033737e2fb5246f361955c14b13a))

	* [NEW] Add Realmac Software applications to application whitelist. ([Nik Fletcher](http://github.com/rentzsch/clicktoflash/commit/c73bba6cadfde92d54770dd5e3af1aa1df6fe767))

	* [FIX] Yet Another Installer Rework. Move to mpkg so we require a password for installation only when necessary (on 10.4 when a non-admin user attempts to install ClickToFlash after an admin user already installed it). [bug 214](http://rentzsch.lighthouseapp.com/projects/24342/tickets/214) ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/96f78edb130f0b8d10149b9d0c053c9c6c9e5b43), [Mo McRoberts](http://github.com/rentzsch/clicktoflash/commit/622673359cc3234076b76051a380598bc1988980))

	* [FIX] Open in QuickTime Player now works on Snowy. [bug 216](http://rentzsch.lighthouseapp.com/projects/24342-clicktoflash/tickets/216) ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/209ecc06a686ff931ba97bd76d25f67ca574eaf9))

	* [FIX] Unchecking 'automatically check for updates' only stopped the check on startup, not subsequent ones. [bug 268](http://rentzsch.lighthouseapp.com/projects/24342/tickets/268) ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/e244b95d8378e677c6027657cab81561db5d8b29))

* **1.5b5** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.5b5.zip)

	* [NEW] Support for HD YouTube videos. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/e03c375ae6358d09e23e371c8402902c2fae14de))

	* [NEW] YouTube H.264 support now works with embedded videos. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/fe5d72cec8d65ab3ea78650fbeb985a9718b6c3f))

	* [FIX] Website whitelist works again. (Simone Manganelli's fault for the bug, also for the fix [1](http://github.com/rentzsch/clicktoflash/commit/2a7423af19ed8d1ea37b3a37a6cee68ef8e8f8f2), [2](http://github.com/rentzsch/clicktoflash/commit/a87d6f32f60353e931cfa0ad6e24321e9fd80b1b))

	* [NEW] Mac app devs can opt out of ClickToFlash on their own by setting 'ClickToFlashOptOut' to YES in their app's Info.plist file. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/7afbf03f62dd77eac1377d6bf4a38f4efd780771))

	* [CHANGE] Gear contextual menu is now always displayed, unless hidden pref 'drawGearImageOnlyOnMouseOver' is set to YES. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/9524aea31f41cb769b3b2f9bc1d15955d5ed2a1a))

	* [FIX] Zattoo, iWeb added to the internal application whitelist. ([Mo McRoberts](http://github.com/rentzsch/clicktoflash/commit/4ec7893e3fd7768c8e9179c866eea258fdbe4660), [Jonathan Rentzsch](http://github.com/rentzsch/clicktoflash/commit/29b08bf159fa3d6291e77f59110c6990461623b9))

	* [FIX] Added Front Row to the application whitelist so that understudy works. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/c94e3f0af2e5c48ec7aaef3d2bdce5bae7001ccf))

	* [FIX] 'Check Now' button is still enabled even if auto-updating is turned off. bug [200](http://rentzsch.lighthouseapp.com/projects/24342/tickets/200) ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/d8bb666ad9cf007e1d581dba656bde2c80cbd340))

	* [FIX] Sparkle status window goes away if the user chooses to restart the app after install at a later date. bug [191](http://rentzsch.lighthouseapp.com/projects/24342/tickets/191) ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/c768f07087c769f12f7645e78dd42802da46048b))

	* [FIX] Modified installer package bundle ID back to 'com.github.rentzsch.clicktoflash.pkg' ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/62c89295fa30edc7af73dc40216efd18be6f296f))

	* [FIX] More clang static analyzer fixes. ([Jeff Johnson](http://github.com/rentzsch/clicktoflash/commit/0236542d1adc5d0aece70ab37b4276e01da32171))

	* [FIX] Changed name to the canonical spelling 'ClickToFlash' plug-in-wide. (Simone Manganelli [1](http://github.com/rentzsch/clicktoflash/commit/1ffec928b54ab55a4475de65c20410c84bff9b26), [2](http://github.com/rentzsch/clicktoflash/commit/33b9caaa4ce6bfac5aa7985d170d04cef9c3d18c), [3](http://github.com/rentzsch/clicktoflash/commit/047eedd562e43eac024da17504e183b0347b0cba))

	* [FIX] Various fixes for H.264 variant checking. (Chris Suter [1](http://github.com/rentzsch/clicktoflash/commit/3b7739e4244e6ac77300df2526e1f47850f16582), [2](http://github.com/rentzsch/clicktoflash/commit/df8cb97f3333d87193af73b8479d888484c4e86b), Simone Manganelli [1](http://github.com/rentzsch/clicktoflash/commit/5ad0fe636d59809146c6f13b5ff50cc8833e3df5), [2](http://github.com/rentzsch/clicktoflash/commit/32aacf1279ccbabb53a41932c65d647475c1fdd4))

	* [FIX] Enable building when the project path has spaces. ([Nathan de Vries](http://github.com/rentzsch/clicktoflash/commit/b87e08bce2a1ac0dc7b31ea5ad633f6afd7e1256))

	* [CHANGE] Deleted unused 'Remove from Whitelist...' contextual menu item. bug [79](http://rentzsch.lighthouseapp.com/projects/24342-clicktoflash/tickets/79) ([Jonathan Rentzsch](http://github.com/rentzsch/clicktoflash/commit/506c049859d0aa78896e0ebcda2aaf1abab7a934))

	* [FIX] Added :restart task to Rakefile so that Safari is restarted when compiling a new ClickToFlash version. ([Ale Mu&ntilde;oz](http://github.com/rentzsch/clicktoflash/commit/c1c717dfb213d8e88af746fad3c06b9db3f96a1d))

	* [FIX] YouTube views now have a 'YouTube' badge if the 'Load H.264' preference is checked. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/c34feb0d3ad76dc18e73a13f9203d94e355975bc))

	* [CHANGE] Badge shows an ellipsis (...) if it's still checking for H.264 variants. ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/f1d8c95336945de0fd126cfce98708870ecfc357))

	* [FIX] Shortened obscenely long tooltips to 200 characters. bug [234](http://rentzsch.lighthouseapp.com/projects/24342/tickets/234) ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/69ddaf9b5ba93516e0e388b3bf2d52166b957ce2))

	* [FIX] Vertical top-bias the badge by 60% so that centered loading text doesn't obscure the badge. bug [56](http://rentzsch.lighthouseapp.com/projects/24342/tickets/56) ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/056f38b4a23b9e9b5494efdd35e6a25f0890209d))

	* [FIX] Sites that loaded 'about:blank' into an iframe for ads were having their ads auto-loaded. bug [240](http://rentzsch.lighthouseapp.com/projects/24342/tickets/240) ([Simone Manganelli](http://github.com/rentzsch/clicktoflash/commit/ec2265a152b28b8edaee5518ca1101a2ae6a6eb5))

	* [FIX] YouTube videos loaded from www.youtube-nocookie.com were not being recognized by ClickToFlash. bug [249](http://rentzsch.lighthouseapp.com/projects/24342/tickets/249) ([Simone Manganelli](http://github.com/simX/clicktoflash/commit/dc5bf53f963e914c81285340d05ee7cdc8cae049))

	* [FIX] Changed 'Open YouTube.com page for this video' to open in the current window in the host app rather than in a new window in Safari. ([Sven-S. Porst](http://github.com/ssp/clicktoflash/commit/26de0f0bd64fd259d96fa15bb43d3f9d87588ff5))

* **1.5b4** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.5b4.zip)

	* [NEW] "Play Fullscreen in QuickTime Player" contextual menu command for viewing YouTube videos in QuickTime Player (which has niceties like supporting the Apple remote). [bug 216](http://rentzsch.lighthouseapp.com/projects/24342/tickets/216) ([Simone Manganelli](http://github.com/simX/clicktoflash/commit/27dd7e5d64b5993fc492b06ec940d2820f323330))
	
	* [NEW] Application-wide whitelisting for apps like Hulu Desktop, PandoraJam and Wii Transfer that utilize Flash. [bugs 26](http://rentzsch.lighthouseapp.com/projects/24342/tickets/216), [118](http://rentzsch.lighthouseapp.com/projects/24342/tickets/118) and [230](http://rentzsch.lighthouseapp.com/projects/24342/tickets/230) ([Simone Manganelli](http://github.com/simX/clicktoflash/commit/f2a1e755c78d6b1edd52b4bb85fb643eae3783c9))

	* [NEW] User preferences now are stored in a separate file, allowing them to be shared across application. Parasitic prefs are migrated to the external file and then deleted. [bug 73](http://rentzsch.lighthouseapp.com/projects/24342/tickets/73) ([Simone Manganelli](http://github.com/simX/clicktoflash/commit/39a3ae3522e168e76f97511fa9623eff587d7580))

	* [NEW] Uninstall button (with a confirmation sheet) in the settings window. [bug 226](http://rentzsch.lighthouseapp.com/projects/24342/tickets/226) ([Simone Manganelli](http://github.com/simX/clicktoflash/commit/7851b478da8ee0fa951362cd04853b035a46fb38))

	* [NEW] Gradient on 10.4 now looks the same as 10.5 and 10.6. ([Kevin Hiscott](http://github.com/mbaltaks/clicktoflash/commit/566097de9e74610e7ae9819d020a404f1fc6223e))

* **1.5b3** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.5b3.zip)

	* [NEW] Additional executable architechure: `x86_64`. This addition enables ClickToFlash to work on Safari 4 on Mac OS X 10.6 Snow Leopard. ClickToFlash retains compatiblity with 10.4-and-later on both PowerPC and Intel (the full list: 10.4/ppc, 10.4/i386, 10.5/ppc, 10.5/i386 and 10.6/x86_64). ([rentzsch](http://github.com/rentzsch/clicktoflash/commit/1ea61443b8f6005dffb3d846c1ecc9eb41165472))

* **1.5b2** [download](http://s3.amazonaws.com/clicktoflash/ClickToFlash-1.5b2.zip)

	* [NEW] Gear icon only appears upon mouse-over (hovering). ([Otyr Ugla](http://github.com/rentzsch/clicktoflash/commit/909dbed81aca5e89af97d12aca546162efb17df3))

	* [NEW] Add custom gear image (derived from Cocoatron) for 10.4 systems which lack `NSActionTemplate`. ([Michael Baltaks](http://github.com/rentzsch/clicktoflash/commit/0e28fe15bd93b3adcb9ef86c00a21e14b5e48b79), [Math Campbell](http://www.mathcampbell.co.uk))

* **1.5b1**

	* [NEW] Restoring 10.4 compatibility. ([Michael Baltaks](http://github.com/rentzsch/clicktoflash/commit/6d1803dfb903e87af13674d4944e4bcbb29df1a4))

	* [NEW] Installer-package-building overhaul. Now creates 10.4-compatible .pkgs. Abandons evil .pmdoc files. ([rentzsch](http://github.com/rentzsch/clicktoflash/commit/25393e0eaa7cd1b5b8ad9d628d9193dc031459ba))

	* [CHANGE] 10.4 compatiblity: only use `-[NSBundle loadAndReturnError:]` when it's available. ([rentzsch](http://github.com/rentzsch/clicktoflash/commit/3674219a5ddc7debb28385655c82a42ef8027b67))

	* [FIX] Work-around `MATrackingArea` 10.4 GC incompatiblity. ([rentzsch](http://github.com/rentzsch/clicktoflash/commit/f027c415cadd1dada95017e57fc117c55152199c))

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

##Hidden Defaults

ClickToFlash has a few hidden preferences that can be used to control its functionality.  These preferences have been added for development or experimental reasons and are **not** guaranteed to persist in future versions of ClickToFlash.

To use these hidden preferences, open the Terminal and type the following command: `defaults write com.github.rentzsch.clicktoflash defaultName defaultValue`, replacing `defaultName` and `defaultValue` with the appropriate values, then press return.  To restore default functionality, use the following Terminal command: `defaults delete com.github.rentzsch.clicktoflash defaultName`, replacing `defaultName` with the appropriate value.

* defaultName: **enableYouTubeAutoPlay**; possible defaultValues: **"YES"**, **"NO"**; autoplays videos on YouTube once you click on the ClickToFlash view, assuming you're either logged out of YouTube or are logged in and have enabled this feature in your YouTube account settings.
* defaultName: **disableVideoElement**; possible defaultValues: **"YES"**, **"NO"**; disables the usage of the HTML 5 VIDEO tag, and uses the old QuickTime plug-in instead.  Note, the VIDEO tag usually exhibits much better performance and lower CPU usage because it supports hardware acceleration, whereas the old QuickTime plug-in does not.  However, some Macs seem to see an adverse effect on performance with the VIDEO tag.
* defaultName: **drawGearImageOnlyOnMouseOver**; possible defaultValues: **"YES"**, **"NO"**; shows the gear menu only when you're mousing over the ClickToFlash view, reducing visual noise for Flash-heavy pages.
* defaultName: **applicationWhitelist**; to use this hidden pref, use the following syntax: `defaults write com.github.rentzsch.clicktoflash applicationWhitelist -array-add bundleID` .  This whitelists Flash for a particular application, and causes ClickToFlash to automatically load all Flash inside the application whose bundle ID is "bundleID".  (This hidden pref *is* guaranteed to persist in future versions.)