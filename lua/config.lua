return {
	finder = {
		---@enum onoma.SymbolKind
		symbol_kinds = {
			-- An unknown or unspecified symbol kind.
			'Unknown',

			-- A method which may or may not have an implementation body.
			'AbstractMethod',

			-- An automatically generated accessor.
			'Accessor',

			-- An array type or value.
			'Array',

			-- A logical assertion.
			'Assertion',

			-- A type associated with another type.
			'AssociatedType',

			-- A language attribute or annotation.
			'Attribute',

			-- A foundational logical axiom.
			'Axiom',

			-- A boolean value or type.
			'Boolean',

			-- A class definition.
			'Class',

			-- A concept, defining compile-time constraints.
			'Concept',

			-- A constant value.
			'Constant',

			-- A constructor used to create instances of a type.
			'Constructor',

			-- A contract.
			'Contract',

			-- A data family declaration.
			'DataFamily',

			-- A delegate type.
			'Delegate',

			-- An enumeration type.
			'Enum',

			-- A single member (variant) of an enumeration.
			'EnumMember',

			-- An error type.
			'Error',

			-- An event symbol.
			'Event',

			-- An extension declaration.
			'Extension',

			-- A logical fact.
			'Fact',

			-- A field declared within a struct or class.
			'Field',

			-- A source file.
			'File',

			-- A free-standing function.
			'Function',

			-- A getter accessor.
			'Getter',

			-- A grammar definition.
			'Grammar',

			-- A type class or trait instance.
			'Instance',

			-- An interface definition.
			'Interface',

			-- A key in a key-value structure.
			'Key',

			-- A language declaration.
			'Lang',

			-- A lemma in formal proofs.
			'Lemma',

			-- A library.
			'Library',

			-- A macro definition.
			'Macro',

			-- A method associated with a type.
			'Method',

			-- A method alias.
			'MethodAlias',

			-- A method receiver without a conventional name.
			'MethodReceiver',

			-- A method specification without implementation.
			'MethodSpecification',

			-- A message definition.
			'Message',

			-- A mixin declaration.
			'Mixin',

			-- A modifier.
			'Modifier',

			-- A module declaration.
			'Module',

			-- A namespace used to group symbols.
			'Namespace',

			-- A null or absent value.
			'Null',

			-- A numeric value or type.
			'Number',

			-- An object value.
			'Object',

			-- An operator symbol.
			'Operator',

			-- A package declaration.
			'Package',

			-- A package-level object.
			'PackageObject',

			-- A function or method parameter.
			'Parameter',

			-- A labeled parameter.
			'ParameterLabel',

			-- A pattern synonym.
			'Pattern',

			-- A logical predicate.
			'Predicate',

			-- A property symbol.
			'Property',

			-- A protocol definition.
			'Protocol',

			-- A protocol method without implementation.
			'ProtocolMethod',

			-- A pure virtual method.
			'PureVirtualMethod',

			-- A quasiquoter.
			'Quasiquoter',

			-- The `self` parameter in methods.
			'SelfParameter',

			-- A setter accessor.
			'Setter',

			-- A signature, analogous to a struct.
			'Signature',

			-- A singleton class.
			'SingletonClass',

			-- A singleton method.
			'SingletonMethod',

			-- A static data member.
			'StaticDataMember',

			-- A static event.
			'StaticEvent',

			-- A static field.
			'StaticField',

			-- A static method.
			'StaticMethod',

			-- A static property.
			'StaticProperty',

			-- A static variable.
			'StaticVariable',

			-- A string value or type.
			'String',

			-- A struct type.
			'Struct',

			-- A subscript.
			'Subscript',

			-- A proof tactic.
			'Tactic',

			-- A proven theorem.
			'Theorem',

			-- A `this` receiver parameter.
			'ThisParameter',

			-- A trait definition.
			'Trait',

			-- A trait method without implementation.
			'TraitMethod',

			-- A type definition.
			'Type',

			-- A type alias.
			'TypeAlias',

			-- A type class definition.
			'TypeClass',

			-- A method belonging to a type class.
			'TypeClassMethod',

			-- A type family declaration.
			'TypeFamily',

			-- A generic type parameter.
			'TypeParameter',

			-- A union type.
			'Union',

			-- A value-level symbol.
			'Value',

			-- A variable binding.
			'Variable',
		},
	},
	snacks = {
		source = {
			title = 'Symbols',
			debug = {
				scores = false,
			},
		},
	},
}
