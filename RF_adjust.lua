--[[
	----------------------------------------------------------------------------
	App using a numeric Sensor Data to display as text
	----------------------------------------------------------------------------
	MIT License
   
	Hiermit wird unentgeltlich jeder Person, die eine Kopie der Software und der
	zugehörigen Dokumentationen (die "Software") erhält, die Erlaubnis erteilt,
	sie uneingeschränkt zu nutzen, inklusive und ohne Ausnahme mit dem Recht, sie
	zu verwenden, zu kopieren, zu verändern, zusammenzufügen, zu veröffentlichen,
	zu verbreiten, zu unterlizenzieren und/oder zu verkaufen, und Personen, denen
	diese Software überlassen wird, diese Rechte zu verschaffen, unter den
	folgenden Bedingungen: 
	Der obige Urheberrechtsvermerk und dieser Erlaubnisvermerk sind in allen Kopien
	oder Teilkopien der Software beizulegen. 
	DIE SOFTWARE WIRD OHNE JEDE AUSDRÜCKLICHE ODER IMPLIZIERTE GARANTIE BEREITGESTELLT,
	EINSCHLIEßLICH DER GARANTIE ZUR BENUTZUNG FÜR DEN VORGESEHENEN ODER EINEM
	BESTIMMTEN ZWECK SOWIE JEGLICHER RECHTSVERLETZUNG, JEDOCH NICHT DARAUF BESCHRÄNKT.
	IN KEINEM FALL SIND DIE AUTOREN ODER COPYRIGHTINHABER FÜR JEGLICHEN SCHADEN ODER
	SONSTIGE ANSPRÜCHE HAFTBAR ZU MACHEN, OB INFOLGE DER ERFÜLLUNG EINES VERTRAGES,
	EINES DELIKTES ODER ANDERS IM ZUSAMMENHANG MIT DER SOFTWARE ODER SONSTIGER
	VERWENDUNG DER SOFTWARE ENTSTANDEN. 
	----------------------------------------------------------------------------
--]]

setmetatable(_G, {
	__newindex = function(array, key, value)
		print(string.format("Changed _G: %s = %s", tostring(key), tostring(value)));
		rawset(array, key, value);
	end
});

collectgarbage()
----------------------------------------------------------------------
Global_adjTable = {}
Global_RF_changed_func = {}
Global_RF_changed = false
Global_TurbineState = ""

-- Locals for the application

local RF_adjustVersion = "1.1"
local dir = "Apps/Rotorflight/"
local dirpartGov = "/"..dir.."gov_"
local dirpartAdjfunc = "/"..dir.."adjfunc_"
local dirModels = dir.."/models/"
local dirGov, dirAdjfunc

local funcLabel, funcId, funcParam
local valueLabel, valueId, valueParam
local governorLabel, governorId, governorParam
local Label = {}
local ID = {}
local Param = {}
local aktPIDprofile, aktRATEprofile = "9","9"
local pidval, rateval = 0, 0

local adj_func = "No function"
local adj_val = 0
local funcTemp, valueTemp, governorTemp = 0, -999, -999
local funcTempstr ="F999"
local switch
local sensoLalist = {"..."}
local sensoIdlist = {"..."}
local sensoPalist = {"..."}

local trans, wave
local lng
local lngGB = false
local model

--------------------------------------------------------------------------------
-- Draw telemetry-window
local function printAdjFunction()
	--lcd.drawText(2,6,"T-Status:",FONT_MINI)
	lcd.drawText(0,1,adj_func.." = "..adj_val,FONT_NORMAL)
end

local function printGovernor()
	--lcd.drawText(2,6,"T-Status:",FONT_MINI)
	lcd.drawText(75-lcd.getTextWidth(FONT_BIG,Global_TurbineState)/2,1,Global_TurbineState,FONT_BIG)
end


----------------------------------------------------------------------
-- Store settings when changed by user
local function funcChanged(value)
	funcLabel = value
	system.pSave("funcLabel",value)
	funcId = string.format("%s", sensoIdlist[value])
	funcParam = string.format("%s", sensoPalist[value])
	if (funcId == "...") then
		funcId = 0
		funcParam = 0
		adj_func = "No function"
    end
	system.pSave("funcId", funcId)
	system.pSave("funcParam", funcParam)
end

local function valueChanged(value)
	valueLabel = value
	system.pSave("valueLabel",value)
	valueId = string.format("%s", sensoIdlist[value])
	valueParam = string.format("%s", sensoPalist[value])
	if (valueId == "...") then
		valueId = 0
		valueParam = 0
		adj_val = 0
    end
	system.pSave("valueId", valueId)
	system.pSave("valueParam", valueParam)
end

