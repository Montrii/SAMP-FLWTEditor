script_name("FLWTEditor")
script_author("Montri")
script_version("1.0")
script_description("Allows you to edit fog, lods, weather and time.")



require"lib.moonloader"
require"lib.sampfuncs"
local raknet = require"lib.samp.raknet"
local ffi =			require "ffi"
local events = require 'lib.samp.events.core'
local utils = require 'lib.samp.events.utils'
local handler	= require 'lib.samp.events.handlers'
            	require 'lib.samp.events.extra_types'
local sampevents = require "lib.samp.events"
local inicfg = require "inicfg"
local imgui = require "imgui"
local ec = require "encoding"
local moon = require "MoonAdditions"
local fa         = require 'fAwesome5'
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
local lfs        = require 'lfs'
local memory = require("memory")

ec.default = 'CP1251'
u8 = ec.UTF8

path = getWorkingDirectory() .. '\\config\\Montris Folder\\'
cfg = path .. 'FDWTEditor.ini'

local fog_dist = ffi.cast('float *', 0x00B7C4F0)
local lods_dist = ffi.cast('float *', 0x00858FD8)

function blankIni()
	fdwt = {
		weather = 5,
        time = 20,
        fog = 360,
        lods = 1000,
	}
	saveIni()
end

function loadIni()
	local f = io.open(cfg, "r")
	if f then
		fdwt = decodeJson(f:read("*all"))
		f:close()
	end
end

function saveIni()
	if type(fdwt) == "table" then
		local f = io.open(cfg, "w")
		f:close()
		if f then
			local f = io.open(cfg, "r+")
			f:write(encodeJson(fdwt))
			f:close()
		end
	end
end

local fsFont = nil
function imgui.BeforeDrawFrame()
	if fa_font == nil then
		local font_config = imgui.ImFontConfig()
		font_config.MergeMode = true
		fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 13.0, font_config, fa_glyph_ranges)
	end
    if fsFont == nil then
        fsFont = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 25.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
end

if not doesDirectoryExist(path) then createDirectory(path) end
if doesFileExist(cfg) then loadIni() else blankIni() end


local main_window_state = imgui.ImBool(false)
local fog_distance = imgui.ImInt(fdwt.fog)
local weather_setting = imgui.ImInt(fdwt.weather)
local time_setting = imgui.ImInt(fdwt.time)
local lods_setting = imgui.ImInt(fdwt.lods)
function imgui.OnDrawFrame()
	if main_window_state.v then
		local sw, sh = getScreenResolution() -- Get Screenresolution to make perfect results.
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(450, 255), imgui.Cond.FirstUseEver)
		imgui.Begin("", main_window_state.v, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar)
		imgui.PushFont(fsFont) imgui.CenterTextColoredRGB('FLWTEditor') imgui.PopFont()
        if imgui.SliderInt(fa.ICON_FA_SMOKING .. ' Fog Distance', fog_distance, 0, 3600) then
            setFogLod(1,fog_distance.v)
        end 
        imgui.Text("Or use /fogd <0 | 3600>")
        if imgui.SliderInt(fa.ICON_FA_SMOKING .. ' Lods', lods_setting, 0, 1000) then
            setFogLod(2,lods_setting.v)
        end 
        imgui.Text("Or use /lod <0 | 1000>")
        if imgui.SliderInt(fa.ICON_FA_SUN .. ' Weather', weather_setting, 0, 45) then
            setTimeWeather(2, weather_setting.v)
        end 
        imgui.Text("Or use /sw <0 | 45>")
        if imgui.SliderInt(fa.ICON_FA_CLOCK .. ' Time (Hours)', time_setting, 0, 23) then
            setTimeWeather(1, time_setting.v)
        end 
        imgui.Text("Or use /st <0 | 23>")
        saveTitle = fa.ICON_FA_SAVE .. " Save"
        if imgui.Button(saveTitle, imgui.ImVec2(60,30)) then
            fdwt.fog = fog_distance.v
            fdwt.lods = lods_setting.v
            fdwt.weather = weather_setting.v
            fdwt.time = time_setting.v
            saveIni()
        end 
        imgui.SameLine()
        loadTitle = fa.ICON_FA_DOWNLOAD .. " Load"
        if imgui.Button(loadTitle, imgui.ImVec2(60,30)) then
            loadIni()
            fog_distance.v = fdwt.fog
            lods_setting.v = fdwt.lods
            weather_setting.v = fdwt.weather
            time_setting.v = fdwt.time
            setFogLod(1,fog_distance.v)
            setFogLod(2,lods_setting.v)
            setTimeWeather(2, weather_setting.v)
            setTimeWeather(1, time_setting.v)
        end 
        imgui.End()
    end 
