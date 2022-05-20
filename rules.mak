# Make rules
#
# (c) 2022 DMSC
# Code under MIT license, see LICENSE file.
#

BUILD_PRG=$(PROGRAMS:%=$(BUILD)/%)
.PHONY: all clean
all: $(BUILD_PRG)

define PROGRAM_template =
 OBJS_$(1) = $$(SRC_$(1):src/%.c=$$(BUILD)/obj/%.o)
 OBJS_ALL += $$(OBJS_$(1))
 $$(BUILD)/$(1): $$(OBJS_$(1))
endef

$(foreach prog,$(PROGRAMS),$(eval $(call PROGRAM_template,$(prog))))


clean:
	rm -f $(OBJS_ALL)

$(BUILD_PRG):
	$(CC) $(CFLAGS) -o $@ $^

$(BUILD)/obj/%.o: src/%.c | $(BUILD) $(BUILD)/obj
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD) $(BUILD)/obj:
	mkdir -p $@

# Automatic generation of dependency information
$(BUILD)/obj/%.d: src/%.c | $(BUILD) $(BUILD)/obj
	$(CC) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(CFLAGS) $<


ifneq "$(MAKECMDGOALS)" "clean"
    -include $(OBJS_ALL:%.o=%.d)
endif
