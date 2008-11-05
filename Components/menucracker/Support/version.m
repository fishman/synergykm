/**
** This file is part of Spy.
 **
 ** The author wishes to stay anonymous, but can be
 ** contacted at the email address <james_007_bond@mac.com>
 **
 **/
#include <Foundation/Foundation.h>

int main (int argc, char *argv[]) {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSString *path;
    NSBundle *bundle;
    NSString *version;
    
    if (argc != 2) {
        printf("Get lost, give me a path!\n");
        exit(-1);
    }

    path = [NSString stringWithUTF8String:argv[1]];

    bundle = [NSBundle bundleWithPath:path];

    version = [[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];

    if (version) {
        printf("%s\n",[version UTF8String]);
    } else {
        printf("0.0\n");
    }

    [pool release];
    exit(0);
    return 0;
}
