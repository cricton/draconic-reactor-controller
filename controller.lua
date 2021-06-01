local reactorSide = "back"
local fluxOutputSide = "right"
local maxTemp = 8000
local targetTemp = 7500
local tolerance = 25
os.loadAPI("lib/f")


local reactor
local fluxInput
local fluxExtract

--local version = 1.2
local version = "2.3"
local singleLine = 2
local singleLineInfo = 3
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
print(mon.monitor)
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



for i,k in pairs(reactor) do
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

infoX, infoY = 4, 4
function drawReactorInfo(mon, reactorInfo)
    --clear text boxes:
    f.draw_line(mon, infoX + string.len("Fuel used: "),infoY, 10,colors.black)
    f.draw_line(mon, infoX + string.len("Temperature: "),infoY+3, 8,colors.black)
    f.draw_line(mon, infoX + string.len("Field power: "),infoY+6, 8,colors.black)

    
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
    
    fuelString = string.format("%.2f", fuelPercentage)
    f.draw_text(mon, infoX + string.len("Fuel used: "),infoY, (fuelString .. "%") ,colors.white, colors.black)
    f.progress_bar(mon, infoX, infoY+1, 20, fuelPercentage, 100, fuelColor, colors.gray)
    
    --draw reactor temp
    currentTemp = reactorInfo.temperature
    if currentTemp>maxTemp then
        currentTemp = maxTemp
    end
    
    reactorPercentage = math.floor((currentTemp / maxTemp)*10000)/100
    if reactorInfo.temperature > (targetTemp + tolerance) then
        reactorColor = colors.orange
        if reactorInfo.temperature>maxTemp then
            reactorColor = colors.red
        end
    else
        reactorColor = colors.green
    end
    f.draw_text(mon, infoX + string.len("Temperature: "), infoY+singleLineInfo, (math.floor(reactorInfo.temperature) .. "°C"), colors.white, colors.black)
    f.progress_bar(mon, infoX, infoY+singleLineInfo+1, 20, reactorPercentage, 100, reactorColor, colors.gray)
    
    --draw containment field
    fieldPercentage = math.ceil(reactorInfo.fieldStrength / reactorInfo.maxFieldStrength * 10000)*.01
    if (fieldPercentage > 55 or fieldPercentage < 45) and reactorInfo.status == running then  
        fieldColor = colors.orange
        if fieldPercentage < 40 then
            fieldColor = colors.red
        end  
    else
        fieldColor = colors.green
    end
    
    fieldString = string.format("%.2f", fieldPercentage)
    f.draw_text(mon, infoX+string.len("Field power: "), infoY+(2*singleLineInfo), (fieldString .. "%"), colors.white, colors.black)
    f.progress_bar(mon, infoX, infoY +(2*singleLineInfo)+1, 20, fieldPercentage, 100, fieldColor, colors.gray)
 
    
    
end 

function drawOutlines(mon)


    draw_vertical(mon, 25, 2, 12, colors.gray)
    f.draw_line(mon, 2, 2, 47, colors.gray)
    f.draw_text(mon, 4, 2, " Info ", colors.white, colors.black)
    f.draw_text(mon, 27, 2, " Log ", colors.white, colors.black)
    
    f.draw_line(mon, 3, 15, 46, colors.gray)
    draw_vertical(mon, 2, 2, 23, colors.gray)
    draw_vertical(mon, 49, 2, 23, colors.gray)
    f.draw_line(mon, 3, 25, 46, colors.gray)
    draw_vertical(mon, 27, 16, 8, colors.gray)
    
    f.draw_text(mon, 4, 15, " Status ", colors.white, colors.black)
    f.draw_text(mon, 29, 15, " IO ", colors.white, colors.black)
    
    f.draw_line(mon, 1, 14, 50, colors.black)
    f.draw_line(mon, 2, 13, 48, colors.gray)
    
    f.draw_text(mon, 39, 25, " ver "..version.." ", colors.gray, colors.black)
    
end


local IOX, IOY = 30, 17
function drawReactorIO(mon, reactorInfo)
    --clear text fields
    f.draw_line(mon, IOX + string.len("Out: "), IOY, 14, colors.black)
    f.draw_line(mon, IOX + string.len("In: "), IOY+singleLine, 15, colors.black)

    if fluxOutput.getSignalLowFlow() > 999999 then
        f.draw_text(mon, IOX + string.len("Out: "), IOY, (fluxOutput.getSignalLowFlow() .. " rf/t"), colors.green,colors.black)
    else
        f.draw_text(mon, IOX + string.len("Out:  "), IOY, (fluxOutput.getSignalLowFlow() .. " rf/t"), colors.green,colors.black)
    end
    f.draw_text(mon, IOX + string.len("In:   "), IOY+singleLine, (fluxInput.getFlow() .. " rf/t"), colors.red, colors.black)
    
    netGain = fluxOutput.getSignalLowFlow() - fluxInput.getSignalLowFlow()
    if netGain > 0 then
        gainColor = colors.green
    else
        gainColor = colors.red
    end
    
    f.draw_line(mon, IOX-1, IOY+4, 19, gainColor)
    f.draw_line(mon, IOX-1, IOY+5, 19, gainColor)
    if netGain > 999999 or netGain < -999999 then 
        f.draw_text(mon, IOX-1, IOY+5, (" Gain:" .. (fluxOutput.getSignalLowFlow()-fluxInput.getSignalLowFlow()) .. " rf/t"), colors.white, gainColor)
    else 
        f.draw_text(mon, IOX-1, IOY+5, (" Gain: " .. (fluxOutput.getSignalLowFlow()-fluxInput.getSignalLowFlow()) .. " rf/t"), colors.white, gainColor)
    end
    
    f.draw_line(mon, IOX-1, IOY+6, 19, gainColor)
    
