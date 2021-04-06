-------------------------------------
--Character Tab
--[[
Various Role playing information,
Player stats etc


]]

------------------------------------
--set character name and record start date
minetest.register_on_newplayer(function(player)
  player_api.set_gender(player, "random") --set random gender
  local meta = player:get_meta()
  meta:set_string("char_name", lore.generate_name(3))
  meta:set_int("char_start_date", minetest.get_day_count())
  meta:set_string("bio", lore.generate_bio(player))
end)

minetest.register_on_respawnplayer(function(player)
  player_api.set_gender(player, "random") --set random gender
  local meta = player:get_meta()
  meta:set_string("char_name", lore.generate_name(3))
  meta:set_int("char_start_date", minetest.get_day_count())
  meta:set_string("bio", lore.generate_bio(player))
end)
------------------------------------

--Forms for sfinv


--get data and create form
local function sfinv_get(self, player, context)
	local meta = player:get_meta()
	local name = meta:get_string("char_name")
  local days = minetest.get_day_count() - meta:get_int("char_start_date")
  local effects_list = meta:get_string("effects_list")
  local effects_list = minetest.deserialize(effects_list) or {}
  local bio = meta:get_string("bio")
  --backwards compatibility
  if bio == "" then
    --generate biography
    bio = lore.generate_bio(player)
  end

  local y = 3.1
  local eff_form = ""


  for _, effect in ipairs(effects_list) do
    --convert into readable
    -- (this would be better handled more flexibly, these might not suit all)
    local severity = effect[2] or 0
    if severity == 0 then
      severity = ""
    elseif severity == 1 then
      severity = "(mild)"
    elseif severity == 2 then
      severity = "(moderate)"
    elseif severity == 3 then
      severity = "(severe)"
    elseif severity >= 4 then
      severity = "(extreme)"
    end

    y = y + 0.4
    eff_form = eff_form.."label[0.1,"..y.."; "..effect[1].." "..severity.."]"
  end

	local formspec = "label[0.1,0.1; Name: " .. name .. "]"..
	"label[5,0.1; Days Survived: " .. days .. "]"..
  "label[0.1,1.1; Biography: " .. bio .. "]"..
  "label[0.1,3.1; Health Effects:]"..
  eff_form


	return formspec
end



local function register_tab()
	sfinv.register_page("lore:char_tab", {
		title = "Character",
		--on_enter = function(self, player, context)
			--sfinv.set_player_inventory_formspec(player)
		--end,
		get = function(self, player, context)
			local formspec = sfinv_get(self, player, context)
			return sfinv.make_formspec(player, context, formspec, false)
		end
	})
end

register_tab()
