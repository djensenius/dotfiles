" Check ':help signature' for default usage
"
" Tweak usage:
"
"   Add:
"
"     + Use mm to auto set next mark, or unset marks:w
"     + Use ma, mb, mc to set mark manually
"
"   Del:
"
"     + Use m<Space> to unset all
"     + Use mm to unset
"
"   Navi:
"
"     + Use mn to jump next, mp to jump prev
"     + Use 'a, 'b, 'c to jump manually
"
"   Show:
"
"     + Use m/
"
let g:SignatureIncludeMarks = 'abcdefghijkloqrstuvwxyz'
let g:SignatureIncludeMarkers = ''

let g:SignatureMap = {
  \ 'ToggleMarkAtLine'   :  "mm",
  \ 'DeleteMark'         :  "dm",
  \ 'PurgeMarks'         :  "m<Space>",
  \ 'GotoNextSpotAlpha'  :  "mn",
  \ 'GotoPrevSpotAlpha'  :  "mp",
  \ 'ListBufferMarks'    :  "m/",
  \}
