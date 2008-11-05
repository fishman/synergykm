#import "MenuCracker.h"
#import <objc/objc-class.h>
#import <unistd.h>

#define kMenuExtraBundle @"MenuCracker.menu"
#define kMenuCrackerIdentifier @"net.sourceforge.menucracker2"
#define kOldMenuCrackerIdentifier @"net.sourceforge.menucracker"
#define kAppleCrackerIdentifier @"com.apple.menuextra.enable"
#define kCPUExtraIdentifier @"com.apple.menuextra.CPU"
#define kOldMenuCrackerClass @"MenuCracker"
#define kAppleCrackerClass @"Enabler"

#define MCDEBUG 0

@implementation MenuCracker2

extern NSString *_MenuCrackerBundlePath;

NSString *_MenuCrackerBundlePath = nil;

static void ensureIAmLastInTheList(NSArray *previousCrackerPaths)
{
    NSArray *menuExtras;
    NSMutableArray *newExtras = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults synchronize];
    menuExtras = [defaults arrayForKey:@"menuExtras"];

    if (MCDEBUG) NSLog(@"ensureIAmLastInTheList menuExtras:%@ crackers:%@", menuExtras, previousCrackerPaths);

    if (menuExtras) {
        // We need to remove from the list anything that look like our cracker.
        // Most likely, our cracker will not be there unless we are installing over an existing install.
        int cc;
        newExtras = [[menuExtras mutableCopy] autorelease];
        for (cc = [newExtras count]-1; cc >= 0; cc--) {
            NSString *currentPath = [newExtras objectAtIndex:cc];

            if ([currentPath hasSuffix:kMenuExtraBundle]) {
                // If it is named properly, this is our crack
                [newExtras removeObjectAtIndex:cc];
               
			// ABH Panther (10.3) SystemUIServer uses ~/ paths for extras located relative to user's home
            } else if (![[NSFileManager defaultManager] fileExistsAtPath:[currentPath stringByExpandingTildeInPath]]) {
                // I'm overstepping a little here, but if there is nothing on disk at the indicated path, I guess I can remove it from the prefs.
                [newExtras removeObjectAtIndex:cc];
                
            } else {
                NSBundle *currentBundle = [NSBundle bundleWithPath:currentPath];
                if ([[currentBundle bundleIdentifier] isEqualToString:kAppleCrackerIdentifier]) {
					// Remove the Apple cracker where possible
                    [newExtras removeObjectAtIndex:cc];
                }
                if ([[currentBundle bundleIdentifier] isEqualToString:kMenuCrackerIdentifier] || 
						[[currentBundle bundleIdentifier] isEqualToString:kOldMenuCrackerIdentifier]) {
                    // the dumb user renamed our crack. What was he thinking?
                    [newExtras removeObjectAtIndex:cc];
                }
            }
        }
    } else {
        newExtras = [NSMutableArray arrayWithObjects:
            @"/System/Library/CoreServices/Menu Extras/AirPort.menu",
            @"/System/Library/CoreServices/Menu Extras/Volume.menu",
            nil];
    }

    [newExtras addObjectsFromArray:previousCrackerPaths];

    [defaults setObject:newExtras forKey:@"menuExtras"];
    [defaults synchronize];

    if (MCDEBUG) NSLog(@"ensureIAmLastInTheList wrote:%@", newExtras);
}

