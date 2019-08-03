" calculate_numstat {{{1 queries git to get the amount of lines that were
" added and/or deleted. It returns a dict with two keys: 'A' and 'D'. 'A'
" holds how many lines were added, 'D' holds how many lines were deleted.
function! lightline#gitdiff#algorithms#numstat#calculate(buffer, Callback) abort
  if !lightline#gitdiff#utils#is_git_exectuable()
    return function(a:Callback)({})
  endif
  call lightline#gitdiff#utils#is_inside_work_tree(a:buffer, function('lightline#gitdiff#algorithms#numstat#calculate_detect_callback',[a:buffer, a:Callback]))
endfunction

function! s:buf_handler(bufnameOrOutput, Callback) abort
  if has('nvim')
    return function(a:Callback)(a:bufnameOrOutput[0][4:-3])
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
function! lightline#gitdiff#algorithms#numstat#calculate_detect_callback(buffer, Callback, inWorkTree) abort
  if !a:inWorkTree
    " b/c there is nothing that can be done here; the algorithm needs git
    return function(a:Callback)({})
  endif

  if has('neovim')
    let l:out = []
    call jobstart(system('cd ' . expand('#' . a:buffer . ':p:h:S')
          \ . ' && git diff --no-ext-diff --numstat -- '
          \ . expand('#' . a:buffer . ':t:S')), { 'on_stdout': {j,d,e -> add(l:out, d) }, 'on_exit': {-> <SID>buf_handler(l:out, a:Callback)}})
  else
    let l:bufname = tempname()
    call job_start(system('bash -c "cd ' . expand('#' . a:buffer . ':p:h:S')
          \ . ' && git diff --no-ext-diff --numstat -- '
          \ . expand('#' . a:buffer . ':t:S')).'"', { 'out_io': 'buffer', 'out_name': l:bufname, 'exit_cb': {-> <SID>buf_handler(l:bufname, a:Callback)}})
    " let l:stats = split(system('cd ' . expand('#' . a:buffer . ':p:h:S')
    "   \ . ' && git diff --no-ext-diff --numstat -- '
    "   \ . expand('#' . a:buffer . ':t:S')))
    " call lightline#gitdiff#algorithms#numstat#calculate_callback(a:Callback, stats)
  endif
endfunction
function! lightline#gitdiff#algorithms#numstat#calculate_callback(Callback, stats) abort
  if len(a:stats) < 2 || join(a:stats[:1], '') !~# '^\d\+$'
    " b/c there are no changes made, the file is untracked or some error
    " occured
    return function(a:Callback)({})
  endif

  let l:ret = {}

  " lines added
  if a:stats[0] !=# '0'
    let l:ret['A'] = a:stats[0]
  endif

  " lines deleted
  if a:stats[1] !=# '0'
    let l:ret['D'] = a:stats[1]
  endif

  return function(a:Callback)(l:ret)
endfunction