end


buttonX, buttonY = 5, 22
function drawButtons(mon)
    
    
    buttons = {}
    buttons.shutdownX, buttons.shutdownY = buttonX, buttonY
    buttons.startupX, buttons.startupY = buttonX+7, buttonY
    buttons.clearlogX, buttons.clearlogY = buttonX+14, buttonY

    f.draw_text(mon, buttons.shutdownX, buttons.shutdownY, " Shut ", colors.white, colors.gray)
    f.draw_text(mon, buttons.shutdownX, buttons.shutdownY+1, " Down ", colors.white, colors.gray)
    
    

    
    f.draw_text(mon, buttons.startupX, buttons.startupY, "Start ", colors.white, colors.gray)
    f.draw_text(mon, buttons.startupX, buttons.startupY+1, "  Up  ", colors.white, colors.gray)
    
    f.draw_text(mon, buttons.clearlogX, buttons.clearlogY, "Clear " , colors.white, colors.gray)
    f.draw_text(mon, buttons.clearlogX, buttons.clearlogY+1, " Log  ", colors.white, colors.gray)
    
end

statusX, statusY= 6, 17
function drawReactorStatus(mon)
    
        --draw reactor status
    if reactorInfo.status == "running" then
        statusColor = colors.green
        statusText = "running"
    elseif reactorInfo.status == "warming_up" then
        statusColor = colors.orange
        statusText = "heating"
    elseif reactorInfo.status == "stopping" then
        statusColor = colors.purple
        statusText = "stopping"
    elseif reactorInfo.status == "cooling" then
        statusColor = colors.blue
        statusText = "cooling"
    elseif reactorInfo.status == "cold" then
        statusColor = colors.gray
        statusText = "offline"
    else
        statusColor = colors.gray
    end
    
    
    
    --clear status text
    f.draw_line(mon, statusX+ string.len("Reactor is "), statusY, 10, colors.black)
    f.draw_line(mon, statusX+ string.len("Fuel rate: "), statusY+singleLine, 10, colors.black)
    
    --update status text
    f.draw_text(mon, statusX+ string.len("Reactor is "), statusY, statusText, statusColor, colors.black)
    f.draw_text(mon, statusX+ string.len("Fuel rate: "), statusY+singleLine, (reactorInfo.fuelConversionRate .. "nb/t"), colors.white, colors.black)
    
end

function drawStaticText(mon)
    --draw Info
    f.draw_text(mon, infoX, infoY, ("Fuel used: ") ,colors.white, colors.black)
    f.draw_text(mon, infoX, infoY+singleLineInfo, ("Temperature: ") ,colors.white, colors.black)
    f.draw_text(mon, infoX, infoY+(2*singleLineInfo), ("Field power: ") ,colors.white, colors.black)
    
    --draw IO
    f.draw_text(mon, IOX, IOY, ("Out: "), colors.green,colors.black)
    f.draw_text(mon, IOX , IOY+singleLine, ("In:   "), colors.red, colors.black)
    
    --draw status
    f.draw_text(mon, statusX, statusY, ("Reactor is"), colors.white, colors.black)
    f.draw_text(mon, statusX, statusY+singleLine, ("Fuel rate: "), colors.white, colors.black)
    
end


local conX, conY = 21, 8
local conXoffset, conYoffset = 27, 3
function drawConsole(mon)
    --[[for i=1 + conYoffset, conY+conYoffset, 1 do
        f.draw_line(mon, conXoffset, i, conX, colors.black)
    end--]]
    
    printConsole(mon)
end

local consoleLog = {}
function log(toLog)

    if string.len(toLog)>42 then
        log("String too long")
        log(toLog:sub(1, 42))
        return
    end
    if string.len(toLog)>21 then
        log(toLog:sub(1,21))
        if toLog:sub(22, 22) == " " then
            log(toLog:sub(23,string.len(toLog)))
        else
            log(toLog:sub(22,string.len(toLog)))
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

function logTime(toLog)
    time = os.date("*t")
    log("["..(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec)).."]")
    log(toLog)
    
end

function clearConsole()
    consoleLog = {}
    for i=1 + conYoffset, conY+conYoffset, 1 do
        f.draw_line(mon, conXoffset, i, conX, colors.black)
    end
end

