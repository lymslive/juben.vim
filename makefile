VIMDIR ?= juben.vim
STATS = $(VIMDIR)/stats.vim
TOHTML = $(VIMDIR)tohtml
HTML_DEP = $(TOHTML) $(VIMDIR)/juben.html

.PHONY: all help stats html

all: stats html

help:
	@echo make stats 生成统计信息
	@echo make html  生成剧本网页

stats: stats.md

stats.md: main.md $(STATS)
	vim -E -s -c "source $(STATS)" -cxall main.md

html: main.html

main.html: main.md $(HTML_DEP)
	vim -E -s -c "source $(TOHTML)" -cxall main.md
