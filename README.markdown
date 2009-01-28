#ClickToFlash

[Download ClickToFlash 1.1 here](http://s3.amazonaws.com/rentzsch/ClickToFlash-1.1.zip). Currently requires Mac OS X 10.5 Leopard.

ClickToFlash is a WebKit plug-in that prevents automatic loading of Adobe Flash content. If you want to see the content, you can opt-in by clicking on it or adding an entire site to its whitelist.

Try control-clicking (or right-clicking) on a unloaded Flash box to access ClickToFlash's contextual menu which allow you to do advanced things like edit its whitelist.

Please [report bugs and request features](http://rentzsch.lighthouseapp.com/projects/24342-clicktoflash/tickets/new) on the [Lighthouse ClickToFlash project site](http://rentzsch.lighthouseapp.com/projects/24342-clicktoflash/tickets?q=all).

##Version History

* **1.1** [download](http://s3.amazonaws.com/rentzsch/ClickToFlash-1.1.zip)
	* [NEW] Tasteful "Flash" icon now drawn on top of the gradient to make it more clear that it's blocked Flash content. ([Ricky Romero, Justin Williams](http://rentzsch.lighthouseapp.com/projects/24342/tickets/3-flash-boxes-are-not-always-obvious))
	* [NEW] Contextual menu and simple whitelist editor. ([Dave Dribin](http://github.com/ddribin/clicktoflash))
	* [NEW] Show the Flash box's source as a tooltip. ([Jason Foreman](http://github.com/threeve/clicktoflash/commit/a54c97c7be43e0adfbb0aad317c6020666d2a2e3))
	* [NEW] Rakefile to compile & upgrade the plugin by running 'rake' in the directory. ([Ale Muñoz](http://github.com/bomberstudios/clicktoflash/commit/2807f05aafe829e942f0c945ab914c0830652f73))
	* [DEV] Clean-up. Nonatomic properties, remove unused methods, `unsigned` => `NSUInteger`. (Jim Correia)
	* [DEV] Change CFBundleIdentifier from com.google.code.p.clicktoflash to com.github.rentzsch.clicktoflash.
* *original Google code project deleted. This fork takes on official-ish mantle.*
* **1.0+rentzsch** [download](http://s3.amazonaws.com/rentzsch/ClickToFlash%2Brentzsch-1.0.zip)
	* Forked from original Google code project (Jonathan 'Wolf' Rentzsch)
	* [NEW] Site whitelisting by holding down option key when clicking a flash box. (Gus Mueller)
	* [FIX] Use `-[NSEvent modifierFlags]` instead of Carbon's `GetCurrentKeyModifiers()`. (Chris Parker)
	* [DEV] Store white-listed sites in an array instead of composite keys. ([Jean-Francois Roy](https://twitter.com/jfroy/status/1150564777))
* **1.0** original Google Code release
