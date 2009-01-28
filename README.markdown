#Slighty-Enhanced version of ClickToFlash

Takes the [ClickToFlash](http://code.google.com/p/clicktoflash/) 1.0 source, and mixes-in:

* [Gus's patch](http://code.google.com/p/clicktoflash/issues/detail?id=10) that adds site-whitelisting by holding the option key when clicking a flash box

* Chris Parker's suggestion of using `-[NSEvent modifierFlags]` instead of Carbon's `GetCurrentKeyModifiers()`

* [Jean-Francois Roy's suggestion](https://twitter.com/jfroy/status/1150564777) that the hosts be stored in an array.

* Ricky Romero's overlay icon

You can [download the binary installer here](http://s3.amazonaws.com/rentzsch/ClickToFlash%2Brentzsch-1.0.zip) (60KB .zip).