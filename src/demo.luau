--!strict
local jello = require("./")
local internal = require("./internal")

local function hint(text: string)
	local label = jello.text {  text = '(?)', color = Color3.fromRGB(160, 160, 160) }

	if label.hovered() then
		jello.tooltip { text = text }
	end
end

-- showcase
local function checkbox()
	jello.checkbox { label = "checkbox with label" }
	
	local box = jello.checkbox()
	jello.text {
		text = `checked: {box.checked()}, clicked: {box.clicked()}, hovered: {box.hovered()}`
	}
end

local function button()
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
	local richtext = `<b>bold text</b> <i>italic text</i> <u>underline text</u> <s>strikethrough text</s> <font color= "rgb(240, 40, 10)">red text</font> <font size="32">bigger text</font>`
	
	jello.text { text = "default text" }
	jello.text { text = string.rep("wrapped text ", 10), wrapped = true }
	jello.text { text = "colored text", color = Color3.fromRGB(255, 128, 0) }
	
	jello.text { text = `richtext: {richtext}`, richText = true, wrapped = true }
end

local function radiobutton()
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
    local input = jello.textinput { placeholder = "enter your name" }
	if input.text_changed() then
		value(input.text())
	end

    jello.text { text = `value: {value()}` }
end

local function group()
	jello.seperator { text = "centered group" }
	
    jello.group { align = "Center", padding = 10 }.with(function()
        jello.text { text = "this is inside a centered group with padding" }
        jello.button { text = "button" }
        jello.checkbox { label = "checkbox" }
    end)

	jello.seperator { text = "right aligned group" }

	jello.group { align = "Right", padding = 10 }.with(function()
		jello.text { text = "This is inside a right aligned group with padding." }
        jello.button { text = "button" }
        jello.checkbox { label = "checkbox" }
	end)
end

local function indent()
	jello.text { text = "indent level 0" }
    
    jello.indent().with(function()
        jello.text { text = "indented level 1" }
        
        jello.indent().with(function()
            jello.text { text = "indented level 2" }
            
            jello.indent().with(function()
                jello.text { text = "indented level 3" }
                jello.checkbox { label = "indented checkbox" }
            end)

            jello.button { text = "indented button" }
        end)
    end)
end

local function input()
	local number_source = jello.source(0)
	local no_buttons = jello.source(false)
	jello.number { value = number_source, noButtons = no_buttons() }
	jello.text { text = `the number is: {number_source()}` }
	
	local randomize = jello.button { text = "randomize number" }
	if randomize.clicked() then
		number_source(math.random(0, 100))
	end

	local no_buttons_checkbox = jello.checkbox { label = "no buttons" }
	no_buttons( no_buttons_checkbox.checked() )

	jello.seperator()
	jello.row().with(function()
		jello.text { text = "datatypes" }
		hint("ctrl click to drag, click to edit")
	end)

	jello.number()
	jello.vector2()
	jello.vector3()
	jello.udim()
	jello.udim2()
	jello.rect()

	jello.seperator()
	
	local hsv_enabled = jello.source(false)
	local color = jello.source(Color3.new(1, 1, 1))
	jello.color3 { value = color, hsv = hsv_enabled() }

	jello.row().with(function()
		local hsv_checkbox = jello.checkbox { label = "hsv" }
		hsv_enabled(hsv_checkbox.checked())

		local randomize_color = jello.button { text = "randomize color" }
		if randomize_color.clicked() then
			local col = Color3.new( math.random(), math.random(), math.random() )
			color(col)
		end
	end)
	jello.text { text = `the color hex is #{color():ToHex()}` }
end

local function option()
	local selected = jello.source(1)
	local options = { "Option 1", "Option 2", "Option 3" }

	for index, option in options do
		jello.option {
			state = selected,
			text = option,
			value = index,
		}
	end

	jello.text { text = `selected: {options[selected()]}` }
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

	jello.seperator { text = "enviroment data" }
	
	local instance = internal._parent_stack[#internal._parent_stack].Parent :: Instance
	local id = jello.source( internal._instance_to_id[instance] ) 
	local object = internal._vdom[id()]
	local meta = internal._instance_metadata[instance]

	local input = jello.textinput {
		placeholder = "enter an object's id",
		wrapped = true,
		text = id(),
	}

	if input.text_changed() then
		id(input.text())
	end

	if object == nil or meta == nil then
		jello.text { text = "invalid id" }
	else
		local metadata = {
			path = instance:GetFullName(),
			class_name = instance.ClassName,

			properties = object.properties,
			actions = meta.actions,
			connections = meta.connections,
		}

		jello.group { padding = 2 }

		jello.text { text = `path: {metadata.path}` }
		jello.text { text = `class name: {metadata.class_name}` }
		jello.text { text = `actions count: {#metadata.actions}` }
		jello.text { text = `connections count: {#metadata.connections}` }

		jello.close()
	end

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

local function bind_to_section(text: string, fn)
	internal.profile(`demo/{text}`)
	jello.section({ text = text }).with(fn)
	internal.endprofile()
end

local function construct_header(name: string, fn)
	jello.header({ text = name }).with(fn)
end

return function()
	local state = {
		show_recursive_window = jello.source(false),
		show_runtime_info = jello.source(false),
	}

	jello.window({ title = "jello demo" }).with(function(window)
		window.menubar()
			jello.menu("file").with(function()
				jello.menuitem("new   ctrl + n")
				jello.menuitem("open  ctrl + o")
				jello.menuitem("save  ctrl + s")
				
				jello.seperator()

				jello.menuitem("quit  ctrl + q")
			end)

			jello.menu("credits").with(function()
				local grey = Color3.fromRGB(160, 160, 160)
				local blue = Color3.fromRGB(33, 155, 255)
				jello.text { text = "jello by ratplier" }
				jello.text { text = "https://github.com/ratplier/jello", color = blue }

				jello.seperator()

				jello.text { text = "copyright (c) @ratplier", color = grey }
				jello.text { text = "all rights reserved", color = grey }
			end)
		jello.close()

		jello.row().with(function()
			jello.text { text = `jello (v{jello.version})` }
			hint("hover over these components to see useful info")
		end)
		
		bind_checkbox_to_source("recursive window", state.show_recursive_window)
		bind_checkbox_to_source("runtime info", state.show_runtime_info)

		construct_header("widgets", function()
			bind_to_section("text", text)
			bind_to_section("checkbox", checkbox)
			bind_to_section("button", button)
			bind_to_section("radiobutton", radiobutton)
			bind_to_section("textinput", textinput)
			bind_to_section("group", group)
			bind_to_section("indent", indent)
			bind_to_section("input", input)
			bind_to_section("option", option)
		end)
	end)
	
	run_if(state.show_recursive_window, recursive_window)
	run_if(state.show_runtime_info, runtime_info)
end