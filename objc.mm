#include <napi.h>
#include <stdio.h>
#include <string.h>
#import <AppKit/AppKit.h>

static Napi::Value MessWithWindow(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();

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
NSLog(@"window style mask= %i, want %i", win.styleMask, NSBorderlessWindowMask);
//  win.backgroundColor = [NSColor clearColor];
//NSLog(@"window2 = %@", view.superview.window);

  return info.Env().Undefined();
}

static Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports["MessWithWindow"] = Napi::Function::New(env, MessWithWindow);
  return exports;
}

NODE_API_MODULE(NODE_GYP_MODULE_NAME, Init)
