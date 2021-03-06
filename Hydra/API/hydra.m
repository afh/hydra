#import "helpers.h"
void PHShowAlert(NSString* oneLineMsg, CGFloat duration);

/// hydra
///
/// General stuff.

static int hydra_exit(lua_State* L) {
    if (lua_isboolean(L, 2) && lua_toboolean(L, 2))
        lua_close(L);
    
    [[NSApplication sharedApplication] terminate: nil];
    return 0; // lol
}

/// hydra.showabout()
/// Displays the standard OS X about panel; implicitly focuses Hydra.
static int hydra_showabout(lua_State* L) {
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:nil];
    return 0;
}

/// hydra.focushydra()
/// Makes Hydra the currently focused app; useful in combination with textgrids.
static int hydra_focushydra(lua_State* L) {
    [NSApp activateIgnoringOtherApps:YES];
    return 0;
}

/// hydra.alert(str, seconds = 2)
/// Shows a message in large words briefly in the middle of the screen; does tostring() on its argument for convenience..
static int hydra_alert(lua_State* L) {
    lua_settop(L, 2);
    NSString* str = [NSString stringWithUTF8String: luaL_tolstring(L, 1, NULL)];
    
    double duration = 2.0;
    if (lua_isnumber(L, 2))
        duration = lua_tonumber(L, 2);
    
    PHShowAlert(str, duration);
    
    return 0;
}

/// hydra.fileexists(path) -> exists, isdir
/// Checks if a file exists, and whether it's a directory.
static int hydra_fileexists(lua_State* L) {
    NSString* path = [NSString stringWithUTF8String:luaL_checkstring(L, 1)];
    
    BOOL isdir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isdir];
    
    lua_pushboolean(L, exists);
    lua_pushboolean(L, isdir);
    return 2;
}

/// hydra.check_accessibility(shouldprompt) -> isenabled
/// Returns whether accessibility is enabled. If passed `true`, prompts the user to enable it.
extern Boolean AXIsProcessTrustedWithOptions(CFDictionaryRef options) __attribute__((weak_import));
extern CFStringRef kAXTrustedCheckOptionPrompt __attribute__((weak_import));

static int hydra_check_accessibility(lua_State* L) {
    BOOL shouldprompt = lua_toboolean(L, 1);
    BOOL enabled;
    
    if (AXIsProcessTrustedWithOptions != NULL) {
        NSDictionary* opts = @{(__bridge id)kAXTrustedCheckOptionPrompt: @(shouldprompt)};
        enabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)opts);
    }
    else {
        enabled = AXAPIEnabled();
        
        if (shouldprompt) {
            NSString* src = @"tell application \"System Preferences\"\nactivate\nset current pane to pane \"com.apple.preference.universalaccess\"\nend tell";
            NSAppleScript *a = [[NSAppleScript alloc] initWithSource:src];
            [a executeAndReturnError:nil];
        }
    }
    
    lua_pushboolean(L, enabled);
    return 1;
}

/// hydra.indock() -> bool
/// Returns whether Hydra has a Dock icon, and thus can be switched to via Cmd-Tab.
static int hydra_indock(lua_State* L) {
    BOOL indock = [[NSApplication sharedApplication] activationPolicy] == NSApplicationActivationPolicyRegular;
    lua_pushboolean(L, indock);
    return 1;
}

/// hydra.putindock(bool)
/// Sets whether Hydra has a Dock icon, and thus can be switched to via Cmd-Tab.
static int hydra_putindock(lua_State* L) {
    BOOL indock = lua_toboolean(L, 1);
    NSApplicationActivationPolicy policy = indock ? NSApplicationActivationPolicyRegular : NSApplicationActivationPolicyAccessory;
    [[NSApplication sharedApplication] setActivationPolicy: policy];
    if (!indock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSApplication sharedApplication] unhide:nil];
        });
    }
    return 0;
}

/// hydra.setosxshadows(bool)
/// Sets whether OSX apps have shadows.
static int hydra_setosxshadows(lua_State* L) {
    BOOL on = lua_toboolean(L, 1);
    
    typedef enum _CGSDebugOptions {
        kCGSDebugOptionNone = 0,
        kCGSDebugOptionNoShadows = 0x4000
    } CGSDebugOptions;
    
    extern void CGSGetDebugOptions(CGSDebugOptions *options);
    extern void CGSSetDebugOptions(CGSDebugOptions options);
    
    CGSDebugOptions options;
    CGSGetDebugOptions(&options);
    options = on ? options & ~kCGSDebugOptionNoShadows : options | kCGSDebugOptionNoShadows;
    CGSSetDebugOptions(options);
    
    return 0;
}

static const luaL_Reg hydralib[] = {
    {"exit", hydra_exit},
    {"showabout", hydra_showabout},
    {"focushydra", hydra_focushydra},
    {"alert", hydra_alert},
    {"fileexists", hydra_fileexists},
    {"check_accessibility", hydra_check_accessibility},
    {"indock", hydra_indock},
    {"putindock", hydra_putindock},
    {"setosxshadows", hydra_setosxshadows},
    {NULL, NULL}
};

int luaopen_hydra(lua_State* L) {
    luaL_newlib(L, hydralib);
    
    lua_pushstring(L, [[[NSBundle mainBundle] resourcePath] fileSystemRepresentation]);
    lua_setfield(L, -2, "resourcesdir");
    
    return 1;
}
