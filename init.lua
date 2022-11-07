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
    for k, v in pairs(
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
    measured,
    granularity,
    lang_code
)
    local translated = minetest.get_translated_string(
        lang_code,
        measured
    )
    if 1 == string.len(
        translated
    ) then
        return granularity
    end
    local proportional = math.ceil(
        string.len(
            translated
        ) / 7 / granularity
    ) * granularity
    return proportional + granularity
end

local remove_input = function(
    form,
    field
)
    form.inputs[
        field
    ] = nil
    form.handlers[
        field
    ] = nil
    form.resources[
        field
    ] = nil
end

local remove_input_prefix = function(
    form,
    prefix
)
    local found = {
    }
    local length = string.len(
        prefix
    )
    for field, _ in pairs(
        form.inputs
    ) do
        if prefix == string.sub(
            field,
            1,
            length
        ) then
            table.insert(
                found,
                field
            )
        end
    end
    for _, field in pairs(
        found
    ) do
        remove_input(
            form,
            field
        )
    end
end

local register_input = function(
    form,
    field,
    handler
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
    form.handlers[
        field
    ] = handler
end

local add_input = function(
    form,
    layout,
    added,
    field_handlers
)
    form:add_element(
        function(
            data,
            resources,
            lang_code
        )
            return added(
                layout,
                data,
                resources,
                lang_code
            )
        end
    )
    local field
    local handler
    for k, v in pairs(
        field_handlers
    ) do
        if 0 == (k % 2) then
            handler = v
            form:register_input(
                field,
                handler
            )
        else
            field = v
        end
    end
end

local register_button = function(
    form,
    field,
    label,
    handler,
    preparation
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

local add_button = function(
    form,
    layout,
    field,
    label,
    handler,
    preparation
)
    form:add_element(
        function(
            data,
            resources,
            lang_code
        )
            local width = string_width(
                label,
                layout.width_granularity,
                lang_code
            )
            local height = 1.5
            local size = width .. "," .. height
            local position = layout:region_position(
                width,
                height,
                0,
                0
            )
            return "button[" .. position .. ";" .. size .. ";" .. field .. ";" .. label .. "]"
        end
    )
    form:register_button(
        field,
        label,
        handler,
        preparation
    )
end

local reset_item_chooser

local add_item_chooser

local last_form_id = 0

local wrap_player = function(
    name
)
    return {
        get_remembered_field = function(
            form
        )
            return form:get_remembered_field(
                name
            )
        end,
        get_lang_code = function(
        )
            return minetest.get_player_information(
                name
            ).lang_code
        end,
    }
end

local wrap_lang_code = function(
    lang_code
)
    return {
        get_remembered_field = function(
            form
        )
            return nil
        end,
        get_lang_code = function(
        )
            return lang_code
        end,
    }
end

local new_form = function(
    base_layout
)
    last_form_id = last_form_id + 1
    local constructed = {
        register_button = register_button,
        register_input = register_input,
        remove_input = remove_input,
        remove_input_prefix = remove_input_prefix,
        add_button = add_button,
        add_input = add_input,
        reset_item_chooser = reset_item_chooser,
        add_item_chooser = add_item_chooser,
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
        get_remembered_field = function(
            self,
            name
        )
            return self.remembered_fields[
                name
            ]
        end,
        get_resources = function(
            self
        )
            return self.resources
        end,
        get_formspec = function(
            self,
            calling
        )
            local formspec = ""
            for index, element in ipairs(
                self.formspec_elements
            ) do
                local resources = self:get_resources(
                )
                formspec = formspec .. element(
                    calling.get_remembered_field(
                        self
                    ),
                    resources,
                    calling.get_lang_code(
                    )
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
        base_layout = base_layout
    }
    return constructed
end

local new_conditional_elements = function(
    base_form
)
    local container = new_form(
    )
    container.base_form = base_form
    local passing = {
        "get_resources",
        "get_remembered_field",
        "new_field",
        "register_input",
        "remove_input",
        "remove_input_prefix",
        "register_button"
    }
    for _, method in pairs(
        passing
    ) do
        container[
            method
        ] = function(
            self,
            ...
        )
            return self.base_form[
                method
            ](
                self.base_form,
                ...
            )
        end
    end
    return container
end

local last_layout_id = 0

local vertical_layout = function(
)
    last_layout_id = last_layout_id + 1
    local row = 0.5
    local column = 0
    return {
        layout_id = last_layout_id,
        row = row,
        column = column,
        row_initial = row,
        column_initial = column,
        width_granularity = 1,
        reset = function(
            self
        )
            self.column = self.column_initial
            self.row = self.row_initial
        end,
        line_break = function(
        )
        end,
        region_position = function(
            self,
            width,
            height,
            offset_column,
            offset_row
        )
            local result = (
                self.column + offset_column
            ) .. "," .. (
                self.row + offset_row
            )
            self.row = self.row + 1
            return result
        end,
    }
end

local horizontal_layout = function(
    max_width
)
    last_layout_id = last_layout_id + 1
    local row = 0.5
    local column = 0
    return {
        layout_id = last_layout_id,
        max_width = max_width,
        row = row,
        column = column,
        row_initial = row,
        column_initial = column,
        width_granularity = 1,
        reset = function(
            self
        )
            self.column = self.column_initial
            self.row = self.row_initial
        end,
        line_break = function(
            self
        )
            self.column = 0
            self.row = self.row + 1
        end,
        region_position = function(
            self,
            width,
            height,
            offset_column,
            offset_row
        )
            local new_column = self.column + width
            if max_width <= new_column then
                self:line_break(
                )
                new_column = self.column + width
            end
            local result = (
                self.column + offset_column
            ) .. "," .. (
                self.row + offset_row
            )
            self.column = new_column
            return result
        end,
    }
end

local horizontal_grid_layout = function(
    column_width,
    max_width
)
    last_layout_id = last_layout_id + 1
    local row = 0.5
    local column = 0
    return {
        layout_id = last_layout_id,
        max_width = max_width,
        column_width = column_width,
        row = row,
        column = column,
        row_initial = row,
        column_initial = column,
        width_granularity = 1,
        reset = function(
            self
        )
            self.column = self.column_initial
            self.row = self.row_initial
        end,
        line_break = function(
            self
        )
            self.column = 0
            self.row = self.row + 1
        end,
        region_position = function(
            self,
            width,
            height,
            offset_column,
            offset_row
        )
            local new_column = self.column + width
            local excess = self.column % self.column_width
            if 0 < excess then
                new_column = new_column + (self.column_width - excess)
            end
            if max_width <= new_column then
                self:line_break(
                )
                new_column = self.column + width
            end
            local result = (
                self.column + offset_column
            ) .. "," .. (
                self.row + offset_row
            )
            self.column = new_column
            return result
        end,
    }
end

local horizontal_grid_adapted_layout = function(
    original_layout,
    new_column_width
)
    return {
        original_layout = original_layout,
        new_column_width = new_column_width,
        width_granularity = original_layout.width_granularity,
        reset = function (
            self
        )
            self.original_layout:reset(
            )
        end,
        line_break = function (
            self
        )
            self.original_layout:line_break(
            )
        end,
        region_position = function(
            self,
            width,
            height,
            offset_column,
            offset_row
        )
            local column_width_old = self.original_layout.column_width
            self.original_layout.column_width = self.new_column_width
            local result = self.original_layout:region_position(
                width,
                height,
                offset_column,
                offset_row
            )
            self.original_layout.column_width = column_width_old
            return result
        end,
    }
end

local static_layout = function(
    position
)
    return {
        line_break = function(
        )
        end,
        width_granularity = 1,
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

local MP = minetest.get_modpath(
    minetest.get_current_modname(
    )
)

local S = minetest.get_translator(
    "edutest"
)

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

local new_main_form = function(
    label,
    base_layout
)
    local constructed = new_form(
        base_layout
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

local set_current_inventory_form = function(
    player,
    form
)
    set_current_form_handlers(
        player,
        form
    )
    if form.base_layout then
        form.base_layout:reset(
        )
    end
    local definition = form:get_formspec(
        wrap_player(
            player:get_player_name(
            )
        )
    )
    player:set_inventory_formspec(
        definition
    )
end

local text_field = function(
    field,
    width,
    height,
    label,
    resource
)
    return function(
        layout,
        data,
        resources
    )
        local value
        if data then
            value = data[
                field
            ]
        end
        if not value then
            value = ""
        end
        if "" == value and resource and resources and resources[resource] then
            value = resources[resource]
        end
        local formspec = "field[" .. layout:region_position(
            width,
            height,
            0.2,
            0.5
        ) .. ";" .. width .. "," .. height .. ";" .. field .. ";" .. label
        formspec = formspec .. ";" .. value .. "]"
        return formspec
    end
end

local show_item_basic = function(
    layout,
    field,
    shown_item
)
    local width = 1
    local height = 1
    local position = layout:region_position(
        width,
        height,
        0.075,
        0.125
    )
    local shown = "item_image_button[" .. position
    shown = shown .. ";" .. width .. "," .. height .. ";"
    shown = shown .. shown_item .. ";" .. field .. "_"
    shown = shown .. shown_item .. ";]"
    return shown
end

reset_item_chooser = function(
    form,
    field
)
    local resources = form:get_resources(
    )
    resources[
        "items_" .. field
    ] = nil
end

add_item_chooser = function(
    form,
    layout,
    field,
    count,
    items,
    show_item,
    handler,
    extra_actions
)
    local adapted = horizontal_grid_adapted_layout(
        layout,
        1
    )
    local resources = form:get_resources(
    )
    if not resources[
        "items_" .. field
    ] then
        resources[
            "items_" .. field
        ] = items
        resources[
            "items_filtered_" .. field
        ] = items
        resources[
            "items_filter_" .. field
        ] = ""
        resources[
            "first_item_" .. field
        ] = 1
    end
    local item_filter = form:new_field(
    )
    form:add_input(
        adapted,
        text_field(
            item_filter,
            4,
            1,
            S(
                "Keyword"
            )
        ),
        {
            item_filter
        }
    )
    form:add_button(
        adapted,
        form:new_field(
        ),
        S(
            "Search"
        ),
        function(
            player,
            formname,
            fields,
            form
        )
            local filter = fields[
                item_filter
            ]
            if resources[
                "items_filter_" .. field
            ] == filter then
                return true
            end
            resources[
                "items_filter_" .. field
            ] = filter
            resources[
                "first_item_" .. field
            ] = 1
            local new_filtered = {
            }
            for _, item_name in pairs(
                resources[
                    "items_" .. field
                ]
            ) do
                if string.find(
                    item_name,
                    filter
                ) then
                    table.insert(
                        new_filtered,
                        item_name
                    )
                end
            end
            resources[
                "items_filtered_" .. field
            ] = new_filtered
            set_current_inventory_form(
                player,
                form
            )
            return true
        end
    )
    form:add_button(
        adapted,
        form:new_field(
        ),
        "<",
        function(
            player,
            formname,
            fields,
            form
        )
            local resources = form:get_resources(
            )
            local decreased = resources[
                "first_item_" .. field
            ] - 1
            if 1 > decreased then
                decreased = 1
            end
            resources[
                "first_item_" .. field
            ] = decreased
            set_current_inventory_form(
                player,
                form
            )
            return true
        end
    )
    form:add_element(
        function(
            data,
            resources
        )
            local buttons = ""
            local first_shown = resources[
                "first_item_" .. field
            ]
            local items = resources[
                "items_filtered_" .. field
            ]
            for shown = 1, count, 1 do
                local shown_absolute = shown + first_shown - 1
                local shown_item = items[
                    shown_absolute
                ]
                if shown_item then
                    buttons = buttons .. show_item(
                        adapted,
                        field,
                        shown_item,
                        form,
                        shown
                    )
                end
            end
            return buttons
        end
    )
    form:add_button(
        adapted,
        form:new_field(
        ),
        ">",
        function(
            player,
            formname,
            fields,
            form
        )
            local resources = form:get_resources(
            )
            local items = resources[
                "items_filtered_" .. field
            ]
            local increased = resources[
                "first_item_" .. field
            ] + 1
            if increased > #items - count + 1 then
                increased = #items - count + 1
            end
            resources[
                "first_item_" .. field
            ] = increased
            set_current_inventory_form(
                player,
                form
            )
            return true
        end
    )
    form:remove_input_prefix(
        field .. "_"
    )
    for index, item in pairs(
        items
    ) do
        form:register_input(
            field .. "_" .. item,
            function(
                player,
                formname,
                fields,
                form
            )
                fields[
                    field
                ] = item
                return handler(
                    player,
                    formname,
                    fields,
                    form
                )
            end
        )
        if extra_actions then
            for _, action in pairs(
                extra_actions
            ) do
                form:register_input(
                    field .. "_" .. item .. "_" .. action,
                    function(
                        player,
                        formname,
                        fields,
                        form
                    )
                        fields[
                            field
                        ] = item
                        fields[
                            field .. "_action"
                        ] = action
                        return handler(
                            player,
                            formname,
                            fields,
                            form
                        )
                    end
                )
            end
        end
    end
end

local all_students_entry = S(
    "All students"
)

local choose_student_entry = S(
    "Choose student"
)

local choose_teacher_entry = S(
    "Choose teacher"
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

local enabled_prefix = "* "

local disabled_prefix = "  "

local without_prefix = function(
    prefixed
)
    if enabled_prefix == string.sub(
        prefixed,
        1,
        string.len(
            enabled_prefix
        )
    ) then
        return string.sub(
            prefixed,
            string.len(
                enabled_prefix
            ) + 1
        )
    end
    if disabled_prefix == string.sub(
        prefixed,
        1,
        string.len(
            disabled_prefix
        )
    ) then
        return string.sub(
            prefixed,
            string.len(
                disabled_prefix
            ) + 1
        )
    end
    return prefixed
end

local dropdown_field = function(
    field,
    height,
    label,
    choices
)
    return function(
        layout,
        data,
        resources,
        lang_code
    )
        local width = string_width(
            label,
            layout.width_granularity,
            lang_code
        )
        local choice_formspec = ""
        for k, v in pairs(
            choices
        ) do
            local choice_width = string_width(
                k,
                layout.width_granularity,
                lang_code
            )
            if choice_width > width then
                width = choice_width
            end
            choice_formspec = choice_formspec .. "," .. k
        end
        local formspec = "dropdown[" .. layout:region_position(
            width,
            height,
            0.1,
            0.25
        ) .. ";" .. width .. ";" .. field .. ";" .. label
        formspec = formspec .. choice_formspec
        return formspec .. ";1]"
    end
end

local password_field = function(
    field,
    width,
    height,
    label
)
    return function(
        layout
    )
        return "pwdfield[" .. layout:region_position(
            width,
            height,
            0.2,
            0.5
        ) .. ";" .. width .. "," .. height .. ";" .. field .. ";" .. label .. "]"
    end
end

local basic_student_dropdown = function(
    field
)
    return function(
        layout,
        data,
        resources,
        lang_code
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
        if without_prefix(
            selected_value
        ) == without_prefix(
            entry
        ) then
            selected_index = current_index
        end
        local entries = entry
        local max_width = string_width(
            entries,
            layout.width_granularity,
            lang_code
        )
        edutest.for_all_students(
            function(
                player,
                name
            )
                local width = string_width(
                    name,
                    layout.width_granularity,
                    lang_code
                )
                if max_width < width then
                    max_width = width
                end
                current_index = current_index + 1
                if without_prefix(
                    selected_value
                ) == without_prefix(
                    name
                ) then
                    selected_index = current_index
                end
                entries = entries .. "," .. name
            end
        )
        local height = 1.5
        return "dropdown[" .. layout:region_position(
            max_width,
            height,
            0,
            0
        ) .. ";" .. max_width .. ";" .. field .. ";" .. entries .. ";" .. selected_index .. "]"
    end
end

local always_enabled = function(
    name
)
    return true
end

local always_disabled = function(
    name
)
    return false
end

local dropdown_privileges = {
}

for privilege, _ in pairs(
    minetest.registered_privileges
) do
    dropdown_privileges[
        privilege
    ] = true
end

local privilege_check = function(
    privilege
)
    local required = {
    }
    required[
        privilege
    ] = true
    return function(
        name
    )
        return minetest.check_player_privs(
            name,
            required
        )
    end
end

local boolean_column_width = function(
    title,
    granularity,
    lang_code
)
    local max_width = string_width(
        title,
        granularity,
        lang_code
    )
    local next_width = string_width(
        S(
            "yes"
        ),
        granularity,
        lang_code
    )
    if next_width > max_width then
        max_width = next_width
    end
    local next_width = string_width(
        S(
            "no"
        ),
        granularity,
        lang_code
    )
    if next_width > max_width then
        max_width = next_width
    end
    return max_width
end

local mapping_add_all = function(
    mapping
)
    mapping.current_row = mapping.current_row + 1
    mapping.rows[
        mapping.current_row
    ] = {
        name = "students",
        type = "all",
    }
end

local mapping_add_groups = function(
    mapping
)
    if edutest.for_all_groups then
        edutest.for_all_groups(
            function(
                name,
                members
            )
                mapping.current_row = mapping.current_row + 1
                mapping.rows[
                    mapping.current_row
                ] = {
                    type = "group",
                    name = name,
                }
            end
        )
    end
end

local mapping_add_students = function(
    mapping
)
    edutest.for_all_students(
        function(
            player,
            name
        )
            mapping.current_row = mapping.current_row + 1
            mapping.rows[
                mapping.current_row
            ] = {
                type = "individual",
                name = name,
            }
        end
    )
end

local mapping_add_offline_students = function(
    mapping
)
    edutest.for_all_offline_students(
        function(
            player,
            name
        )
            mapping.current_row = mapping.current_row + 1
            mapping.rows[
                mapping.current_row
            ] = {
                type = "individual_offline",
                name = name,
            }
        end
    )
end

local mapping_add_teachers = function(
    mapping
)
    edutest.for_all_teachers(
        function(
            player,
            name
        )
            mapping.current_row = mapping.current_row + 1
            mapping.rows[
                mapping.current_row
            ] = {
                type = "individual_teacher",
                name = name,
            }
        end
    )
end

local generic_axis_mapping = function(
    columns,
    categories
)
    local mapping = {
        current_row = 1,
        rows = {
        },
        columns = {
        },
    }
    for _, adder in pairs(
        categories
    ) do
        adder(
            mapping
        )
    end
    local column_index = 2
    for k, column in pairs(
        columns
    ) do
        column_index = column_index + 2
        mapping.columns[
            column_index
        ] = {
            title = column.title,
            check = column.check,
            enabling = column.enabling,
            disabling = column.disabling,
        }
    end
    return mapping
end

local generic_axis_mapping_lazy = function(
    columns,
    categories
)
    return function(
    )
        return generic_axis_mapping(
            columns,
            categories
        )
    end
end

local student_all_group_axis_mapping = function(
    columns
)
    local mapping = {
        current_row = 1,
        rows = {
        },
        columns = {
        },
    }
    mapping.current_row = mapping.current_row + 1
    mapping.rows[
        mapping.current_row
    ] = {
        name = "students",
        type = "all",
    }
    if edutest.for_all_groups then
        edutest.for_all_groups(
            function(
                name,
                members
            )
                mapping.current_row = mapping.current_row + 1
                mapping.rows[
                    mapping.current_row
                ] = {
                    type = "group",
                    name = name,
                }
            end
        )
    end
    edutest.for_all_students(
        function(
            player,
            name
        )
            mapping.current_row = mapping.current_row + 1
            mapping.rows[
                mapping.current_row
            ] = {
                type = "individual",
                name = name,
            }
        end
    )
    local column_index = 2
    for k, column in pairs(
        columns
    ) do
        column_index = column_index + 2
        mapping.columns[
            column_index
        ] = {
            title = column.title,
            check = column.check,
            enabling = column.enabling,
            disabling = column.disabling,
        }
    end
    return mapping
end

local student_all_group_axis_mapping_lazy = function(
    columns
)
    return function(
    )
        return student_all_group_axis_mapping(
            columns
        )
    end
end

local student_group_axis_mapping = function(
    columns
)
    local mapping = {
        rows = {
        },
        columns = {
        },
    }
    local row = 1
    if edutest.for_all_groups then
        edutest.for_all_groups(
            function(
                name,
                members
            )
                row = row + 1
                mapping.rows[
                    row
                ] = {
                    type = "group",
                    name = name,
                }
            end
        )
    end
    edutest.for_all_students(
        function(
            player,
            name
        )
            row = row + 1
            mapping.rows[
                row
            ] = {
                type = "individual",
                name = name,
            }
        end
    )
    local column_index = 2
    for k, column in pairs(
        columns
    ) do
        column_index = column_index + 2
        mapping.columns[
            column_index
        ] = {
            title = column.title,
            check = column.check,
            enabling = column.enabling,
            disabling = column.disabling,
        }
    end
    return mapping
end

local student_group_axis_mapping_lazy = function(
    columns
)
    return function(
    )
        return student_group_axis_mapping(
            columns
        )
    end
end

local student_axis_mapping = function(
    columns
)
    local mapping = {
        rows = {
        },
        columns = {
        },
    }
    local row = 1
    edutest.for_all_students(
        function(
            player,
            name
        )
            row = row + 1
            mapping.rows[
                row
            ] = {
                type = "individual",
                name = name,
            }
        end
    )
    local column_index = 2
    for k, column in pairs(
        columns
    ) do
        column_index = column_index + 2
        mapping.columns[
            column_index
        ] = {
            title = column.title,
            check = column.check,
            enabling = column.enabling,
            disabling = column.disabling,
        }
    end
    return mapping
end

local student_axis_mapping_lazy = function(
    columns
)
    return function(
    )
        return student_axis_mapping(
            columns
        )
    end
end

local mapping_table = function(
    field,
    lazy_mapping
)
    return function(
        layout,
        data,
        resources,
        lang_code
    )
        local mapping = lazy_mapping(
        )
        if not resources.selected_index then
            resources.selected_index = 1
        end
        local entries = ""
        local delimiter = ""
        local max_width = string_width(
            entries,
            layout.width_granularity,
            lang_code
        )
        local row_index = 2
        while mapping.rows[
            row_index
        ] do
            local row = mapping.rows[
                row_index
            ]
            local name = row.name
            local type = row.type
            local entry
            if "individual" == type then
                entry = "#FFFFFF," .. name
            elseif "individual_offline" == type then
                entry = "#BBBBBB," .. name
            elseif "individual_teacher" == type then
                entry = "#DDDDFF," .. name
            elseif 'group' == type then
                entry = "#DDFFDD," .. group_prefix .. name
                if resources.temp_selected_group
                and resources.temp_selected_group == name then
                    resources.selected_index = row_index
                    resources.temp_selected_group = nil
                end
            else
                entry = "#FFDDDD," .. all_students_entry
            end
            local width = string_width(
                entry,
                layout.width_granularity,
                lang_code
            )
            local column_index = 4
            while mapping.columns[
                column_index
            ] do
                local column = mapping.columns[
                    column_index
                ]
                column_index = column_index + 2
                if "individual" == type then
                    if column.check(
                        name
                    ) then
                        entry = entry .. ",#00FF00," .. S(
                            "yes"
                        )
                    else
                        entry = entry .. ",#FF0000," .. S(
                            "no"
                        )
                    end
                elseif "individual_offline" == type then
                    if column.check(
                        name
                    ) then
                        entry = entry .. ",#00FF00," .. S(
                            "yes"
                        )
                    else
                        entry = entry .. ",#FF0000," .. S(
                            "no"
                        )
                    end
                elseif "individual_teacher" == type then
                    if column.check(
                        name
                    ) then
                        entry = entry .. ",#00FF00," .. S(
                            "yes"
                        )
                    else
                        entry = entry .. ",#FF0000," .. S(
                            "no"
                        )
                    end
                elseif 'group' == type then
                    local enabled_count = 0
                    local disabled_count = 0
                    edutest.for_all_members(
                        name,
                        function(
                            player,
                            name
                        )
                            if column.check(
                                name
                            ) then
                                enabled_count = enabled_count + 1
                            else
                                disabled_count = disabled_count + 1
                            end
                        end
                    )
                    if 0 == disabled_count then
                        entry = entry .. ",#00FF00," .. S(
                            "all"
                        )
                    elseif 0 == enabled_count then
                        entry = entry .. ",#FF0000," .. S(
                            "none"
                        )
                    else
                        entry = entry .. ",#FFFF00," .. S(
                            "some"
                        )
                    end
                else
                    local enabled_count = 0
                    local disabled_count = 0
                    edutest.for_all_students(
                        function(
                            player,
                            name
                        )
                            if column.check(
                                name
                            ) then
                                enabled_count = enabled_count + 1
                            else
                                disabled_count = disabled_count + 1
                            end
                        end
                    )
                    if 0 == disabled_count then
                        entry = entry .. ",#00FF00," .. S(
                            "all"
                        )
                    elseif 0 == enabled_count then
                        entry = entry .. ",#FF0000," .. S(
                            "none"
                        )
                    else
                        entry = entry .. ",#FFFF00," .. S(
                            "some"
                        )
                    end
                end
            end
            if max_width < width then
                max_width = width
            end
            entries = entries .. delimiter .. entry
            delimiter = ","
            row_index = row_index + 1
        end
        local height = 1.5
        local full_width = max_width
        local column_index = 4
        while mapping.columns[
            column_index
        ] do
            local column = mapping.columns[
                column_index
            ]
            column_index = column_index + 2
            full_width = full_width + boolean_column_width(
                column.title,
                layout.width_granularity,
                lang_code
            )
        end
        local adjusted_width = full_width * 2 / 3
        local position = layout:region_position(
            adjusted_width,
            height,
            0,
            0
        )
        local formspec = "tablecolumns[color;text"
        column_index = 4
        while mapping.columns[
            column_index
        ] do
            column_index = column_index + 2
            formspec = formspec .. ";color;text"
        end
        formspec = formspec .. "]table[" .. position .. ";"
        formspec = formspec .. adjusted_width .. ",4;"
        formspec = formspec .. field .. ";#FFFFFF," .. S(
            "Name"
        )
        column_index = 4
        while mapping.columns[
            column_index
        ] do
            local column = mapping.columns[
                column_index
            ]
            column_index = column_index + 2
            formspec = formspec .. ",#FFFFFF," .. column.title
        end
        formspec = formspec .. "," .. entries .. ";" .. resources.selected_index
        formspec = formspec .. "]"
        return formspec
    end
end

local basic_teacher_dropdown = function(
    field
)
    return function(
        layout,
        data,
        resources,
        lang_code
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
        local entry = choose_teacher_entry
        if selected_value == entry then
            selected_index = current_index
        end
        local entries = entry
        local max_width = string_width(
            entries,
            layout.width_granularity,
            lang_code
        )
        edutest.for_all_teachers(
            function(
                player,
                name
            )
                local width = string_width(
                    name,
                    layout.width_granularity,
                    lang_code
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
            height,
            0,
            0
        ) .. ";" .. max_width .. ";" .. field .. ";" .. entries .. ";" .. selected_index .. "]"
    end
end

local student_dropdown = function(
    field,
    enabled_check
)
    return function(
        layout,
        data,
        resources,
        lang_code
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
        if without_prefix(
            selected_value
        ) == without_prefix(
            entry
        ) then
            selected_index = current_index
        end
        local entries = entry
        local max_width = string_width(
            entries,
            layout.width_granularity,
            lang_code
        )
        if edutest.for_all_groups then
            edutest.for_all_groups(
                function(
                    name,
                    members
                )
                    local entry = group_prefix .. name
                    local width = string_width(
                        entry,
                        layout.width_granularity,
                        lang_code
                    )
                    if max_width < width then
                        max_width = width
                    end
                    current_index = current_index + 1
                    if without_prefix(
                        selected_value
                    ) == without_prefix(
                        entry
                    ) then
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
                local prefix
                if enabled_check(
                    name
                ) then
                    prefix = enabled_prefix
                else
                    prefix = disabled_prefix
                end
                local entry = prefix .. name
                local width = string_width(
                    entry,
                    layout.width_granularity,
                    lang_code
                )
                if max_width < width then
                    max_width = width
                end
                current_index = current_index + 1
                if without_prefix(
                    selected_value
                ) == without_prefix(
                    entry
                ) then
                    selected_index = current_index
                end
                entries = entries .. "," .. entry
            end
        )
        local height = 1.5
        return "dropdown[" .. layout:region_position(
            max_width,
            height,
            0,
            0
        ) .. ";" .. max_width .. ";" .. field .. ";" .. entries .. ";" .. selected_index .. "]"
    end
end

local basic_student_dropdown_with_groups = function(
    field
)
    return function(
        layout,
        data,
        resources,
        lang_code
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
        if without_prefix(
            selected_value
        ) == without_prefix(
            entry
        ) then
            selected_index = current_index
        end
        local entries = entry
        local max_width = string_width(
            entries,
            layout.width_granularity,
            lang_code
        )
        if edutest.for_all_groups then
            edutest.for_all_groups(
                function(
                    name,
                    members
                )
                    local entry = group_prefix .. name
                    local width = string_width(
                        entry,
                        layout.width_granularity,
                        lang_code
                    )
                    if max_width < width then
                        max_width = width
                    end
                    current_index = current_index + 1
                    if without_prefix(
                        selected_value
                    ) == without_prefix(
                        entry
                    ) then
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
                    name,
                    layout.width_granularity,
                    lang_code
                )
                if max_width < width then
                    max_width = width
                end
                current_index = current_index + 1
                if without_prefix(
                    selected_value
                ) == without_prefix(
                    name
                ) then
                    selected_index = current_index
                end
                entries = entries .. "," .. name
            end
        )
        local height = 1.5
        return "dropdown[" .. layout:region_position(
            max_width,
            height,
            0,
            0
        ) .. ";" .. max_width .. ";" .. field .. ";" .. entries .. ";" .. selected_index .. "]"
    end
end

local group_dropdown = function(
    field
)
    return function(
        layout,
        data,
        resources,
        lang_code
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
        if without_prefix(
            selected_value
        ) == without_prefix(
            entry
        ) then
            selected_index = current_index
        end
        local entries = entry
        local max_width = string_width(
            entry,
            layout.width_granularity,
            lang_code
        )
        entry = new_group_entry
        if without_prefix(
            selected_value
        ) == without_prefix(
            entry
        ) then
            selected_index = current_index
        end
        local width = string_width(
            entry,
            layout.width_granularity,
            lang_code
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
                    name,
                    layout.width_granularity,
                    lang_code
                )
                if max_width < width then
                    max_width = width
                end
                current_index = current_index + 1
                if without_prefix(
                    selected_value
                ) == without_prefix(
                    name
                ) then
                    selected_index = current_index
                end
                entries = entries .. "," .. name
            end
        )
        local height = 1.5
        return "dropdown[" .. layout:region_position(
            max_width,
            height,
            0,
            0
        ) .. ";" .. max_width .. ";" .. field .. ";" .. entries .. ";" .. selected_index .. "]"
    end
end

local main_menu_form

local highlight_form

local new_sub_form = function(
    label,
    width,
    height,
    base_layout
)
    local size
    if not width then
        size = "7,7"
    else
        size = width .. "," .. height
    end
    local constructed = new_form(
        base_layout
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
            main_layout:reset(
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

local player_name_function_passing = function(
    called
)
    return {
        called = called,
        to_group = function(
            self,
            player_name,
            group_name
        )
            edutest.for_all_members(
                group_name,
                function(
                    player,
                    name
                )
                    self.called(
                        name
                    )
                end
            )
            return true
        end,
        to_students = function(
            self,
            player_name
        )
            edutest.for_all_students(
                function(
                    player,
                    name
                )
                    self.called(
                        name
                    )
                end
            )
            return true
        end,
        to_individual = function(
            self,
            player_name,
            individual_name
        )
            self.called(
                individual_name
            )
            return true
        end
    }
end

local unary_command_application = function(
    command
)
    return {
        command = command,
        to_group = function(
            self,
            player_name,
            group_name
        )
            minetest.chatcommands[
                "every_member"
            ].func(
                player_name,
                group_name .. " " .. self.command .. " subject"
            )
            return true
        end,
        to_students = function(
            self,
            player_name
        )
            minetest.chatcommands[
                "every_student"
            ].func(
                player_name,
                self.command .. " subject"
            )
            return true
        end,
        to_individual = function(
            self,
            player_name,
            individual_name
        )
            minetest.chatcommands[
                self.command
            ].func(
                player_name,
                individual_name
            )
            return true
        end
    }
end

local privilege_grant = function(
    privilege
)
    dropdown_privileges[
        privilege
    ] = nil
    return {
        privilege = privilege,
        to_group = function(
            self,
            player_name,
            group_name
        )
            minetest.chatcommands[
                "every_member"
            ].func(
                player_name,
                group_name .. " grant subject " .. self.privilege
            )
            return true
        end,
        to_students = function(
            self,
            player_name
        )
            minetest.chatcommands[
                "every_student"
            ].func(
                player_name,
                "grant subject " .. self.privilege
            )
            return true
        end,
        to_individual = function(
            self,
            player_name,
            individual_name
        )
            minetest.chatcommands[
                "grant"
            ].func(
                player_name,
                individual_name .. " " .. self.privilege
            )
            return true
        end
    }
end

local privilege_revocation = function(
    privilege
)
    return {
        privilege = privilege,
        to_group = function(
            self,
            player_name,
            group_name
        )
            minetest.chatcommands[
                "every_member"
            ].func(
                player_name,
                group_name .. " revoke subject " .. self.privilege
            )
            return true
        end,
        to_students = function(
            self,
            player_name
        )
            minetest.chatcommands[
                "every_student"
            ].func(
                player_name,
                "revoke subject " .. self.privilege
            )
            return true
        end,
        to_individual = function(
            self,
            player_name,
            individual_name
        )
            minetest.chatcommands[
                "revoke"
            ].func(
                player_name,
                individual_name .. " " .. self.privilege
            )
            return true
        end
    }
end

local sequential_operation = function(
    earlier,
    later
)
    return {
        earlier = earlier,
        later = later,
        to_group = function(
            self,
            player_name,
            group_name
        )
            if not self.earlier:to_group(
                player_name,
                group_name
            ) then
                return false
            end
            if not self.later:to_group(
                player_name,
                group_name
            ) then
                return false
            end
            return true
        end,
        to_students = function(
            self,
            player_name
        )
            if not self.earlier:to_students(
                player_name
            ) then
                return false
            end
            if not self.later:to_students(
                player_name
            ) then
                return false
            end
            return true
        end,
        to_individual = function(
            self,
            player_name,
            individual_name
        )
            if not self.earlier:to_individual(
                player_name,
                individual_name
            ) then
                return false
            end
            if not self.later:to_individual(
                player_name,
                individual_name
            ) then
                return false
            end
            return true
        end
    }
end

local apply_operation = function(
    player_name,
    applied,
    target
)
    if group_prefix == string.sub(
        target,
        1,
        string.len(
            group_prefix
        )
    ) then
        local group_name = string.sub(
            target,
            string.len(
                group_prefix
            ) + 1
        )
        return applied:to_group(
            player_name,
            group_name
        )
    end
    if all_students_entry == target then
        return applied:to_students(
            player_name
        )
    end
    return applied:to_individual(
        player_name,
        without_prefix(
            target
        )
    )
end

local apply_to_row = function(
    player_name,
    applied,
    row
)
    if "group" == row.type then
        return applied:to_group(
            player_name,
            row.name
        )
    end
    if "all" == row.type then
        return applied:to_students(
            player_name
        )
    end
    return applied:to_individual(
        player_name,
        row.name
    )
end

local tabular_interface_columns = {
}

local old_style_enabling_buttons

local add_enabling_button = function(
    label,
    enable_label,
    enabling,
    disable_label,
    disabling,
    enabled_check
)
    local new_column = {
        title = label,
        check = enabled_check,
        enabling = enabling,
        disabling = disabling,
    }
    tabular_interface_columns[
        #tabular_interface_columns + 1
    ] = new_column
    if not old_style_enabling_buttons then
        return
    end
    old_style_enabling_buttons:add_button(
        main_layout,
        main_menu_form:new_field(
        ),
        label,
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
                "EDUtest > " .. label
            )
            local subject = form:new_field(
            )
            form:add_input(
                static_layout(
                    "0,2"
                ),
                student_dropdown(
                    subject,
                    enabled_check
                ),
                {
                    subject
                }
            )
            form:add_button(
                static_layout(
                    "0,3"
                ),
                form:new_field(
                ),
                enable_label,
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
                    local result = apply_operation(
                        name,
                        enabling,
                        fields[
                            subject
                        ]
                    )
                    set_current_inventory_form(
                        player,
                        form
                    )
                    return result
                end
            )
            form:add_button(
                static_layout(
                    "3,3"
                ),
                form:new_field(
                ),
                disable_label,
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
                    local result = apply_operation(
                        name,
                        disabling,
                        fields[
                            subject
                        ]
                    )
                    set_current_inventory_form(
                        player,
                        form
                    )
                    return result
                end
            )
            return {
                form = form
            }
        end
    )
end

local add_privilege_button = function(
    label,
    privilege
)
    local grant = privilege_grant(
        privilege
    )
    local revocation = privilege_revocation(
        privilege
    )
    add_enabling_button(
        label,
        S(
            "Enable"
        ),
        grant,
        S(
            "Disable"
        ),
        revocation,
        privilege_check(
            privilege
        )
    )
end

local item_pack_table_data = function(
    field
)
    local result = {
        width = 7,
        height = 4,
        field = field
    }
    local rows = {
    }
    rows[
        #rows + 1
    ] = S(
        "Name"
    )
    edutest.for_all_item_packs(
        function(
            pack_name
        )
            rows[
                #rows + 1
            ] = pack_name
        end
    )
    local columns = {
    }
    columns[
        #columns + 1
    ] = "pack_name"
    result.rows = rows
    result.columns = columns
    return result
end

local member_table_data = function(
    field,
    group
)
    local result = {
        width = 7,
        height = 4,
        field = field
    }
    local rows = {
    }
    rows[
        #rows + 1
    ] = S(
        "Name"
    )
    edutest.for_all_members(
        group,
        function(
            player,
            name
        )
            rows[
                #rows + 1
            ] = name
        end
    )
    local columns = {
    }
    columns[
        #columns + 1
    ] = "player_name"
    result.rows = rows
    result.columns = columns
    return result
end

local nonmember_table_data = function(
    field,
    group
)
    local result = {
        width = 7,
        height = 4,
        field = field
    }
    local rows = {
    }
    rows[
        #rows + 1
    ] = S(
        "Name"
    )
    edutest.for_all_nonmembers(
        group,
        function(
            player,
            name
        )
            rows[
                #rows + 1
            ] = name
        end
    )
    local columns = {
    }
    columns[
        #columns + 1
    ] = "player_name"
    result.rows = rows
    result.columns = columns
    return result
end

local annotated_table_event = function(
    event_string,
    table_data
)
    local result = minetest.explode_table_event(
        event_string
    )
    result.row_name = table_data.rows[
        result.row
    ]
    result.column_name = table_data.columns[
        result.column
    ]
    return result
end

local data_table = function(
    layout,
    data,
    selected_value
)
    return function (
    )
        local width = data.width
        local height = data.height
        local position = layout:region_position(
            width,
            height,
            0,
            0
        )
        local selected_row = 1
        local added_row = 1
        formspec = "tablecolumns[text]table["
        formspec = formspec .. position
        formspec = formspec .. ";" .. width .. "," .. height .. ";"
        formspec = formspec .. data.field .. ";"
        local delimiter = ""
        for k, v in pairs(
            data.rows
        ) do
            if selected_value == v then
                selected_row = added_row
            end
            formspec = formspec .. delimiter .. v
            delimiter = ","
            added_row = added_row + 1
        end
        formspec = formspec .. ";" .. selected_row .. "]"
        return formspec
    end
end

local get_group_controls = function(
    multi_controls,
    group_member_controls,
    add_to_group,
    remove_from_group,
    column_mapping,
    form,
    layout,
    group_member,
    group_nonmember,
    resources,
    lang_code
)
    local group_member_controls = new_conditional_elements(
        form
    )
    resources.group_member_table = member_table_data(
        group_member,
        column_mapping.rows[
            resources.selected_index
        ].name
    )
    group_member_controls:add_element(
        data_table(
            static_layout(
                "0,7"
            ),
            resources.group_member_table,
            form.resources.selected_member
        )
    )
    resources.group_nonmember_table = nonmember_table_data(
        group_nonmember,
        column_mapping.rows[
            resources.selected_index
        ].name
    )
    group_member_controls:add_element(
        data_table(
            static_layout(
                "8,7"
            ),
            resources.group_nonmember_table,
            form.resources.selected_nonmember
        )
    )
    group_member_controls:remove_input(
        add_to_group
    )
    group_member_controls:add_button(
        static_layout(
            "7.13,8"
        ),
        add_to_group,
        "<",
        function(
            player,
            formname,
            fields,
            form
        )
            local added = form.resources.selected_nonmember
            local name = player:get_player_name(
            )
            if not added then
                minetest.chat_send_player(
                    name,
                    "EDUtest: " .. S(
                        "no player selected"
                    )
                )
                return true
            end
            local group = column_mapping.rows[
                form.resources.selected_index
            ]
            minetest.chatcommands[
                "enter_group"
            ].func(
                name,
                group.name .. " " .. added
            )
            set_current_inventory_form(
                player,
                form
            )
            return true
        end
    )
    group_member_controls:remove_input(
        remove_from_group
    )
    group_member_controls:add_button(
        static_layout(
            "7.13,9"
        ),
        remove_from_group,
        ">",
        function(
            player,
            formname,
            fields,
            form
        )
            local removed = form.resources.selected_member
            local name = player:get_player_name(
            )
            if not removed then
                minetest.chat_send_player(
                    name,
                    "EDUtest: " .. S(
                        "no player selected"
                    )
                )
                return true
            end
            local group = column_mapping.rows[
                form.resources.selected_index
            ]
            minetest.chatcommands[
                "leave_group"
            ].func(
                name,
                group.name .. " " .. removed
            )
            set_current_inventory_form(
                player,
                form
            )
            return true
        end
    )
    local formspec = group_member_controls:get_formspec(
        wrap_lang_code(
            lang_code
        )
    )
    formspec = formspec .. multi_controls:get_formspec(
        wrap_lang_code(
            lang_code
        )
    )
    return formspec
end

local initialize_forms = function(
)
    main_menu_form = new_main_form(
        "EDUtest",
        main_layout
    )
    highlight_form = new_form(
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
                        wrap_player(
                            name
                        )
                    )
                )
            end
        )
    end
    if nil ~= minetest.chatcommands[
        "freeze"
    ] then
        add_enabling_button(
            S(
                "Freeze"
            ),
            S(
                "Freeze"
            ),
            unary_command_application(
                "freeze"
            ),
            S(
                "Unfreeze"
            ),
            sequential_operation(
                unary_command_application(
                    "unfreeze"
                ),
                privilege_grant(
                    "interact"
                )
            ),
            edutest.tracked_command_enabled(
                "freeze"
            )
        )
    else
        add_privilege_button(
            S(
                "Interaction"
            ),
            "interact"
        )
    end
    if nil ~= minetest.chatcommands[
        "basic_hand"
    ] then
        add_enabling_button(
            S(
                "Creative Mode"
            ),
            S(
                "Enable"
            ),
            sequential_operation(
                unary_command_application(
                    "creative_hand"
                ),
                privilege_grant(
                    "creative"
                )
            ),
            S(
                "Disable"
            ),
            sequential_operation(
                unary_command_application(
                    "basic_hand"
                ),
                privilege_revocation(
                    "creative"
                )
            ),
            privilege_check(
                "creative"
            )
        )
    else
        add_enabling_button(
            S(
                "Creative Mode"
            ),
            S(
                "Enable"
            ),
            privilege_grant(
                "creative"
            ),
            S(
                "Disable"
            ),
            privilege_revocation(
                "creative"
            ),
            privilege_check(
                "creative"
            )
        )
    end
    main_menu_form:add_button(
        main_layout,
        main_menu_form:new_field(
        ),
        S(
            "Manage players"
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
                    "Manage players"
                ),
                20,
                15
            )
            local mapping = generic_axis_mapping_lazy(
                tabular_interface_columns,
                {
                    mapping_add_all,
                    mapping_add_groups,
                    mapping_add_students,
                    mapping_add_offline_students
                }
            )
            local group_controls = new_conditional_elements(
                form
            )
            local group_control_layout = horizontal_grid_layout(
                4,
                20
            )
            group_control_layout.row_initial = 8
            group_control_layout.column_initial = 0.5
            local new_group = form:new_field(
            )
            group_controls:add_input(
                group_control_layout,
                text_field(
                    new_group,
                    6,
                    1,
                    S(
                        "Name for new group"
                    )
                ),
                {
                    new_group
                }
            )
            group_controls:add_button(
                group_control_layout,
                form:new_field(
                ),
                S(
                    "Create group"
                ),
                function(
                    player,
                    formname,
                    fields
                )
                    local name = player:get_player_name(
                    )
                    local group_name
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
                    form.resources.temp_selected_group = group_name
                    set_current_inventory_form(
                        player,
                        form
                    )
                    return true
                end
            )
            local multi_controls = new_conditional_elements(
                form
            )
            local multi_control_layout = horizontal_grid_layout(
                4,
                20
            )
            multi_control_layout.row_initial = 10
            local individual_controls = new_conditional_elements(
                form
            )
            local individual_control_layout = horizontal_grid_layout(
                4,
                20
            )
            individual_control_layout.row_initial = 7
            local other_teleport = form:new_field(
            )
            multi_controls:add_button(
                multi_control_layout,
                other_teleport,
                S(
                    "Bring student"
                ),
                function(
                    player,
                    formname,
                    fields,
                    form
                )
                    local name = player:get_player_name(
                    )
                    if not form.resources.selected_index then
                        form.resources.selected_index = 1
                    end
                    local column_mapping = mapping(
                    )
                    if not column_mapping.rows[
                        form.resources.selected_index
                    ] then
                        return false
                    end
                    if "all" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "every_student"
                        ].func(
                            name,
                            teleport_command .. " subject " .. name
                        )
                        return true
                    end
                    if "group" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "every_member"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. teleport_command .. " subject " .. name
                        )
                        return true
                    end
                    if "individual" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            teleport_command
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. name
                        )
                        return true
                    end
                    if "individual_teacher" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            teleport_command
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. name
                        )
                        return true
                    end
                    if "individual_offline" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            teleport_command
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. name
                        )
                        return true
                    end
                    return false
                end
            )
            if nil ~= minetest.chatcommands[
                "return"
            ] then
                local other_previous_position = form:new_field(
                )
                multi_controls:add_button(
                    multi_control_layout,
                    other_previous_position,
                    S(
                        "Previous position"
                    ),
                    function(
                        player,
                        formname,
                        fields,
                        form
                    )
                        local name = player:get_player_name(
                        )
                        if not form.resources.selected_index then
                            form.resources.selected_index = 1
                        end
                        local column_mapping = mapping(
                        )
                        if not column_mapping.rows[
                            form.resources.selected_index
                        ] then
                            return false
                        end
                        apply_to_row(
                            name,
                            unary_command_application(
                                "return"
                            ),
                            column_mapping.rows[
                                form.resources.selected_index
                            ]
                        )
                        return true
                    end
                )
                local self_previous_position = form:new_field(
                )
                individual_controls:add_button(
                    individual_control_layout,
                    self_previous_position,
                    S(
                        "Previous position"
                    ),
                    function(
                        player,
                        formname,
                        fields,
                        form
                    )
                        local name = player:get_player_name(
                        )
                        if not form.resources.selected_index then
                            form.resources.selected_index = 1
                        end
                        local column_mapping = mapping(
                        )
                        if not column_mapping.rows[
                            form.resources.selected_index
                        ] then
                            return false
                        end
                        if "individual" == column_mapping.rows[
                            form.resources.selected_index
                        ].type then
                            minetest.chatcommands[
                                "return"
                            ].func(
                                name,
                                ""
                            )
                            return true
                        end
                        if "individual_offline" == column_mapping.rows[
                            form.resources.selected_index
                        ].type then
                            minetest.chatcommands[
                                "return"
                            ].func(
                                name,
                                ""
                            )
                            return true
                        end
                        if "individual_teacher" == column_mapping.rows[
                            form.resources.selected_index
                        ].type then
                            minetest.chatcommands[
                                "return"
                            ].func(
                                name,
                                ""
                            )
                            return true
                        end
                        return false
                    end
                )
            end
            local new_password = form:new_field(
            )
            local modified_privilege = form:new_field(
            )
            multi_controls:add_input(
                multi_control_layout,
                dropdown_field(
                    modified_privilege,
                    1,
                    S(
                        "Choose privilege"
                    ),
                    dropdown_privileges
                ),
                {
                    modified_privilege
                }
            )
            multi_controls:add_button(
                multi_control_layout,
                form:new_field(
                ),
                S(
                    "Grant"
                ),
                function(
                    player,
                    formname,
                    fields,
                    form
                )
                    local name = player:get_player_name(
                    )
                    if not form.resources.selected_index then
                        form.resources.selected_index = 1
                    end
                    local column_mapping = mapping(
                    )
                    if not column_mapping.rows[
                        form.resources.selected_index
                    ] then
                        return false
                    end
                    local chosen_privilege = fields[
                        modified_privilege
                    ]
                    if not dropdown_privileges[
                        chosen_privilege
                    ] then
                        minetest.chat_send_player(
                            name,
                            "EDUtest: " .. S(
                                "You need to choose a privilege first"
                            )
                        )
                        return false
                    end
                    if "all" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "every_student"
                        ].func(
                            name,
                            "grant subject " .. chosen_privilege
                        )
                        return true
                    end
                    if "group" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "every_member"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " grant subject " .. chosen_privilege
                        )
                        return true
                    end
                    if "individual" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "grant"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. chosen_privilege
                        )
                        return true
                    end
                    if "individual_teacher" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "grant"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. chosen_privilege
                        )
                        return true
                    end
                    if "individual_offline" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "grant"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. chosen_privilege
                        )
                        return true
                    end
                    return false
                end
            )
            multi_controls:add_button(
                multi_control_layout,
                form:new_field(
                ),
                S(
                    "Revoke"
                ),
                function(
                    player,
                    formname,
                    fields,
                    form
                )
                    local name = player:get_player_name(
                    )
                    if not form.resources.selected_index then
                        form.resources.selected_index = 1
                    end
                    local column_mapping = mapping(
                    )
                    if not column_mapping.rows[
                        form.resources.selected_index
                    ] then
                        return false
                    end
                    local chosen_privilege = fields[
                        modified_privilege
                    ]
                    if not dropdown_privileges[
                        chosen_privilege
                    ] then
                        minetest.chat_send_player(
                            name,
                            "EDUtest: " .. S(
                                "You need to choose a privilege first"
                            )
                        )
                        return false
                    end
                    if "all" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "every_student"
                        ].func(
                            name,
                            "revoke subject " .. chosen_privilege
                        )
                        return true
                    end
                    if "group" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "every_member"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " revoke subject " .. chosen_privilege
                        )
                        return true
                    end
                    if "individual" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "revoke"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. chosen_privilege
                        )
                        return true
                    end
                    if "individual_teacher" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "revoke"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. chosen_privilege
                        )
                        return true
                    end
                    if "individual_offline" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "revoke"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. chosen_privilege
                        )
                        return true
                    end
                    return false
                end
            )
            local give_count = form:new_field(
            )
            multi_controls:add_input(
                multi_control_layout,
                text_field(
                    give_count,
                    4,
                    1,
                    S(
                        "Amount to give"
                    )
                ),
                {
                    give_count
                }
            )
            local choosable_items = {
            }
            for item_name, item_data in pairs(
                minetest.registered_items
            ) do
                if "" ~= item_name
                and not item_data.not_in_creative_inventory then
                    table.insert(
                        choosable_items,
                        item_name
                    )
                end
            end
            local give_item_chooser = form:new_field(
            )
            multi_controls:add_item_chooser(
                multi_control_layout,
                give_item_chooser,
                5,
                choosable_items,
                show_item_basic,
                function(
                    player,
                    formname,
                    fields,
                    form
                )
                    local name = player:get_player_name(
                    )
                    if not form.resources.selected_index then
                        form.resources.selected_index = 1
                    end
                    local column_mapping = mapping(
                    )
                    if not column_mapping.rows[
                        form.resources.selected_index
                    ] then
                        return false
                    end
                    local count_raw = fields[
                        give_count
                    ]
                    local count = ""
                    if "" ~= count_raw then
                        local count_matched = count_raw:match "^%d+$"
                        if not count_matched then
                            minetest.chat_send_player(
                                name,
                                "EDUtest: " .. S(
                                    "Invalid item count"
                                )
                            )
                            return false
                        end
                        count = " " .. count_matched
                    end
                    if "all" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "every_student"
                        ].func(
                            name,
                            "give subject " .. fields[
                                give_item_chooser
                            ] .. count
                        )
                        return true
                    end
                    if "group" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "every_member"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " give subject " .. fields[
                                give_item_chooser
                            ] .. count
                        )
                        return true
                    end
                    if "individual" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "give"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. fields[
                                give_item_chooser
                            ] .. count
                        )
                        return true
                    end
                    if "individual_teacher" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "give"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. fields[
                                give_item_chooser
                            ] .. count
                        )
                        return true
                    end
                    if "individual_offline" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "give"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. fields[
                                give_item_chooser
                            ] .. count
                        )
                        return true
                    end
                    return false
                end
            )
            local given_item_pack = form:new_field(
            )
            local dropdown_item_packs = {
            }
            edutest.for_all_item_packs(
                function(
                    pack_name
                )   
                    dropdown_item_packs[
                        pack_name
                    ] = true
                end
            )
            multi_controls:add_input(
                multi_control_layout,
                dropdown_field(
                    given_item_pack,
                    1,
                    S(
                        "Choose item pack"
                    ),
                    dropdown_item_packs
                ),
                {
                    given_item_pack
                }
            )
            multi_controls:add_button(
                multi_control_layout,
                form:new_field(
                ),
                S(
                    "Give"
                ),
                function(
                    player,
                    formname,
                    fields,
                    form
                )
                    local name = player:get_player_name(
                    )
                    if not form.resources.selected_index then
                        form.resources.selected_index = 1
                    end
                    local column_mapping = mapping(
                    )
                    if not column_mapping.rows[
                        form.resources.selected_index
                    ] then
                        return false
                    end
                    local chosen_pack = fields[
                        given_item_pack
                    ]
                    if not dropdown_item_packs[
                        chosen_pack
                    ] then
                        minetest.chat_send_player(
                            name,
                            "EDUtest: " .. S(
                                "You need to choose an item pack first"
                            )
                        )
                        return false
                    end
                    if "all" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "every_student"
                        ].func(
                            name,
                            "item_pack_give subject " .. chosen_pack
                        )
                        return true
                    end
                    if "group" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "every_member"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " item_pack_give subject " .. chosen_pack
                        )
                        return true
                    end
                    if "individual" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "item_pack_give"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. chosen_pack
                        )
                        return true
                    end
                    if "individual_teacher" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "item_pack_give"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. chosen_pack
                        )
                        return true
                    end
                    if "individual_offline" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "item_pack_give"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. chosen_pack
                        )
                        return true
                    end
                    return false
                end
            )
            multi_controls:add_button(
                multi_control_layout,
                form:new_field(
                ),
                S(
                    "Clear inventory"
                ),
                function(
                    player,
                    formname,
                    fields,
                    form
                )
                    local name = player:get_player_name(
                    )
                    if not form.resources.selected_index then
                        form.resources.selected_index = 1
                    end
                    local column_mapping = mapping(
                    )
                    if not column_mapping.rows[
                        form.resources.selected_index
                    ] then
                        return false
                    end
                    if "all" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "every_student"
                        ].func(
                            name,
                            "clearinv subject"
                        )
                        return true
                    end
                    if "group" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "every_member"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " clearinv subject"
                        )
                        return true
                    end
                    if "individual" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "clearinv"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name
                        )
                        return true
                    end
                    if "individual_teacher" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "clearinv"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name
                        )
                        return true
                    end
                    if "individual_offline" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "clearinv"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name
                        )
                        return true
                    end
                    return false
                end
            )
            local self_teleport = form:new_field(
            )
            individual_controls:add_button(
                individual_control_layout,
                self_teleport,
                S(
                    "Teleport to student"
                ),
                function(
                    player,
                    formname,
                    fields,
                    form
                )
                    local name = player:get_player_name(
                    )
                    if not form.resources.selected_index then
                        form.resources.selected_index = 1
                    end
                    local column_mapping = mapping(
                    )
                    if not column_mapping.rows[
                        form.resources.selected_index
                    ] then
                        return false
                    end
                    if "individual" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            teleport_command
                        ].func(
                            name,
                            name .. " " .. column_mapping.rows[
                                form.resources.selected_index
                            ].name
                        )
                        return true
                    end
                    if "individual_teacher" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            teleport_command
                        ].func(
                            name,
                            name .. " " .. column_mapping.rows[
                                form.resources.selected_index
                            ].name
                        )
                        return true
                    end
                    if "individual_offline" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            teleport_command
                        ].func(
                            name,
                            name .. " " .. column_mapping.rows[
                                form.resources.selected_index
                            ].name
                        )
                        return true
                    end
                    return false
                end
            )
            individual_controls:add_element(
                function (
                )
                    individual_control_layout:line_break(
                    )
                    return ""
                end
            )
            individual_controls:add_input(
                individual_control_layout,
                password_field(
                    new_password,
                    6,
                    1,
                    S(
                        "New password"
                    )
                ),
                {
                    new_password
                }
            )
            individual_controls:add_button(
                individual_control_layout,
                form:new_field(
                ),
                S(
                    "Set password"
                ),
                function(
                    player,
                    formname,
                    fields,
                    form
                )
                    local name = player:get_player_name(
                    )
                    if not form.resources.selected_index then
                        form.resources.selected_index = 1
                    end
                    local column_mapping = mapping(
                    )
                    if not column_mapping.rows[
                        form.resources.selected_index
                    ] then
                        return false
                    end
                    if "individual" == column_mapping.rows[
                        form.resources.selected_index
                    ].type
                    or "individual_teacher" == column_mapping.rows[
                        form.resources.selected_index
                    ].type
                    or "individual_offline" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "setpassword"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. fields[
                                new_password
                            ]
                        )
                        return true
                    end
                    return false
                end
            )
            local kick_reason = form:new_field(
            )
            individual_controls:add_input(
                individual_control_layout,
                text_field(
                    kick_reason,
                    6,
                    1,
                    S(
                        "Kick reason"
                    )
                ),
                {
                    kick_reason
                }
            )
            individual_controls:add_button(
                individual_control_layout,
                form:new_field(
                ),
                S(
                    "Kick"
                ),
                function(
                    player,
                    formname,
                    fields,
                    form
                )
                    local name = player:get_player_name(
                    )
                    if not form.resources.selected_index then
                        form.resources.selected_index = 1
                    end
                    local column_mapping = mapping(
                    )
                    if not column_mapping.rows[
                        form.resources.selected_index
                    ] then
                        return false
                    end
                    if "individual" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "kick"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name .. " " .. fields[
                                kick_reason
                            ]
                        )
                        return true
                    end
                    if "individual_teacher" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chat_send_player(
                            name,
                            "EDUtest: " .. S(
                                "Cannot kick teachers"
                            )
                        )
                        return true
                    end
                    if "individual_offline" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chat_send_player(
                            name,
                            "EDUtest: " .. S(
                                "Cannot kick offline players"
                            )
                        )
                        return true
                    end
                    return false
                end
            )
            individual_controls:add_button(
                individual_control_layout,
                form:new_field(
                ),
                S(
                    "Ban"
                ),
                function(
                    player,
                    formname,
                    fields,
                    form
                )
                    local name = player:get_player_name(
                    )
                    if not form.resources.selected_index then
                        form.resources.selected_index = 1
                    end
                    local column_mapping = mapping(
                    )
                    if not column_mapping.rows[
                        form.resources.selected_index
                    ] then
                        return false
                    end
                    if "individual" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "ban"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name
                        )
                        return true
                    end
                    if "individual_teacher" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chat_send_player(
                            name,
                            "EDUtest: " .. S(
                                "Cannot ban teachers"
                            )
                        )
                        return true
                    end
                    if "individual_offline" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chat_send_player(
                            name,
                            "EDUtest: " .. S(
                                "Cannot ban offline players"
                            )
                        )
                        return true
                    end
                    return false
                end
            )
            individual_controls:add_button(
                individual_control_layout,
                form:new_field(
                ),
                S(
                    "Unban"
                ),
                function(
                    player,
                    formname,
                    fields,
                    form
                )
                    local name = player:get_player_name(
                    )
                    if not form.resources.selected_index then
                        form.resources.selected_index = 1
                    end
                    local column_mapping = mapping(
                    )
                    if not column_mapping.rows[
                        form.resources.selected_index
                    ] then
                        return false
                    end
                    if "individual" == column_mapping.rows[
                        form.resources.selected_index
                    ].type
                    or "individual_teacher" == column_mapping.rows[
                        form.resources.selected_index
                    ].type
                    or "individual_offline" == column_mapping.rows[
                        form.resources.selected_index
                    ].type then
                        minetest.chatcommands[
                            "unban"
                        ].func(
                            name,
                            column_mapping.rows[
                                form.resources.selected_index
                            ].name
                        )
                        return true
                    end
                    return false
                end
            )
            local subject = form:new_field(
            )
            local group_member = form:new_field(
            )
            local group_nonmember = form:new_field(
            )
            local add_to_group = form:new_field(
            )
            local remove_from_group = form:new_field(
            )
            form:add_input(
                static_layout(
                    "0,2"
                ),
                mapping_table(
                    subject,
                    mapping
                ),
                {
                    subject,
                    function(
                        player,
                        formname,
                        fields,
                        form
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
                        local exploded = minetest.explode_table_event(
                            fields[
                                subject
                            ]
                        )
                        local column_mapping = mapping(
                        )
                        form.resources.selected_index = exploded.row
                        if "CHG" ~= exploded.type then
                            set_current_inventory_form(
                                player,
                                form
                            )
                            return true
                        end
                        if column_mapping.rows[
                            exploded.row
                        ]
                        and column_mapping.columns[
                            exploded.column
                        ] then
                            local subject_name = column_mapping.rows[
                                exploded.row
                            ].name
                            local status
                            if "individual" == column_mapping.rows[
                                exploded.row
                            ].type then
                                if column_mapping.columns[
                                    exploded.column
                                ].check(
                                    subject_name
                                ) then
                                    status = "on"
                                    column_mapping.columns[
                                        exploded.column
                                    ].disabling:to_individual(
                                        name,
                                        subject_name
                                    )
                                else
                                    status = "off"
                                    column_mapping.columns[
                                        exploded.column
                                    ].enabling:to_individual(
                                        name,
                                        subject_name
                                    )
                                end
                            elseif "individual_teacher" == column_mapping.rows[
                                exploded.row
                            ].type then
                                if column_mapping.columns[
                                    exploded.column
                                ].check(
                                    subject_name
                                ) then
                                    status = "on"
                                    column_mapping.columns[
                                        exploded.column
                                    ].disabling:to_individual(
                                        name,
                                        subject_name
                                    )
                                else
                                    status = "off"
                                    column_mapping.columns[
                                        exploded.column
                                    ].enabling:to_individual(
                                        name,
                                        subject_name
                                    )
                                end
                            elseif "individual_offline" == column_mapping.rows[
                                exploded.row
                            ].type then
                                if column_mapping.columns[
                                    exploded.column
                                ].check(
                                    subject_name
                                ) then
                                    status = "on"
                                    column_mapping.columns[
                                        exploded.column
                                    ].disabling:to_individual(
                                        name,
                                        subject_name
                                    )
                                else
                                    status = "off"
                                    column_mapping.columns[
                                        exploded.column
                                    ].enabling:to_individual(
                                        name,
                                        subject_name
                                    )
                                end
                            elseif "group" == column_mapping.rows[
                                exploded.row
                            ].type then
                                local enabled_count = 0
                                local disabled_count = 0
                                edutest.for_all_members(
                                    subject_name,
                                    function(
                                        player,
                                        name
                                    )
                                        if column_mapping.columns[
                                            exploded.column
                                        ].check(
                                            name
                                        ) then
                                            enabled_count = enabled_count + 1
                                        else
                                            disabled_count = disabled_count + 1
                                        end
                                    end
                                )
                                if 0 == disabled_count then
                                    status = "on"
                                    column_mapping.columns[
                                        exploded.column
                                    ].disabling:to_group(
                                        name,
                                        subject_name
                                    )
                                else
                                    status = "off"
                                    column_mapping.columns[
                                        exploded.column
                                    ].enabling:to_group(
                                        name,
                                        subject_name
                                    )
                                end
                            else
                                local enabled_count = 0
                                local disabled_count = 0
                                edutest.for_all_students(
                                    function(
                                        player,
                                        name
                                    )
                                        if column_mapping.columns[
                                            exploded.column
                                        ].check(
                                            name
                                        ) then
                                            enabled_count = enabled_count + 1
                                        else
                                            disabled_count = disabled_count + 1
                                        end
                                    end
                                )
                                if 0 == disabled_count then
                                    status = "on"
                                    column_mapping.columns[
                                        exploded.column
                                    ].disabling:to_students(
                                        name
                                    )
                                else
                                    status = "off"
                                    column_mapping.columns[
                                        exploded.column
                                    ].enabling:to_students(
                                        name
                                    )
                                end
                            end
                        end
                        set_current_inventory_form(
                            player,
                            form
                        )
                        return true
                    end
                }
            )
            form:add_input(
                static_layout(
                    "0,6"
                ),
                function(
                    layout,
                    data,
                    resources,
                    lang_code
                )
                    group_control_layout:reset(
                    )
                    if not resources.selected_index then
                        resources.selected_index = 1
                    end
                    local help = "label[" .. layout:region_position(
                        1,
                        1,
                        0,
                        0
                    ) .. ";" .. S(
                        "Click on table cells to grant or revoke privileges"
                    ) .. "]"
                    if not data then
                        return help .. group_controls:get_formspec(
                            wrap_lang_code(
                                lang_code
                            )
                        )
                    end
                    if not data[
                        subject
                    ] then
                        return help .. group_controls:get_formspec(
                            wrap_lang_code(
                                lang_code
                            )
                        )
                    end
                    local column_mapping = mapping(
                    )
                    if not column_mapping.rows[
                        resources.selected_index
                    ] then
                        return help .. group_controls:get_formspec(
                            wrap_lang_code(
                                lang_code
                            )
                        )
                    end
                    if "group" == column_mapping.rows[
                        resources.selected_index
                    ].type then
                        multi_control_layout:reset(
                        )
                        return get_group_controls(
                            multi_controls,
                            group_member_controls,
                            add_to_group,
                            remove_from_group,
                            column_mapping,
                            form,
                            layout,
                            group_member,
                            group_nonmember,
                            resources,
                            lang_code
                        )
                    end
                    if "individual" == column_mapping.rows[
                        resources.selected_index
                    ].type then
                        individual_control_layout:reset(
                        )
                        multi_control_layout:reset(
                        )
                        return individual_controls:get_formspec(
                            wrap_lang_code(
                                lang_code
                            )
                        ) .. multi_controls:get_formspec(
                            wrap_lang_code(
                                lang_code
                            )
                        )
                    end
                    if "individual_teacher" == column_mapping.rows[
                        resources.selected_index
                    ].type then
                        individual_control_layout:reset(
                        )
                        multi_control_layout:reset(
                        )
                        return individual_controls:get_formspec(
                            wrap_lang_code(
                                lang_code
                            )
                        ) .. multi_controls:get_formspec(
                            wrap_lang_code(
                                lang_code
                            )
                        )
                    end
                    if "individual_offline" == column_mapping.rows[
                        resources.selected_index
                    ].type then
                        individual_control_layout:reset(
                        )
                        multi_control_layout:reset(
                        )
                        return individual_controls:get_formspec(
                            wrap_lang_code(
                                lang_code
                            )
                        ) .. multi_controls:get_formspec(
                            wrap_lang_code(
                                lang_code
                            )
                        )
                    end
                    multi_control_layout:reset(
                    )
                    return multi_controls:get_formspec(
                        wrap_lang_code(
                            lang_code
                        )
                    )
                end,
                {
                    group_member,
                    function(
                        player,
                        formname,
                        fields,
                        form,
                        field
                    )
                        local annotated = annotated_table_event(
                            fields[
                                field
                            ],
                            form.resources.group_member_table
                        )
                        if 1 == annotated.row then
                            form.resources.selected_member = nil
                        else
                            form.resources.selected_member = annotated.row_name
                        end
                        return false
                    end,
                    group_nonmember,
                    function(
                        player,
                        formname,
                        fields,
                        form,
                        field
                    )
                        local annotated = annotated_table_event(
                            fields[
                                field
                            ],
                            form.resources.group_nonmember_table
                        )
                        if 1 == annotated.row then
                            form.resources.selected_nonmember = nil
                        else
                            form.resources.selected_nonmember = annotated.row_name
                        end
                        return false
                    end
                }
            )
            return {
                form = form
            }
        end
    )
    if nil ~= minetest.chatcommands[
        "item_pack_add"
    ] then
        main_menu_form:add_button(
            main_layout,
            main_menu_form:new_field(
            ),
            S(
                "Manage item packs"
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
                local item_pack_layout = horizontal_layout(
                    15
                )
                item_pack_layout.row_initial = 7
                item_pack_layout.column_initial = 0.5
                local form = new_sub_form(
                    "EDUtest > " .. S(
                        "Manage item packs"
                    ),
                    15,
                    14,
                    item_pack_layout
                )
                local item_pack_table_layout = horizontal_layout(
                    15
                )
                item_pack_table_layout.row_initial = 0
                item_pack_table_layout.column_initial = 0.5
                local item_pack_table = form:new_field(
                )
                local item_pack_content_layout = horizontal_layout(
                    15
                )
                item_pack_content_layout.row_initial = 11
                item_pack_content_layout.column_initial = 0.5
                local item_pack_content = form:new_field(
                )
                form:add_input(
                    static_layout(
                        "0,0"
                    ),
                    function(
                        layout,
                        data,
                        resources,
                        lang_code
                    )
                        item_pack_table_layout:reset(
                        )
                        local item_pack_table_controls = new_conditional_elements(
                            form
                        )
                        resources.item_pack_table = item_pack_table_data(
                            item_pack_table
                        )
                        item_pack_table_controls:add_element(
                            data_table(
                                static_layout(
                                    "0,2"
                                ),
                                resources.item_pack_table,
                                form.resources.selected_item_pack
                            )
                        )
                        local formspec_data = item_pack_table_controls:get_formspec(
                            wrap_lang_code(
                                lang_code
                            )
                        )
                        return formspec_data
                    end,
                    {
                        item_pack_table,
                        function(
                            player,
                            formname,
                            fields,
                            form,
                            field
                        )
                            local annotated = annotated_table_event(
                                fields[
                                    field
                                ],
                                form.resources.item_pack_table
                            )
                            if 1 == annotated.row then
                                form.resources.selected_item_pack = nil
                            else
                                local pack_name = annotated.row_name
                                form.resources.selected_item_pack = pack_name
                            end
                            set_current_inventory_form(
                                player,
                                form
                            )
                            return false
                        end
                    }
                )
                local new_pack_name = form:new_field(
                )
                form:add_input(
                    item_pack_layout,
                    text_field(
                        new_pack_name,
                        4,
                        1,
                        S(
                            "Item pack name"
                        ),
                        "selected_item_pack"
                    ),
                    {
                        new_pack_name
                    }
                )
                local add_count = form:new_field(
                )
                form:add_input(
                    item_pack_layout,
                    text_field(
                        add_count,
                        4,
                        1,
                        S(
                            "Amount to add"
                        )
                    ),
                    {
                        add_count
                    }
                )
                local choosable_items = {
                }
                for item_name, item_data in pairs(
                    minetest.registered_items
                ) do
                    if "" ~= item_name
                    and not item_data.not_in_creative_inventory then
                        table.insert(
                            choosable_items,
                            item_name
                        )
                    end
                end
                local added_item_chooser = form:new_field(
                )
                form:add_item_chooser(
                    item_pack_layout,
                    added_item_chooser,
                    5,
                    choosable_items,
                    show_item_basic,
                    function(
                        player,
                        formname,
                        fields,
                        form
                    )
                        local name = player:get_player_name(
                        )
                        if "" == fields[
                            new_pack_name
                        ] then
                            minetest.chat_send_player(
                                name,
                                "EDUtest: " .. S(
                                    "Please specify item pack name"
                                )
                            )
                            return false
                        end
                        local count_raw = fields[
                            add_count
                        ]
                        local count = ""
                        if "" ~= count_raw then
                            local count_matched = count_raw:match "^%d+$"
                            if not count_matched then
                                minetest.chat_send_player(
                                    name,
                                    "EDUtest: " .. S(
                                        "Invalid item count"
                                    )
                                )
                                return false
                            end
                            count = " " .. count_matched
                        end
                        minetest.chatcommands[
                            "item_pack_add"
                        ].func(
                            name,
                            fields[
                                new_pack_name
                            ] .. " " .. fields[
                                added_item_chooser
                            ] .. count
                        )
                        form.resources.item_pack_modified = true
                        set_current_inventory_form(
                            player,
                            form
                        )
                        return true
                    end
                )
                form:add_input(
                    static_layout(
                        "11,0"
                    ),
                    function(
                        layout,
                        data,
                        resources,
                        lang_code
                    )
                        item_pack_content_layout:reset(
                        )
                        local item_pack_content_controls = new_conditional_elements(
                            form
                        )
                        local selected_pack = form.resources.selected_item_pack
                        if selected_pack then
                            local pack_items = {
                            }
                            local pack_item_counts = {
                            }
                            edutest.for_all_pack_items(
                                form.resources.selected_item_pack,
                                function(
                                    item_name,
                                    item_count
                                )
                                    table.insert(
                                        pack_items,
                                        item_name
                                    )
                                    pack_item_counts[
                                        item_name
                                    ] = item_count
                                end
                            )
                            if selected_pack ~= form.resources.last_pack then
                                form.resources.last_pack = selected_pack
                                item_pack_content_controls:reset_item_chooser(
                                    item_pack_content
                                )
                            end
                            if form.resources.item_pack_modified then
                                form.resources.item_pack_modified = nil
                                item_pack_content_controls:reset_item_chooser(
                                    item_pack_content
                                )
                            end
                            item_pack_content_controls:add_item_chooser(
                                item_pack_content_layout,
                                item_pack_content,
                                5,
                                pack_items,
                                function(
                                    layout,
                                    field,
                                    shown_item,
                                    form,
                                    index
                                )
                                    local width = 1
                                    local height = 1
                                    local count = pack_item_counts[
                                        shown_item
                                    ]
                                    local position = layout:region_position(
                                        0.06,
                                        height,
                                        0.1,
                                        0.1
                                    )
                                    local shown = ""
                                    if 1 ~= index then
                                        shown = shown .. "box[" .. position
                                        shown = shown .. ";0.06,1;black]"
                                    end
                                    position = layout:region_position(
                                        width,
                                        height,
                                        0.375,
                                        0.375
                                    )
                                    shown = shown .. "label[" .. position
                                    shown = shown .. ";" .. count .. "]"
                                    position = layout:region_position(
                                        width,
                                        height,
                                        0.075,
                                        0.125
                                    )
                                    shown = shown .. "button["
                                    shown = shown .. position
                                    shown = shown .. ";" .. width .. "," .. height
                                    shown = shown .. ";"
                                    shown = shown .. field
                                    shown = shown .. "_"
                                    shown = shown .. shown_item .. "_remove;X]"
                                    position = layout:region_position(
                                        width,
                                        height,
                                        0.075,
                                        0.125
                                    )
                                    shown = shown .. "button["
                                    shown = shown .. position
                                    shown = shown .. ";" .. width .. "," .. height
                                    shown = shown .. ";"
                                    shown = shown .. field
                                    shown = shown .. "_"
                                    shown = shown .. shown_item .. "_plus;+]"
                                    position = layout:region_position(
                                        width,
                                        height,
                                        0.075,
                                        0.125
                                    )
                                    shown = shown .. "button["
                                    shown = shown .. position
                                    shown = shown .. ";" .. width .. "," .. height
                                    shown = shown .. ";"
                                    shown = shown .. field
                                    shown = shown .. "_"
                                    shown = shown .. shown_item .. "_minus;-]"
                                    position = layout:region_position(
                                        width,
                                        height,
                                        0.075,
                                        0.125
                                    )
                                    shown = shown .. "item_image_button["
                                    shown = shown .. position
                                    shown = shown .. ";" .. width .. "," .. height
                                    shown = shown .. ";"
                                    shown = shown .. shown_item .. ";" .. field
                                    shown = shown .. "_"
                                    shown = shown .. shown_item .. ";]"
                                    return shown
                                end,
                                function(
                                    player,
                                    formname,
                                    fields,
                                    form
                                )
                                    if "remove" == fields[
                                        item_pack_content .. "_action"
                                    ] then
                                        local name = player:get_player_name(
                                        )
                                        local pack = form.resources.selected_item_pack
                                        minetest.chatcommands[
                                            "item_pack_remove"
                                        ].func(
                                            name,
                                            pack .. " " .. fields[
                                                item_pack_content
                                            ]
                                        )
                                        form.resources.item_pack_modified = true
                                        set_current_inventory_form(
                                            player,
                                            form
                                        )
                                    end
                                    if "plus" == fields[
                                        item_pack_content .. "_action"
                                    ] then
                                        local name = player:get_player_name(
                                        )
                                        local pack = form.resources.selected_item_pack
                                        minetest.chatcommands[
                                            "item_pack_add"
                                        ].func(
                                            name,
                                            pack .. " " .. fields[
                                                item_pack_content
                                            ] .. " 1"
                                        )
                                        set_current_inventory_form(
                                            player,
                                            form
                                        )
                                    end
                                    if "minus" == fields[
                                        item_pack_content .. "_action"
                                    ] then
                                        local name = player:get_player_name(
                                        )
                                        local pack = form.resources.selected_item_pack
                                        minetest.chatcommands[
                                            "item_pack_remove"
                                        ].func(
                                            name,
                                            pack .. " " .. fields[
                                                item_pack_content
                                            ] .. " 1"
                                        )
                                        set_current_inventory_form(
                                            player,
                                            form
                                        )
                                    end
                                    return true
                                end,
                                {
                                    "remove",
                                    "plus",
                                    "minus"
                                }
                            )
                        end
                        local formspec = item_pack_content_controls:get_formspec(
                            wrap_lang_code(
                                lang_code
                            )
                        )
                        return formspec
                    end,
                    {
                    }
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
            "Add teacher"
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
                    "Add teacher"
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
                {
                    subject
                }
            )
            form:add_button(
                static_layout(
                    "0,3"
                ),
                form:new_field(
                ),
                S(
                    "Grant teacher privilege"
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
                    edutest.student_to_teacher(
                        player,
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
    main_menu_form:add_button(
        main_layout,
        main_menu_form:new_field(
        ),
        S(
            "Remove teacher"
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
                    "Remove teacher"
                )
            )
            local subject = form:new_field(
            )
            form:add_input(
                static_layout(
                    "0,2"
                ),
                basic_teacher_dropdown(
                    subject
                ),
                {
                    subject
                }
            )
            form:add_button(
                static_layout(
                    "0,3"
                ),
                form:new_field(
                ),
                S(
                    "Revoke teacher privilege"
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
                    if choose_teacher_entry == fields[
                        subject
                    ] then
                        return false
                    end
                    edutest.teacher_to_student(
                        player,
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
    if rawget(
        _G,
        "pvpplus"
    ) then
        add_enabling_button(
            S(
                "PvP"
            ),
            S(
                "Enable"
            ),
            player_name_function_passing(
                pvpplus.pvp_enable
            ),
            S(
                "Disable"
            ),
            player_name_function_passing(
                pvpplus.pvp_disable
            ),
            pvpplus.is_pvp
        )
    end
    if nil ~= minetest.chatcommands[
        "notify"
    ] then
        main_menu_form:add_button(
            main_layout,
            main_menu_form:new_field(
            ),
            S(
                "Notify players"
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
                        "Notify players"
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
                    student_dropdown(
                        subject,
                        always_disabled
                    ),
                    {
                        subject
                    }
                )
                local notification = form:new_field(
                )
                form:add_input(
                    static_layout(
                        "0.5,5"
                    ),
                    text_field(
                        notification,
                        6,
                        1,
                        S(
                            "Notification"
                        )
                    ),
                    {
                        notification
                    }
                )
                form:add_button(
                    static_layout(
                        "0,6"
                    ),
                    form:new_field(
                    ),
                    S(
                        "Send"
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
                            notification
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
                                group_name .. " notify subject " .. fields[
                                    notification
                                ]
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
                                "notify subject " .. fields[
                                    notification
                                ]
                            )
                            return true
                        end
                        minetest.chatcommands[
                            "notify"
                        ].func(
                            name,
                            fields[
                                subject
                            ] .. " " .. fields[
                                notification
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
                    {
                        subject
                    }
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
                    {
                        group
                    }
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
                    {
                        new_group
                    }
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
    add_privilege_button(
        S(
            "Messaging"
        ),
        "shout"
    )
    add_privilege_button(
        S(
            "Fly Mode"
        ),
        "fly"
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
                    {
                        owner
                    }
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
                    {
                        area_name
                    }
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
-- invisibility support disabled until resolution of collision detection issues
--    if nil ~= minetest.chatcommands[
--        "vanish"
--    ] then
    if false then
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
    main_menu_form:add_button(
        main_layout,
        main_menu_form:new_field(
        ),
        S(
            "Toggle sun movement"
        ),
        function(
            player,
            formname,
            fields
        )
            local own_name = player:get_player_name(
            )
            if not minetest.check_player_privs(
                own_name,
                {
                    server = true,
                }
            ) then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "missing privilege: @1",
                        "server"
                    )
                )
                return true
            end
            local old_value = minetest.settings:get(
                "time_speed"
            )
            if "0" == old_value then
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "sun movement enabled"
                    )
                )
                minetest.settings:set(
                    "time_speed",
                    "72"
                )
            else
                minetest.chat_send_player(
                    own_name,
                    "EDUtest: " .. S(
                        "sun movement disabled"
                    )
                )
                minetest.settings:set(
                    "time_speed",
                   "0"
                )
            end
            return true
        end
    )
end

minetest.after(
    0,
    initialize_forms
)

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
                        wrap_player(
                            player:get_player_name(
                            )
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
                main_layout:reset(
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
                main_layout:reset(
                )
                return main_menu_form:get_formspec(
                    wrap_player(
                        player:get_player_name(
                        )
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
