/*

The MIT License

Copyright (c) 2008-2009 ClickToFlash Developers

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/


#ifndef NSAppKitVersionNumber10_5
#define NSAppKitVersionNumber10_5 949
#endif


    // Simple ForEach macro to make life easier on those porting to Tiger
    // than using Leopard's fast enumeration and "in" keyword:
#define CTFForEachObject( Type, varName, container ) \
    NSEnumerator* feoEnum_##__LINE__ = [ container objectEnumerator ]; \
    Type* varName; \
    while( ( varName = [ feoEnum_##__LINE__ nextObject ] ) )


    // Load our localised strings from the correct bundle [use genstrings -s CtFLocalizedString]
#define CtFLocalizedString(key, explanation) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:(nil)]
