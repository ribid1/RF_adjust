--[[
	----------------------------------------------------------------------------
	app um Notizen zu dem Modellen anzuzeigen und abzuspeichern, in max. 10 Zeilen und 10 Spalten
	----------------------------------------------------------------------------
	
	MIT License

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
   
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
	
	
	Version 1.0: 
	
	https://github.com/ribid1/Notizbuch

--]]--------------------------------------------------------------------------------


-- nach unbeabsichtigten globalen Variablen suchen
setmetatable(_G, {
	__newindex = function(array, key, value)
		print(string.format("Changed _G: %s = %s", tostring(key), tostring(value)));
		rawset(array, key, value);
	end
});

local Version = "1.0"
local trans
local widthScr = 320
local heightScr = 160
local rows, columns, fontdef, frame, frameb
local fontInt
local height
local windows = 2
local borderX  = 2
local borderY
local startY
local yText
local startX = {}
local xText = {}
local widthTab = {}
local widthNr, widthFunc, widthP0
local maxRow, maxCol
local Colcount --Table
local sortadjTable
local colwin = {}
colwin[0] = 0
local RF_changed_func
local adjTable


local test = 0

local function calc()
	local tempwidth
	local ProfileCount
	local ProfileSort
	local fontConstants = {FONT_MINI, FONT_NORMAL, FONT_BOLD, FONT_MAXI}
	fontdef = fontConstants[fontInt]
	
	if fontInt == 1 then
		borderY = -1.5
	elseif fontInt == 4 then
		borderY = -4
	else
		borderY = -2
	end
	widthNr = lcd.getTextWidth(fontdef,"000")
	widthP0 = (widthNr-lcd.getTextWidth(fontdef,"P0")) / 2
	widthNr = widthNr + borderX*2 + frame
	local heightmin  = lcd.getTextHeight(fontdef, "0") + frame + borderY * 2
	local heightmax  = heightmin * 1.5
	height = math.floor((heightScr + borderY*2 - frame - frame*borderY*2)/(rows+1))
	if height < heightmin then
		height = heightmin
	elseif height > heightmax then 
		height = heightmax 
	end
	startY  = math.floor(((heightScr) - height * (rows+1) - frame)/2) - borderY -- für Rahmen
	yText = startY + math.floor((height-heightmin)/2) + borderY -- für Text
	
	widthFunc = {}
	Colcount = {}
	maxCol = {}
	adjTable = Global_adjTable
	RF_changed_func = Global_RF_changed_func
	sortadjTable = {}
	
	for i,j in pairs(adjTable) do
		table.insert(sortadjTable, i)
	end
	maxRow = #sortadjTable
	table.sort(sortadjTable)
	
	colwin[1] = math.min(columns, math.ceil(maxRow/rows))
	colwin[2] = math.min(windows * columns, math.ceil(maxRow/rows))
	for i = 1, colwin[2] do
		tempwidth = 0
		widthFunc[i] = 0
		Colcount[i] = {}
		ProfileCount = {}
		ProfileSort = {}
		for j = (i-1) * rows + 1, math.min(i * rows, maxRow) do
			tempwidth = lcd.getTextWidth(fontdef,trans[sortadjTable[j]]) + borderX*2 + frame
			if tempwidth > widthFunc[i] then widthFunc[i] = tempwidth end
			for k in pairs(adjTable[sortadjTable[j]]) do
				ProfileCount[k] = string.byte(k,-1)-48       
			end		
		end
		for h, k in pairs(ProfileCount) do
			table.insert(ProfileSort, h)
		end
		table.sort(ProfileSort)
		for l, m in ipairs(ProfileSort) do
			Colcount[i][m] = l
		end	
		maxCol[i] = #ProfileSort	
		
		widthTab[i] = frame + frame*borderX*2 - borderX*2 + widthFunc[i] + widthNr * maxCol[i]
		if columns == 1 or i % 2 == 1 then 
			startX[i] = (widthScr - widthTab[i])/2
			xText[i] = startX[i] + frame + frame * borderX
		elseif i % 2 == 0 then
			startX[i-1] = (widthScr - widthTab[i-1] - widthTab[i])/3
			startX[i] = startX[i-1] * 2 + widthTab[i-1]
			xText[i-1] = startX[i-1] + frame + frame * borderX
			xText[i] = startX[i] + frame + frame * borderX
		end	
	end	

	-- if maxCol > 3 and columns == 2 then widthFunc = 68 end
	
end

