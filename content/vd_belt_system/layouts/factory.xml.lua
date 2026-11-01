local K = require("kompot:kompot")
local WM = require("wooden_meat_menu:wm_ds")

local handle
local selected_recipe = K.state(nil)

local RECIPES = {
	{
		id = "stone",
		title = "STONE",
		icon = "blocks:stone",
		description = "Process raw stone materials into construction blocks",
	},
	{
		id = "glass",
		title = "GLASS",
		icon = "blocks:glass",
		description = "Craft glass products from sand and silica",
	},
	{
		id = "metall",
		title = "METAL",
		icon = "blocks:metall",
		description = "Forge metal components and industrial parts",
	},
}

local FactoryScreen = K.component(function()
	K.Box({
		modifier = K.M:fill_max_size():background("#0E1715"):padding(40),
	}, function()
		K.Column({
			modifier = K.M:fill_max_size(),
			spacing = 32,
		}, function()
			K.Box({
				modifier = K.M
					:fill_max_width()
					:height(80)
					:background("#2EC4B6", K.Shape.rectangle())
					:border(6, "#0B2B26", K.Shape.rectangle())
					:offset(-4, -4)
					:padding(24),
			}, function()
				K.Box({
					modifier = K.M:match_parent_size():offset(8, 8):background("#0B2B26", K.Shape.rectangle()),
				})
				K.Box({
					modifier = K.M:match_parent_size():offset(-4, -4):padding(24),
				}, function()
					K.Text("FACTORY", {
						style = "display",
						color = "#0B2B26",
						bold = true,
					})
				end)
			end)

			K.Row({
				modifier = K.M:fill_max_width(),
				spacing = 24,
				align = "center",
			}, function()
				for _, recipe in ipairs(RECIPES) do
					WM.RecipeCard({
						title = recipe.title,
						icon = recipe.icon,
						description = recipe.description,
						selected = selected_recipe.value == recipe.id,
						on_click = function()
							selected_recipe.value = recipe.id
							print("Selected recipe: " .. recipe.id)
						end,
					})
				end
			end)

			K.Box({
				modifier = K.M:fill_max_width():margin_top("auto"),
			}, function()
				WM.Button({
					text = "CLOSE",
					variant = "danger",
					fill_width = true,
					on_click = function()
						hud.close("vd_belt_system:factory")
					end,
				})
			end)
		end)
	end)
end)

function on_open()
	handle = K.mount({
		target = document.root,
		theme = WM.theme(),
		content = FactoryScreen,
		interactive = true,
		lock_inventory = true,
	})
end

function on_close()
	if handle then
		handle:dispose()
		handle = nil
	end
	selected_recipe.value = nil
end
