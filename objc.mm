#include <napi.h>
#include <stdio.h>
#include <string.h>
#import <AppKit/AppKit.h>

#include <objc/runtime.h>
#include <objc/message.h>

// simple shim to conditionally disable setIgnoresMouseEvents so that it doesn't
// destroy our transparent window click-thru-ability (CV-401)
static void (*oldSetIgnoresMouseEvents)(id, SEL, BOOL);

// See the comment on this answer that says NSWindow.ignoresMouseEvents has THREE states
//   https://stackoverflow.com/a/29451199/22147
//    1. ignoresMouseEvents on transparent areas (the initial state)
//    2. ignores all events (YES)
//    3. does not ignore any events (NO)
// The first state is what we want for the camera bubble, and once setIgnoresMouseEvents
// has been called, you can never return to the initial state, so we turn calls to 
// setIgnoreMouseEvents into a no-op using a monkey patch.
static void setIgnoresMouseEvents(id self, SEL _cmd, BOOL ignores) {
  NSLog(@"setIgnoresMouseEvents: %@ - %@ to %i", self, NSStringFromRect([self frame]), ignores);

  // TODO: don't call on all windows.
  if (0) oldSetIgnoresMouseEvents(self, _cmd, ignores);
}

// as an addon, this is called at require('bindings')('yourAddOn') time
// this is early enough in test app.
// which means this could equally be called by Init() without constructor magic
__attribute__((constructor))
static void swizzle() {
  fprintf(stderr, "Swizzling NSWindow\n");
    id cls = objc_getClass("NSWindow");
    oldSetIgnoresMouseEvents = (void(*)(id,SEL,BOOL))method_setImplementation(class_getInstanceMethod(cls, @selector(setIgnoresMouseEvents:)), (IMP)setIgnoresMouseEvents);
    if (!oldSetIgnoresMouseEvents) fprintf(stderr, "[!] WARNING: NSButtonCell swizzle failed\n");
}

static Napi::Value MessWithWindow(const Napi::CallbackInfo& info) {

  Napi::Env env = info.Env();
NSLog(@"GOT CALLED BYE");
return env.Undefined();

  if (info.Length() != 1) {
    Napi::Error::New(env, "Wrong number of arguments. Expected: (viewHandle)")
        .ThrowAsJavaScriptException();
    return env.Undefined();
  }

  if (!info[0].IsBuffer()) {
     Napi::TypeError::New(env, "First argument must be a Buffer").ThrowAsJavaScriptException();
     return env.Undefined();
  }

  NSView* view = nil;
  if (info[0].As<Napi::Buffer<uint8_t>>().Length() != sizeof(view)) {
    Napi::TypeError::New(env, "Buffer must contain correct pointer size").ThrowAsJavaScriptException();
    return env.Null();
  }

  Napi::Buffer<uint8_t> bytes = info[0].As<Napi::Buffer<uint8_t>>();
//pretty sure this is an NSView, but why doesn't subtreeDescription work?

  view = *reinterpret_cast<NSView**>(bytes.Data());


  printf("raw pointer %p\n", view);
  NSLog(@"as objc: %@", view);
NSLog(@"super view: %@", view.superview);
NSLog(@"super super view: %@", view.superview.superview);
  //NSLog(@"hierarchy : %@", [view.superview _subtreeDescription]);

  //NSLog(@"BG colour %@", view.backgroundColor); // nil on 6
  NSLog(@"clear colour %@", [NSColor clearColor]);
//  NSLog(@"Can become key %i", [view canBecomeKey]);
  NSLog(@"aaa %@", [[view class] debugDescription]);
if (1) {
  NSLog(@"Subclass of NSView: %i", [view.class isSubclassOfClass:[NSView class]]);
  NSLog(@"Subclass of NSWindow: %i", [view.class isSubclassOfClass:[NSWindow class]]);
}
  //NSLog(@"wantsLayer %i", view.wantsLayer);
  //view.backgroundColor = [NSColor blueColor]; // works!
  //view.superview.backgroundColor = [NSColor blueColor];
  //view.superview.backgroundColor = [NSColor clearColor];
  NSWindow *win = view.window;
NSLog(@"window = %@", win);
NSLog(@"window bg colour = %@", win.backgroundColor);
NSLog(@"window style mask= %lu, want %lu", win.styleMask, NSBorderlessWindowMask);
NSLog(@"opaque: %i", win.opaque);
win.ignoresMouseEvents = YES;
NSLog(@"ignoresMouseEvents: %i", win.ignoresMouseEvents);
NSLog(@"canBecomeKeyWindow: %i", win.canBecomeKeyWindow);

//  win.backgroundColor = [NSColor clearColor];
//NSLog(@"window2 = %@", view.superview.window);

  return info.Env().Undefined();
}

static Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports["MessWithWindow"] = Napi::Function::New(env, MessWithWindow);
  return exports;
}

NODE_API_MODULE(NODE_GYP_MODULE_NAME, Init)
