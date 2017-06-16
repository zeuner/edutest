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

local button_handlers = {
}

local set_main_menu_button_handlers

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
            set_main_menu_button_handlers(
                player
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

local set_current_form_handlers = function(
    player,
    form
)
    local name = player:get_player_name(
    )
    button_handlers[
        name
    ] = {
    }
    for k, v in pairs(
        form.handlers
    ) do
        button_handlers[
            name
        ][
            k
        ] = v
    end
end

local set_current_inventory_form = function(
    player,
    form
)
    set_current_form_handlers(
        player,
        form
    )
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

local main_menu_form = new_form(
)

main_menu_form.formspec = main_menu_form.formspec .. "label[0,0;EDUtest]"

local main_menu_row = 0.5

add_button(
    main_menu_form,
    "0," .. main_menu_row,
    "2,1.5",
    "edutest_freeze",
    "Freeze",
    function(
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
)

main_menu_row = main_menu_row + 2

add_button(
    main_menu_form,
    "0," .. main_menu_row,
    "2,1.5",
    "edutest_creative",
    "Creative Mode",
    function(
        player,
        formname,
        fields
    )
        local form = new_sub_form(
            "EDUtest > Creative Mode"
        )
        form.formspec = form.formspec .. student_dropdown(
            "subject"
        )
        add_button(
            form,
            "0,3",
            "2,1.5",
            "edutest_do_grant",
            "Enable",
            function(
                player,
                formname,
                fields
            )
                local name = player:get_player_name(
                )
                if nil == fields[
                    "subject"
                ] then
                    print(
                        "EDUtest unexpected condition: subject field empty"
                    )
                    field_debug_dump(
                        name,
                        formname,
                        fields
                    )
                    return false
                end
                if "All students" == fields[
                    "subject"
                ] then
                    minetest.chatcommands[
                        "every_student"
                    ].func(
                        name,
                        "grant subject creative"
                    )
                    return true
                end
                minetest.chatcommands[
                    "grant"
                ].func(
                    name,
                    fields[
                        "subject"
                    ] .. " creative"
                )
                return true
            end
        )
        add_button(
            form,
            "3,3",
            "2,1.5",
            "edutest_do_revoke",
            "Disable",
            function(
                player,
                formname,
                fields
            )
                local name = player:get_player_name(
                )
                if nil == fields[
                    "subject"
                ] then
                    print(
                        "EDUtest unexpected condition: subject field empty"
                    )
                    field_debug_dump(
                        name,
                        formname,
                        fields
                    )
                    return false
                end
                if "All students" == fields[
                    "subject"
                ] then
                    minetest.chatcommands[
                        "every_student"
                    ].func(
                        name,
                        "revoke subject creative"
                    )
                    return true
                end
                minetest.chatcommands[
                    "revoke"
                ].func(
                    name,
                    fields[
                        "subject"
                    ] .. " creative"
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
)

main_menu_row = main_menu_row + 2

set_main_menu_button_handlers = function(
    player
)
    set_current_form_handlers(
        player,
        main_menu_form
    )
end

minetest.register_on_joinplayer(
    function(
        player
    )
        set_main_menu_button_handlers(
            player
        )
    end
)

minetest.register_on_player_receive_fields(
    function(
        player,
        formname,
        fields
    )
        local name = player:get_player_name(
        )
        for k, v in pairs(
            button_handlers[
                name
            ]
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
            return {
                formspec = main_menu_form.formspec,
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
