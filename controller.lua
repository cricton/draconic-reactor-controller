local reactorSide = "back"
local fluxOutputSide = "right"
local maxTemp = 8000

os.loadAPI("lib/f")


local reactor
local fluxInput
local fluxExtract

local version = 1.0

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

--[[
if fluxOutput.getSignalLowFlow() <= 300000 then
    fluxOutput.setSignalLowFlow(300000)
end

if fluxInput.getSignalLowFlow() <= 100000 then
    fluxInput.setSignalLowFlow(100000)
end
--]]

f.clear(mon)


reactorInfo = reactor.getReactorInfo()

for i,k in pairs(reactorInfo) do
    print(i .. ": " .. tostring(k))
end

function draw_vertical(mon, x, y, length, color)
    if length < 0 then
        length = 0
    end
    
    for i=y, length+y, 1 do
        
        f.draw_line(mon, x, i, 1, color)
    end
    

end

function drawReactorInfo(mon, reactorInfo)

    --draw fuel conversion
    fuelPercentage = math.floor((reactorInfo.fuelConversion / reactorInfo.maxFuelConversion)*10000)/100
    if fuelPercentage > 75 then
        fuelColor = colors.orange
        if fuelPercentage > 90 then
            fuelColor = colors.red
        end
    else
        fuelColor = colors.green
    end
    f.draw_text(mon, 2,2, ("Fuel conversion: " .. fuelPercentage .. "%") ,colors.white, colors.black)
    f.progress_bar(mon, 3, 3, 20, fuelPercentage, 100, fuelColor, colors.gray)
    
    --draw reactor temp
    reactorPercentage = math.floor((reactorInfo.temperature / maxTemp)*10000)/100
    if reactorInfo.temperature > 7500 then
        reactorColor = colors.orange
        if reactorInfo.temperature>7900 then
            reactorColor = colors.red
        end
    else
        reactorColor = colors.green
    end
    f.draw_text(mon, 2, 5, ("Reactor temp: "  .. math.ceil(reactorInfo.temperature) .. "°C"), colors.white, colors.black)
    f.progress_bar(mon, 3, 6, 20, reactorPercentage, 100, reactorColor, colors.gray)
    
    --draw containment field
    fieldPercentage = math.floor(reactorInfo.fieldStrength/10000)/100
    if fieldPercentage > 55 or fieldPercentage < 50 then  
        fieldColor = colors.orange
        if fieldPercentage < 40 then
            fieldColor = colors.red
        end  
    else
        fieldColor = colors.green
    end
    
    f.draw_text(mon, 2, 8, ("Field power: " .. fieldPercentage .. "% "), colors.white, colors.black)
    f.progress_bar(mon, 3, 9, 20, fieldPercentage, 100, fieldColor, colors.gray)
 
    
end 

function drawOutlines(mon)

    draw_vertical(mon, 25, 1, 10, colors.gray)
    draw_vertical(mon, 26, 1, 10, colors.gray)
    
    f.draw_line(mon, 1, 11, mon.X, colors.gray)
    --f.draw_line(mon, 1, 12, mon.X, colors.gray)
    
    
    f.draw_line(mon, 3, 13, 46, colors.gray)
    draw_vertical(mon, 3, 13, 12, colors.gray)
    draw_vertical(mon, 48, 13, 12, colors.gray)
    f.draw_line(mon, 3, 25, 46, colors.gray)
end

function drawReactorIO(mon, reactorInfo)
    f.draw_text(mon, 9, 17, ("Output target power: " .. fluxOutput.getSignalLowFlow() .. " rf/t"), colors.green,colors.black)
    f.draw_text(mon, 9, 19, ("Input target power:  " .. fluxInput.getFlow() .. " rf/t"), colors.red, colors.black)
    
    netGain = fluxOutput.getSignalLowFlow() - fluxInput.getSignalLowFlow()
    if netGain > 0 then
        gainColor = colors.green
    else
        gainColor = colors.red
    end
    f.draw_line(mon, 8, 22, 35, gainColor)
    f.draw_text(mon, 14, 22, (" Net gain: " .. (fluxOutput.getSignalLowFlow()-fluxInput.getSignalLowFlow()) .. " rf/t "), colors.white, gainColor)
    f.draw_line(mon, 8, 21, 35, gainColor)
    f.draw_line(mon, 8, 23, 35, gainColor)
    
    
    
    --draw reactor status
    if reactorInfo.status == "running" then
        statusColor = colors.green
        statusText = "running"
    elseif reactorInfo.status == "warming_up" then
        statusColor = colors.blue
        statusText = "warming up"
    elseif reactorInfo.status == "stopping" then
        statusColor = colors.purple
        statusText = "stopping"
    elseif reactorInfo.status == "cooling_down" then
        statusColor = colors.orange
        statusText = "cooling down"
    else
        statusColor = colors.gray
    end
    f.draw_text(mon, 16, 15, ("Reactor is "), colors.white, colors.black)
    f.draw_text(mon, 27, 15, statusText, statusColor, colors.black)
    
end


local failsaveOn = reactorInfo.failSafe

function drawButtons(mon)
    
    if failsaveOn then
        failsaveColor = colors.blue
    else
        failsaveColor = colors.gray
    end
    
    
    
    f.draw_text(mon, 28, 2, " Shut ", colors.white, colors.gray)
    f.draw_text(mon, 28, 3, " Down ", colors.white, colors.gray)
    
    
    f.draw_text(mon, 28, 8, " Fail ", colors.white, failsaveColor)
    f.draw_text(mon, 28, 9, " Safe ", colors.white, failsaveColor)
    
    f.draw_text(mon, 28, 5, " Start", colors.white, colors.gray)
    f.draw_text(mon, 28, 6, "  Up  ", colors.white, colors.gray)
    
