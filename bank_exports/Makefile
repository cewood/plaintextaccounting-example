.PHONY: gen
gen:
	@$(foreach i, $(wildcard *.csv), make --no-print-directory $(word 1,$(subst ., ,$i)).bean;)

%.bean: %.csv
	csv2beancount \
	  convert \
	  --config $(word 1,$(subst _, ,$@)).yaml \
	  $(word 1,$(subst ., ,$@)).csv | bean-format > $@

.PHONY: diff
diff:
	csv2beancount \
	  convert \
	  --config $(patsubst %$(shell echo ${ARG} | grep -o "_.*.csv"),%.yaml,$(ARG)) \
	  ${ARG} | \
	  bean-format | \
	  diff --ignore-space-change \
	  $(basename ${ARG}).bean \
	  -
