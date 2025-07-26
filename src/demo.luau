--!strict
local jello = require("./")
local internal = require("./internal")

-- showcase
local function checkbox()
	jello.seperator { text = "checkbox" }
	
	jello.checkbox { label = "checkbox with label" }
	
	local box = jello.checkbox()
	jello.text {
		text = `checked: {box.checked()}, clicked: {box.clicked()}, hovered: {box.hovered()}`
	}
end

local function button()
	jello.seperator { text = "button" }

	jello.row()
	
	jello.button { text = "normal button" }
	jello.button { text = "small padding", padding = 1 }
	jello.button { text = "big padding", padding = 8 }
	
	jello.close()
	
	local counter = jello.source(0)
	local increment = jello.source(1)
	
	jello.row()
	
	local btn = jello.button { text = `click me!` }
	jello.text { text = `counter is at {counter()}` }
	
	jello.close()
	
	if btn.clicked() then
		counter( counter() + increment() )
	end
end

local function text()
	jello.seperator { text = "text" }
	
	local richtext = `<b>bold text</b> <i>italic text</i> <u>underline text</u> <s>strikethrough text</s> <font color= "rgb(240, 40, 10)">red text</font> <font size="32">bigger text</font>`
	
	jello.text { text = "default text" }
	jello.text { text = string.rep("wrapped text", 10), wrapped = true }
	jello.text { text = "colored text", color = Color3.fromRGB(255, 128, 0) }
	
	jello.text { text = `richtext: {richtext}`, richText = true, wrapped = true }
end

local function radiobutton()
    jello.seperator { text = "radiobutton" }

    local selected = jello.source("Option 1")
    jello.text { text = "Choose an option:" }
	jello.text { text = `selected: {selected()}` }

    local options = { "Option 1", "Option 2", "Option 3" }

	jello.row()

    for _, option in options do
        jello.radiobutton { index = option, text = option, state = selected }
    end

    jello.close()
end

local function textinput()
    jello.seperator { text = "textinput" }

    local value = jello.source("")
    local input = jello.textinput { multiLine = true, placeholder = "enter your name" }
	if input.text_changed() then
		value(input.text())
	end

    jello.text { text = `value: {value()}` }
end

-- windows
local function runtime_info()
	local window = jello.window {
		title = "runtime info",
	}
	
	local last_update = jello.source(-1)
	
	local places = 10000
	local ms = jello.source(1/60)
	local avg_ms = math.round(ms() * places)/places
	local avg_fps = math.round((1/avg_ms) * 10)/10
	
	if last_update() + 30 <= internal._tick then
		last_update(internal._tick)
		ms(task.wait())
	end

	jello.seperator { text = "stats" }
	
	jello.text { text = `avarage {avg_ms} ms/frame ({avg_fps} fps)` }
	jello.text { text = `current tick: {internal._tick}` }
	jello.text { text = `window position: {window.position()}` }
	
	jello.close()
end

local function recursive_window()
	local window = jello.window {
		title = "recursive window",
		noMinimize = true,
		noResize = true,
		noClose = false,
	}
	local checkbox = jello.checkbox { label = "recurse again" }
	
	window.size( vector.create(200, 100) )
	jello.close()
	
	if checkbox.checked() then
		recursive_window()
	end
end

local function bind_checkbox_to_source(label: string, source: jello.source<boolean>)
	local checkbox = jello.checkbox { label = label }
	source(checkbox.checked())
end

local function run_if(condition: jello.source<boolean>, fn: () -> ())
	if condition() then fn() end
end

return function()
	local state = {
		show_recursive_window = jello.source(false),
		show_runtime_info = jello.source(false),
	}
	
	jello.window({ title = "jello demo" }).with(function()
		jello.text { text = `wazzup ({jello.version})` }
		
		bind_checkbox_to_source("recursive window", state.show_recursive_window)
		bind_checkbox_to_source("runtime info", state.show_runtime_info)
		
		text()
		checkbox()
		button()
		radiobutton()
		textinput()
	end)
	
	run_if(state.show_recursive_window, recursive_window)
	run_if(state.show_runtime_info, runtime_info)
end