end

local conX, conY = 15, 8
local conXoffset, conYoffset = 35, 1
function drawConsole(mon)
    for i=1 + conYoffset, conY+conYoffset, 1 do
        f.draw_line(mon, conXoffset, i, conX, colors.gray)
    end
    printConsole(mon)
end

local consoleLog = {}
function log(toLog)
    if string.len(toLog)>30 then
        log("String too long")
        log(toLog:sub(1, 30))
        return
    end
    if string.len(toLog)>15 then
        log(toLog:sub(1,15))
        if toLog:sub(16, 16) == " " then
            log(toLog:sub(17,string.len(toLog)))
        else
            log(toLog:sub(16,string.len(toLog)))
        end
        return
    end
    for i=1, conY, 1 do
        if consoleLog[i] == nil then
            consoleLog[i] = toLog
            return
        end
    end
    
    for i=2, conY, 1 do
        consoleLog[i-1] = consoleLog[i]
    end
    consoleLog[conY] = toLog
    
end

function printConsole(mon)
    for i=1+conYoffset, conY+conYoffset, 1 do
        f.draw_text(mon, conXoffset, i, consoleLog[i-conYoffset], colors.white, colors.gray)
    end
end


local weakening
local lastStrength
local strengthTolerance = 0

function manageInputPower(reactorInfo)
   fieldStrength = math.ceil(reactorInfo.fieldStrength / reactorInfo.maxFieldStrength * 10000)*.01
   
   if lastStrength == null then
       lastStrength = fieldStrength
   end
   
   if (lastStrength - fieldStrength) + strengthTolerance > 0 then
       weakening = true
   else 
       weakening = false
   end
       
   if fieldStrength < 50 and weakening then
       log("Increasing flux input")
       fluxInput.setSignalLowFlow(fluxInput.getSignalLowFlow() + 5000)
   end    
   
   if fieldStrength > 55 and not weakening then
       log("Decreasing flux input")
       fluxInput.setSignalLowFlow(fluxInput.getSignalLowFlow()-5000)   
   end
   lastStrength = fieldStrength
end


local cooling 
local lastTemp
local tempTolerance = 3
local emergencyDecrease = false

function manageOutputPower(reactorInfo)
    temp = reactorInfo.temperature
    
    if lastTemp == null then
        lastTemp = 0
    end
    
    if (lastTemp - temp)+tempTolerance > 0 then
        cooling = true
    else
        cooling = false
    end
    
    if temp < 8000 and not cooling then
        emergencyDecrease = false
    end
    
    if temp < 7250 and cooling then 
        log("Increasing temperature")
        if temp < 6500 and not emergencyDecrease then
            inc = 20000
        else 
            inc = 5000
        end    
        fluxOutput.setSignalLowFlow(fluxOutput.getSignalLowFlow()+inc)
        cooling = false 
    end    
    
    if temp > 8000 and not cooling and not emergencyDecrease then
        log("Temp critical, accomodating...")
        fluxOutput.setSignalLowFlow(fluxOutput.getSignalLowFlow()*0.5)
        emergencyDecrease = true
    end
    
    lastTemp = temp
end
    
function manageFuelEmpty(reactorInfo)
    usedFuelPercent = math.floor((reactorInfo.fuelConversion / reactorInfo.maxFuelConversion)*100)
    if usedFuelPercent > 90 and reactorInfo.status == "running" then
        reactor.stopReactor()
        print("Stopping, fuel almost depleted")
    end
end

function manageWarmup(reactorInfo)
    if math.floor(reactorInfo.temperature) >= 2000 then
        reactor.activateReactor()
        return
    end
    fluxInput.setSignalLowFlow(1000000)
    
end            
            
function buttons()
    while true do
        sleep(0)
        
        event, side, xPos, yPos = os.pullEvent("monitor_touch")

        if xPos >= 28 and xPos <= 33 then
            reactorStatus = reactor.getReactorInfo().status
            if yPos >=2 and yPos <= 3 then
                
                if reactorStatus == "running" then
                    reactor.stopReactor()
                    log("Stopping...")
                end
            end
            
            if yPos >=5 and yPos <= 6 then
                if reactorStatus ~= "running" then
                    reactor.activateReactor()
                    log("Starting...")
                end
            end
            
            if yPos >=8 and yPos <= 9 then
                
                failsaveOn = not failsaveOn
                reactor.setFailSafe(failsaveOn)
                if failsaveOn then
                    log("FailSafe on")
                else
                    log("FailSafe off")
                end
            end
        end
    end
end


function update()
                                        
    while true do
        f.clear(mon)
        reactorInfo = reactor.getReactorInfo()
        drawReactorInfo(mon, reactorInfo)
        drawReactorIO(mon, reactorInfo)
        drawOutlines(mon)
        drawButtons(mon)
        drawConsole(mon)
           
        if reactorInfo.status == "running" then
            manageOutputPower(reactorInfo)
            manageFuelEmpty(reactorInfo)
        end
    
        if reactorInfo.status == "warming_up" then 
            manageWarmup(reactorInfo)
        end
        
        --log(reactorInfo.status)
        if reactorInfo.status ~= "cooling" then
            manageInputPower(reactorInfo)
        end
        
        
        
        sleep(1)
    
        end
    end

parallel.waitForAny(buttons, update)