static int sortByBundleVersion( id path1, id path2, void *context) {
    float v1, v2;

    v1 = [[[[NSBundle bundleWithPath:path1] infoDictionary] objectForKey:@"CFBundleVersion"] floatValue];
    v2 = [[[[NSBundle bundleWithPath:path2] infoDictionary] objectForKey:@"CFBundleVersion"] floatValue];

    if( v1 < v2 )
        return NSOrderedAscending;
    else if( v1 > v2 )
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

static NSArray *buildListOfMenuCrackerPaths(NSString *extraPath) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *results = [NSMutableArray array];
    NSArray *menuExtras;
    unsigned ii, cc;

    if (MCDEBUG) NSLog(@"buildListOfMenuCrackerPaths()");
	
	// Append the extra path to the list
	if (extraPath) {
		[results addObject:extraPath];
	}

    [defaults synchronize];
    menuExtras = [defaults arrayForKey:@"menuExtras"];
    for (ii = 0, cc = [menuExtras count]; ii < cc; ii++) {
        NSString *currentPath = [menuExtras objectAtIndex:ii];

        // First check that the file exists, there is no need to save information about a deleted cracker
        if (![currentPath isEqual:_MenuCrackerBundlePath] && 
				[[NSFileManager defaultManager] fileExistsAtPath:[currentPath stringByExpandingTildeInPath]]) {
            NSBundle *currentBundle = [NSBundle bundleWithPath:currentPath];

            // Is it our cracker?
            if ([[currentBundle bundleIdentifier] isEqualToString:kMenuCrackerIdentifier] ||
					[[currentBundle bundleIdentifier] isEqualToString:kOldMenuCrackerIdentifier]) {
				// Dedupe the list
				if (![results containsObject:currentPath]) {
					[results addObject:currentPath];
				}
            }
        }
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:[_MenuCrackerBundlePath stringByExpandingTildeInPath]] && 
			![results containsObject:_MenuCrackerBundlePath]) {
        [results addObject:_MenuCrackerBundlePath];
    }

    // sort found menu crackers by version (latest one becomes the last in list)
    [results sortUsingFunction:sortByBundleVersion context:nil];

    if (MCDEBUG) NSLog(@"\tFound the following valid paths:%@", results);

    if (![results count]) {
        NSLog(@"MenuCracker Warning: MenuCracker can't find itself. Please reinstall menucracker before loging out or it will be unable to reload your third-party menu extras.");
    }
    return results;
}

static IMP _originalCreateMenuExtra = NULL;
static IMP _originalLoadClass = NULL;
static IMP _originalWriteDefaults = NULL;

static id fixUpMenuExtraLoad(id self, SEL _cmd, id extrabundle, int position, char unknown1, void *unknown2)
{	
	// Block Enable.menu
	if ([[extrabundle bundleIdentifier] isEqualToString:kAppleCrackerIdentifier]) {
		NSLog(@"MenuCracker: Blocked load of conflicting enabler '%@'.\n", [extrabundle bundleIdentifier]);
		return nil;
	}
	// Force the CPU extra bundle to load, redefining CPUExtra class and allowing it to load properly
	if ([[extrabundle bundleIdentifier] isEqualToString:kCPUExtraIdentifier]) {
		[extrabundle load];
	}
	// Block older crackers from loading, but write them out just in case the user uninstalls this bundle
	// and some other app has an older copy and is still expecting it to load (consistent with 1.3 behavior)
	if ([[extrabundle bundleIdentifier] isEqualToString:kOldMenuCrackerIdentifier]) {
		NSLog(@"MenuCracker: Blocked load of MenuCracker 1.3 or earlier.\n");
		ensureIAmLastInTheList(buildListOfMenuCrackerPaths([extrabundle bundlePath]));
		return nil;
	}
	
	return (id)(*_originalCreateMenuExtra)(self, _cmd, extrabundle, position, unknown1, unknown2);
}

static BOOL justSayYESIWantToLoadClass(id self, SEL _cmd, id className)
{
    if (!(int)(*_originalLoadClass)(self, _cmd, className)) {
       NSLog(@"MenuCracker: Loading '%@'.", className);
    }
    return YES;
}

static void hackWriteAsWellWhileWeAreAtIt(id self, SEL _cmd, id stuff) {
    NSArray *previousCrackerPaths;

    if (MCDEBUG) NSLog(@"hackWriteAsWellWhileWeAreAtIt()");

    previousCrackerPaths = buildListOfMenuCrackerPaths(nil);

    (*_originalWriteDefaults)(self, _cmd, stuff);
    
    ensureIAmLastInTheList(previousCrackerPaths);
}

extern void _objc_flush_caches(Class cls);

