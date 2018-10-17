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
    if 1 == string.len(
        measured
    ) then
        return 1
    end
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
    form:add_element(
        function(
            data
        )
            return added(
                layout,
                data
            )
        end
    )
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
    ] = field
end

local add_button = function(
    form,
    layout,
    field,
    label,
    handler,
    preparation
)
    local width = string_width(
        label
    )
    local height = 1.5
    local size = width .. "," .. height
    local position = layout:region_position(
        width,
        height
    )
    form:add_element(
        function(
            data
        )
            return "button[" .. position .. ";" .. size .. ";" .. field .. ";" .. label .. "]"
        end
    )
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
    if form.resources[
        field
    ] then
        fatal(
            "duplicate UI handler: " .. field
        )
    end
    form.handlers[
        field
    ] = handler
    form.resources[
        field
    ] = {
    }
    if preparation then
        form.resources[
            field
        ] = preparation(
        )
    end
end

local last_form_id = 0

local new_form = function(
)
    last_form_id = last_form_id + 1
    local constructed = {
        add_button = add_button,
        add_input = add_input,
        form_id = last_form_id,
        last_field = 0,
        last_element = 0,
        add_element = function(
            self,
            layout
        )
            self.last_element = self.last_element + 1
            self.formspec_elements[
                self.last_element
            ] = layout
        end,
        new_field = function(
            self
        )
            self.last_field = self.last_field + 1
            return "edutest_field_" .. self.form_id .. "_" .. self.last_field
        end,
        get_formspec = function(
            self,
            name
        )
            local formspec = ""
            for index, element in ipairs(
                self.formspec_elements
            ) do
                formspec = formspec .. element(
                    self.remembered_fields[
                        name
                    ]
                )
            end
            return formspec
        end,
        formspec_elements = {
        },
        remembered_fields = {
        },
        handlers = {
        },
        inputs = {
        },
        resources = {
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

local player_context_form = {
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
    constructed:add_element(
        function(
            data
        )
            return "size[11,11]"
        end
    )
    constructed:add_element(
        function(
            data
        )
            return "label[0,0;" .. label .. "]"
        end
    )
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
            fields,
            form
        )
            local name = player:get_player_name(
            )
            player_context_form[
                name
            ][
                "inventory"
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
    form,
    context
)
    local installed_context = context
    if not installed_context then
        installed_context = "inventory"
    end
    local name = player:get_player_name(
    )
    if not player_context_form[
        name
    ] then
        player_context_form[
            name
        ] = {
        }
    end
    player_context_form[
        name
    ][
        installed_context
    ] = form
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
        form:get_formspec(
            player:get_player_name(
            )
        )
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
        layout,
        data
    )
        local selected_value = ""
        local selected_index = 1
        local current_index = 1
        if data then
            if data[
                field
            ] then
                selected_value = data[
                    field
                ]
            end
        end
        local entry = choose_student_entry
        if selected_value == entry then
            selected_index = current_index
        end
        local entries = entry
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
                current_index = current_index + 1
                if selected_value == name then
                    selected_index = current_index
                end
                entries = entries .. "," .. name
            end
        )
        local height = 1.5
        return "dropdown[" .. layout:region_position(
            max_width,
            height
        ) .. ";" .. max_width .. ";" .. field .. ";" .. entries .. ";" .. selected_index .. "]"
    end
end

local student_dropdown = function(
    field
)
    return function(
        layout,
        data
    )
        local selected_value = ""
        local selected_index = 1
        local current_index = 1
        if data then
            if data[
                field
            ] then
                selected_value = data[
                    field
                ]
            end
        end
        local entry = all_students_entry
        if selected_value == entry then
            selected_index = current_index
        end
        local entries = entry
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
                    current_index = current_index + 1
                    if selected_value == entry then
                        selected_index = current_index
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
                current_index = current_index + 1
                if selected_value == name then
                    selected_index = current_index
                end
                entries = entries .. "," .. name
            end
        )
        local height = 1.5
        return "dropdown[" .. layout:region_position(
            max_width,
            height
        ) .. ";" .. max_width .. ";" .. field .. ";" .. entries .. ";" .. selected_index .. "]"
    end
end

