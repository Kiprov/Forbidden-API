local API = {}

API.basic = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kiprov/Forbidden-API/main/stdfunctions.lua"))() -- gets Standard functions (exists like this so .Math can require the stdfunctions module without recursion)
API.math = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kiprov/Forbidden-API/main/Math.lua"))() -- Math Library

return API
