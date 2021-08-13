" Stores the current window in the quit history, so we can undo the :quit
" later.
function! undoquit#SaveWindowQuitHistory()
  if !s:IsStorable(bufnr('%'))
    return
  endif

  if !exists('g:undoquit_stack')
    let g:undoquit_stack = []
  endif

  let window_data = undoquit#GetWindowRestoreData()

  call add(g:undoquit_stack, window_data)
endfunction

function! undoquit#Tabclose(prefix_count, suffix_count, bang)
  if a:suffix_count != ''
    let tab_description = a:suffix_count
  elseif a:prefix_count > 0
    let tab_description = a:prefix_count
  else
    let tab_description = ''
  endif

  if tab_description != ''
    exe 'tabnext ' . tab_description
  endif

  for bufnr in tabpagebuflist()
    if bufexists(bufnr)
      let winnr = bufwinnr(bufnr)
      exe winnr.'wincmd w'
      exe 'quit'.a:bang
    endif
  endfor
endfunction

" Restores the last-:quit window.
function! undoquit#RestoreWindow()
  if !exists('g:undoquit_stack') || empty(g:undoquit_stack)
    echo "No closed windows to undo"
    return
  endif

  let window_data = remove(g:undoquit_stack, -1)
  if window_data.down_winid && win_gotoid(window_data.down_winid)
    let open_command = 'leftabove split'
  elseif window_data.up_winid && win_gotoid(window_data.up_winid)
    let open_command = 'rightbelow split'
  elseif window_data.left_winid && win_gotoid(window_data.left_winid)
    let open_command = 'rightbelow vsplit'
  elseif window_data.right_winid && win_gotoid(window_data.right_winid)
    let open_command = 'leftabove vsplit'
  else
    let open_command = (window_data['tabpagenr'] - 1).'tabnew'
  endif

  exe open_command.' '.escape(fnamemodify(window_data.filename, ':~:.'), ' ')

  call winrestview(window_data.view)

  call s:RemapStackWinID(window_data.winid, win_getid())
endfunction

function! undoquit#RestoreTab()
  if !exists('g:undoquit_stack') || empty(g:undoquit_stack)
    echo "No closed tabs to undo"
    return
  endif

  let last_window = g:undoquit_stack[len(g:undoquit_stack) - 1]
  let last_tab    = last_window.tabpagenr

  while last_window.tabpagenr == last_tab
    call undoquit#RestoreWindow()

    if len(g:undoquit_stack) > 0
      let last_window = g:undoquit_stack[len(g:undoquit_stack) - 1]
    else
      break
    endif

    if last_window.open_command == '1tabnew'
      " then this was the window that opens a new tab page, stop here
      break
    endif
  endwhile
endfunction

" Fetches the data we need to successfully restore a window we're just about
" to :quit.
function! undoquit#GetWindowRestoreData()
  let window_data = {
        \ 'filename':     expand('%:p'),
        \ 'tabpagenr':    tabpagenr(),
        \ 'view':         winsaveview(),
        \ 'winid':        win_getid(),
        \ 'left_winid':   s:GetNeighbourWinID('h'),
        \ 'down_winid':   s:GetNeighbourWinID('j'),
        \ 'up_winid':     s:GetNeighbourWinID('k'),
        \ 'right_winid':  s:GetNeighbourWinID('l'),
        \ }
  return window_data
endfunction

function! s:GetNeighbourWinID(direction)
  let current_winnr = winnr()
  let neighbour_winnr = winnr(a:direction)
  
  if current_winnr == neighbour_winnr
    return 0
  endif

  let neighbour_bufnr = winbufnr(neighbour_winnr)
  if !s:IsStorable(neighbour_bufnr)
    return 0
  endif

  return win_getid(neighbour_winnr)
endfunction

function! s:RemapStackWinID(from, to)
  for window_data in g:undoquit_stack
    if window_data.down_winid == a:from
      let window_data.down_winid = a:to
    elseif window_data.up_winid == a:from
      let window_data.up_winid = a:to
    elseif window_data.left_winid == a:from
      let window_data.left_winid = a:to
    elseif window_data.right_winid == a:from
      let window_data.right_winid = a:to
    endif
  endfor
endfunction

function! s:IsStorable(bufnr)
  if buflisted(a:bufnr) && getbufvar(a:bufnr, '&buftype') == ''
    return 1
  else
    return getbufvar(a:bufnr, '&buftype') == 'help'
  endif
endfunction
