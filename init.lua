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
    end
)

unified_inventory.register_page(
    "edutest",
    {
        get_formspec = function(
            player
        )
            local formspec = "label[0,0;EDUtest]"
	    formspec = formspec .. "button[2,0;4,0.5;testfield;Test]"
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