local function governorChanged(value)
	governorLabel = value
	system.pSave("governorLabel",value)
	governorId = string.format("%s", sensoIdlist[value])
	governorParam = string.format("%s", sensoPalist[value])
	if (governorId == "...") then
		governorId = 0
		governorParam = 0
		Global_TurbineState = ""
    end
	system.pSave("governorId", governorId)
	system.pSave("governorParam", governorParam)
end

local function InputChanged(name, value)
	Label[name] = value
	system.pSave(name,value)
	ID[name] = string.format("%s", sensoIdlist[value])
	Param[name] = string.format("%s", sensoPalist[value])
	if (ID[name] == "...") then
		ID[name] = 0
		Param[name] = 0
    end
	system.pSave(name.."ID", ID[name])
	system.pSave(name.."Param", Param[name])
end

----------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function initForm()
	local cbIndex
	form.setTitle("RF-adjustments:")

	form.addRow(2)	
	form.addLabel({label=trans.adjfunction, width = 160, alignRight = false})
	form.addSelectbox(sensoLalist,funcLabel,true,funcChanged, {alignRight = true})
	
	form.addRow(2)	
	form.addLabel({label=trans.adjvalue, width = 160, alignRight = false})
	form.addSelectbox(sensoLalist,valueLabel,true,valueChanged, {alignRight = true})
	
	form.addSpacer(300,20)
	
	form.addRow(2)	
	form.addLabel({label=trans.governor, width = 160, alignRight = false})
	form.addSelectbox(sensoLalist,governorLabel,true,governorChanged, {alignRight = true})
		
	form.addRow(2)
	form.addLabel({label=trans.announcement, width = 160, alignRight = false})
	form.addInputbox(switch, true,
		function (value)
			switch = value
			system.pSave("switch",value) 
		end)
		
	if lng == "en" then
		form.addRow(2)	
		form.addLabel({label="GB voice ?", width = 160, alignRight = false})
		cbIndex = form.addCheckbox(lngGB,
						function(value)
							lngGB = not value
							system.pSave("lngGB",lngGB and 1 or 0 )
							form.setValue(cbIndex,lngGB)
							if lngGB then
								dirAdjfunc = dirpartAdjfunc.."gb".."/"
								dirGov = dirpartGov.."gb".."/"
							else
								dirAdjfunc = dirpartAdjfunc..lng.."/"
								dirGov = dirpartGov..lng.."/"
							end
						end, {width = 15})
	end
		
	form.addSpacer(300,20)
	
	form.addRow(2)	
	form.addLabel({label=trans.PIDprofile, width = 160, alignRight = false})
	form.addSelectbox(sensoLalist,Label.PIDprofile,true,
					function(value)
						InputChanged("PIDprofile", value)
					end, {alignRight = true})
	
	form.addRow(2)	
	form.addLabel({label=trans.RATEprofile, width = 160, alignRight = false})
	form.addSelectbox(sensoLalist,Label.RATEprofile,true,
					function(value)
						InputChanged("RATEprofile", value)
					end, {alignRight = true})
	
	form.addSpacer(300,20)
	
	form.addRow(1)
	form.addLabel({label="dit71 v."..RF_adjustVersion.." ",font=FONT_MINI, alignRight=true})