end 


function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("{33FFDD}[FLWTEditor] {FFFFFF}Coded by Montri.")
    sampRegisterChatCommand("fdwt", editor)
    sampRegisterChatCommand("sw", cmd_setweather)
    sampRegisterChatCommand("st", cmd_settime)
    sampRegisterChatCommand("fogd", cmd_setFog)
    sampRegisterChatCommand("lods", cmd_setLods)
    setFogLod(1, fdwt.fog)
    setFogLod(2, fdwt.lods)
    setTimeWeather(1, fdwt.time)
    setTimeWeather(2, fdwt.weather)
    while true do
        wait(0)
        if time then
            setTimeOfDay(time, 0)
        end
		imgui.Process = main_window_state.v
    end 
end 

function editor()
    main_window_state.v = not main_window_state.v
end 

function cmd_setFog(params)
    local value = tonumber(params)
    if value > 3600.0 or value < 0 then return false end
        fog_dist[0] = value
        fog_distance.v = value
        fdwt.fog = value
        saveIni()
end 

function cmd_setLods(params)
    local value = tonumber(params)
    if value > 1000.0 or value < 0 then return false end
    lods_dist[0] = value
    lods_setting.v = value
    fdwt.lods = value
    saveIni()
end 

function setFogLod(number, value)
    if number == 1 then
        if value > 3600.0 or value < 0 then return false end
        fog_dist[0] = value
        fdwt.fog = value
        saveIni()
    end 
    if number == 2 then
        if value > 1000.0 or value < 0 then return false end
        lods_dist[0] = value
        fdwt.lods = value
        saveIni()
    end 
end 

function setTimeWeather(number, value)
    if number == 1 then
        if value ~= nil and value >= 0 and value <= 23 then
            time = value
            time_setting.v = value
            timeSet(true)
            saveIni()
        else
            timeSet(false)
            time = nil
        end
    end 
    if number == 2 then
        if value ~= nil and value >= 0 and value <= 45 then
            weather_setting.v = value
          forceWeatherNow(value)
          saveIni()
        end
    end 
end 
function cmd_settime(param)
    local hour = tonumber(param)
    if hour ~= nil and hour >= 0 and hour <= 23 then
      time = hour
      time_setting.v = hour
      timeSet(true)
      sampAddChatMessage("{33FFDD}[FLWTEditor] {FFFFFF}Successfully changed time!")
      saveIni()
    else
      timeSet(false)
      time = nil
    end
  end
  
  function cmd_setweather(param)
    local weather = tonumber(param)
    if weather ~= nil and weather >= 0 and weather <= 45 then
        weather_setting.v = weather
      forceWeatherNow(weather)
      sampAddChatMessage("{33FFDD}[FLWTEditor] {FFFFFF}Successfully changed weather!")
      saveIni()
    end
  end
  

function timeSet(enable)
	if enable and default == nil then
		default = readMemory(sampGetBase() + 0x9C0A0, 4, true)
		writeMemory(sampGetBase() + 0x9C0A0, 4, 0x000008C2, true)
	elseif enable == false and default ~= nil then
		writeMemory(sampGetBase() + 0x9C0A0, 4, default, true)
		default = nil
	end
end


function imgui.CenterTextColoredRGB(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            imgui.SetCursorPosX( width / 2 - text_width .x / 2 )
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function imgui.TextColoredRGB(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function imgui.Hint(text, delay)
    if imgui.IsItemHovered() then
        if go_hint == nil then go_hint = os.clock() + (delay and delay or 0.0) end
        local alpha = (os.clock() - go_hint) * 5 --spawn rate
        if os.clock() >= go_hint then 
            imgui.PushStyleVar(imgui.StyleVar.Alpha, (alpha <= 1.0 and alpha or 1.0))
                imgui.PushStyleColor(imgui.Col.PopupBg, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
                    imgui.BeginTooltip()
                    imgui.PushTextWrapPos(450)
                    imgui.TextUnformatted(text)
                    if not imgui.IsItemVisible() and imgui.GetStyle().Alpha == 1.0 then go_hint = nil end
                    imgui.PopTextWrapPos()
                    imgui.EndTooltip()
                imgui.PopStyleColor()
            imgui.PopStyleVar()
        end
    end
end
