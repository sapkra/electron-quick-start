#include <napi.h>
#include <stdio.h>
#include <string.h>
#import <AppKit/AppKit.h>

static Napi::Value MessWithWindow(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();

  if (info.Length() != 1) {
    Napi::Error::New(env, "Wrong number of arguments. Expected: (windowHandle)")
        .ThrowAsJavaScriptException();
    return env.Undefined();
  }

  if (!info[0].IsBuffer()) {
     Napi::TypeError::New(env, "First argument must be a Buffer").ThrowAsJavaScriptException();
     return env.Undefined();
  }

  NSWindow* window = nil;
  if (info[0].As<Napi::Buffer<uint8_t>>().Length() != sizeof(window)) {
    Napi::TypeError::New(env, "Buffer must contain correct pointer size").ThrowAsJavaScriptException();
    return env.Null();
  }

  Napi::Buffer<uint8_t> bytes = info[0].As<Napi::Buffer<uint8_t>>();

  window = *reinterpret_cast<NSWindow**>(bytes.Data());


  printf("raw pointer %p\n", window);
  NSLog(@"as objc: %@", window);
  NSLog(@"hierarchy : %@", [window _subtreeDescription]);

  NSLog(@"BG colour %@", window.backgroundColor); // nil on 6
  NSLog(@"clear colour %@", [NSColor clearColor]);
  //NSLog(@"wantsLayer %i", window.wantsLayer);
  //window.backgroundColor = [NSColor blueColor]; // works!
  // window.backgroundColor = [NSColor clearColor];

  return info.Env().Undefined();
}

static Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports["MessWithWindow"] = Napi::Function::New(env, MessWithWindow);
  return exports;
}

NODE_API_MODULE(NODE_GYP_MODULE_NAME, Init)