local basic_student_dropdown_with_groups = function(
    field
)
    return function(
        layout,
        data
    )
        local selected_value = ""
        local selected_index = 1
        local current_index = 1
        if data then
            if data[
                field
            ] then
                selected_value = data[
                    field
                ]
            end
        end
        local entry = choose_student_entry
        if selected_value == entry then
            selected_index = current_index
        end
        local entries = entry
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
                    current_index = current_index + 1
                    if selected_value == entry then
                        selected_index = current_index
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
                current_index = current_index + 1
                if selected_value == name then
                    selected_index = current_index
                end
                entries = entries .. "," .. name
            end
        )
        local height = 1.5
        return "dropdown[" .. layout:region_position(
            max_width,
            height
        ) .. ";" .. max_width .. ";" .. field .. ";" .. entries .. ";" .. selected_index .. "]"
    end
end

local group_dropdown = function(
    field
)
    return function(
        layout,
        data
    )
        local selected_value = ""
        local selected_index = 1
        local current_index = 1
        if data then
            if data[
                field
            ] then
                selected_value = data[
                    field
                ]
            end
        end
        local entry = choose_group_entry
        if selected_value == entry then
            selected_index = current_index
        end
        local entries = entry
        local max_width = string_width(
            entry
        )
        entry = new_group_entry
        current_index = current_index + 1
        if selected_value == entry then
            selected_index = current_index
        end
        local width = string_width(
            entry
        )
        if max_width < width then
            max_width = width
        end
        entries = entries .. "," .. entry
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
                current_index = current_index + 1
                if selected_value == name then
                    selected_index = current_index
                end
                entries = entries .. "," .. name
            end
        )
        local height = 1.5
        return "dropdown[" .. layout:region_position(
            max_width,
            height
        ) .. ";" .. max_width .. ";" .. field .. ";" .. entries .. ";" .. selected_index .. "]"
    end
end

local main_menu_form = new_main_form(
    "EDUtest"
)

local new_sub_form = function(
    label,
    width,
    height
)
    local size
    if not width then
        size = "7,7"
    else
        size = width .. "," .. height
    end
    local constructed = new_form(
    )
    constructed:add_element(
        function(
            data
        )
            return "size[" .. size .. "]"
        end
    )
    constructed:add_element(
        function(
            data
        )
            return "label[0,0;" .. label .. "]"
        end
    )
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
            fields,
            form
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

local highlight_form = new_form(
)

