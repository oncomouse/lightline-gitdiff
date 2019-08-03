" calculate_porcelain {{{1 transcodes a `git diff --word-diff=porcelain` and
" returns a dictionary that tells how many lines in the diff mean Addition,
" Deletion or Modification.
function! lightline#gitdiff#algorithms#word_diff_porcelain#calculate(buffer, Callback) abort
  if !lightline#gitdiff#utils#is_git_exectuable()
    return function(a:Callback)({})
  endif
  call lightline#gitdiff#utils#is_inside_work_tree(a:buffer, function('lightline#gitdiff#algorithms#word_diff_porcelain#calculate_detect_callback',[a:buffer, a:Callback]))
endfunction

function! lightline#gitdiff#algorithms#word_diff_porcelain#calculate_detect_callback(buffer, Callback, inWorkTree) abort
  if !a:inWorkTree
    " b/c there is nothing that can be done here; the algorithm needs git
    return function(a:Callback)({})
  endif
  call s:get_diff_porcelain(a:buffer, function('lightline#gitdiff#algorithms#word_diff_porcelain#calculate_callback',[a:Callback]))
endfunction

function! lightline#gitdiff#algorithms#word_diff_porcelain#calculate_callback(Callback, porcelain) abort
  let l:indicator_groups = s:transcode_diff_porcelain(a:porcelain)

  let l:changes = map(copy(l:indicator_groups), { idx, val ->
        \ lightline#gitdiff#algorithms#word_diff_porcelain#parse_indicator_group(val) })

  let l:lines_added = len(filter(copy(l:changes), { idx, val -> val ==# 'A' }))
  let l:lines_deleted = len(filter(copy(l:changes), { idx, val -> val ==# 'D' }))
  let l:lines_modified = len(filter(copy(l:changes), { idx, val -> val ==# 'M' }))

  let l:ret = {}

  if l:lines_added > 0
    let l:ret['A'] = l:lines_added
  endif

  if l:lines_deleted > 0
    let l:ret['D'] = l:lines_deleted
  endif

  if l:lines_modified > 0
    let l:ret['M'] = l:lines_modified
  endif
  return function(a:Callback)(l:ret)
endfunction

" get_diff_porcelain {{{1 returns the output of git's word-diff as list. The
" header of the diff is removed b/c it is not needed.
function! s:buf_handler(bufnameOrOutput, Callback) abort
  if has('nvim')
    return function(a:Callback)(a:bufnameOrOutput[0][4:-2])
  else
    let l:buflines = getbufline(bufnr(a:bufnameOrOutput), 1, '$')
    try
      execute('bdelete! '.bufnr(a:bufnameOrOutput))
    catch
    endtry
    let l:output = l:buflines[4:]
    return function(a:Callback)(l:output)
  endif
endfunction

function! s:get_diff_porcelain(buffer, Callback) abort
  if has('nvim')
    let l:out = []
    call jobstart('cd ' . expand('#' . a:buffer . ':p:h:S') .
          \ ' && git diff --no-ext-diff --word-diff=porcelain --unified=0 -- ' . expand('#' . a:buffer . ':t:S'), { 'on_stdout': {j,d,e -> add(l:out, d) }, 'on_exit': {-> <SID>buf_handler(l:out, a:Callback)}})
  else
    let l:bufname = tempname()
    call job_start('bash -c "cd ' . expand('#' . a:buffer . ':p:h:S') .
          \ ' && git diff --no-ext-diff --word-diff=porcelain --unified=0 -- ' . expand('#' . a:buffer . ':t:S').'"', { 'out_io': 'buffer', 'out_name': l:bufname, 'exit_cb': {-> <SID>buf_handler(l:bufname, a:Callback)}})
  endif
endfunction

" transcode_diff_porcelain() {{{1 turns a diff porcelain into a list of lists
" such as the following:
"
"   [ [' ', '-', '~'], ['~'], ['+', '~'], ['+', '-', '~' ] ]
"
" This translates to Deletion, Addition, Addition and Modification eventually,
" see s:parse_indicator_group. The characters ' ', '-', '+', '~' are the very
" first columns of a `--word-diff=porcelain` output and include everything we
" need for calculation.
function! s:transcode_diff_porcelain(porcelain) abort
  " b/c we do not need the line identifiers
  call filter(a:porcelain, { idx, val -> val !~# '^@@' })

  " b/c we only need the identifiers at the first char of each diff line
  call map(a:porcelain, { idx, val -> strcharpart(val, -1, 2) })

  return lightline#gitdiff#utils#group_at({ el -> el ==# '~' }, a:porcelain, v:true)
endfunction

" parse_indicator_group() {{{1 parses a group of indicators af a word-diff
" porcelain that describes an Addition, Delition or Modification. It returns a
" single character of either 'A', 'D', 'M' for the type of diff that is
" recorded by the group respectively. A group looks like the following:
"
"   [' ', '+', '~']
"
" In this case it means A_ddition. The algorithm is rather simple because
" there are only four indicators: ' ', '+', '-', '~'. These are the rules:
"
"   1. Sometimes a group starts with a 'space'. This can be ignored.
"   2. '+' and '-' I call "changers". In combination with other indicators
"      they specify what kind of change was made.
"   3. If a '+' or '-' is follwed by a '~' the group means Addition or
"      Deletion respectively.
"   4. If a '+' or '-' is followed by anything else than a '~' it is a
"      Modification.
"   5. If the group consists of a single '~' it is an Addition.
"   6. There must be one but only one '~' in *every* group.
"
" The method implements this algorithm. It is far from perfect but seems to
" work as some tests showed.
function! lightline#gitdiff#algorithms#word_diff_porcelain#parse_indicator_group(indicators) abort
  let l:changer = ''

  if len(a:indicators) ==# 1 && a:indicators[0] ==# '~'
    return 'A'
  endif

  for el in a:indicators
    if l:changer ==# '' && ( el ==# '-' || el ==# '+' )
      let l:changer = el
      continue
    endif

    if l:changer ==# '+' && el ==# '~'
      return 'A'
    endif

    if l:changer ==# '-' && el ==# '~' 
      return 'D'
    endif

    if l:changer !=# el
      return 'M'
    endif
  endfor

  " b/c we should never end up here
  echoerr 'lightline#gitdiff: Error parsing indicator group: [ ' . join(a:indicators, ', ') . ' ]'
endfunction
