# Make rules
#
# (c) 2022 DMSC
# Code under MIT license, see LICENSE file.
#

# Detect target Windows OS and set target file extensions:
ifeq ($(strip $(shell echo '_WIN32' | $(CROSS)$(CXX) -E - | grep  "_WIN32")),_WIN32)
    # Linux / OS-X
    PRG_EXT=
else
    # Windows:
    PRG_EXT=.exe
endif

BUILD_PRG=$(PROGRAMS:%=$(BUILD)/%$(PRG_EXT))
.PHONY: all clean
all: $(BUILD_PRG)

define PROGRAM_template =
 OBJS_$(1) = $$(SRC_$(1):src/%.c=$$(BUILD)/obj/%.o)
 OBJS_ALL += $$(OBJS_$(1))
 $$(BUILD)/$(1)$(PRG_EXT): $$(OBJS_$(1))
endef

$(foreach prog,$(PROGRAMS),$(eval $(call PROGRAM_template,$(prog))))

dist: $(BUILD)/$(ZIPFILE)

$(BUILD)/$(ZIPFILE): $(BUILD_PRG) README.md LICENSE LICENSE.zx0 | build
	$(CROSS)strip $(BUILD_PRG)
	rm -f $@
	zip -9j $@ $^

clean:
	rm -f $(OBJS_ALL)

$(BUILD_PRG):
	$(CROSS)$(CC) $(CFLAGS) -o $@ $^

$(BUILD)/obj/%.o: src/%.c | $(BUILD) $(BUILD)/obj
	$(CROSS)$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD) $(BUILD)/obj:
	mkdir -p $@

# Automatic generation of dependency information
$(BUILD)/obj/%.d: src/%.c | $(BUILD) $(BUILD)/obj
	$(CROSS)$(CC) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(CFLAGS) $<


ifneq "$(MAKECMDGOALS)" "clean"
    -include $(OBJS_ALL:%.o=%.d)
endif
