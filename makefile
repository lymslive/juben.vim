.PHONY: all help stats html

all: stats html

help:
	@echo make stats 生成统计信息
	@echo make html  生成剧本网页

stats: stats.md

stats.md: main.md
	vim -E -s -c "source .vim/stats.vim" -cxall main.md

html: main.html

main.html: main.md .vim/tohtml.vim .vim/juben.html
	vim -E -s -c "source .vim/tohtml.vim" -cxall main.md
