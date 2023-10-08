#include <objc/objc-runtime.h>

int main(int argc, const char * argv[]) {
    id pool = ((id(*)(id, SEL))objc_msgSend)((id)objc_getClass("NSAutoreleasePool"), sel_registerName("alloc"));
    pool = ((id(*)(id, SEL))objc_msgSend)(pool, sel_registerName("init"));

    id app = ((id(*)(id, SEL))objc_msgSend)((id)objc_getClass("NSApplication"), sel_registerName("sharedApplication"));

    Class delegateClass = objc_getClass("AppDelegate");
    if (!delegateClass) {
        objc_registerClassPair(objc_allocateClassPair((Class)objc_getClass("NSObject"), "AppDelegate", 0));
    }

    id delegate = ((id(*)(id, SEL))objc_msgSend)((id)objc_getClass("AppDelegate"), sel_registerName("alloc"));
    delegate = ((id(*)(id, SEL))objc_msgSend)(delegate, sel_registerName("init"));
    ((void(*)(id, SEL, id))objc_msgSend)(app, sel_registerName("setDelegate:"), delegate);

    ((void(*)(id, SEL))objc_msgSend)(app, sel_registerName("run"));

    return 0;
}
