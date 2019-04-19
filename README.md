# lightline-gitdiff

I had been using [airblade/vim-gitgutter][gitgutter] for a while, however, I
felt distracted by the indicators shown in the sign column in the end. That
said, I wanted some lightweight signal indicating whether the current file
contains uncommitted changes to the repository or not.

So, this little plugin was born. I myself use
[itchyny/lightline.vim][lightline] to configure the statusline of vim easily. .
This is where the name of the plugin comes from. In addition, I embrace
lightlines's philosophy to provide a lightweight and stable, yet configurable
plugin that "just works". In addition, you can also integrate the plugin with
vim's vanilla `statusline` because it generates nothing more than a string.

By default the plugin shows an indicator such as the following:

```
A: 4 D: 6 M: 2
```

which indicates that, in comparison to the git index, the current buffer
contains 12 uncommitted changes: four lines were deleted, six lines were added
and two lines only modified. If there are no uncommitted changes, nothing is
shown to reduce distraction.

You can see the plugin in action in my statusline/lightline:

![screenshot](https://raw.githubusercontent.com/wiki/niklaas/lightline-gitdiff/images/screenshot.png)

## Installation

Use your favorite plugin manager to install the plugin. I personally prefer
vim-plug but feel free to choose another one:

```vim
Plug 'niklaas/lightline-gitdiff'
```

## Configuration

### Using vim's vanilla statusline

```vim
set statusline=%!lightline#gitdiff#get()
```

which let's your `statusline` consist of `gitdiff`'s indicators only. (Probably
not what you want but you can consult `:h statusline` for further information
on how to include additional elements.)

### Using lightline

```vim
let g:lightline = {
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'filename', 'readonly', 'modified' ],
      \             [ 'gitdiff' ] ],
      \   'right': [ [ 'lineinfo' ],
      \              [ 'percent' ] ]
      \ },
      \ 'inactive': {
      \   'left': [ [ 'filename', 'gitversion' ] ],
      \ },
      \ 'component_function': {
      \   'gitbranch': 'fugitive#head',
      \ },
      \ 'component_expand': {
      \   'gitdiff': 'lightline#gitdiff#get',
      \ },
      \ 'component_type': {
      \   'gitdiff': 'middle',
      \ },
      \ }
```

which should give you pretty much the same result as the screenshot.

# Configuration

You can configure the indicators and the separator between them. The following
are the defaults:

```vim
let g:lightline#gitdiff#indicator_added = 'A: '
let g:lightline#gitdiff#indicator_deleted = 'D: '
let g:lightline#gitdiff#separator = ' '
```

# How it works / performance

In the background, the `lightline#gitdiff#get()` calls `git --numstat` or `git
--word-diff=porcelain` (depending on the algorithm you choose, the latter being
the default) for the current buffer and caches the result.

If possible e.g., when an already open buffer is entered, the cache is used and
no call to `git` is made. `git` is only executed when reading or writing to a
buffer. See the `augroup` in [plugin/lightline/gitdiff.vim][augroup].

If you have any suggestions to improve the performance, please let me know. I
am happy to implement your suggestions on my own -- or you can create a pull
request.

# Bugs etc.

Probably this code has some sharp edges. Feel free to report bugs, suggestions
and pull requests. I'll try to fix them as soon as possible.

[gitgutter]: https://github.com/airblade/vim-gitgutter
[lightline]: https://github.com/itchyny/lightline.vim
[augroup]: https://github.com/niklaas/lightline-gitdiff/blob/master/plugin/lightline/gitdiff.vim
