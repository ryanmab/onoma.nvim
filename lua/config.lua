---@alias onoma.Picker "snacks" | "telescope"

---@class onoma.SnacksConfig
---@field title? string

---@class onoma.TelescopeConfig
---@field results_title? string
---@field prompt_title? string
---@field preview_title? string

---@class onoma.Config
---@field picker? onoma.Picker | (onoma.Picker)[]
---@field debug? boolean
---@field snacks? onoma.SnacksConfig
---@field telescope? onoma.TelescopeConfig
---@field symbol_kinds? {string: onoma.SymbolKind[]}|onoma.SymbolKind[]

---@type onoma.Config
return {
	picker = { 'snacks' },
	debug = false,
	snacks = {
		title = 'Symbols (Onoma)',
	},
	telescope = {
		results_title = 'Symbols (Onoma)',
		prompt_title = '',
		preview_title = '',
	},
	symbol_kinds = {
		go = {
			'Unknown',
			'Constant',
			'Function',
			'Interface',
			'Method',
			'Module',
			'Namespace',
			'Struct',
			'Type',
		},
		rust = {
			'Unknown',
			'Constant',
			'Enum',
			'EnumMember',
			'Function',
			'Getter',
			'Macro',
			'Method',
			'Module',
			'StaticVariable',
			'Struct',
			'Trait',
			'TraitMethod',
			'TypeAlias',
		},
		lua = {
			'Unknown',
			'Enum',
			'EnumMember',
			'Function',
			'Method',
			'Property',
			'Struct',
		},
		typescript = {
			'Unknown',
			'Class',
			'Constant',
			'Enum',
			'EnumMember',
			'Function',
			'Getter',
			'Interface',
			'Method',
			'Module',
			'Property',
			'Setter',
			'TypeAlias',
		},
		typescriptjsx = {
			'Unknown',
			'Class',
			'Constant',
			'Enum',
			'EnumMember',
			'Function',
			'Getter',
			'Interface',
			'Method',
			'Module',
			'Property',
			'Setter',
			'TypeAlias',
		},
		javascript = {
			'Unknown',
			'Class',
			'Constant',
			'Function',
			'Getter',
			'Method',
			'Module',
			'Property',
			'Setter',
		},
		javascriptjsx = {
			'Unknown',
			'Class',
			'Constant',
			'Function',
			'Getter',
			'Method',
			'Module',
			'Property',
			'Setter',
		},
		clojure = {
			'Unknown',
			'Enum',
			'EnumMember',
			'Function',
			'Macro',
			'Namespace',
		},
		python = {
			'Unknown',
			'Class',
			'Constant',
			'Enum',
			'EnumMember',
			'Error',
			'Function',
			'Getter',
			'Method',
			'Module',
			'Property',
			'Setter',
			'StaticMethod',
		},
	},
}
