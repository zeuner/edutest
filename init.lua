minetest.register_on_player_receive_fields(
    function(
        player,
        formname,
        fields
    )
        print(
	    "EDUtest received button press"
	)
	print(
	    "EDUtest player: " .. player:get_player_name(
	    )
	)
	print(
	    "EDUtest form: " .. formname
	)
	for k,v in pairs(
            fields
	) do
	    print(
	        "EDUtest field: " .. k .. " | " .. v
	    )
        end
	if nil ~= fields[
	    "edutest_back"
        ] then
	    unified_inventory.set_inventory_formspec(
	        player,
		"edutest"
	    )
	    return true
	elseif nil ~= fields[
	    "edutest_freeze"
        ] then
	    local formspec = "size[7,7]"
	    formspec = formspec .. "label[0,0;EDUtest > Freeze]"
	    formspec = formspec .. "button[0,2;2,2.5;edutest_back;Back]"
	    player:set_inventory_formspec(
	        formspec
	    )
	    return true
        end
        return false
    end
)

unified_inventory.register_page(
    "edutest",
    {
        get_formspec = function(
            player
        )
            local formspec = "label[0,0;EDUtest]"
	    formspec = formspec .. "button[0,2;2,2.5;edutest_freeze;Freeze]"
            return {
                formspec = formspec,
            }
        end,
    }
)

unified_inventory.register_button(
    "edutest",
    {
        type = "image",
        image = "edutest_gui.png",
    }
)