static void freeTheUserToLoadAnyMenulingTheyWant()
{
    Class cls;
    Method method;

    if (MCDEBUG) NSLog(@"freeTheUserToLoadAnyMenulingTheyWant()");

    // Find the class
    cls = NSClassFromString(@"SUISStartupObject");
    if (nil == cls) {
        NSLog(@"MenuCracker: can't find SUISStartupObject.  This crack is now useless.");
        return;
    }
	
	// Replace the create extra, allows us to block undesirables from loading
	method = class_getInstanceMethod(cls, @selector(createMenuExtra:atPosition:write:data:));
	if (!method) {
        NSLog(@"MenuCracker: can't find -createMenuExtra:.  This crack is now useless.");
        return;
	}
	_originalCreateMenuExtra = method->method_imp;
	method->method_imp = (IMP)fixUpMenuExtraLoad;
	
    // Replace the security model, all hinged on the method -_canLoadClass:
    method = class_getInstanceMethod(cls, @selector(_canLoadClass:));
    if (!method) {
        NSLog(@"MenuCracker: can't find -_canLoadClass:.  This crack is now useless.");
        return;
    }
	_originalLoadClass = method->method_imp;
    method->method_imp = (IMP)justSayYESIWantToLoadClass;

    // Make sure we are saved at the right place
    method = class_getInstanceMethod(cls, @selector(writeMenuBarPlugins:));
    if (!method) {
        NSLog(@"MenuCracker: can't find -writeMenuBarPlugins:.  This crack is now useless.");
        return;
    }
	_originalWriteDefaults = method->method_imp;
    method->method_imp = (IMP)hackWriteAsWellWhileWeAreAtIt;
	
    // Flush the ObjectiveC caches
    _objc_flush_caches(cls);

    // Say it's me!
    NSLog(@"\n    MenuCracker"
          @"\n    see http://sourceforge.net/projects/menucracker"
          @"\n    MenuCracker is now loaded. Ready to accept new menus. Ignore the failure message that follow.");
}

static BOOL _firstTimeEver = YES;

- (id)initWithBundle:(NSBundle *)bundle
{
    NSString *versionString;
    float version;
	NSString *restartFilePath = [NSString stringWithFormat:@"/tmp/net.sf.menucracker-restartcheck-%d", getuid()];
	NSFileManager *fileMan = [NSFileManager defaultManager];
    
    [super init];
	
	if (MCDEBUG) NSLog(@"-[%@ %s%@]", NSStringFromClass([self class]), _cmd, bundle);

    // examine SystemUIServer's version number
	versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    version = [versionString floatValue];

    if (MCDEBUG) NSLog(@"SystemUIServer's version: %@ (0x%.8x)", versionString, version);

    if( version < 1.1 ) {
        if (MCDEBUG) NSLog(@"MenuCracker makes only sense on Mac OS X v10.2\n");
        return nil;
    }
        
    if (_firstTimeEver) {
        _firstTimeEver = NO;

		freeTheUserToLoadAnyMenulingTheyWant();
    }

    if (!_MenuCrackerBundlePath || ![_MenuCrackerBundlePath isEqual:[bundle bundlePath]]) {
        if (MCDEBUG) NSLog(@"\tOld _MenuCrackerBundlePath:%@", _MenuCrackerBundlePath);
        [_MenuCrackerBundlePath release];
        _MenuCrackerBundlePath = [[bundle bundlePath] copy];
        if (MCDEBUG) NSLog(@"\tnew _MenuCrackerBundlePath:%@", _MenuCrackerBundlePath);

        ensureIAmLastInTheList(buildListOfMenuCrackerPaths(nil));
    }
	[self release];
	
	// Force a SystemUIServer restart if a conflicting object is found

	if (MCDEBUG) NSLog(@"%@ -- %@", NSClassFromString(kAppleCrackerClass) , NSClassFromString(kOldMenuCrackerClass));
	if (NSClassFromString(kAppleCrackerClass) || NSClassFromString(kOldMenuCrackerClass)) {
		if (![fileMan fileExistsAtPath:restartFilePath]) {
			// First time this has happened
			NSLog(@"MenuCracker detected conflicting enabler, restart SystemUIServer.\n");
			if (![fileMan createFileAtPath:restartFilePath contents:nil attributes:nil]) {
				NSLog(@"MenuCracker error: Unable to create restart check file.\n");
			}
			[NSApp terminate:nil];
		}
		else {
			NSLog(@"MenuCracker detected conflicting enabler but has already attempted restart. Abort restart.\n");
		}
	}
	
	// Clean up restart file
	if ([fileMan fileExistsAtPath:restartFilePath]) {
		if (![fileMan removeFileAtPath:restartFilePath handler:nil]) {
			NSLog(@"MenuCracker error: Unable to clean up restart check file.\n");
		}
	}
	
    return nil;
}

@end

@implementation CPUExtra
@end