end
----------------------------------------------------------------------
-- Runtime functions
local function loop()
	local switchValue
	local sensor
	local governorTempstr
	local txtelemetry = system.getTxTelemetry()		
	switchValue = system.getInputsVal(switch)
	
	-- gets the active pid Profile
	sensor = system.getSensorByID(ID.PIDprofile, Param.PIDprofile) 
	if(sensor and sensor.valid) then 
		if sensor.value ~= pidval then
			pidval = sensor.value
			aktPIDprofile = "P"..math.floor(pidval)  --tostring(math.floor(pidval))
			--funcTemp = 0
			--valueTemp = -999
		end
	end	
	
	-- gets the active Rate Profile
	sensor = system.getSensorByID(ID.RATEprofile, Param.RATEprofile) 
	if(sensor and sensor.valid) then
			if sensor.value ~= rateval then
			rateval = sensor.value
			aktRATEprofile = "P"..math.floor(rateval)
			--funcTemp = 0
			--valueTemp = -999
		end
	end	
	
	-- plays the changed function
	sensor = system.getSensorByID(funcId, funcParam) 
	if(sensor and sensor.valid) then
		if sensor.value ~= funcTemp then
			valueTemp = -999
			funcTemp = sensor.value
			funcTempstr = "F"..math.floor(funcTemp)
			if funcTemp < 14 then
				Global_RF_changed_func[funcTempstr..aktRATEprofile] = true
			else
				Global_RF_changed_func[funcTempstr..aktPIDprofile] = true
			end
			Global_RF_changed = true
			adj_func = trans[funcTempstr] or funcTempstr
			if switchValue == 1 then
				if wave[funcTempstr] then
					for _,aktwave in ipairs(wave[funcTempstr]) do
						system.playFile(dirAdjfunc..aktwave..".wav",AUDIO_QUEUE) 
					end	
				else
					system.playNumber(funcTemp,0)
				end
			end		
		end
	end
	
	-- plays the changed value
	sensor = system.getSensorByID(valueId, valueParam) 
	if(sensor and sensor.valid) then
		if sensor.value ~= valueTemp then
			valueTemp = sensor.value
			adj_val = math.floor(valueTemp)
			if funcTemp > 13 then
				if not Global_adjTable[funcTempstr] then Global_adjTable[funcTempstr] = {} end
				Global_RF_changed = true
				Global_adjTable[funcTempstr][aktPIDprofile] = adj_val
				Global_RF_changed_func[funcTempstr..aktPIDprofile] = true
				if switchValue==1 then system.playNumber(adj_val,0) end	
			elseif funcTemp > 0 then
				Global_RF_changed = true
				if not Global_adjTable[funcTempstr] then Global_adjTable[funcTempstr] = {} end
				Global_adjTable[funcTempstr][aktRATEprofile] = adj_val
				Global_RF_changed_func[funcTempstr..aktRATEprofile] = true
				if switchValue==1 then system.playNumber(adj_val,0) end		
			end			
		end
	end

	--plays the governor status
	sensor = system.getSensorByID(governorId, governorParam) 
	if(sensor and sensor.valid) then
		if sensor.value ~= governorTemp then
			governorTemp = sensor.value 
			governorTempstr = "G"..tostring(math.floor(governorTemp))
			Global_TurbineState = trans[governorTempstr] or governorTempstr
			if switchValue == 1 then 
				if wave[governorTempstr] then
					for _,aktwave in ipairs(wave[governorTempstr]) do
							system.playFile(dirGov..aktwave..".wav",AUDIO_QUEUE) 
					end
				else
					system.playNumber(governorTemp,0)
				end
			end		
		end
	end	
	
	if txtelemetry.rx1Percent < 1 and txtelemetry.rx2Percent < 1 and txtelemetry.rxBPercent < 1 then
		local obj = json.encode(Global_adjTable)
		local file = io.open(dirModels..model..".jsn", "w+")		
		if file then
			io.write(file,obj)
			io.close(file)
		end
	end
end
----------------------------------------------------------------------
-- Application initialization
local function init()
	system.registerForm(1,MENU_MAIN,"RF-adjustments",initForm)
	
	funcLabel = system.pLoad("funcLabel",0)
	funcId = system.pLoad("funcId",0)
	funcParam = system.pLoad("funcParam",0)
	valueLabel = system.pLoad("valueLabel",0)
	valueId = system.pLoad("valueId",0)
	valueParam = system.pLoad("valueParam",0)
	governorLabel = system.pLoad("governorLabel",0)
	governorId = system.pLoad("governorId",0)
	governorParam = system.pLoad("governorParam",0)
	
		--------------------------------------------------------------------------------
	-- Read available sensors for user to select
	local sensors = system.getSensors()
	for i,sensor in ipairs(sensors) do
		if (sensor.label ~= "") then
			table.insert(sensoLalist, string.format("%s", sensor.label))
			table.insert(sensoIdlist, string.format("%s", sensor.id))
			table.insert(sensoPalist, string.format("%s", sensor.param))
		end
	end
	
		
	for _,i in ipairs{"PIDprofile", "RATEprofile"} do
		Label[i] = system.pLoad(i,0)
		ID[i] = system.pLoad(i.."ID",0)
		Param[i] = system.pLoad(i.."Param",0)
	end
	
	switch = system.pLoad("switch")
	
	system.registerTelemetry(1,"RF adjustments",1,printAdjFunction)
	system.registerTelemetry(2,"Governor",1,printGovernor)

	local file
	lng = system.getLocale()
	file = io.readall(dir.."RF_adjust_lang.jsn")
	local obj = json.decode(file)
	if(obj) then
		trans = obj[lng] or obj[obj.default]
		wave = obj["wave"]
	end
	if system.pLoad("lngGB",0) == 1 then lngGB = true end
	if lng == "en" and lngGB then
		dirAdjfunc = dirpartAdjfunc.."gb".."/"
		dirGov = dirpartGov.."gb".."/"
	else
		dirAdjfunc = dirpartAdjfunc..lng.."/"
		dirGov = dirpartGov..lng.."/"
	end	
	
	model = system.getProperty("Model") or ""
	file = io.readall(dirModels..model..".jsn") 
	if file then Global_adjTable = json.decode(file) end
end
----------------------------------------------------------------------

return {init=init, loop=loop, author="dit71", version=RF_adjustVersion, name="RF-adjustments"}