local field_debug_dump = function(
    name,
    formname,
    fields
)
    print(
        "EDUtest received player fields"
    )
    print(
        "EDUtest player: " .. name
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

local button_handlers = {
    edutest_back = function(
        player,
        formname,
        fields
    )
        unified_inventory.set_inventory_formspec(
            player,
            "edutest"
        )
        return true
    end,
    edutest_freeze = function(
        player,
        formname,
        fields
    )
        local formspec = "size[7,7]"
        formspec = formspec .. "label[0,0;EDUtest > Freeze]"
        formspec = formspec .. "button[0,0.5;2,1.5;edutest_back;Back]"
        local dropdown = "dropdown[0,2;2;frozen;All students"
        edutest.for_all_students(
            function(
                player,
                name
            )
                dropdown = dropdown .. "," .. name
            end
        )
        dropdown = dropdown .. ";1]"
        formspec = formspec .. dropdown
        formspec = formspec .. "button[0,3;2,1.5;edutest_do_freeze;Freeze]"
        formspec = formspec .. "button[3,3;2,1.5;edutest_do_unfreeze;Unfreeze]"
        player:set_inventory_formspec(
            formspec
        )
        return true
    end,
    edutest_do_freeze = function(
        player,
        formname,
        fields
    )
        local name = player:get_player_name(
        )
        if nil == fields[
            "frozen"
        ] then
            print(
                "EDUtest unexpected condition: frozen field empty"
            )
            field_debug_dump(
                name,
                formname,
                fields
            )
            return false
        end
        if "All students" == fields[
            "frozen"
        ] then
            minetest.chatcommands[
                "every_student"
            ].func(
                name,
                "freeze subject"
            )
            return true
        end
        minetest.chatcommands[
            "freeze"
        ].func(
            name,
            fields[
                "frozen"
            ]
        )
        return true
    end,
    edutest_do_unfreeze = function(
        player,
        formname,
        fields
    )
        local name = player:get_player_name(
        )
        if nil == fields[
            "frozen"
        ] then
            print(
                "EDUtest unexpected condition: frozen field empty"
            )
            field_debug_dump(
                name,
                formname,
                fields
            )
            return false
        end
        if "All students" == fields[
            "frozen"
        ] then
            minetest.chatcommands[
                "every_student"
            ].func(
                name,
                "unfreeze subject"
            )
            minetest.chatcommands[
                "every_student"
            ].func(
                name,
                "grant subject interact"
            )
            return true
        end
        minetest.chatcommands[
            "unfreeze"
        ].func(
            name,
            fields[
                "frozen"
            ]
        )
        minetest.chatcommands[
            "grant"
        ].func(
            name,
            fields[
                "frozen"
            ] .. " interact"
        )
        return true
    end,
}

minetest.register_on_player_receive_fields(
    function(
        player,
        formname,
        fields
    )
        for k, v in pairs(
            button_handlers
        ) do
            if nil ~= fields[
                k
            ] then
                return v(
                    player,
                    formname,
                    fields
                )
            end
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
            formspec = formspec .. "button[0,0.5;2,1.5;edutest_freeze;Freeze]"
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
        condition = function(
            player
        )
            return minetest.check_player_privs(
                player:get_player_name(
                ),
                {
                    teacher = true,
                }
            )
        end,
    }
)
