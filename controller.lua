local reactorSide = "back"
local fluxOutputSide = "right"
local maxTemp = 8000

os.loadAPI("lib/f")


local reactor
local fluxInput
local fluxExtract

local version = 0.1

local mon, monitor, monX, monY

local reactorInfo

reactor = peripheral.wrap(reactorSide)
fluxOutput = peripheral.wrap(fluxOutputSide)
fluxInput = f.periphSearch("flux_gate")
monitor = f.periphSearch("monitor")


if reactor == null then
    error("No reactor found. Expected on ".. reactorSide .. " side.")
end

if fluxOutput == null then
    error("No output flux gate found. Expected on " .. fluxOutputSide .. " side.")
end

if fluxInput == null then
    error("No input flux gate found. Expected on network.")
end

if monitor == null then
    error("No monitor found. Expected on network.")
end

monX, monY = monitor.getSize()
mon = {}
mon.monitor, mon.X, mon.Y = monitor, monX, monY

f.clear(mon)
--f.draw_text(mon, 1, 1, "Hello World", colors.white, colors.black)

reactorInfo = reactor.getReactorInfo()

for i,k in pairs(reactorInfo) do
    print(i .. ", " .. tostring(k))
end

function drawReactorInfo(mon, reactorInfo)
    
    i = 1
    for key,value in pairs(reactorInfo) do
        f.draw_text(mon, 1, i, (key .. ", " .. tostring(value)), colors.white, colors.black)
        i = i + 1
    end
    f.draw_line(mon, 1, i, mon.X, colors.gray)
    return i 
    
end    

function manageInputPower(reactorInfo)
    
end

local cooling 
local lastTemp

function manageOutputPower(reactorInfo)
    temp = reactorInfo.temperature
    
    if lastTemp == null then
        lastTemp = temp
    end
    
    if lastTemp - temp > 0 then
        cooling = true
    end
    
    if temp < 7000 and cooling then 
        print("Increasing temperature")
        fluxOutput.setSignalLowFlow(fluxOutput.getSignalLowFlow()+20000)
        cooling = false
    end    
    
    if temp > 8000 then
        print("Temperature too high, decreasing power output.")
        fluxOutput.setSignalLowFlow(fluxOutput.getSignalLowFlow()*0.2)
    end
    
    lastTemp = temp
end
                        
while true do
    reactorInfo = reactor.getReactorInfo()
    i = drawReactorInfo(mon, reactorInfo)
    f.draw_text(mon, 1, i+1, ("Output target power: " .. fluxOutput.getSignalLowFlow() .. "rf/t"), colors.green,colors.black)
    f.draw_text(mon, 1, i+2, ("Input target power: " .. fluxInput.getFlow() .. "rf/t"), colors.red, colors.black)
    manageOutputPower(reactorInfo)
    sleep(1)
    
    
end

print("Found all peripherals. Exiting.")