if nil ~= edutest.set_highlight_marker_click_handler then
    local highlight_adapting = {
    }
    highlight_form:add_element(
        function(
            data
        )
            return "size[7,7]"
        end
    )
    highlight_form:add_element(
        function(
            data
        )
            return "label[0,0;" .. S(
                "Adjust area"
            ) .. "]"
        end
    )
    highlight_form:add_button(
        static_layout(
            "0,0.5"
        ),
        highlight_form:new_field(
        ),
        S(
            "Close"
        ),
        function(
            player,
            formname,
            fields,
            form
        )
            local name = player:get_player_name(
            )
            minetest.close_formspec(
                name,
                "highlight"
            )
            return true
        end
    )
    highlight_form:add_button(
        static_layout(
            "2,1.5"
        ),
        highlight_form:new_field(
        ),
        "+",
        function(
            player,
            formname,
            fields,
            form
        )
            local name = player:get_player_name(
            )
            edutest.adapt_highlighted_area(
                name,
                "y",
                "max",
                1
            )
            return true
        end
    )
    highlight_form:add_button(
        static_layout(
            "3,1.5"
        ),
        highlight_form:new_field(
        ),
        "-",
        function(
            player,
            formname,
            fields,
            form
        )
            local name = player:get_player_name(
            )
            edutest.adapt_highlighted_area(
                name,
                "y",
                "max",
                -1
            )
            return true
        end
    )
    highlight_form:add_button(
        static_layout(
            "2,5.5"
        ),
        highlight_form:new_field(
        ),
        "+",
        function(
            player,
            formname,
            fields,
            form
        )
            local name = player:get_player_name(
            )
            edutest.adapt_highlighted_area(
                name,
                "y",
                "min",
                -1
            )
            return true
        end
    )
    highlight_form:add_button(
        static_layout(
            "3,5.5"
        ),
        highlight_form:new_field(
        ),
        "-",
        function(
            player,
            formname,
            fields,
            form
        )
            local name = player:get_player_name(
            )
            edutest.adapt_highlighted_area(
                name,
                "y",
                "min",
                1
            )
            return true
        end
    )
    highlight_form:add_button(
        static_layout(
            "0,3"
        ),
        highlight_form:new_field(
        ),
        "+",
        function(
            player,
            formname,
            fields,
            form
        )
            local name = player:get_player_name(
            )
            edutest.adapt_highlighted_area(
                name,
                highlight_adapting[
                    name
                ].axis,
                highlight_adapting[
                    name
                ].left_extreme,
                -highlight_adapting[
                    name
                ].right_growing
            )
            return true
        end
    )
    highlight_form:add_button(
        static_layout(
            "0,4"
        ),
        highlight_form:new_field(
        ),
        "-",
        function(
            player,
            formname,
            fields,
            form
        )
            local name = player:get_player_name(
            )
            edutest.adapt_highlighted_area(
                name,
                highlight_adapting[
                    name
                ].axis,
                highlight_adapting[
                    name
                ].left_extreme,
                highlight_adapting[
                    name
                ].right_growing
            )
            return true
        end
    )
    highlight_form:add_button(
        static_layout(
            "5,3"
        ),
        highlight_form:new_field(
        ),
        "+",
        function(
            player,
            formname,
            fields,
            form
        )
            local name = player:get_player_name(
            )
            edutest.adapt_highlighted_area(
                name,
                highlight_adapting[
                    name
                ].axis,
                highlight_adapting[
                    name
                ].right_extreme,
                highlight_adapting[
                    name
                ].right_growing
            )
            return true
        end
    )
    highlight_form:add_button(
        static_layout(
            "5,4"
        ),
        highlight_form:new_field(
        ),
        "-",
        function(
            player,
            formname,
            fields,
            form
        )
            local name = player:get_player_name(
            )
            edutest.adapt_highlighted_area(
                name,
                highlight_adapting[
                    name
                ].axis,
                highlight_adapting[
                    name
                ].right_extreme,
                -highlight_adapting[
                    name
                ].right_growing
            )
            return true
        end
    )
    edutest.set_highlight_marker_click_handler(
        function(
            self,
            clicker
        )
            if not self.range then
                print(
                    "EDUtest unexpected marker"
                )
                self.object:remove(
                )
                return
            end
            local name = clicker:get_player_name(
            )
            if self.player_name ~= name then
                if self.player_name then
                    print(
                        "EDUtest owner check mismatch left " .. self.player_name
                    )
                end
                if name then
                    print(
                        "EDUtest owner check mismatch right " .. name
                    )
                end
                minetest.chat_send_player(
                    name,
                    "EDUtest: " .. S(
                        "not your marker"
                    )
                )
                return
            end
            set_current_form_handlers(
                clicker,
                highlight_form,
                "highlight"
            )
            local forward = clicker:get_look_dir(
            )
            local right = {
                x = forward.z,
                y = forward.y,
                z = -forward.x,
            }
            highlight_adapting[
                name
            ] = {
                axis = self.range,
            }
            if 0 <= right[
                self.range
            ] then
                highlight_adapting[
                    name
                ] = {
                    axis = self.range,
                    right_extreme = "max",
                    right_growing = 1,
                    left_extreme = "min",
                }
            else
                highlight_adapting[
                    name
                ] = {
                    axis = self.range,
                    right_extreme = "min",
                    right_growing = -1,
                    left_extreme = "max",
                }
            end
            minetest.show_formspec(
                name,
                "highlight",
                highlight_form:get_formspec(
                    name
                )
            )
        end
    )
end

