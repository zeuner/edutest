local die

local fatal = function(
    message
)
    print(
        "FATAL: " .. message
    )
    die(
    )
end

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

local string_width = function(
    measured
)
    local proportional = math.ceil(
        string.len(
            measured
        ) / 7
    )
    return proportional + 1
end

local add_input = function(
    form,
    layout,
    added,
    field
)
    local formspec = added(
        layout
    )
    form.formspec = form.formspec .. formspec
    if form.handlers[
        field
    ] then
        fatal(
            "duplicate UI handler: " .. field
        )
    end
    if form.inputs[
        field
    ] then
        fatal(
            "duplicate UI handler: " .. field
        )
    end
    form.inputs[
        field
    ] = formspec
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
    if form.handlers[
        field
    ] then
        fatal(
            "duplicate UI handler: " .. field
        )
    end
    if form.inputs[
        field
    ] then
        fatal(
            "duplicate UI handler: " .. field
        )
    end
    form.handlers[
        field
    ] = handler
end

local new_form = function(
)
    local constructed = {
        add_button = add_button,
        add_input = add_input,
        last_field = 0,
        new_field = function(
            self
        )
            self.last_field = self.last_field + 1
            return "edutest_field_" .. self.last_field
        end,
        formspec = "",
        handlers = {
        },
        inputs = {
        },
    }
    return constructed
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