function printConsole(mon)
    for i=1+conYoffset, conY+conYoffset, 1 do
        f.draw_text(mon, conXoffset, i, consoleLog[i-conYoffset], colors.white, colors.black)
    end
end


lastStatus = nil
local lastStrength
local strengthTolerance = 0


function manageInputPower(reactorInfo)
    if reactorInfo.status == "cooling" or reactorInfo.status == "cold" then
        fluxInput.setSignalLowFlow(0)
        return
    end

    drainRate = reactorInfo.fieldDrainRate
    
    

    fluxInput.setSignalLowFlow(drainRate*2)

end


local cooling 

local tempTolerance = 3
local emergencyDecrease = false





local minTemp = 2000

function manageOutputPower(reactorInfo)
    
    temp = reactorInfo.temperature
    genRate = reactorInfo.generationRate
    energyRate = reactorInfo.energySaturation/reactorInfo.maxEnergySaturation
    
    --logTime(""..reactorInfo.status .. " " .. reactorInfo.generationRate)
    if reactorInfo.status ~= "running" then
        if reactorInfo.status == "cold" then
            fluxOutput.setSignalLowFlow(0)
            return
        end
        if reactorInfo.status == "stopping" then
            fluxOutput.setSignalLowFlow(reactorInfo.generationRate)
            return
        end
        fluxOutput.setSignalLowFlow(reactorInfo.generationRate*25)
        return
    end
    
    
    if energyRate >= 0.75 then
        fluxOutput.setSignalLowFlow(reactorInfo.energySaturation/100)
        return
    end
    
    tempDif = math.floor((targetTemp+1) - temp)
    tempDif = math.max(tempDif, 0)
    --logTime(changeRate .. ", " .. expectedTemp)

    if temp <targetTemp+0.5 then
        fluxOutput.setSignalLowFlow(genRate + tempDif*(genRate/10000))
    else
        if genRate < fluxOutput.getSignalLowFlow() then
            fluxOutput.setSignalLowFlow(genRate)
        end
    end


    --logTime(tempDif)
end


    
function manageFuelEmpty(reactorInfo)
    usedFuelPercent = math.floor((reactorInfo.fuelConversion / reactorInfo.maxFuelConversion)*100)
    if usedFuelPercent >= 80 and reactorInfo.status == "running" then
        reactor.stopReactor()
        logTime("Stopping, please refuel.")
    end
end

function manageWarmup(reactorInfo)
    if math.floor(reactorInfo.temperature) >= 2000 then
        reactor.activateReactor()
        fluxInput.setSignalLowFlow(reactorInfo.fieldDrainRate)
        return
    end
    --if reactorInfo.fieldStrength/reactorInfo.maxFieldStrength >= 0.5 then
    --    fluxInput.setSignalLowFlow(2*reactorInfo.fieldDrainRate)
    --else
        fluxInput.setSignalLowFlow(1000000)
    --end
end            
            
buttonY, buttonWidth, buttonHeight =  22, 6, 1
buttonStopX=4
buttonStartX= 12
buttonClearX= 20
function buttons()
    while true do   
        event, side, xPos, yPos = os.pullEvent("monitor_touch")
        if yPos >= buttonY and yPos <= buttonY + buttonHeight then
            reactorStatus = reactor.getReactorInfo().status
            if xPos >=buttonStopX and xPos <= buttonStopX+buttonWidth then
                
                if reactorStatus == "running" then
                    reactor.stopReactor()
                    logTime("Stopping reactor.")
                    lastTemp = 0
                end
            end
            
            if xPos >=buttonStartX and xPos <= buttonStartX+buttonWidth then
                if reactorStatus ~= "running" then
                    if reactorStatus == "cold" or reactorStatus == "cooling" then
                        reactor.chargeReactor()
                        logTime("Charging reactor")
                    else
                        
                            reactor.activateReactor()
                            logTime("Starting reactor.")
                        
                    end
                end
            end
            
            if xPos >=buttonClearX and xPos <= buttonClearX+buttonWidth then
                
                clearConsole()
            end
        end
    end
end


function updateGUI()
    drawOutlines(mon) 
    drawStaticText(mon)
    drawButtons(mon)
    --sleep(3)
    while true do
        --f.clear(mon)
          
        reactorInfo = reactor.getReactorInfo()
        drawReactorInfo(mon, reactorInfo)
        drawReactorIO(mon, reactorInfo)
        drawReactorStatus(mon, reactorInfo)
        drawConsole(mon)
        
        
        sleep(0.1)
    
        end
    end

function updateIO()
    while true do
        reactorInfo = reactor.getReactorInfo()
        manageOutputPower(reactorInfo)
        if reactorInfo.status == "running" then
            manageFuelEmpty(reactorInfo)
        end
        
        if reactorInfo.status == "warming_up" then 
            manageWarmup(reactorInfo)
        end
        
        if reactorInfo.status ~= "warming_up" then
            manageInputPower(reactorInfo)
        end
        
        lastStatus = reactorInfo.status
        
        sleep(0.1)
    end
end
parallel.waitForAny(buttons, updateGUI, updateIO)
