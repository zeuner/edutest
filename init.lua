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

local check_field = function(
    name,
    formname,
    fields,
    checked
)
    if nil == fields[
        checked
    ] then
        print(
            "EDUtest unexpected condition: " .. checked .. " field empty"
        )
        field_debug_dump(
            name,
            formname,
            fields
        )
        return false
    end
    return true
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

local string_width = function(
    measured
)
    local proportional = math.ceil(
        string.len(
            measured
        ) / 7
    )
    if 2 > proportional then
        return 2
    end
    return proportional
end

local vertical_layout = function(
)
    return {
        row = 0.5,
        column = 0,
        region_position = function(
            self,
            width,
            height
        )
            local result = self.column .. "," .. self.row
            self.row = self.row + 1
            return result
        end,
    }
end

local static_layout = function(
    position
)
    return {
        region_position = function(
            self,
            width,
            height
        )
            return position
        end
    }
end

local add_button = function(
    form,
    layout,
    field,
    label,
    handler
)
    local width = string_width(
        label
    )
    local height = 1.5
    local size = width .. "," .. height
    form.formspec = form.formspec .. "button[" .. layout:region_position(
        width,
        height
    ) .. ";" .. size .. ";" .. field .. ";" .. label .. "]"
    form.handlers[
        field
    ] = handler
end

local button_handlers = {
}

local set_main_menu_button_handlers

local S

if minetest.get_modpath(
    "intllib"
) then
    S = intllib.Getter(
    )
else
    S = function(
        translated
    )
        return translated
    end
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
        static_layout(
            "0,0.5"
        ),
        "edutest_back",
        S(
            "Back"
        ),
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

local all_students_entry = S(
    "All students"
)

local choose_student_entry = S(
    "Choose student"
)

local basic_student_dropdown = function(
    field
)
    local entries = choose_student_entry
    local max_width = string_width(
        entries
    )
    edutest.for_all_students(
        function(
            player,
            name
        )
            local width = string_width(
                name
            )
            if max_width < width then
                max_width = width
            end
            entries = entries .. "," .. name
        end
    )
    return "dropdown[0,2;" .. max_width .. ";" .. field .. ";" .. entries .. ";1]"
end

local student_dropdown = function(
    field
)
    local entries = all_students_entry
    local max_width = string_width(
        entries
    )
    edutest.for_all_students(
        function(
            player,
            name
        )
            local width = string_width(
                name
            )
            if max_width < width then
                max_width = width
            end
            entries = entries .. "," .. name
        end
    )
    return "dropdown[0,2;" .. max_width .. ";" .. field .. ";" .. entries .. ";1]"
end

local main_layout = vertical_layout(
)

local main_menu_form = new_form(
)

main_menu_form.formspec = main_menu_form.formspec .. "label[0,0;EDUtest]"

