---@meta

-- Define common string enum types for reusability
---@alias NvimTreeSide "left"|"right"
---@alias NvimTreeSortMethod "name"|"case_sensitive"|"modification_time"|"extension"|"suffix"|"filetype"
---@alias NvimTreeHighlightPolicy "none"|"icon"|"name"|"all"
---@alias NvimTreeWindowPickerStyle "default"|function

---Main Configuration Entry
---@class NvimTreeOpts
---@field on_attach? "default"|function(bufnr: number) Setup mappings
---@field hijack_cursor? boolean Keep cursor on the first letter of the filename when moving
---@field auto_reload_on_write? boolean Reload on buffer write
---@field disable_netrw? boolean Disable netrw
---@field hijack_netrw? boolean Hijack netrw window
---@field hijack_unnamed_buffer_when_opening? boolean Open in unnamed buffer
---@field root_dirs? string[] List of preferred root directories
---@field prefer_startup_root? boolean Prefer startup path when updating root
---@field sync_root_with_cwd? boolean Sync root with cwd on DirChanged
---@field reload_on_bufenter? boolean Reload tree on BufEnter
---@field respect_buf_cwd? boolean Switch cwd based on new buffer
---@field select_prompts? boolean Use vim.ui.select style prompts
---@field sort? NvimTreeSortOpts Sorting options
---@field view? NvimTreeViewOpts View options
---@field renderer? NvimTreeRendererOpts Renderer and icon options
---@field hijack_directories? NvimTreeHijackDirectoriesOpts Directory hijacking options
---@field update_focused_file? NvimTreeUpdateFocusedFileOpts Focused file update options
---@field system_open? NvimTreeSystemOpenOpts System open command options
---@field git? NvimTreeGitOpts Git integration options
---@field diagnostics? NvimTreeDiagnosticsOpts Diagnostics integration options
---@field modified? NvimTreeModifiedOpts Modified status indication
---@field filters? NvimTreeFiltersOpts File filters
---@field live_filter? NvimTreeLiveFilterOpts Live filter options
---@field filesystem_watchers? NvimTreeFilesystemWatchersOpts Filesystem watchers
---@field actions? NvimTreeActionsOpts Action behavior options
---@field trash? NvimTreeTrashOpts Trash options
---@field tab? NvimTreeTabOpts Tab sync options
---@field notify? NvimTreeNotifyOpts Notification options
---@field help? NvimTreeHelpOpts Help window options
---@field ui? NvimTreeUiOpts UI confirmation prompts
---@field bookmarks? NvimTreeBookmarksOpts Bookmarks options
---@field log? NvimTreeLogOpts Log options

---@class NvimTreeSortOpts
---@field sorter? NvimTreeSortMethod|function(nodes: table) Sorting method
---@field folders_first? boolean Folders first
---@field files_first? boolean Files first (overrides folders_first)

---@class NvimTreeViewOpts
---@field centralize_selection? boolean Centralize selected node on entry
---@field cursorline? boolean Enable cursorline
---@field cursorlineopt? string Cursorline options
---@field debounce_delay? number Refresh delay (ms)
---@field side? NvimTreeSide Display side
---@field preserve_window_proportions? boolean Preserve window proportions
---@field number? boolean Show line numbers
---@field relativenumber? boolean Show relative line numbers
---@field signcolumn? "yes"|"auto"|"no" Show sign column
---@field width? number|string|table|fun(): number|string Width configuration
---@field float? NvimTreeViewFloatOpts Floating window options

---@class NvimTreeViewFloatOpts
---@field enable? boolean Enable floating window
---@field quit_on_focus_loss? boolean Close on focus loss
---@field open_win_config? table|fun(): table Floating window config (refer to nvim_open_win)

---@class NvimTreeRendererOpts
---@field add_trailing? boolean Add trailing slash to folders
---@field group_empty? boolean|function(path: string): string Compact empty folders
---@field full_name? boolean Show full name in floating window
---@field root_folder_label? string|boolean|function(path: string): string Root folder label format
---@field indent_width? number Indentation width
---@field special_files? string[] List of special highlighted files
---@field hidden_display? "none"|"simple"|"all"|function(stats: table): string Hidden file summary display
---@field symlink_destination? boolean Show symlink destination
---@field decorators? string[] List of decorators used
---@field highlight_git? NvimTreeHighlightPolicy Git highlight policy
---@field highlight_diagnostics? NvimTreeHighlightPolicy Diagnostics highlight policy
---@field highlight_opened_files? NvimTreeHighlightPolicy Opened files highlight policy
---@field highlight_modified? NvimTreeHighlightPolicy Modified files highlight policy
---@field highlight_hidden? NvimTreeHighlightPolicy Hidden files highlight policy
---@field highlight_bookmarks? NvimTreeHighlightPolicy Bookmarks highlight policy
---@field highlight_clipboard? NvimTreeHighlightPolicy Clipboard highlight policy
---@field indent_markers? NvimTreeIndentMarkersOpts Indentation markers
---@field icons? NvimTreeIconsOpts Icons configuration

---@class NvimTreeIndentMarkersOpts
---@field enable? boolean Show indentation markers
---@field inline_arrows? boolean Arrows on the same line as indent markers
---@field icons? table<string, string> Custom marker icons