if nil ~= edutest.set_highlight_marker_tooltip then
    edutest.set_highlight_marker_tooltip(
        S(
            "right-click to adapt area"
        )
    )
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
            fields,
            form,
            field
        )
            local subform = form.resources[
                field
            ].form
            set_current_inventory_form(
                player,
                subform
            )
            return true
        end,
        function(
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
            return {
                form = form
            }
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
        fields,
        form,
        field
    )
        local subform = form.resources[
            field
        ].form
        set_current_inventory_form(
            player,
            subform
        )
        return true
    end,
    function(
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
        return {
            form = form
        }
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
        fields,
        form,
        field
    )
        local subform = form.resources[
            field
        ].form
        set_current_inventory_form(
            player,
            subform
        )
        return true
    end,
    function(
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
        return {
            form = form
        }
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
        fields,
        form,
        field
    )
        local subform = form.resources[
            field
        ].form
        set_current_inventory_form(
            player,
            subform
        )
        return true
    end,
    function(
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
        return {
            form = form
        }
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
            fields,
            form,
            field
        )
            local subform = form.resources[
                field
            ].form
            set_current_inventory_form(
                player,
                subform
            )
            return true
        end,
        function(
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
            return {
                form = form
            }
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
            fields,
            form,
            field
        )
            local subform = form.resources[
                field
            ].form
            set_current_inventory_form(
                player,
                subform
            )
            return true
        end,
        function(
        )
            local form = new_sub_form(
                "EDUtest > " .. S(
                    "Manage groups"
                ),
                7,
                8
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
            return {
                form = form
            }
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
        fields,
        form,
        field
    )
        local subform = form.resources[
            field
        ].form
        set_current_inventory_form(
            player,
            subform
        )
        return true
    end,
    function(
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
        return {
            form = form
        }
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
        fields,
        form,
        field
    )
        local subform = form.resources[
            field
        ].form
        set_current_inventory_form(
            player,
            subform
        )
        return true
    end,
    function(
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
        return {
            form = form
        }
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
            fields,
            form,
            field
        )
            local subform = form.resources[
                field
            ].form
            set_current_inventory_form(
                player,
                subform
            )
            return true
        end,
        function(
        )
            local form = new_sub_form(
                "EDUtest > " .. S(
                    "Area protection"
                ),
                7,
                8
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
            local owner = form:new_field(
            )
            form:add_input(
                static_layout(
                    "0.2,4.2"
                ),
                basic_student_dropdown_with_groups(
                    owner
                ),
                owner
            )
            local area_name = form:new_field(
            )
            form:add_input(
                static_layout(
                    "0.5,6"
                ),
                text_field(
                    area_name,
                    6,
                    1,
                    S(
                        "Name for new area"
                    )
                ),
                area_name
            )
            form:add_button(
                static_layout(
                    "0,7"
                ),
                form:new_field(
                ),
                S(
                    "Assign area"
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
                        owner
                    ) then
                        return false
                    end
                    if choose_student_entry == fields[
                        owner
                    ] then
                        return false
                    end
                    if "" == fields[
                        area_name
                    ] then
                        minetest.chat_send_player(
                            name,
                            "EDUtest: " .. S(
                                "Please enter a name for the area"
                            )
                        )
                        return false
                    end
                    if group_prefix == string.sub(
                        fields[
                            owner
                        ],
                        1,
                        string.len(
                            group_prefix
                        )
                    ) then
                        local group_name = string.sub(
                            fields[
                                owner
                            ],
                            string.len(
                                group_prefix
                            ) + 1
                        )
                        minetest.chatcommands[
                            "highlight_set_owner_group"
                        ].func(
                            name,
                            group_name .. " " .. fields[
                                area_name
                            ]
                        )
                        return true
                    end
                    minetest.chatcommands[
                        "highlight_areas"
                    ].func(
                        name,
                        "set_owner " .. fields[
                            owner
                        ] .. " " .. fields[
                            area_name
                        ]
                    )
                    return true
                end
            )
            return {
                form = form
            }
        end
    )
end

if nil ~= minetest.registered_privileges[
    "invincible"
] then
    main_menu_form:add_button(
        main_layout,
        main_menu_form:new_field(
        ),
        S(
            "Toggle invulnerability"
        ),
        function(
            player,
            formname,
            fields
        )
            local name = player:get_player_name(
            )
            if minetest.check_player_privs(
                name,
                {
                    invincible = true
                }
            ) then
                minetest.chatcommands[
                    "revoke"
                ].func(
                    name,
                    name .. " invincible"
                )
            else
                minetest.chatcommands[
                    "grant"
                ].func(
                    name,
                    name .. " invincible"
                )
            end
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
    local contexts = player_context_form[
        name
    ]
    if not contexts then
        return false
    end
    for context, form in pairs(
        contexts
    ) do
        for field, action in pairs(
            form.handlers
        ) do
            if nil ~= fields[
                field
            ] then
                return action(
                    player,
                    formname,
                    fields,
                    form,
                    field
                )
            end
        end
        if fields.quit then
            set_current_inventory_form(
                player,
                form
            )
            return true
        else
            if not form.remembered_fields[
                name
            ] then
                form.remembered_fields[
                    name
                ] = {
                }
            end
            for field_name, field_value in pairs(
                fields
            ) do
                form.remembered_fields[
                    name
                ][
                    field_name
                ] = field_value
            end
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
                    formspec = main_menu_form:get_formspec(
                        player:get_player_name(
                        )
                    ),
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
                return main_menu_form:get_formspec(
                    player:get_player_name(
                    )
                )
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
