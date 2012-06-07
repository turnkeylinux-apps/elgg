COMMON_CONF = apache-credit

CREDIT_LOCATION = ~ "^/(?!(.*mod/tinymce))"

include $(FAB_PATH)/common/mk/turnkey/lamp.mk
include $(FAB_PATH)/common/mk/turnkey.mk
