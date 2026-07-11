# 目標設定：產生動態庫（非越獄使用）
TARGET := iphone:clang:latest:8.0
ARCHS := arm64 arm64e

# 專案名稱（生成的 dylib 檔案名，可自定義）
PROJECT_NAME := HideDylib

# 原始檔（Tweak.xm + fishhook.c 需在同一目錄下）
HideDylib_FILES := Tweak.xm fishhook.c

# 需鏈接的系統框架（fishhook 需 Foundation？實際上 fishhook 不依賴 Foundation，但保留無妨）
HideDylib_FRAMEWORKS := Foundation

# 如果是 MonkeyDev 或手動注入，不需要額外安裝腳本
# 以下設定僅用於編譯階段
include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/library.mk

# 若 fishhook 是以靜態庫提供，可改用下面的方式（將 fishhook.c 加入 FILES 則無需 LIBRARY）
# HideDylib_LIBRARIES := fishhook