local function showPage(window)
	local x, y
	local val
	for icol = colwin[window-1] + 1, colwin[window] do
		y = yText	
		lcd.drawText(xText[icol], y, "Profile:", fontdef)
		x = xText[icol] + widthFunc[icol]
		for p,r in pairs(Colcount[icol]) do
			lcd.drawText(x + widthNr * (r - 1) + widthP0, y, p, fontdef)
		end
		y = y + height
		for i = (icol - 1) * rows + 1, math.min(icol * rows, maxRow) do   --print Zeilen
			lcd.drawText(xText[icol], y, trans[sortadjTable[i]], fontdef)
			x = xText[icol] + widthFunc[icol]
			for p,r in pairs(adjTable[sortadjTable[i]]) do  --print Spalten
				val = math.floor(r)
				--print("sortTable:"..sortadjTable[i].."P"..string.byte(p,-1)-48)
				if RF_changed_func[sortadjTable[i].."P"..string.byte(p,-1)-48] then
					lcd.setColor(250,0,0)
					lcd.drawText(x + widthNr *Colcount[icol][p] - lcd.getTextWidth(fontdef, val) - borderX*2 - frame, y, val, fontdef)
					lcd.setColor(0,0,0)
				else
					lcd.drawText(x + widthNr *Colcount[icol][p] - lcd.getTextWidth(fontdef, val) - borderX*2 - frame, y, val, fontdef)
				end
			end
			y = y + height
		end
		
		if frameb then
			x = startX[icol] + widthTab[icol] - 1
			y = startY
			lcd.drawLine(startX[icol], y, x, y)
			for i = 1, rows+1 do --horizontal
				y = y + height
				lcd.drawLine(startX[icol], y, x, y)
			end
			x = startX[icol]
			lcd.drawLine(x, startY, x, y)
			x = x + widthFunc[icol]
			lcd.drawLine(x, startY, x, y)
			for i = 1, maxCol[icol] do  --vertikal
				x = x + widthNr
				lcd.drawLine(x, startY, x, y)
			end
		end
	end
end

local function showPage1(width, height)
	widthScr = width+1 
	heightScr = height+1
	return showPage(1)
end

local function showPage2(width, height)
	widthScr = width+1 
	heightScr = height+1
	return showPage(2)
end

local function setupForm1()
	local fontOptions = {"Mini", "Normal", "Bold", "Maxi"}
	local cbIndex
	form.addRow(2)
	form.addLabel({label = trans.Zeilen, width=200})
	form.addIntbox(rows, 1, 18, 2, 0, 1, 
		function(value)
			rows = value
			system.pSave("rows",rows)
			Global_RF_changed = true
		end)

	form.addRow(2)
	form.addLabel({label = trans.Spalten, width=200})
	form.addIntbox(columns, 1, 2, 2, 0, 1,
		function(value)
			columns = value
			system.pSave("columns",columns)
			Global_RF_changed = true
		end)
	
	form.addRow(2)
	form.addLabel({label = trans.Schrift, width=200})
	form.addSelectbox(fontOptions, fontInt, false, function(value)
		fontInt = value
		system.pSave("fontInt",fontInt)
		Global_RF_changed = true
	end)

	form.addRow(2)
	form.addLabel({label = trans.Rahmen, width=275})
	cbIndex = form.addCheckbox(frameb, function(value)
		 frameb = not value
		 if frameb then 
			frame = 1
		else 
			frame = 0
		end
		 form.setValue(cbIndex, not value)
		 system.pSave("frame",frame)
		 Global_RF_changed = true
	end)
	
	form.addSpacer(1, 7)
	form.addRow(1)
	form.addLabel({label="Designed by dit71 - v."..Version, font=FONT_MINI, alignRight=false, enabled=false})
end

local function loop()
	if Global_RF_changed and not form.getActiveForm() then
		calc()
		Global_RF_changed = false
		test = test +1
	end
end

local function init()
	local dir = "Apps/Rotorflight/"
	local dirModels = dir.."/models/"
	local pages
	local model
	local file
	local lng
	local obj
	
	rows = system.pLoad("rows",10)
	columns = system.pLoad("columns",2)
	fontInt = system.pLoad("fontInt",1)
	frame = system.pLoad("frame",1)
	frameb = frame == 1

	pages = {showPage1, showPage2}
	model = system.getProperty("Model") or ""
	
	lng = system.getLocale()
	file = io.readall(dir.."RF_adjust_lang.jsn")
	obj = json.decode(file)
	if obj then
		trans = obj[lng] or obj[obj.default]
	end
	

	if Global_adjTable then
		adjTable = Global_adjTable
	else
		file = io.readall(dirModels..model..".jsn") 
		if file then 
			adjTable = json.decode(file) 
		else
			adjTable = {}
		end
	end		
		
	calc()
	if not RF_changed_func then RF_changed_func = {} end
	
	local r,g,b   = lcd.getBgColor()
	if (r+g+b)/3 > 128 then
	    r,g,b = 0,0,0
	else
	    r,g,b = 255,255,255
	end
	lcd.setColor(r,g,b)
	
	system.registerForm(1, MENU_MAIN, "RF_adj_scr_1", setupForm1)
	for w=1, windows do
		system.registerTelemetry(w,"RF-adj_scr_1 - "..model.." - Page "..w, 4, pages[w])   -- full size Window
	end
end

return {init=init, loop=loop, author="dit71", version=Version, name = "RF_adj_scr_1"}