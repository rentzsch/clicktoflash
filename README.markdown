#Slighty-Enhanced version of ClickToFlash

Takes the [ClickToFlash](http://code.google.com/p/clicktoflash/) 1.0 source, mixes-in [Gus's patch](http://code.google.com/p/clicktoflash/issues/detail?id=10) that adds site-whitelisting by holding the option key when clicking a flash box, along with Chris Parker's suggestion of using `-[NSEvent modifierFlags]` instead of Carbon's `GetCurrentKeyModifiers()` and [Jean-Francois Roy's suggestion that the hosts be stored in an array](https://twitter.com/jfroy/status/1150564777).

You can [download the binary installer here](http://s3.amazonaws.com/rentzsch/ClickToFlash+wolf.zip) (60KB .zip).