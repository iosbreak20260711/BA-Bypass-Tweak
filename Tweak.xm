#import <dlfcn.h>
#import <string.h>
#import <mach-o/dyld.h>
#include "fishhook.h"

// 要隱藏的動態庫名稱關鍵字（可根據需求修改）
static const char *kHideKeyword = "hack.dylib";

// 偽裝用的系統庫路徑與 header（在初始化時取得）
static const char *kFakeImageName = NULL;
static const struct mach_header *kFakeImageHeader = NULL;

// 保存原始函數指針
static const char *(*orig_dyld_get_image_name)(uint32_t image_index);
static const struct mach_header *(*orig_dyld_get_image_header)(uint32_t image_index);

// 自訂 Hook 函數：過濾含有關鍵字的 image 名稱
static const char *my_dyld_get_image_name(uint32_t image_index) {
    const char *realName = orig_dyld_get_image_name(image_index);
    if (realName && strstr(realName, kHideKeyword)) {
        // 命中關鍵字，回傳偽裝的系統庫路徑
        return kFakeImageName;
    }
    return realName;
}

// 自訂 Hook 函數：當名稱被偽裝時，一併回傳對應的 mach_header
static const struct mach_header *my_dyld_get_image_header(uint32_t image_index) {
    // 透過原始函數取得真實名稱來判斷是否要隱藏
    const char *realName = orig_dyld_get_image_name(image_index);
    if (realName && strstr(realName, kHideKeyword)) {
        return kFakeImageHeader;
    }
    return orig_dyld_get_image_header(image_index);
}

// 安全取得 UIKit 的 header（作為偽裝目標）
static void setupFakeImageInfo(void) {
    // 方法 1：直接 dlopen UIKit（dyld 會回傳 mach_header 位址）
    void *handle = dlopen("/System/Library/Frameworks/UIKit.framework/UIKit", RTLD_LAZY);
    if (handle) {
        kFakeImageName = "/System/Library/Frameworks/UIKit.framework/UIKit";
        kFakeImageHeader = (const struct mach_header *)handle;
        return;
    }

    // 方法 2：遍歷所有 image 尋找 UIKit（備用方案）
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "UIKit.framework/UIKit")) {
            kFakeImageName = name;
            kFakeImageHeader = _dyld_get_image_header(i);
            return;
        }
    }

    // 若都找不到，則降級使用 dyld_shared_cache 中的第一個庫（極端備用）
    kFakeImageName = "/usr/lib/libSystem.B.dylib";
    kFakeImageHeader = _dyld_get_image_header(0);
}

%ctor {
    // 1. 在 Hook 前先取得真實函數位址
    orig_dyld_get_image_name = (const char *(*)(uint32_t))dlsym(RTLD_DEFAULT, "_dyld_get_image_name");
    orig_dyld_get_image_header = (const struct mach_header *(*)(uint32_t))dlsym(RTLD_DEFAULT, "_dyld_get_image_header");

    // 2. 準備偽裝用的 image 資訊
    setupFakeImageInfo();

    // 3. 使用 fishhook 進行符號重定
    struct rebinding rebindings[] = {
        {"_dyld_get_image_name", (void *)my_dyld_get_image_name, (void **)&orig_dyld_get_image_name},
        {"_dyld_get_image_header", (void *)my_dyld_get_image_header, (void **)&orig_dyld_get_image_header}
    };
    rebind_symbols(rebindings, sizeof(rebindings) / sizeof(struct rebinding));
}
