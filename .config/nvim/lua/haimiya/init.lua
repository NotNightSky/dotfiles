-- haimiya: a custom colorscheme for Neovim.
--
-- The palette is taken from the rest of the desktop setup:
--   house palette  -> hyprland, quickshell, wofi, snappy-switcher
--                     (cream / denim / slate / sky / periwinkle / peach)
--   nord hues     -> kitty terminal
--                     (used for the syntax accents that the house
--                     palette does not cover)
--
-- Two variants share the same roles:
--   :colorscheme haimiya       light (matches the house UI)
--   :colorscheme haimiya-dark  dark  (matches the Nord-ish terminal)
--   :Haimiya [light|dark]      switch between them
--
-- Optional globals:
--   vim.g.haimiya_transparent = true   -- transparent editor background
--   vim.g.haimiya_italic_comments = false

local M = {}

M.palettes = {
  light = {
    bg = "#F8FAF9", -- cream
    surface = "#FFFFFF",
    panel = "#FFFFFF",
    line = "#F1F5F4",
    wash = "#EDF1FA",
    bluewash = "#E4ECF5",
    selwash = "#D4DAF3",

    fg = "#2B4C6F", -- denim
    deep = "#1F3049",
    slate = "#62829F",
    slate_dim = "#5C7A96",

    blue = "#3E6FA8",
    purple = "#7E5A8C",
    teal = "#2F7C8A",
    green = "#4E7D46",
    olive = "#8A6D1A",
    red = "#A8454E",
    peach = "#EBAA9D",
    peach_dark = "#A95544",
    sky = "#A7CBEB",
    periwinkle = "#A7B3EB",

    diff_add = "#E4F0E3",
    diff_change = "#F3EBD8",
    diff_delete = "#F6E2E2",
    diff_text = "#D6E9D4",

    cursor_fg = "#F8FAF9",
    cursor_bg = "#2B4C6F",
    accent_fg = "#1F3049", -- text on top of sky / periwinkle / peach
  },
  dark = {
    bg = "#16212C", -- deep denim
    surface = "#1D2A36",
    panel = "#1D2A36",
    line = "#223140",
    wash = "#1B2B3A",
    bluewash = "#1E3145",
    selwash = "#274056",

    fg = "#DCE6F2",
    deep = "#F2F7FC",
    slate = "#6B87A6",
    slate_dim = "#7E9CBE",

    blue = "#81A1C1",
    purple = "#B48EAD",
    teal = "#88C0D0",
    green = "#A3BE8C",
    olive = "#EBCB8B",
    red = "#D6767F",
    peach = "#EBAA9D",
    peach_dark = "#E09079",
    sky = "#A7CBEB",
    periwinkle = "#A7B3EB",

    diff_add = "#223D2C",
    diff_change = "#3E3A20",
    diff_delete = "#43272C",
    diff_text = "#2C5138",

    cursor_fg = "#16212C",
    cursor_bg = "#DCE6F2",
    accent_fg = "#101A24", -- text on top of sky / periwinkle / peach
  },
}

local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