---@class NvimTreeIconsOpts
---@field web_devicons? table devicons plugin configuration
---@field git_placement? "before"|"after"|"signcolumn"|"right_align" Git icon placement
---@field diagnostics_placement? "before"|"after"|"signcolumn"|"right_align" Diagnostics icon placement
---@field modified_placement? "before"|"after"|"signcolumn"|"right_align" Modified icon placement
---@field hidden_placement? "before"|"after"|"signcolumn"|"right_align" Hidden icon placement
---@field bookmarks_placement? "before"|"after"|"signcolumn"|"right_align" Bookmarks icon placement
---@field padding? table<string, string> Icon padding
---@field symlink_arrow? string Symlink arrow
---@field show? table<string, boolean> Control display of various icons
---@field glyphs? NvimTreeGlyphsOpts Icon glyphs configuration

---@class NvimTreeGlyphsOpts
---@field default? string Default file icon
---@field symlink? string Symlink icon
---@field modified? string Modified icon
---@field hidden? string Hidden icon
---@field folder? table<string, string> Folder icons
---@field git? table<string, string> Git status icons

---@class NvimTreeHijackDirectoriesOpts
---@field enable? boolean Enable directory hijacking
---@field auto_open? boolean Auto open tree

---@class NvimTreeUpdateFocusedFileOpts
---@field enable? boolean Enable auto-focus
---@field update_root? boolean|table Update root directory settings
---@field exclude? boolean|function(event: table): boolean Exclude specific BufEnter events

---@class NvimTreeSystemOpenOpts
---@field cmd? string Open command (defaults to xdg-open/open/start)
---@field args? string[] Command arguments

---@class NvimTreeGitOpts
---@field enable? boolean Enable Git integration
---@field show_on_dirs? boolean Show status on directories
---@field show_on_open_dirs? boolean Show status on open directories
---@field disable_for_dirs? string[]|fun(path: string): boolean Disable for specific directories
---@field timeout? number Timeout (ms)
---@field cygwin_support? boolean Cygwin support

---@class NvimTreeDiagnosticsOpts
---@field enable? boolean Enable diagnostics
---@field debounce_delay? number Update delay (ms)
---@field show_on_dirs? boolean Show on directories
---@field show_on_open_dirs? boolean Show on open directories
---@field severity? table<string, any> Severity filtering
---@field icons? table<string, string> Severity icons

---@class NvimTreeModifiedOpts
---@field enable? boolean Enable modification detection
---@field show_on_dirs? boolean Show on directories
---@field show_on_open_dirs? boolean Show on open directories

---@class NvimTreeFiltersOpts
---@field enable? boolean Enable filters
---@field git_ignored? boolean Filter .gitignore
---@field dotfiles? boolean Filter dotfiles
---@field git_clean? boolean Filter files without Git status
---@field no_buffer? boolean Filter files with no buffer
---@field no_bookmark? boolean Filter files with no bookmarks
---@field custom? string[]|fun(path: string): boolean Custom regex filtering
---@field exclude? string[] Exclude filter list

---@class NvimTreeLiveFilterOpts
---@field prefix? string Filter prefix
---@field always_show_folders? boolean Always show folders

---@class NvimTreeFilesystemWatchersOpts
---@field enable? boolean Enable filesystem watchers
---@field debounce_delay? number Watcher delay (ms)
---@field ignore_dirs? string[]|fun(path: string): boolean Ignore directories

---@class NvimTreeActionsOpts
---@field use_system_clipboard? boolean Use system clipboard
---@field change_dir? NvimTreeChangeDirOpts Directory changing behavior
---@field expand_all? table<string, any> Expand all behavior
---@field file_popup? table Floating preview window config
---@field open_file? NvimTreeOpenFileOpts Open file behavior
---@field remove_file? table Remove file behavior

---@class NvimTreeChangeDirOpts
---@field enable? boolean Enable switching
---@field global? boolean Use :cd instead of :lcd
---@field restrict_above_cwd? boolean Restrict switching above cwd

---@class NvimTreeOpenFileOpts
---@field quit_on_open? boolean Close tree after opening
---@field eject? boolean Prevent opening in tree window
---@field resize_window? boolean Resize window on open
---@field window_picker? NvimTreeWindowPickerOpts Window picker

---@class NvimTreeWindowPickerOpts
---@field enable? boolean Enable window picker
---@field picker? NvimTreeWindowPickerStyle Picker logic
---@field chars? string Picker characters
---@field exclude? table<string, string[]> Excluded buffer types

---@class NvimTreeTrashOpts
---@field cmd? string Trash command (gio trash/trash)

---@class NvimTreeTabOpts
---@field sync? table<string, any> Tab sync settings

---@class NvimTreeNotifyOpts
---@field threshold? integer Notification level threshold (vim.log.levels)
---@field absolute_path? boolean Use absolute path in notifications

---@class NvimTreeHelpOpts
---@field sort_by? "key"|"desc" Help sorting

---@class NvimTreeUiOpts
---@field confirm? table<string, boolean> Confirmation prompt settings

---@class NvimTreeBookmarksOpts
---@field persist? boolean|string Persistence path

---@class NvimTreeLogOpts
---@field enable? boolean Enable log
---@field truncate? boolean Clear log on startup
---@field types? table<string, boolean> Log types
