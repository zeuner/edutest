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

local new_form = function(
)
    local constructed = {
        formspec = "",
        handlers = {
        },
    }
    return constructed
end

local add_button = function(
    form,
    position,
    size,
    field,
    label,
    handler
)
    form.formspec = form.formspec .. "button[" .. position .. ";" .. size .. ";" field .. ";" .. label .. "]"
    form.handlers[
        field
    ] = handler
end

local new_sub_form = function(
    label
)
    local constructed = new_form(
    )
    constructed.formspec = constructed.formspec .. "size[7,7]"
    constructed.formspec = constructed.formspec .. "label[0,0;" .. label .. "]"
    add_button(
        constructed,
        "0,0.5",
        "2,1.5",
        "edutest_back",
        "Back",
        function(
            player,
            formname,
            fields
        )
            button_handlers = {
            }
            set_main_menu_button_handlers(
            )
            unified_inventory.set_inventory_formspec(
                player,
                "edutest"
            )
            return true
        end
    )
    return constructed
end

local set_current_inventory_form = function(
    player,
    form
)
    for k, v in pairs(
        form.handlers
    ) do
        button_handlers = {
        }
        button_handlers[
            k
        ] = v
    end
    player:set_inventory_formspec(
        form.formspec
    )
end

local student_dropdown = function(
    field
)
    local dropdown = "dropdown[0,2;2;" .. field .. ";All students"
    edutest.for_all_students(
        function(
            player,
            name
        )
            dropdown = dropdown .. "," .. name
        end
    )
    dropdown = dropdown .. ";1]"
    return dropdown
end

local button_handlers = {
}

local set_main_menu_button_handlers

set_main_menu_button_handlers = function(
)
    button_handlers[
        "edutest_freeze"
    ] = function(
        player,
        formname,
        fields
    )
        local form = new_sub_form(
            "EDUtest > Freeze"
        )
        form.formspec = form.formspec .. student_dropdown(
	    "frozen"
	)
        add_button(
            form,
            "0,3",
            "2,1.5",
            "edutest_do_freeze",
            "Freeze",
            function(
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
            end
        )
        add_button(
            form,
            "3,3",
            "2,1.5",
            "edutest_do_unfreeze",
            "Unfreeze",
            function(
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
            end
        )
        set_current_inventory_form(
	    player,
	    form
        )
        return true
    end
end

set_main_menu_button_handlers(
)

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