---@param p table
local function build(p)
  local transparent = vim.g.haimiya_transparent == true
  local italic_comments = vim.g.haimiya_italic_comments ~= false
  local bg = transparent and "NONE" or p.bg

  if vim.o.background ~= (p == M.palettes.light and "light" or "dark") then
    vim.o.background = p == M.palettes.light and "light" or "dark"
  end
  vim.o.termguicolors = true
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  ---------------------------------------------------------------------
  -- editor
  ---------------------------------------------------------------------
  hl("Normal", { fg = p.fg, bg = bg })
  hl("NormalNC", { fg = p.fg, bg = bg })
  hl("NormalFloat", { fg = p.fg, bg = p.surface })
  hl("FloatBorder", { fg = p.slate, bg = p.surface })
  hl("FloatTitle", { fg = p.deep, bg = p.surface, bold = true })
  hl("FloatFooter", { fg = p.slate, bg = p.surface })
  hl("ColorColumn", { bg = p.line })
  hl("Conceal", { fg = p.slate })
  hl("Cursor", { fg = p.cursor_fg, bg = p.cursor_bg })
  hl("lCursor", { fg = p.cursor_fg, bg = p.cursor_bg })
  hl("CursorIM", { fg = p.cursor_fg, bg = p.cursor_bg })
  hl("CursorLine", { bg = p.wash })
  hl("CursorColumn", { bg = p.line })
  hl("CursorLineNr", { fg = p.blue, bg = p.wash, bold = true })
  hl("LineNr", { fg = p.slate })
  hl("LineNrAbove", { fg = p.slate })
  hl("LineNrBelow", { fg = p.slate })
  hl("Directory", { fg = p.blue, bold = true })
  hl("DiffAdd", { bg = p.diff_add })
  hl("DiffChange", { bg = p.diff_change })
  hl("DiffDelete", { bg = p.diff_delete })
  hl("DiffText", { bg = p.diff_text })
  hl("EndOfBuffer", { fg = p.slate, bg = bg })
  hl("TermCursor", { fg = p.cursor_fg, bg = p.cursor_bg })
  hl("TermCursorNC", { fg = p.cursor_fg, bg = p.slate })
  hl("ErrorMsg", { fg = p.red, bold = true })
  hl("VertSplit", { fg = p.bluewash, bg = bg })
  hl("WinSeparator", { fg = p.bluewash, bg = bg })
  hl("Folded", { fg = p.slate, bg = p.line })
  hl("FoldColumn", { fg = p.slate, bg = bg })
  hl("SignColumn", { fg = p.slate, bg = bg })
  hl("SignColumnSB", { fg = p.slate, bg = bg })
  hl("IncSearch", { fg = p.accent_fg, bg = p.peach, bold = true })
  hl("CurSearch", { fg = p.accent_fg, bg = p.periwinkle, bold = true })
  hl("Search", { fg = p.deep, bg = p.selwash })
  hl("Substitute", { fg = p.accent_fg, bg = p.peach })
  hl("MatchParen", { fg = p.accent_fg, bg = p.periwinkle, bold = true })
  hl("ModeMsg", { fg = p.deep, bold = true })
  hl("MoreMsg", { fg = p.blue })
  hl("MsgArea", { fg = p.fg })
  hl("MsgSeparator", { fg = p.slate, bg = bg })
  hl("NonText", { fg = p.slate, bg = bg })
  hl("Pmenu", { fg = p.fg, bg = p.surface })
  hl("PmenuSel", { fg = p.accent_fg, bg = p.periwinkle, bold = true })
  hl("PmenuKind", { fg = p.purple })
  hl("PmenuExtra", { fg = p.slate })
  hl("PmenuMatch", { fg = p.blue, bold = true })
  hl("PmenuMatchSel", { fg = p.accent_fg, bg = p.periwinkle, bold = true })
  hl("PmenuSbar", { bg = p.line })
  hl("PmenuThumb", { bg = p.sky })
  hl("Question", { fg = p.blue })
  hl("QuickFixLine", { bg = p.wash, bold = true })
  hl("SpecialKey", { fg = p.blue })
  hl("SpellBad", { sp = p.red, undercurl = true })
  hl("SpellCap", { sp = p.olive, undercurl = true })
  hl("SpellLocal", { sp = p.teal, undercurl = true })
  hl("SpellRare", { sp = p.purple, undercurl = true })
  hl("StatusLine", { fg = p.fg, bg = p.panel })
  hl("StatusLineNC", { fg = p.slate, bg = bg })
  hl("TabLine", { fg = p.slate, bg = p.bluewash })
  hl("TabLineFill", { bg = bg })
  hl("TabLineSel", { fg = p.deep, bg = p.wash, bold = true })
  hl("Title", { fg = p.blue, bold = true })
  hl("Visual", { fg = p.accent_fg, bg = p.periwinkle })
  hl("VisualNOS", { fg = p.accent_fg, bg = p.periwinkle })
  hl("WarningMsg", { fg = p.olive, bold = true })
  hl("Whitespace", { fg = p.slate, bg = bg })
  hl("WildMenu", { fg = p.accent_fg, bg = p.sky, bold = true })
  hl("Winbar", { fg = p.fg, bg = p.bluewash })
  hl("WinbarNC", { fg = p.slate, bg = bg })
  hl("debugPC", { fg = p.red })
  hl("debugBreakpoint", { fg = p.red, bold = true })

  ---------------------------------------------------------------------
  -- syntax
  ---------------------------------------------------------------------
  hl("Comment", { fg = p.slate_dim, italic = italic_comments })
  hl("SpecialComment", { fg = p.slate_dim, italic = italic_comments, bold = true })
  hl("Constant", { fg = p.peach_dark })
  hl("String", { fg = p.green })
  hl("Character", { fg = p.green })
  hl("Number", { fg = p.peach_dark })
  hl("Boolean", { fg = p.peach_dark })
  hl("Float", { fg = p.peach_dark })
  hl("Identifier", { fg = p.fg })
  hl("Function", { fg = p.blue })
  hl("Statement", { fg = p.deep, bold = true })
  hl("Conditional", { fg = p.deep, bold = true })
  hl("Repeat", { fg = p.deep, bold = true })
  hl("Label", { fg = p.deep, bold = true })
  hl("Operator", { fg = p.slate_dim })
  hl("Exception", { fg = p.red })
  hl("PreProc", { fg = p.purple })
  hl("Include", { fg = p.purple })
  hl("Define", { fg = p.purple })
  hl("Macro", { fg = p.purple })
  hl("PreCondit", { fg = p.purple })
  hl("Type", { fg = p.purple })
  hl("StorageClass", { fg = p.purple })
  hl("Structure", { fg = p.purple })
  hl("Typedef", { fg = p.purple })
  hl("Special", { fg = p.teal })
  hl("SpecialChar", { fg = p.teal })
  hl("Tag", { fg = p.teal })
  hl("Delimiter", { fg = p.slate_dim })
  hl("Debug", { fg = p.olive })
  hl("Underlined", { fg = p.fg, underline = true })
  hl("Ignore", { fg = p.slate })
  hl("Error", { fg = p.red })
  hl("Todo", { fg = p.accent_fg, bg = p.peach, bold = true })

  -- git / diff
  hl("gitSignsAdd", { fg = p.green })
  hl("gitSignsChange", { fg = p.olive })
  hl("gitSignsDelete", { fg = p.red })
  hl("gitSignsCurrentLineBlame", { fg = p.slate })
  hl("added", { fg = p.green })
  hl("changed", { fg = p.olive })
  hl("removed", { fg = p.red })

  ---------------------------------------------------------------------
  -- treesitter
  ---------------------------------------------------------------------
  hl("@variable", { fg = p.fg })
  hl("@variable.builtin", { fg = p.purple })
  hl("@variable.parameter", { fg = p.fg, italic = true })
  hl("@variable.member", { fg = p.blue })
  hl("@constant", { fg = p.peach_dark })
  hl("@constant.builtin", { fg = p.peach_dark, bold = true })
  hl("@constant.macro", { fg = p.purple })
  hl("@module", { fg = p.purple })
  hl("@label", { fg = p.deep })
  hl("@string", { fg = p.green })
  hl("@string.regexp", { fg = p.teal })
  hl("@string.escape", { fg = p.peach_dark })
  hl("@string.special", { fg = p.peach_dark })
  hl("@character", { fg = p.green })
  hl("@character.special", { fg = p.peach_dark })
  hl("@boolean", { fg = p.peach_dark })
  hl("@number", { fg = p.peach_dark })
  hl("@number.float", { fg = p.peach_dark })
  hl("@type", { fg = p.purple })
  hl("@type.builtin", { fg = p.teal })
  hl("@type.definition", { fg = p.purple })
  hl("@attribute", { fg = p.peach_dark })
  hl("@property", { fg = p.blue })
  hl("@function", { fg = p.blue })
  hl("@function.builtin", { fg = p.teal })
  hl("@function.call", { fg = p.blue })
  hl("@function.macro", { fg = p.purple })
  hl("@function.method", { fg = p.blue })
  hl("@function.method.call", { fg = p.blue })
  hl("@constructor", { fg = p.purple })
  hl("@operator", { fg = p.slate_dim })
  hl("@keyword", { fg = p.deep, bold = true })
  hl("@keyword.coroutine", { fg = p.purple, bold = true })
  hl("@keyword.function", { fg = p.deep, bold = true })
  hl("@keyword.operator", { fg = p.slate_dim, bold = true })
  hl("@keyword.return", { fg = p.purple, bold = true })
  hl("@keyword.import", { fg = p.purple, bold = true })
  hl("@keyword.conditional", { fg = p.deep, bold = true })
  hl("@keyword.repeat", { fg = p.deep, bold = true })
  hl("@keyword.exception", { fg = p.red, bold = true })
  hl("@keyword.debug", { fg = p.olive, bold = true })
  hl("@keyword.directive", { fg = p.purple })
  hl("@keyword.directive.define", { fg = p.purple })
  hl("@punctuation.delimiter", { fg = p.slate_dim })
  hl("@punctuation.bracket", { fg = p.slate_dim })
  hl("@punctuation.special", { fg = p.peach_dark })
  hl("@comment", { fg = p.slate_dim, italic = italic_comments })
  hl("@comment.error", { fg = p.red, bold = true })
  hl("@comment.warning", { fg = p.olive, bold = true })
  hl("@comment.todo", { fg = p.accent_fg, bg = p.peach, bold = true })
  hl("@comment.note", { fg = p.blue, italic = italic_comments })
  hl("@markup.strong", { fg = p.deep, bold = true })
  hl("@markup.italic", { fg = p.fg, italic = true })
  hl("@markup.strikethrough", { fg = p.slate, strikethrough = true })
  hl("@markup.underline", { fg = p.fg, underline = true })
  hl("@markup.heading", { fg = p.blue, bold = true })
  hl("@markup.quote", { fg = p.slate_dim, italic = true })
  hl("@markup.math", { fg = p.teal })
  hl("@markup.link", { fg = p.blue, underline = true })
  hl("@markup.link.label", { fg = p.purple })
  hl("@markup.link.url", { fg = p.teal, underline = true })
  hl("@markup.raw", { fg = p.green })
  hl("@markup.raw.block", { fg = p.green })
  hl("@markup.list", { fg = p.peach_dark })
  hl("@markup.list.checked", { fg = p.green })
  hl("@markup.list.unchecked", { fg = p.slate_dim })
  hl("@diff.plus", { fg = p.green })
  hl("@diff.minus", { fg = p.red })
  hl("@diff.delta", { fg = p.olive })

  ---------------------------------------------------------------------
  -- lsp / diagnostics
  ---------------------------------------------------------------------
  hl("DiagnosticError", { fg = p.red })
  hl("DiagnosticWarn", { fg = p.olive })
  hl("DiagnosticInfo", { fg = p.blue })
  hl("DiagnosticHint", { fg = p.purple })
  hl("DiagnosticOk", { fg = p.green })
  hl("DiagnosticDeprecated", { fg = p.slate, strikethrough = true })
  hl("DiagnosticUnnecessary", { fg = p.slate })
  hl("DiagnosticVirtualTextError", { fg = p.red, bg = p.line })
  hl("DiagnosticVirtualTextWarn", { fg = p.olive, bg = p.line })
  hl("DiagnosticVirtualTextInfo", { fg = p.blue, bg = p.line })
  hl("DiagnosticVirtualTextHint", { fg = p.purple, bg = p.line })
  hl("DiagnosticVirtualTextOk", { fg = p.green, bg = p.line })
  hl("DiagnosticUnderlineError", { sp = p.red, undercurl = true })
  hl("DiagnosticUnderlineWarn", { sp = p.olive, undercurl = true })
  hl("DiagnosticUnderlineInfo", { sp = p.blue, undercurl = true })
  hl("DiagnosticUnderlineHint", { sp = p.purple, undercurl = true })
  hl("DiagnosticUnderlineOk", { sp = p.green, undercurl = true })
  hl("DiagnosticFloatingError", { fg = p.red, bg = p.surface })
  hl("DiagnosticFloatingWarn", { fg = p.olive, bg = p.surface })
  hl("DiagnosticFloatingInfo", { fg = p.blue, bg = p.surface })
  hl("DiagnosticFloatingHint", { fg = p.purple, bg = p.surface })
  hl("DiagnosticFloatingOk", { fg = p.green, bg = p.surface })
  hl("DiagnosticSignError", { fg = p.red })
  hl("DiagnosticSignWarn", { fg = p.olive })
  hl("DiagnosticSignInfo", { fg = p.blue })
  hl("DiagnosticSignHint", { fg = p.purple })
  hl("DiagnosticSignOk", { fg = p.green })

  hl("LspReferenceText", { bg = p.bluewash })
  hl("LspReferenceRead", { bg = p.bluewash })
  hl("LspReferenceWrite", { bg = p.bluewash })
  hl("LspReferenceTarget", { bg = p.selwash })
  hl("LspCodeLens", { fg = p.slate, italic = true })
  hl("LspCodeLensSeparator", { fg = p.slate })
  hl("LspInlayHint", { fg = p.slate, bg = p.line, italic = true })
  hl("LspInfoList", { fg = p.fg })
  hl("LspSignatureActiveParameter", { fg = p.deep, bold = true })
  hl("LspMatchLabel", { fg = p.blue, bold = true })
  hl("LspSelectionRange", { bg = p.bluewash })

  hl("@lsp.type.class", { fg = p.purple })
  hl("@lsp.type.comment", { fg = p.slate_dim, italic = italic_comments })
  hl("@lsp.type.decorator", { fg = p.purple })
  hl("@lsp.type.enum", { fg = p.purple })
  hl("@lsp.type.enumMember", { fg = p.peach_dark })
  hl("@lsp.type.event", { fg = p.purple })
  hl("@lsp.type.function", { fg = p.blue })
  hl("@lsp.type.interface", { fg = p.purple })
  hl("@lsp.type.keyword", { fg = p.deep })
  hl("@lsp.type.macro", { fg = p.purple })
  hl("@lsp.type.method", { fg = p.blue })
  hl("@lsp.type.modifier", { fg = p.purple })
  hl("@lsp.type.namespace", { fg = p.purple })
  hl("@lsp.type.number", { fg = p.peach_dark })
  hl("@lsp.type.operator", { fg = p.slate_dim })
  hl("@lsp.type.parameter", { fg = p.fg, italic = true })
  hl("@lsp.type.property", { fg = p.blue })
  hl("@lsp.type.regexp", { fg = p.teal })
  hl("@lsp.type.string", { fg = p.green })
  hl("@lsp.type.struct", { fg = p.purple })
  hl("@lsp.type.type", { fg = p.purple })
  hl("@lsp.type.typeParameter", { fg = p.peach_dark })
  hl("@lsp.type.variable", { fg = p.fg })
  hl("@lsp.mod.deprecated", { strikethrough = true })
  hl("@lsp.mod.defaultLibrary", { fg = p.slate })
  hl("@lsp.mod.readonly", { fg = p.slate })
  hl("@lsp.mod.text", { fg = p.fg })
  hl("@lsp.typemod.variable.defaultLibrary", { fg = p.slate })
  hl("@lsp.typemod.variable.readonly", { fg = p.slate })
  hl("@lsp.typemod.variable.parameter", { fg = p.fg, italic = true })
  hl("@lsp.typemod.variable.member", { fg = p.blue })

  ---------------------------------------------------------------------
  -- lualine
  ---------------------------------------------------------------------
  hl("lualineNormal", { fg = p.fg, bg = p.panel })
  hl("lualineNormalNC", { fg = p.slate, bg = bg })
  hl("lualineInvisible", { fg = p.slate, bg = bg })
  hl("lualineModeNormal", { fg = p.accent_fg, bg = p.sky, bold = true })
  hl("lualineModeInsert", { fg = p.accent_fg, bg = p.periwinkle, bold = true })
  hl("lualineModeVisual", { fg = p.accent_fg, bg = p.peach, bold = true })
  hl("lualineModeReplace", { fg = p.accent_fg, bg = p.sky, bold = true })
  hl("lualineModeCommand", { fg = p.accent_fg, bg = p.sky, bold = true })
  hl("lualineModeTerminal", { fg = p.accent_fg, bg = p.periwinkle, bold = true })
  hl("lualineModeOther", { fg = p.accent_fg, bg = p.sky, bold = true })
  hl("lualineFile", { fg = p.fg, bg = p.panel })
  hl("lualineFileName", { fg = p.fg, bg = p.panel })
  hl("lualineFileIcon", { fg = p.blue, bg = p.panel })
  hl("lualineReadonly", { fg = p.slate, bg = p.panel })
  hl("lualineModified", { fg = p.peach_dark, bg = p.panel, bold = true })
  hl("lualineDiffAdd", { fg = p.green, bg = p.panel })
  hl("lualineDiffChange", { fg = p.olive, bg = p.panel })
  hl("lualineDiffDelete", { fg = p.red, bg = p.panel })
  hl("lualineDiffText", { fg = p.deep, bg = p.panel })
  hl("lualineGitBranch", { fg = p.purple, bg = p.panel })
  hl("lualineGitBranchIcon", { fg = p.purple, bg = p.panel })
  hl("lualineGitAhead", { fg = p.green, bg = p.panel })
  hl("lualineGitBehind", { fg = p.red, bg = p.panel })
  hl("lualineGitDiverged", { fg = p.olive, bg = p.panel })
  hl("lualineGitUntracked", { fg = p.peach_dark, bg = p.panel })
  hl("lualineDiagnosticsError", { fg = p.red, bg = p.panel })
  hl("lualineDiagnosticsWarn", { fg = p.olive, bg = p.panel })
  hl("lualineDiagnosticsInfo", { fg = p.blue, bg = p.panel })
  hl("lualineDiagnosticsHint", { fg = p.purple, bg = p.panel })
  hl("lualineLspProgress", { fg = p.teal, bg = p.panel })
  hl("lualineFormatProgress", { fg = p.purple, bg = p.panel })
  hl("lualineIndent", { fg = p.slate, bg = p.panel })
  hl("lualineSpace", { fg = p.slate, bg = p.panel })
  hl("lualineLocation", { fg = p.slate, bg = p.panel })
  hl("lualinePosition", { fg = p.fg, bg = p.panel })
  hl("lualineFiletype", { fg = p.blue, bg = p.panel })
  hl("lualineSpacer", { fg = p.slate, bg = p.panel })
  hl("lualineRight", { fg = p.slate, bg = p.panel })
  hl("lualineCommands", { fg = p.slate, bg = p.panel })
  hl("lualineFilter", { fg = p.blue, bg = p.panel })
  hl("lualineFileSymbol", { fg = p.slate, bg = p.panel })
  hl("lualineFolder", { fg = p.slate, bg = p.panel })
  hl("lualineDirectory", { fg = p.blue, bg = p.panel })
  hl("lualineError", { fg = p.red, bg = p.panel })

  ---------------------------------------------------------------------
  -- bufferline
  ---------------------------------------------------------------------
  hl("BufferLine", { fg = p.fg, bg = bg })
  hl("BufferLineFill", { bg = bg })
  hl("BufferLineBuffer", { fg = p.fg, bg = bg })
  hl("BufferLineBufferSelected", { fg = p.deep, bg = p.wash, bold = true })
  hl("BufferLineBufferVisible", { fg = p.fg, bg = bg })
  hl("BufferLineBufferVisibleSelected", { fg = p.deep, bg = p.wash, bold = true })
  hl("BufferLineBufferModified", { fg = p.peach_dark, bg = bg, bold = true })
  hl("BufferLineBufferModifiedSelected", { fg = p.peach_dark, bg = p.wash, bold = true })
  hl("BufferLineBufferModifiedVisible", { fg = p.peach_dark, bg = bg, bold = true })
  hl("BufferLineBufferModifiedVisibleSelected", { fg = p.peach_dark, bg = p.wash, bold = true })
  hl("BufferLineIndicatorSelected", { fg = p.periwinkle, bg = p.wash })
  hl("BufferLineIndicatorVisible", { fg = p.blue, bg = bg })
  hl("BufferLineTab", { fg = p.slate, bg = p.bluewash })
  hl("BufferLineTabSelected", { fg = p.deep, bg = p.wash, bold = true })
  hl("BufferLineTabSeparator", { fg = p.slate, bg = bg })
  hl("BufferLineTabSeparatorSelected", { fg = p.slate, bg = p.wash })
  hl("BufferLineTabClose", { fg = p.slate, bg = bg })
  hl("BufferLineTabCloseSelected", { fg = p.deep, bg = p.wash })
  hl("BufferLineNumber", { fg = p.slate, bg = bg })
  hl("BufferLineNumberSelected", { fg = p.blue, bg = p.wash })
  hl("BufferLineNumberVisible", { fg = p.slate, bg = bg })
  hl("BufferLineNumberVisibleSelected", { fg = p.blue, bg = p.wash })
  hl("BufferLineOffset", { fg = p.slate, bg = bg })
  hl("BufferLineOffsetSelected", { fg = p.blue, bg = p.wash })
  hl("BufferLineOffsetVisible", { fg = p.slate, bg = bg })
  hl("BufferLineOffsetVisibleSelected", { fg = p.blue, bg = p.wash })
  hl("BufferLineDuplicate", { fg = p.slate, bg = p.bluewash, italic = true })
  hl("BufferLineDuplicateSelected", { fg = p.slate, bg = p.wash, italic = true })
  hl("BufferLineDuplicateVisible", { fg = p.slate, bg = bg, italic = true })
  hl("BufferLineDuplicateVisibleSelected", { fg = p.slate, bg = p.wash, italic = true })
  hl("BufferLinePin", { fg = p.blue, bg = bg })
  hl("BufferLinePinSelected", { fg = p.blue, bg = p.wash })
  hl("BufferLineTarget", { fg = p.red, bg = bg })
  hl("BufferLineTargetSelected", { fg = p.red, bg = p.wash })

  ---------------------------------------------------------------------
  -- gitsigns
  ---------------------------------------------------------------------
  hl("GitSignsAdd", { fg = p.green })
  hl("GitSignsChange", { fg = p.olive })
  hl("GitSignsDelete", { fg = p.red })
  hl("GitSignsUntracked", { fg = p.peach_dark })
  hl("GitSignsTopdelete", { fg = p.red })
  hl("GitSignsChanged", { fg = p.olive })
  hl("GitSignsAddLn", { bg = p.diff_add })
  hl("GitSignsChangeLn", { bg = p.diff_change })
  hl("GitSignsDeleteLn", { bg = p.diff_delete })
  hl("GitSignsCurrentLineBlame", { fg = p.slate })
  hl("GitSignsAddInline", { bg = p.diff_add })
  hl("GitSignsChangeInline", { bg = p.diff_change })
  hl("GitSignsDeleteInline", { bg = p.diff_delete })

  ---------------------------------------------------------------------
  -- which-key / noice
  ---------------------------------------------------------------------
  hl("WhichKey", { fg = p.purple })
  hl("WhichKeyGroup", { fg = p.blue })
  hl("WhichKeyDesc", { fg = p.fg })
  hl("WhichKeySeparator", { fg = p.slate })
  hl("WhichKeyFloat", { bg = p.surface })
  hl("which-key", { fg = p.purple })
  hl("which-key-group", { fg = p.blue })
  hl("which-key-desc", { fg = p.fg })
  hl("which-key-separator", { fg = p.slate })
  hl("which-key-normal", { fg = p.deep })
  hl("which-key-pending", { fg = p.slate })
  hl("which-key-ice", { fg = p.blue })

  hl("NoiceCmdline", { fg = p.fg, bg = p.surface })
  hl("NoiceCmdlineIcon", { fg = p.blue })
  hl("NoiceCmdlineIconSearch", { fg = p.teal })
  hl("NoiceCmdlinePrompt", { fg = p.deep, bold = true })
  hl("NoiceCmdlinePopup", { fg = p.fg, bg = p.surface })
  hl("NoiceCmdlinePopupBorder", { fg = p.slate })
  hl("NoiceCmdlinePopupBorderSearch", { fg = p.teal })
  hl("NoiceCmdlinePopupTitle", { fg = p.deep, bg = p.surface, bold = true })
  hl("NoiceMini", { fg = p.fg, bg = p.surface })
  hl("NoiceConfirm", { fg = p.fg, bg = p.surface })
  hl("NoicePopup", { fg = p.fg, bg = p.surface })
  hl("NoicePopupBorder", { fg = p.slate })
  hl("NoicePopupmenu", { fg = p.fg, bg = p.surface })
  hl("NoicePopupmenuBorder", { fg = p.slate })
  hl("NoicePopupmenuMatch", { fg = p.blue, bold = true })
  hl("NoicePopupmenuSelected", { fg = p.accent_fg, bg = p.periwinkle, bold = true })
  hl("NoiceSplit", { fg = p.fg, bg = p.surface })
  hl("NoiceSplitBorder", { fg = p.slate })
  hl("NoiceVirtualText", { fg = p.slate })

  ---------------------------------------------------------------------
  -- snacks.nvim
  ---------------------------------------------------------------------
  hl("SnacksPicker", { fg = p.fg, bg = p.surface })
  hl("SnacksPickerNormal", { fg = p.fg, bg = p.surface })
  hl("SnacksPickerBorder", { fg = p.slate, bg = p.surface })
  hl("SnacksPickerTitle", { fg = p.deep, bg = p.surface, bold = true })
  hl("SnacksPickerIcon", { fg = p.blue })
  hl("SnacksPickerIconDirectory", { fg = p.blue })
  hl("SnacksPickerIconFile", { fg = p.slate })
  hl("SnacksPickerIconSpecial", { fg = p.purple })
  hl("SnacksPickerListCursorLine", { bg = p.wash })
  hl("SnacksPickerListDir", { fg = p.blue })
  hl("SnacksPickerListFile", { fg = p.fg })
  hl("SnacksPickerListSpecial", { fg = p.purple })
  hl("SnacksPickerListPrompt", { fg = p.deep, bold = true })
  hl("SnacksPickerListSearch", { fg = p.teal })
  hl("SnacksPickerListFuzzyMatch", { fg = p.blue, bold = true })
  hl("SnacksPickerPreview", { fg = p.fg, bg = p.surface })
  hl("SnacksPickerPreviewLine", { fg = p.fg, bg = p.surface })
  hl("SnacksPickerPreviewCursorLine", { bg = p.wash })
  hl("SnacksPickerPreviewTitle", { fg = p.deep, bg = p.surface, bold = true })
  hl("SnacksPickerMatch", { fg = p.blue, bold = true })
  hl("SnacksPickerMulti", { fg = p.purple })
  hl("SnacksPickerInput", { fg = p.fg, bg = p.line })
  hl("SnacksPickerInputBorder", { fg = p.slate, bg = p.line })
  hl("SnacksPickerInputTitle", { fg = p.deep, bg = p.line, bold = true })
  hl("SnacksPickerInputIcon", { fg = p.blue })
  hl("SnacksPickerHelp", { fg = p.slate, bg = p.surface })
  hl("SnacksPickerListUnselected", { fg = p.slate })
  hl("SnacksPickerIndent", { fg = p.slate_dim })
  hl("SnacksPickerRange", { fg = p.peach_dark })
  hl("SnacksPickerDirectory", { fg = p.blue })
  hl("SnacksPickerGitSignsAdd", { fg = p.green })
  hl("SnacksPickerGitSignsChange", { fg = p.olive })
  hl("SnacksPickerGitSignsDelete", { fg = p.red })
  hl("SnacksPickerGitSignsUntracked", { fg = p.peach_dark })

  hl("SnacksDashboard", { fg = p.fg, bg = bg })
  hl("SnacksDashboardHeader", { fg = p.blue, bg = bg, bold = true })
  hl("SnacksDashboardFooter", { fg = p.slate, bg = bg })
  hl("SnacksDashboardDesc", { fg = p.slate, bg = bg })
  hl("SnacksDashboardKey", { fg = p.purple, bg = bg })
  hl("SnacksDashboardIcon", { fg = p.blue, bg = bg })
  hl("SnacksDashboardTitle", { fg = p.deep, bg = bg, bold = true })

  hl("SnacksNotif", { fg = p.fg, bg = p.surface })
  hl("SnacksNotifBorder", { fg = p.slate, bg = p.surface })
  hl("SnacksNotifTitle", { fg = p.deep, bg = p.surface, bold = true })
  hl("SnacksNotifIcon", { fg = p.blue })
  hl("SnacksNotifIconInfo", { fg = p.blue })
  hl("SnacksNotifIconWarn", { fg = p.olive })
  hl("SnacksNotifIconError", { fg = p.red })
  hl("SnacksNotifIconSuccess", { fg = p.green })
  hl("SnacksNotifIconProgress", { fg = p.purple })
  hl("SnacksNotifBody", { fg = p.fg, bg = p.surface })
  hl("SnacksNotifBodyIndent", { fg = p.fg, bg = p.surface })
  hl("SnacksNotifTime", { fg = p.slate, bg = p.surface })

  hl("SnacksIndent", { fg = p.slate_dim })
  hl("SnacksIndentChar", { fg = p.slate_dim })
  hl("SnacksIndentScope", { fg = p.slate_dim })
  hl("SnacksIndentLine", { fg = p.slate_dim })
  hl("SnacksIndentModule", { fg = p.slate_dim })
  hl("SnacksIndentText", { fg = p.slate_dim })
  hl("SnacksIndentBlankline", { fg = p.slate_dim })
  hl("SnacksIndentSticky", { fg = p.blue })

  hl("SnacksWordsCurrent", { fg = p.accent_fg, bg = p.periwinkle, bold = true })
  hl("SnacksWordsNext", { fg = p.slate })

  hl("SnacksScrollbar", { fg = p.slate, bg = bg })
  hl("SnacksScrollbarHandle", { fg = p.slate_dim, bg = bg })

  hl("SnacksImage", { fg = p.fg, bg = bg })
  hl("SnacksImageFile", { fg = p.fg, bg = bg })
  hl("SnacksImageMedia", { fg = p.fg, bg = bg })
  hl("SnacksImageTitle", { fg = p.deep, bg = bg, bold = true })
  hl("SnacksImageBorder", { fg = p.slate, bg = bg })

  hl("SnacksBigFile", { fg = p.fg, bg = bg })
  hl("SnacksBigFileFile", { fg = p.fg, bg = bg })
  hl("SnacksBigFileIcon", { fg = p.blue, bg = bg })
  hl("SnacksBigFileTitle", { fg = p.deep, bg = bg, bold = true })

  hl("SnacksWinSeparator", { fg = p.bluewash, bg = bg })
  hl("SnacksConfig", { fg = p.fg, bg = p.surface })
  hl("SnacksConfigHeader", { fg = p.deep, bg = p.surface, bold = true })
  hl("SnacksConfigHeaderHelp", { fg = p.slate, bg = p.surface })
  hl("SnacksConfigKey", { fg = p.purple, bg = p.surface })
  hl("SnacksConfigTitle", { fg = p.deep, bg = p.surface, bold = true })
  hl("SnacksConfigValue", { fg = p.blue, bg = p.surface })
  hl("SnacksConfigSpecial", { fg = p.purple, bg = p.surface })
  hl("SnacksConfigSection", { fg = p.slate, bg = p.surface })
  hl("SnacksConfigFooter", { fg = p.slate, bg = p.surface })

  ---------------------------------------------------------------------
  -- telescope / blink / cmp
  ---------------------------------------------------------------------
  hl("TelescopeBorder", { fg = p.slate, bg = p.surface })
  hl("TelescopeTitle", { fg = p.deep, bg = p.surface, bold = true })
  hl("TelescopePromptTitle", { fg = p.deep, bg = p.surface, bold = true })
  hl("TelescopePromptPrefix", { fg = p.blue, bg = p.surface })
  hl("TelescopePromptNormal", { fg = p.fg, bg = p.surface })
  hl("TelescopeResultsTitle", { fg = p.deep, bg = p.surface, bold = true })
  hl("TelescopePreviewTitle", { fg = p.deep, bg = p.surface, bold = true })
  hl("TelescopeMatching", { fg = p.blue, bold = true })
  hl("TelescopeSelection", { fg = p.accent_fg, bg = p.periwinkle, bold = true })
  hl("TelescopeSelectionCaret", { fg = p.accent_fg, bg = p.periwinkle, bold = true })
  hl("TelescopeMultiSelection", { fg = p.purple, bg = p.surface })
  hl("TelescopeMultiIcon", { fg = p.purple })
  hl("TelescopeNormal", { fg = p.fg, bg = p.surface })
  hl("TelescopeResultsNormal", { fg = p.fg, bg = p.surface })
  hl("TelescopePreviewNormal", { fg = p.fg, bg = p.surface })
  hl("TelescopePromptCounter", { fg = p.slate })
  hl("TelescopeResultsDiffChange", { fg = p.olive })
  hl("TelescopeResultsDiffAdd", { fg = p.green })
  hl("TelescopeResultsDiffDelete", { fg = p.red })

  hl("BlinkCmpMenu", { fg = p.fg, bg = p.surface })
  hl("BlinkCmpMenuBorder", { fg = p.slate, bg = p.surface })
  hl("BlinkCmpMenuKind", { fg = p.purple })
  hl("BlinkCmpMenuKindIcon", { fg = p.purple })
  hl("BlinkCmpMenuLabel", { fg = p.fg })
  hl("BlinkCmpMenuLabelDeprecated", { fg = p.slate, strikethrough = true })
  hl("BlinkCmpMenuLabelDetail", { fg = p.slate })
  hl("BlinkCmpMenuLabelMatch", { fg = p.blue, bold = true })
  hl("BlinkCmpMenuLabelMatched", { fg = p.blue, bold = true })
  hl("BlinkCmpMenuSelection", { fg = p.accent_fg, bg = p.periwinkle })
  hl("BlinkCmpMenuSelectionKind", { fg = p.accent_fg, bg = p.periwinkle })
  hl("BlinkCmpGhostText", { fg = p.slate })
  hl("CmpItemAbbr", { fg = p.fg })
  hl("CmpItemAbbrDeprecated", { fg = p.slate, strikethrough = true })
  hl("CmpItemAbbrMatch", { fg = p.blue, bold = true })
  hl("CmpItemAbbrMatchFuzzy", { fg = p.blue, bold = true })
  hl("CmpItemMenu", { fg = p.purple })
  hl("CmpItemKind", { fg = p.purple })

  ---------------------------------------------------------------------
  -- mini.nvim
  ---------------------------------------------------------------------
  hl("MiniIconsAzure", { fg = p.blue })
  hl("MiniIconsBlue", { fg = p.blue })
  hl("MiniIconsCyan", { fg = p.teal })
  hl("MiniIconsGreen", { fg = p.green })
  hl("MiniIconsGrey", { fg = p.slate })
  hl("MiniIconsOrange", { fg = p.peach_dark })
  hl("MiniIconsPurple", { fg = p.purple })
  hl("MiniIconsRed", { fg = p.red })
  hl("MiniIconsYellow", { fg = p.olive })
  hl("MiniAnimateCursor", { nocombine = true })
  hl("MiniCompletionActiveParameter", { fg = p.deep, bold = true })
  hl("MiniCursorword", { bg = p.selwash })
  hl("MiniCursorwordCurrent", { fg = p.accent_fg, bg = p.periwinkle })
  hl("MiniIndentscopeSymbol", { fg = p.slate_dim })
  hl("MiniIndentscopePrefix", { nocombine = true })
  hl("MiniJump", { fg = p.blue })
  hl("MiniJump2dSpot", { fg = p.accent_fg, bg = p.periwinkle, bold = true })
  hl("MiniJump2dSpotAhead", { fg = p.slate_dim, bg = p.bluewash, nocombine = true })
  hl("MiniJump2dSpotUnique", { fg = p.accent_fg, bg = p.peach, bold = true, nocombine = true })
  hl("MiniStarterCurrent", { nocombine = true })
  hl("MiniStarterFooter", { fg = p.slate })
  hl("MiniStarterHeader", { fg = p.blue })
  hl("MiniStarterInactive", { fg = p.slate, italic = true })
  hl("MiniStarterItem", { fg = p.fg })
  hl("MiniStarterItemBullet", { fg = p.blue })
  hl("MiniStarterItemPrefix", { fg = p.purple })
  hl("MiniStarterSection", { fg = p.deep, bold = true })
  hl("MiniStarterQuery", { fg = p.blue })
  hl("MiniStatuslineDevinfo", { fg = p.slate, bg = p.panel })
  hl("MiniStatuslineFileinfo", { fg = p.fg, bg = p.panel })
  hl("MiniStatuslineFilename", { fg = p.fg, bg = p.panel })
  hl("MiniStatuslineInactive", { fg = p.slate, bg = bg })
  hl("MiniStatuslineModeCommand", { fg = p.accent_fg, bg = p.sky, bold = true })
  hl("MiniStatuslineModeInsert", { fg = p.accent_fg, bg = p.periwinkle, bold = true })
  hl("MiniStatuslineModeNormal", { fg = p.accent_fg, bg = p.sky, bold = true })
  hl("MiniStatuslineModeOther", { fg = p.accent_fg, bg = p.sky, bold = true })
  hl("MiniStatuslineModeReplace", { fg = p.accent_fg, bg = p.sky, bold = true })
  hl("MiniStatuslineModeVisual", { fg = p.accent_fg, bg = p.peach, bold = true })
  hl("MiniTablineCurrent", { fg = p.deep, bg = p.wash, bold = true })
  hl("MiniTablineFill", { bg = bg })
  hl("MiniTablineHidden", { fg = p.slate, bg = bg })
  hl("MiniTablineModifiedCurrent", { fg = p.peach_dark, bg = p.wash, bold = true })
  hl("MiniTablineModifiedHidden", { fg = p.peach_dark, bg = bg, bold = true })
  hl("MiniTablineModifiedVisible", { fg = p.peach_dark, bg = bg, bold = true })
  hl("MiniTablineTabpagesection", { fg = p.deep, bg = p.bluewash, bold = true })
  hl("MiniTablineVisible", { fg = p.fg, bg = bg })
  hl("MiniTestEmphasis", { bold = true })
  hl("MiniTestFail", { fg = p.red, bold = true })
  hl("MiniTestPass", { fg = p.green, bold = true })
  hl("MiniTrailspace", { bg = p.peach })

  ---------------------------------------------------------------------
  -- trouble / conform / misc
  ---------------------------------------------------------------------
  hl("TroubleNormal", { fg = p.fg, bg = p.surface })
  hl("TroubleNormalNC", { fg = p.slate, bg = p.surface })
  hl("TroubleText", { fg = p.fg, bg = p.surface })
  hl("TroubleCount", { fg = p.surface, bg = p.blue, bold = true })
  hl("TroubleLocation", { fg = p.blue, bg = p.surface, bold = true })
  hl("TroubleSource", { fg = p.slate, bg = p.surface })
  hl("TroubleCode", { fg = p.peach_dark, bg = p.surface })
  hl("TroubleFoldIcon", { fg = p.slate, bg = p.surface })
  hl("TroubleIndent", { fg = p.slate_dim, bg = p.surface })
  hl("TroubleTextError", { fg = p.red, bg = p.surface })
  hl("TroubleTextWarning", { fg = p.olive, bg = p.surface })
  hl("TroubleTextInformation", { fg = p.blue, bg = p.surface })
  hl("TroubleTextHint", { fg = p.purple, bg = p.surface })
  hl("TroubleIconDirectory", { fg = p.blue, bg = p.surface })
  hl("TroubleIconFile", { fg = p.slate, bg = p.surface })

  hl("ConformInfo", { fg = p.blue })
  hl("ConformWarn", { fg = p.olive })
  hl("ConformError", { fg = p.red })
  hl("FormattingCheck", { fg = p.blue })
  hl("FormattingFix", { fg = p.green })
  hl("FormattingFail", { fg = p.red })

  hl("TodoTxtChecked", { fg = p.green, strikethrough = true })
  hl("TodoTxtTodo", { fg = p.blue })
  hl("TodoTxtDone", { fg = p.slate })
  hl("markdownH1", { fg = p.blue, bold = true })
  hl("markdownH2", { fg = p.blue, bold = true })
  hl("markdownH3", { fg = p.teal, bold = true })
  hl("markdownH4", { fg = p.purple, bold = true })
  hl("markdownH5", { fg = p.purple, bold = true })
  hl("markdownH6", { fg = p.slate, bold = true })
  hl("markdownCode", { fg = p.green })
  hl("markdownCodeBlock", { fg = p.green })
  hl("markdownLinkText", { fg = p.blue, underline = true })
  hl("markdownUrl", { fg = p.teal, underline = true })
  hl("markdownLink", { fg = p.blue, underline = true })
  hl("markdownRule", { fg = p.slate })
  hl("markdownBlockquote", { fg = p.slate_dim, italic = true })
  hl("markdownListMarker", { fg = p.peach_dark })
  hl("markdownHeadingDelimiter", { fg = p.blue, bold = true })

  hl("NavicText", { fg = p.fg })
  hl("NavicSeparator", { fg = p.slate })
  hl("NavicIconsFile", { fg = p.blue })
  hl("NavicIconsModule", { fg = p.purple })
  hl("NavicIconsNamespace", { fg = p.purple })
  hl("NavicIconsPackage", { fg = p.purple })
  hl("NavicIconsClass", { fg = p.purple })
  hl("NavicIconsMethod", { fg = p.blue })
  hl("NavicIconsProperty", { fg = p.blue })
  hl("NavicIconsField", { fg = p.blue })
  hl("NavicIconsConstructor", { fg = p.purple })
  hl("NavicIconsEnum", { fg = p.purple })
  hl("NavicIconsInterface", { fg = p.purple })
  hl("NavicIconsFunction", { fg = p.blue })
  hl("NavicIconsVariable", { fg = p.peach_dark })
  hl("NavicIconsConstant", { fg = p.peach_dark })
  hl("NavicIconsString", { fg = p.green })
  hl("NavicIconsNumber", { fg = p.peach_dark })
  hl("NavicIconsBoolean", { fg = p.peach_dark })
  hl("NavicIconsArray", { fg = p.peach_dark })
  hl("NavicIconsObject", { fg = p.peach_dark })
  hl("NavicIconsKey", { fg = p.blue })
  hl("NavicIconsKeyword", { fg = p.deep })
  hl("NavicIconsOperator", { fg = p.slate_dim })
  hl("NavicIconsTypeParameter", { fg = p.peach_dark })

  hl("TreesitterContext", { bg = p.bluewash })
  hl("TreesitterContextLineNumber", { fg = p.slate, bg = p.bluewash })
  hl("TreesitterContextSeparator", { fg = p.slate })
  hl("TreesitterContextBottom", { sp = p.slate, underline = true })
  hl("IndentBlanklineChar", { fg = p.slate_dim, nocombine = true })
  hl("IndentBlanklineContextChar", { fg = p.line, nocombine = true })
  hl("IndentBlanklineSpaceChar", { fg = p.line, nocombine = true })
  hl("IndentBlanklineSpaceCharBlankline", { fg = p.line, nocombine = true })
  hl("IBLIndent", { fg = p.slate_dim })
  hl("LiveServerPort", { fg = p.green, bold = true })
  hl("GrugFarHelpHeader", { fg = p.deep, bg = p.line, bold = true })
  hl("GrugFarHelpFooter", { fg = p.slate, bg = p.line })
  hl("GrugFarFile", { fg = p.fg })
  hl("GrugFarMatch", { fg = p.blue, bold = true })
  hl("GrugFarLineNo", { fg = p.slate })
  hl("GrugFarText", { fg = p.fg })
  hl("DiffviewStatusAdded", { fg = p.green })
  hl("DiffviewStatusModified", { fg = p.olive })
  hl("DiffviewStatusDeleted", { fg = p.red })
  hl("DiffviewFilePanelTitle", { fg = p.deep, bold = true })
  hl("DiffviewFilePanelCounter", { fg = p.slate, bold = true })
  hl("DiffviewFilePanelFileName", { fg = p.fg })
  hl("DiffviewStatusLineAdded", { fg = p.green })
  hl("DiffviewStatusLineModified", { fg = p.olive })
  hl("DiffviewStatusLineDeleted", { fg = p.red })
  hl("DiffviewFilePanelRootPath", { fg = p.blue, bold = true })
  hl("DiffviewFilePanelPath", { fg = p.slate })
  hl("DiffviewFilePanelInsertions", { fg = p.green })
  hl("DiffviewFilePanelDeletions", { fg = p.red })
  hl("DiffviewReference", { fg = p.purple })
  hl("DiffviewPrimary", { fg = p.blue })
  hl("DiffviewSecondary", { fg = p.peach_dark })
  hl("DiffviewNonText", { fg = p.slate_dim })
  hl("DiffviewDim1", { fg = p.slate_dim })
  hl("DiffviewFilePanelSelected", { fg = p.deep, bg = p.wash, bold = true })

  vim.g.colors_name = p == M.palettes.light and "haimiya" or "haimiya-dark"
end

---@param opts? { variant?: "light" | "dark" }
function M.load(opts)
  opts = opts or {}
  local variant = opts.variant or "light"
  local palette = M.palettes[variant] or M.palettes.light
  build(palette)
end

---@return "light" | "dark"
function M.current()
  return vim.g.colors_name == "haimiya-dark" and "dark" or "light"
end

function M.toggle()
  local variant = M.current() == "dark" and "light" or "dark"
  M.load({ variant = variant })
  vim.notify("haimiya: " .. variant, vim.log.levels.INFO, { title = "colorscheme" })
end

return M