local horizontal_layout = function(
    max_width
)
    return {
        max_width = max_width,
        row = 0.5,
        column = 0,
        line_break = function(
            self
        )
            self.column = 0
            self.row = self.row + 1
        end,
        region_position = function(
            self,
            width,
            height
        )
            local new_column = self.column + width
            if max_width <= new_column then
                self.column = 0
                self.row = self.row + 1
                new_column = self.column + width
            end
            local result = self.column .. "," .. self.row
            self.column = new_column
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

local button_handlers = {
}

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

local player_previous_inventory_page = {
}

local default_inventory_page

local set_inventory_page

if rawget(
    _G,
    "unified_inventory"
) then
    default_inventory_page = "craft"
    local old_set_inventory_formspec = unified_inventory.set_inventory_formspec
    unified_inventory.set_inventory_formspec = function(
        player,
        page
    )
        local name = player:get_player_name(
        )
        old_set_inventory_formspec(
            player,
            page
        )
        player_previous_inventory_page[
            name
        ] = page
    end
    set_inventory_page = unified_inventory.set_inventory_formspec
elseif rawget(
    _G,
    "sfinv"
) then
    local player_current_inventory_page = {
    }
    default_inventory_page = "sfinv:crafting"
    local old_set_page = sfinv.set_page
    sfinv.set_page = function(
        player,
        page
    )
        local name = player:get_player_name(
        )
        old_set_page(
            player,
            page
        )
        player_previous_inventory_page[
            name
        ] = player_current_inventory_page[
            name
        ]
        player_current_inventory_page[
            name
        ] = page
    end
    set_inventory_page = function(
        player,
        page
    )
        sfinv.set_page(
            player,
            page
        )
    end
else
    fatal(
        "unsupported inventory implementation"
    )
end

local main_layout = horizontal_layout(
    11
)

local new_main_form = function(
    label
)
    local constructed = new_form(
    )
    constructed.formspec = constructed.formspec .. "size[11,11]"
    constructed.formspec = constructed.formspec .. "label[0,0;" .. label .. "]"
    constructed:add_button(
        main_layout,
        constructed:new_field(
        ),
        S(
            "Back"
        ),
        function(
            player,
            formname,
            fields
        )
            local name = player:get_player_name(
            )
            button_handlers[
                name
            ] = nil
            local old_page = player_previous_inventory_page[
                name
            ]
            if not old_page then
                old_page = default_inventory_page
            end
            set_inventory_page(
                player,
                old_page
            )
            return true
        end
    )
    main_layout:line_break(
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

local choose_group_entry = S(
    "Choose group"
)

local new_group_entry = S(
    "New group (enter name below)"
)

local group_prefix = S(
    "Group"
) .. " "

local text_field = function(
    field,
    width,
    height,
    label
)
    return function(
        layout
    )
        return "field[" .. layout:region_position(
            width,
            height
        ) .. ";" .. width .. "," .. height .. ";" .. field .. ";" .. label .. ";]"
    end
end

local basic_student_dropdown = function(
    field
)
    return function(
        layout
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
        local height = 1.5
        return "dropdown[" .. layout:region_position(
            max_width,
            height
        ) .. ";" .. max_width .. ";" .. field .. ";" .. entries .. ";1]"
    end
end

local student_dropdown = function(
    field
)
    return function(
        layout
    )
        local entries = all_students_entry
        local max_width = string_width(
            entries
        )
        if edutest.for_all_groups then
            edutest.for_all_groups(
                function(
                    name,
                    members
                )
                    local entry = group_prefix .. name
                    local width = string_width(
                        entry
                    )
                    if max_width < width then
                        max_width = width
                    end
                    entries = entries .. "," .. entry
                end
            )
        end
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
        local height = 1.5
        return "dropdown[" .. layout:region_position(
            max_width,
            height
        ) .. ";" .. max_width .. ";" .. field .. ";" .. entries .. ";1]"
    end
end

local group_dropdown = function(
    field
)
    return function(
        layout
    )
        local entries = choose_group_entry
        local max_width = string_width(
            entries
        )
        local width = string_width(
            new_group_entry
        )
        if max_width < width then
            max_width = width
        end
        entries = entries .. "," .. new_group_entry
        edutest.for_all_groups(
            function(
                name,
                members
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
        local height = 1.5
        return "dropdown[" .. layout:region_position(
            max_width,
            height
        ) .. ";" .. max_width .. ";" .. field .. ";" .. entries .. ";1]"
    end
end

local main_menu_form = new_main_form(
    "EDUtest"
)

local new_sub_form = function(
    label
)
    local constructed = new_form(
    )
    constructed.formspec = constructed.formspec .. "size[7,8]"
    constructed.formspec = constructed.formspec .. "label[0,0;" .. label .. "]"
    constructed:add_button(
        static_layout(
            "0,0.5"
        ),
        constructed:new_field(
        ),
        S(
            "Back"
        ),
        function(
            player,
            formname,
            fields
        )
            set_current_inventory_form(
                player,
                main_menu_form
            )
            return true
        end
    )
    return constructed
end

local teleport_command = "teleport"

if nil ~= minetest.chatcommands[
    "visitation"
] then
    teleport_command = "visitation"
end

if nil ~= minetest.chatcommands[
    "freeze"
] then
    main_menu_form:add_button(
        main_layout,
        main_menu_form:new_field(
        ),
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
            local frozen = form:new_field(
            )
            form:add_input(
                static_layout(
                    "0,2"
                ),
                student_dropdown(
                    frozen
                ),
                frozen
            )
            form:add_button(
                static_layout(
                    "0,3"
                ),
                form:new_field(
                ),
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
                        frozen
                    ) then
                        return false
                    end
                    if group_prefix == string.sub(
                        fields[
                            frozen
                        ],
                        1,
                        string.len(
                            group_prefix
                        )
                    ) then
                        local group_name = string.sub(
                            fields[
                                frozen
                            ],
                            string.len(
                                group_prefix
                            ) + 1
                        )
                        minetest.chatcommands[
                            "every_member"
                        ].func(
                            name,
                            group_name .. " freeze subject"
                        )
                        return true
                    end
                    if all_students_entry == fields[
                        frozen
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
                            frozen
                        ]
                    )
                    return true
                end
            )
            form:add_button(
                static_layout(
                    "3,3"
                ),
                form:new_field(
                ),
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
                        frozen
                    ) then
                        return false
                    end
                    if group_prefix == string.sub(
                        fields[
                            frozen
                        ],
                        1,
                        string.len(
                            group_prefix
                        )
                    ) then
                        local group_name = string.sub(
                            fields[
                                frozen
                            ],
                            string.len(
                                group_prefix
                            ) + 1
                        )
                        minetest.chatcommands[
                            "every_member"
                        ].func(
                            name,
                            group_name .. " unfreeze subject"
                        )
                        return true
                    end
                    if all_students_entry == fields[
                        frozen
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
                            frozen
                        ]
                    )
                    minetest.chatcommands[
                        "grant"
                    ].func(
                        name,
                        fields[
                            frozen
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

main_menu_form:add_button(
    main_layout,
    main_menu_form:new_field(
    ),
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
        local subject = form:new_field(
        )
        form:add_input(
            static_layout(
                "0,2"
            ),
            student_dropdown(
                subject
            ),
            subject
        )
        form:add_button(
            static_layout(
                "0,3"
            ),
            form:new_field(
            ),
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
                    subject
                ) then
                    return false
                end
                if group_prefix == string.sub(
                    fields[
                        subject
                    ],
                    1,
                    string.len(
                        group_prefix
                    )
                ) then
                    local group_name = string.sub(
                        fields[
                            subject
                        ],
                        string.len(
                            group_prefix
                        ) + 1
                    )
                    if nil ~= minetest.chatcommands[
                        "creative_hand"
                    ] then
                        minetest.chatcommands[
                            "every_member"
                        ].func(
                            name,
                            group_name .. " creative_hand subject"
                        )
                    end
                    minetest.chatcommands[
                        "every_member"
                    ].func(
                        name,
                        group_name .. " grant subject creative"
                    )
                    return true
                end
                if all_students_entry == fields[
                    subject
                ] then
                    if nil ~= minetest.chatcommands[
                        "creative_hand"
                    ] then
                        minetest.chatcommands[
                            "every_student"
                        ].func(
                            name,
                            "creative_hand subject"
                        )
                    end
                    minetest.chatcommands[
                        "every_student"
                    ].func(
                        name,
                        "grant subject creative"
                    )
                    return true
                end
                if nil ~= minetest.chatcommands[
                    "creative_hand"
                ] then
                    minetest.chatcommands[
                        "creative_hand"
                    ].func(
                        name,
                        fields[
                            subject
                        ]
                    )
                end
                minetest.chatcommands[
                    "grant"
                ].func(
                    name,
                    fields[
                        subject
                    ] .. " creative"
                )
                return true
            end
        )
        form:add_button(
            static_layout(
                "3,3"
            ),
            form:new_field(
            ),
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
                    subject
                ) then
                    return false
                end
                if group_prefix == string.sub(
                    fields[
                        subject
                    ],
                    1,
                    string.len(
                        group_prefix
                    )
                ) then
                    local group_name = string.sub(
                        fields[
                            subject
                        ],
                        string.len(
                            group_prefix
                        ) + 1
                    )
                    if nil ~= minetest.chatcommands[
                        "creative_hand"
                    ] then
                        minetest.chatcommands[
                            "every_member"
                        ].func(
                            name,
                            group_name .. " basic_hand subject"
                        )
                    end
                    minetest.chatcommands[
                        "every_member"
                    ].func(
                        name,
                        group_name .. " revoke subject creative"
                    )
                    return true
                end
                if all_students_entry == fields[
                    subject
                ] then
                    if nil ~= minetest.chatcommands[
                        "basic_hand"
                    ] then
                        minetest.chatcommands[
                            "every_student"
                        ].func(
                            name,
                            "basic_hand subject"
                        )
                    end
                    minetest.chatcommands[
                        "every_student"
                    ].func(
                        name,
                        "revoke subject creative"
                    )
                    return true
                end
                if nil ~= minetest.chatcommands[
                    "basic_hand"
                ] then
                    minetest.chatcommands[
                        "basic_hand"
                    ].func(
                        name,
                        fields[
                            subject
                        ]
                    )
                end
                minetest.chatcommands[
                    "revoke"
                ].func(
                    name,
                    fields[
                        subject
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

main_menu_form:add_button(
    main_layout,
    main_menu_form:new_field(
    ),
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
        local subject = form:new_field(
        )
        form:add_input(
            static_layout(
                "0,2"
            ),
            basic_student_dropdown(
                subject
            ),
            subject
        )
        form:add_button(
            static_layout(
                "0,3"
            ),
            form:new_field(
            ),
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
                    subject
                ) then
                    return false
                end
                if choose_student_entry == fields[
                    subject
                ] then
                    return false
                end
                minetest.chatcommands[
                    teleport_command
                ].func(
                    name,
                    name .. " " .. fields[
                        subject
                    ]
                )
                return true
            end
        )
        if nil ~= minetest.chatcommands[
            "return"
        ] then
            form:add_button(
                static_layout(
                    "3,3"
                ),
                form:new_field(
                ),
                S(
                    "Previous position"
                ),
                function(
                    player,
                    formname,
                    fields
                )
                    local name = player:get_player_name(
                    )
                    minetest.chatcommands[
                        "return"
                    ].func(
                        name,
                        ""
                    )
                    return true
                end
            )
        end
        set_current_inventory_form(
            player,
            form
        )
        return true
    end
)

main_menu_form:add_button(
    main_layout,
    main_menu_form:new_field(
    ),
    S(
        "Bring student"
    ),
    function(
        player,
        formname,
        fields
    )
        local form = new_sub_form(
            "EDUtest > " .. S(
                "Bring student"
            )
        )
        local subject = form:new_field(
        )
        form:add_input(
            static_layout(
                "0,2"
            ),
            student_dropdown(
                subject
            ),
            subject
        )
        form:add_button(
            static_layout(
                "0,3"
            ),
            form:new_field(
            ),
            S(
                "Bring"
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
                    subject
                ) then
                    return false
                end
                if group_prefix == string.sub(
                    fields[
                        subject
                    ],
                    1,
                    string.len(
                        group_prefix
                    )
                ) then
                    local group_name = string.sub(
                        fields[
                            subject
                        ],
                        string.len(
                            group_prefix
                        ) + 1
                    )
                    minetest.chatcommands[
                        "every_member"
                    ].func(
                        name,
                        group_name .. " " .. teleport_command .. " subject " .. name
                    )
                    return true
                end
                if all_students_entry == fields[
                    subject
                ] then
                    minetest.chatcommands[
                        "every_student"
                    ].func(
                        name,
                        teleport_command .. " subject " .. name
                    )
                    return true
                end
                minetest.chatcommands[
                    teleport_command
                ].func(
                    name,
                    fields[
                        subject
                    ] .. " " .. name
                )
                return true
            end
        )
        if nil ~= minetest.chatcommands[
            "return"
        ] then
            form:add_button(
                static_layout(
                    "3,3"
                ),
                form:new_field(
                ),
                S(
                    "Previous position"
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
                        subject
                    ) then
                        return false
                    end
                    if group_prefix == string.sub(
                        fields[
                            subject
                        ],
                        1,
                        string.len(
                            group_prefix
                        )
                    ) then
                        local group_name = string.sub(
                            fields[
                                subject
                            ],
                            string.len(
                                group_prefix
                            ) + 1
                        )
                        minetest.chatcommands[
                            "every_member"
                        ].func(
                            name,
                            group_name .. " return subject"
                        )
                        return true
                    end
                    if all_students_entry == fields[
                        subject
                    ] then
                        minetest.chatcommands[
                            "every_student"
                        ].func(
                            name,
                            "return subject"
                        )
                        return true
                    end
                    minetest.chatcommands[
                        "return"
                    ].func(
                        name,
                        fields[
                            subject
                        ]
                    )
                    return true
                end
            )
        end
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
    main_menu_form:add_button(
        main_layout,
        main_menu_form:new_field(
        ),
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
            local subject = form:new_field(
            )
            form:add_input(
                static_layout(
                    "0,2"
                ),
                student_dropdown(
                    subject
                ),
                subject
            )
            form:add_button(
                static_layout(
                    "0,3"
                ),
                form:new_field(
                ),
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
                        subject
                    ) then
                        return false
                    end
                    if group_prefix == string.sub(
                        fields[
                            subject
                        ],
                        1,
                        string.len(
                            group_prefix
                        )
                    ) then
                        local group_name = string.sub(
                            fields[
                                subject
                            ],
                            string.len(
                                group_prefix
                            ) + 1
                        )
                        edutest.for_all_members(
                            group_name,
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
                    if all_students_entry == fields[
                        subject
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
                            subject
                        ]
                    )
                    return true
                end
            )
            form:add_button(
                static_layout(
                    "3,3"
                ),
                form:new_field(
                ),
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
                        subject
                    ) then
                        return false
                    end
                    if group_prefix == string.sub(
                        fields[
                            subject
                        ],
                        1,
                        string.len(
                            group_prefix
                        )
                    ) then
                        local group_name = string.sub(
                            fields[
                                subject
                            ],
                            string.len(
                                group_prefix
                            ) + 1
                        )
                        edutest.for_all_members(
                            group_name,
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
                    if all_students_entry == fields[
                        subject
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
                            subject
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

if edutest.for_all_groups then
    main_menu_form:add_button(
        main_layout,
        main_menu_form:new_field(
        ),
        S(
            "Manage groups"
        ),
        function(
            player,
            formname,
            fields
        )
            local form = new_sub_form(
                "EDUtest > " .. S(
                    "Manage groups"
                )
            )
            local subject = form:new_field(
            )
            form:add_input(
                static_layout(
                    "0,2"
                ),
                basic_student_dropdown(
                    subject
                ),
                subject
            )
            local group = form:new_field(
            )
            form:add_input(
                static_layout(
                    "0,3"
                ),
                group_dropdown(
                    group
                ),
                group
            )
            local new_group = form:new_field(
            )
            form:add_input(
                static_layout(
                    "0.5,5"
                ),
                text_field(
                    new_group,
                    6,
                    1,
                    S(
                        "Name for new group"
                    )
                ),
                new_group
            )
            form:add_button(
                static_layout(
                    "0,6"
                ),
                form:new_field(
                ),
                S(
                    "Add to group"
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
                        subject
                    ) then
                        return false
                    end
                    if false == check_field(
                        name,
                        formname,
                        fields,
                        group
                    ) then
                        return false
                    end
                    if choose_student_entry == fields[
                        subject
                    ] then
                        return false
                    end
                    local group_name
                    if choose_group_entry == fields[
                        group
                    ] then
                        return false
                    end
                    if new_group_entry == fields[
                        group
                    ] then
                        group_name = fields[
                            new_group
                        ]
                        group_name = string.gsub(
                            group_name,
                            " ",
                            "_"
                        )
                        minetest.chatcommands[
                            "create_group"
                        ].func(
                            name,
                            group_name
                        )
                    else
                        group_name = fields[
                            group
                        ]
                    end
                    minetest.chatcommands[
                        "enter_group"
                    ].func(
                        name,
                        group_name .. " " .. fields[
                            subject
                        ]
                    )
                    return true
                end
            )
            form:add_button(
                static_layout(
                    "0,7"
                ),
                form:new_field(
                ),
                S(
                    "Remove from group"
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
                        subject
                    ) then
                        return false
                    end
                    if false == check_field(
                        name,
                        formname,
                        fields,
                        group
                    ) then
                        return false
                    end
                    if choose_student_entry == fields[
                        subject
                    ] then
                        return false
                    end
                    local group_name
                    if choose_group_entry == fields[
                        group
                    ] then
                        return false
                    end
                    if new_group_entry == fields[
                        group
                    ] then
                        group_name = fields[
                            new_group
                        ]
                        group_name = string.gsub(
                            group_name,
                            " ",
                            "_"
                        )
                        minetest.chatcommands[
                            "create_group"
                        ].func(
                            name,
                            group_name
                        )
                    else
                        group_name = fields[
                            group
                        ]
                    end
                    minetest.chatcommands[
                        "leave_group"
                    ].func(
                        name,
                        group_name .. " " .. fields[
                            subject
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

main_menu_form:add_button(
    main_layout,
    main_menu_form:new_field(
    ),
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
        local subject = form:new_field(
        )
        form:add_input(
            static_layout(
                "0,2"
            ),
            student_dropdown(
                subject
            ),
            subject
        )
        form:add_button(
            static_layout(
                "0,3"
            ),
            form:new_field(
            ),
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
                    subject
                ) then
                    return false
                end
                if group_prefix == string.sub(
                    fields[
                        subject
                    ],
                    1,
                    string.len(
                        group_prefix
                    )
                ) then
                    local group_name = string.sub(
                        fields[
                            subject
                        ],
                        string.len(
                            group_prefix
                        ) + 1
                    )
                    minetest.chatcommands[
                        "every_member"
                    ].func(
                        name,
                        group_name .. " grant subject shout"
                    )
                    return true
                end
                if all_students_entry == fields[
                    subject
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
                        subject
                    ] .. " shout"
                )
                return true
            end
        )
        form:add_button(
            static_layout(
                "3,3"
            ),
            form:new_field(
            ),
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
                    subject
                ) then
                    return false
                end
                if group_prefix == string.sub(
                    fields[
                        subject
                    ],
                    1,
                    string.len(
                        group_prefix
                    )
                ) then
                    local group_name = string.sub(
                        fields[
                            subject
                        ],
                        string.len(
                            group_prefix
                        ) + 1
                    )
                    minetest.chatcommands[
                        "every_member"
                    ].func(
                        name,
                        group_name .. " revoke subject shout"
                    )
                    return true
                end
                if all_students_entry == fields[
                    subject
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
                        subject
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

main_menu_form:add_button(
    main_layout,
    main_menu_form:new_field(
    ),
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
        local subject = form:new_field(
        )
        form:add_input(
            static_layout(
                "0,2"
            ),
            student_dropdown(
                subject
            ),
            subject
        )
        form:add_button(
            static_layout(
                "0,3"
            ),
            form:new_field(
            ),
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
                    subject
                ) then
                    return false
                end
                if group_prefix == string.sub(
                    fields[
                        subject
                    ],
                    1,
                    string.len(
                        group_prefix
                    )
                ) then
                    local group_name = string.sub(
                        fields[
                            subject
                        ],
                        string.len(
                            group_prefix
                        ) + 1
                    )
                    minetest.chatcommands[
                        "every_member"
                    ].func(
                        name,
                        group_name .. " grant subject fly"
                    )
                    return true
                end
                if all_students_entry == fields[
                    subject
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
                        subject
                    ] .. " fly"
                )
                return true
            end
        )
        form:add_button(
            static_layout(
                "3,3"
            ),
            form:new_field(
            ),
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
                    subject
                ) then
                    return false
                end
                if group_prefix == string.sub(
                    fields[
                        subject
                    ],
                    1,
                    string.len(
                        group_prefix
                    )
                ) then
                    local group_name = string.sub(
                        fields[
                            subject
                        ],
                        string.len(
                            group_prefix
                        ) + 1
                    )
                    minetest.chatcommands[
                        "every_member"
                    ].func(
                        name,
                        group_name .. " revoke subject fly"
                    )
                    return true
                end
                if all_students_entry == fields[
                    subject
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
                        subject
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

if nil ~= minetest.chatcommands[
    "area_pos"
] then
    main_menu_form:add_button(
        main_layout,
        main_menu_form:new_field(
        ),
        S(
            "Area protection"
        ),
        function(
            player,
            formname,
            fields
        )
            local form = new_sub_form(
                "EDUtest > " .. S(
                    "Area protection"
                )
            )
            form:add_button(
                static_layout(
                    "0,2"
                ),
                form:new_field(
                ),
                S(
                    "Set corner 1"
                ),
                function(
                    player,
                    formname,
                    fields
                )
                    local name = player:get_player_name(
                    )
                    if nil ~= minetest.chatcommands[
                        "highlight_pos1"
                    ] then
                        minetest.chatcommands[
                            "highlight_pos1"
                        ].func(
                            name,
                            ""
                        )
                    else
                        minetest.chatcommands[
                            "area_pos"
                        ].func(
                            name,
                            "set1"
                        )
                        minetest.chat_send_player(
                            name,
                            S(
                                "Punch a block to set the corner of the area"
                            )
                        )
                    end
                    return true
                end
            )
            form:add_button(
                static_layout(
                    "0,3"
                ),
                form:new_field(
                ),
                S(
                    "Set corner 2"
                ),
                function(
                    player,
                    formname,
                    fields
                )
                    local name = player:get_player_name(
                    )
                    if nil ~= minetest.chatcommands[
                        "highlight_pos2"
                    ] then
                        minetest.chatcommands[
                            "highlight_pos2"
                        ].func(
                            name,
                            ""
                        )
                    else
                        minetest.chatcommands[
                            "area_pos"
                        ].func(
                            name,
                            "set2"
                        )
                        minetest.chat_send_player(
                            name,
                            S(
                                "Punch a block to set the corner of the area"
                            )
                        )
                    end
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

if nil ~= minetest.chatcommands[
    "vanish"
] then
    main_menu_form:add_button(
        main_layout,
        main_menu_form:new_field(
        ),
        S(
            "Toggle invisibility"
        ),
        function(
            player,
            formname,
            fields
        )
            local name = player:get_player_name(
            )
            minetest.chatcommands[
                "vanish"
            ].func(
                name,
                ""
            )
            return true
        end
    )
end

local on_player_receive_fields = function(
    player,
    formname,
    fields
)
    local name = player:get_player_name(
    )
    local handlers = button_handlers[
        name
    ]
    if not handlers then
        return false
    end
    for k, v in pairs(
        handlers
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

minetest.register_on_player_receive_fields(
    on_player_receive_fields
)

if rawget(
    _G,
    "unified_inventory"
) then
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
            action = function(
                player
            )
                local name = player:get_player_name(
                )
                set_current_inventory_form(
                    player,
                    main_menu_form
                )
            end,
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
elseif rawget(
    _G,
    "sfinv"
) then
    sfinv.register_page(
        "edutest:edu",
        {
            title = "EDU",
            get = function(
                self,
                player,
                context
            )
                return main_menu_form.formspec
            end,
            on_enter = function(
                self,
                player,
                context
            )
                set_current_form_handlers(
                    player,
                    main_menu_form
                )
            end,
            is_in_nav = function(
                self,
                player,
                context
            )
                return minetest.check_player_privs(
                    player,
                    {
                        teacher = true,
                    }
                )
            end,
        }
    )
end