if nil ~= minetest.chatcommands[
    "freeze"
] then
    add_button(
        main_menu_form,
        main_layout,
        "edutest_freeze",
        S(
            "Freeze"
        ),
        function(
            player,
            formname,
            fields
        )
            local form = new_sub_form(
                "EDUtest > " .. S(
                    "Freeze"
                )
            )
            form.formspec = form.formspec .. student_dropdown(
                "frozen"
            )
            add_button(
                form,
                static_layout(
                    "0,3"
                ),
                "edutest_do_freeze",
                S(
                    "Freeze"
                ),
                function(
                    player,
                    formname,
                    fields
                )
                    local name = player:get_player_name(
                    )
                    if false == check_field(
                        name,
                        formname,
                        fields,
                        "frozen"
                    ) then
                        return false
                    end
                    if all_students_entry == fields[
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
                static_layout(
                    "3,3"
                ),
                "edutest_do_unfreeze",
                S(
                    "Unfreeze"
                ),
                function(
                    player,
                    formname,
                    fields
                )
                    local name = player:get_player_name(
                    )
                    if false == check_field(
                        name,
                        formname,
                        fields,
                        "frozen"
                    ) then
                        return false
                    end
                    if all_students_entry == fields[
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
end

add_button(
    main_menu_form,
    main_layout,
    "edutest_creative",
    S(
        "Creative Mode"
    ),
    function(
        player,
        formname,
        fields
    )
        local form = new_sub_form(
            "EDUtest > " .. S(
                "Creative Mode"
            )
        )
        form.formspec = form.formspec .. student_dropdown(
            "subject"
        )
        add_button(
            form,
            static_layout(
                "0,3"
            ),
            "edutest_do_grant",
            S(
                "Enable"
            ),
            function(
                player,
                formname,
                fields
            )
                local name = player:get_player_name(
                )
                if false == check_field(
                    name,
                    formname,
                    fields,
                    "subject"
                ) then
                    return false
                end
                if all_students_entry == fields[
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
            static_layout(
                "3,3"
            ),
            "edutest_do_revoke",
            S(
                "Disable"
            ),
            function(
                player,
                formname,
                fields
            )
                local name = player:get_player_name(
                )
                if false == check_field(
                    name,
                    formname,
                    fields,
                    "subject"
                ) then
                    return false
                end
                if all_students_entry == fields[
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

add_button(
    main_menu_form,
    main_layout,
    "edutest_visit",
    S(
        "Teleport to student"
    ),
    function(
        player,
        formname,
        fields
    )
        local form = new_sub_form(
            "EDUtest > " .. S(
                "Teleport to student"
            )
        )
        form.formspec = form.formspec .. basic_student_dropdown(
            "subject"
        )
        add_button(
            form,
            static_layout(
                "0,3"
            ),
            "edutest_do_teleport",
            S(
                "Teleport"
            ),
            function(
                player,
                formname,
                fields
            )
                local name = player:get_player_name(
                )
                if false == check_field(
                    name,
                    formname,
                    fields,
                    "subject"
                ) then
                    return false
                end
                if choose_student_entry == fields[
                    "subject"
                ] then
                    return false
                end
                minetest.chatcommands[
                    "teleport"
                ].func(
                    name,
                    name .. " " .. fields[
                        "subject"
                    ]
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

if rawget(
    _G,
    "pvpplus"
) then
    add_button(
        main_menu_form,
        main_layout,
        "edutest_pvp",
        S(
            "PvP"
        ),
        function(
            player,
            formname,
            fields
        )
            local form = new_sub_form(
                "EDUtest > " .. S(
                    "PvP"
                )
            )
            form.formspec = form.formspec .. student_dropdown(
                "subject"
            )
            add_button(
                form,
                static_layout(
                    "0,3"
                ),
                "edutest_do_enable",
                S(
                    "Enable"
                ),
                function(
                    player,
                    formname,
                    fields
                )
                    local name = player:get_player_name(
                    )
                    if false == check_field(
                        name,
                        formname,
                        fields,
                        "subject"
                    ) then
                        return false
                    end
                    if all_students_entry == fields[
                        "subject"
                    ] then
                        edutest.for_all_students(
                            function(
                                player,
                                name
                            )
                                pvpplus.pvp_enable(
                                    name
                                )
                            end
                        )
                        return true
                    end
                    pvpplus.pvp_enable(
                        fields[
                            "subject"
                        ]
                    )
                    return true
                end
            )
            add_button(
                form,
                static_layout(
                    "3,3"
                ),
                "edutest_do_disable",
                S(
                    "Disable"
                ),
                function(
                    player,
                    formname,
                    fields
                )
                    local name = player:get_player_name(
                    )
                    if false == check_field(
                        name,
                        formname,
                        fields,
                        "subject"
                    ) then
                        return false
                    end
                    if all_students_entry == fields[
                        "subject"
                    ] then
                        edutest.for_all_students(
                            function(
                                player,
                                name
                            )
                                pvpplus.pvp_disable(
                                    name
                                )
                            end
                        )
                        return true
                    end
                    pvpplus.pvp_disable(
                        fields[
                            "subject"
                        ]
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
end

add_button(
    main_menu_form,
    main_layout,
    "edutest_chat",
    S(
        "Messaging"
    ),
    function(
        player,
        formname,
        fields
    )
        local form = new_sub_form(
            "EDUtest > " .. S(
                "Messaging"
            )
        )
        form.formspec = form.formspec .. student_dropdown(
            "subject"
        )
        add_button(
            form,
            static_layout(
                "0,3"
            ),
            "edutest_do_grant",
            S(
                "Enable"
            ),
            function(
                player,
                formname,
                fields
            )
                local name = player:get_player_name(
                )
                if false == check_field(
                    name,
                    formname,
                    fields,
                    "subject"
                ) then
                    return false
                end
                if all_students_entry == fields[
                    "subject"
                ] then
                    minetest.chatcommands[
                        "every_student"
                    ].func(
                        name,
                        "grant subject shout"
                    )
                    return true
                end
                minetest.chatcommands[
                    "grant"
                ].func(
                    name,
                    fields[
                        "subject"
                    ] .. " shout"
                )
                return true
            end
        )
        add_button(
            form,
            static_layout(
                "3,3"
            ),
            "edutest_do_revoke",
            S(
                "Disable"
            ),
            function(
                player,
                formname,
                fields
            )
                local name = player:get_player_name(
                )
                if false == check_field(
                    name,
                    formname,
                    fields,
                    "subject"
                ) then
                    return false
                end
                if all_students_entry == fields[
                    "subject"
                ] then
                    minetest.chatcommands[
                        "every_student"
                    ].func(
                        name,
                        "revoke subject shout"
                    )
                    return true
                end
                minetest.chatcommands[
                    "revoke"
                ].func(
                    name,
                    fields[
                        "subject"
                    ] .. " shout"
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

add_button(
    main_menu_form,
    main_layout,
    "edutest_fly",
    S(
        "Fly Mode"
    ),
    function(
        player,
        formname,
        fields
    )
        local form = new_sub_form(
            "EDUtest > " .. S(
                "Fly Mode"
            )
        )
        form.formspec = form.formspec .. student_dropdown(
            "subject"
        )
        add_button(
            form,
            static_layout(
                "0,3"
            ),
            "edutest_do_grant",
            S(
                "Enable"
            ),
            function(
                player,
                formname,
                fields
            )
                local name = player:get_player_name(
                )
                if false == check_field(
                    name,
                    formname,
                    fields,
                    "subject"
                ) then
                    return false
                end
                if all_students_entry == fields[
                    "subject"
                ] then
                    minetest.chatcommands[
                        "every_student"
                    ].func(
                        name,
                        "grant subject fly"
                    )
                    return true
                end
                minetest.chatcommands[
                    "grant"
                ].func(
                    name,
                    fields[
                        "subject"
                    ] .. " fly"
                )
                return true
            end
        )
        add_button(
            form,
            static_layout(
                "3,3"
            ),
            "edutest_do_revoke",
            S(
                "Disable"
            ),
            function(
                player,
                formname,
                fields
            )
                local name = player:get_player_name(
                )
                if false == check_field(
                    name,
                    formname,
                    fields,
                    "subject"
                ) then
                    return false
                end
                if all_students_entry == fields[
                    "subject"
                ] then
                    minetest.chatcommands[
                        "every_student"
                    ].func(
                        name,
                        "revoke subject fly"
                    )
                    return true
                end
                minetest.chatcommands[
                    "revoke"
                ].func(
                    name,
                    fields[
                        "subject"
                    ] .. " fly"
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
        tooltip = "EDUtest",
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
