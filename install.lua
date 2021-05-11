--installation script
--rhNbNbFE
--Version 1.0
--taken from https://github.com/OmegaPhi115/Draconic-Evolution-Reactor-Controller/blob/master/install.lua, credit goes to OmegaPhi115

local libURL = "https://raw.githubusercontent.com/cricton/draconic-reactor-controller/main/lib/f.lua"
local startupURL = "https://raw.githubusercontent.com/cricton/draconic-reactor-controller/main/controller.lua"
local lib, startup
local libFile, startupFile

fs.makeDir("lib")

lib = http.get(libURL)
libFile = lib.readAll()

local file1 = fs.open("lib/f", "w")
file1.write(libFile)
file1.close()

startup = http.get(startupURL)
startupFile = startup.readAll()

local file2 = fs.open("startup", "w")
file2.write(startupFile)
file2.close()
os.reboot()
