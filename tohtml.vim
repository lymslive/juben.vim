" 将剧本 markdown 生成 html

" 脚本所在目录
let s:dir = expand('<sfile>:p:h')

let s:class = {}

" 剧本格式 css 命名
let s:style = {}
" 总标题 h1
let s:style.title = 'title'
" 总信息 li
let s:style.signature = 'signature'
" 分节标题 h2
let s:style.section = 'section'
" 场景说明 li
let s:style.scene = 'scene'
" 行外描叙 p
let s:style.show = 'show'
" 人物台词 p
let s:style.line = 'line'
" 人物名 span
let s:style.role = 'role'
" 台词提示，行内描叙 span
let s:style.prompt = 'prompt'

" Func: s:new 
function! s:new() abort
    let l:obj = copy(s:class)
    " .state: 当前状态
    let l:obj.state = ''
    " 处理行号
    let l:obj.curline = 1
    let l:obj.maxline = line('$')
    let l:obj.title = '剧本标题'
    " 项目首页地址
    let l:obj.home = ''
    " 转化的 html 文本行
    let l:obj.html = []
    " 导航栏 html
    let l:obj.hnav = []
    let l:obj.template = s:dir . '/juben.html'
    return l:obj
endfunction 

" Method: run 
function! s:class.run() dict abort
    while self.curline <= self.maxline
        let l:sLine = getline(self.curline)
        let self.curline += 1
        if l:sLine =~# '^\s*$'
            continue
        elseif l:sLine =~# '^\s*#\s\+'
            call self.deal_title(l:sLine)
        elseif l:sLine =~# '^\s*##\s\+'
            call self.deal_section(l:sLine)
        elseif l:sLine =~# '^\s*\*\s*'
            call self.deal_list(l:sLine)
        elseif l:sLine =~# '^\s*（.\+'
            call self.deal_show(l:sLine)
        elseif l:sLine =~# '^\s*.\+：.\+'
            call self.deal_line(l:sLine)
        else
            call self.deal_paragraph(l:sLine)
        endif
    endwhile
    call self.post_run()
endfunction

" Method: deal_title 
" # 剧本总标题
function! s:class.deal_title(text) dict abort
    let l:sLine = a:text
    let l:lsMatch = matchlist(l:sLine, '^\s*#\s\+\(.\+\)\s*$')
    if len(l:lsMatch) <= 1
        return v:false
    endif
    let l:title = l:lsMatch[1]
    let l:html = printf('<h1 class="%s">%s</h1>', s:style.title, l:title)
    call add(self.html, l:html)
    let self.title = l:title
    let self.state = s:style.title
    return v:true
endfunction

" Method: deal_section 
" ## 1 【分节标题】
function! s:class.deal_section(text) dict abort
    let l:sLine = a:text
    let l:lsMatch = matchlist(l:sLine, '^\s*##\s\+\(.\+\)\s*$')
    if len(l:lsMatch) <= 1
        return v:false
    endif
    let l:section = l:lsMatch[1]
    let l:secNo = substitute(l:section, '^\d\+\zs\s*', '', '')
    if l:secNo =~# '^\d\+'
        let l:html = printf('<a name="s%d"></a>', l:secNo)
        call add(self.html, l:html)
    endif
    let l:html = printf('<h2 class="%s">%s</h2>', s:style.section, l:section)
    call add(self.html, l:html)
    if l:secNo =~# '^\d\+'
        let l:html = printf('<a href="#s%d">%d</a>', l:secNo, l:secNo)
        call add(self.hnav, l:html)
    endif
    let self.state = s:style.section
    return v:true
endfunction

" Method: deal_list 
function! s:class.deal_list(text) dict abort
    let l:style = ''
    if self.state == s:style.title
        let l:style = s:style.signature
    elseif self.state == s:style.section
        let l:style = s:style.scene
    endif

    let l:ul = printf('<ul class="%s">', l:style)
    call add(self.html, l:ul)
    let l:sLine = a:text
    while v:true
        if l:sLine !~# '^\s*\*\s*'
            break
        endif
        if empty(self.home)
            let l:home = matchstr(l:sLine, 'https\?://\S\+')
            if !empty(l:home)
                let self.home = l:home
            endif
        endif
        let l:sLine = substitute(l:sLine, '^\s*\*\s*', '', '')
        let l:sLine = substitute(l:sLine, '\s*\(https\?://\S\+\)', '<a href="\1">\1</a>', '')
        let l:html = printf('<li>%s</li>', l:sLine)
        call add(self.html, l:html)
        let l:sLine = getline(self.curline)
        let self.curline += 1
    endwhile
    call add(self.html, '</ul>')
endfunction

" Method: join_paragraph 
function! s:class.join_paragraph(text) dict abort
    let l:sLine = a:text
    let l:paragraph = ''
    while v:true
        if l:sLine =~# '^\s*$'
            break
        endif
        let l:paragraph .= l:sLine
        let l:sLine = getline(self.curline)
        let self.curline += 1
    endwhile
    return l:paragraph
endfunction

" Method: deal_paragraph 
" 普通段落
function! s:class.deal_paragraph(text) dict abort
    let l:paragraph = self.join_paragraph(a:text)
    call add(self.html, '<p>')
    call add(self.html, l:paragraph)
endfunction

" Method: deal_show 
" （行外描叙
function! s:class.deal_show(text) dict abort
    let l:paragraph = self.join_paragraph(a:text)
    let l:html = printf('<p class="%s">', s:style.show)
    call add(self.html, l:html)
    call add(self.html, l:paragraph)
endfunction

" Method: deal_line 
" 人物名；台词（行内描叙）台词
function! s:class.deal_line(text) dict abort
    let l:paragraph = self.join_paragraph(a:text)
    let l:role = printf('<span class="%s">\1</span>', s:style.role)
    let l:paragraph = substitute(l:paragraph, '^\s*\(.\+：\)', l:role, '')
    let l:prompt = printf('<span class="%s">\1</span>', s:style.prompt) 
    let l:paragraph = substitute(l:paragraph, '\(（.\{-}）\)', l:prompt, 'g')
    let l:html = printf('<p class="%s">', s:style.line)
    call add(self.html, l:html)
    call add(self.html, l:paragraph)
endfunction

" Method: post_run 
function! s:class.post_run() dict abort
    " pass
endfunction

" Method: render 
function! s:class.render() dict abort
    let l:lsTemplate = readfile(self.template)
    let l:html = []
    for l:line in l:lsTemplate
        if l:line =~? '{vim:main}'
            call extend(l:html, self.html)
            continue
        elseif l:line =~? '{vim:navigator}'
            call extend(l:html, self.hnav)
            continue
        endif

        if l:line =~? '{vim:title}'
            let l:line = substitute(l:line, '{vim:title}', self.title, '')
        elseif l:line =~? '{vim:home}'
            let l:line = substitute(l:line, '{vim:home}', self.home, '')
        endif

        call add(l:html, l:line)
    endfor
    let self.html = l:html
endfunction

" Method: output 
function! s:class.output() dict abort
    let l:name = expand('%:p:t:r')
    let l:name .= '.html'
    execute 'vsplit' l:name
    1,$ delete
    call append(0, self.html)
endfunction

" Func: s:run 
function! s:run(...) abort
    let l:formater = s:new()
    call l:formater.run()
    call l:formater.render()
    call l:formater.output()
endfunction

call s:run()
command! -nargs=* JubenHtml call s:run()
