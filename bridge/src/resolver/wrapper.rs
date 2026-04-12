use std::{
    collections::HashMap,
    ops::{Deref, DerefMut},
    str::FromStr,
};

use mlua::prelude::*;
use onoma::models::{self};
use tokio_stream::StreamExt;

use crate::resolver::RUNTIME;

/// A newtype Lua binding for the [`onoma::resolver::Context`] struct.
///
/// This struct can be safely returned from Rust to Lua,
/// and used when querying an index using a resolver.
#[derive(Debug, FromLua, Clone)]
pub struct Context(pub onoma::resolver::Context);
impl LuaUserData for Context {}

impl Deref for Context {
    type Target = onoma::resolver::Context;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
impl DerefMut for Context {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

/// A newtype Lua binding for the Tokio Receiver stream.
///
/// This can safely be iterated through asynchronously in Lua, using coroutines.
#[derive(Debug)]
pub struct ReceiverStream<T>(tokio_stream::wrappers::ReceiverStream<T>);

impl LuaUserData for ReceiverStream<models::resolved::ResolvedSymbol> {
    fn add_methods<M: LuaUserDataMethods<Self>>(methods: &mut M) {
        methods.add_async_method_mut(
            "next",
            async |_, mut this: LuaUserDataRefMut<Self>, (): ()| {
                mlua::Result::Ok(this.0.next().await.map(ResolvedSymbol))
            },
        );
    }
}

/// A newtype Lua binding for the [`models::parsed::SymbolKind`] enum.
#[derive(Debug, Default)]
pub struct SymbolKind(models::parsed::SymbolKind);
impl IntoLua for SymbolKind {
    fn into_lua(self, lua: &Lua) -> LuaResult<LuaValue> {
        LuaResult::Ok(LuaValue::String(lua.create_string(self.0.to_string())?))
    }
}

impl FromLua for SymbolKind {
    fn from_lua(value: LuaValue, _lua: &Lua) -> LuaResult<Self> {
        match value {
            LuaValue::String(value) => {
                onoma::models::parsed::SymbolKind::from_str(value.to_string_lossy().as_str())
                    .map(SymbolKind)
                    .map_err(|e| LuaError::external(format!("Invalid SymbolKind: {e}")))
            }
            other => Err(mlua::Error::FromLuaConversionError {
                from: other.type_name(),
                to: "SymbolKind".to_string(),
                message: Some("expected symbol kind".to_string()),
            }),
        }
    }
}

impl Deref for SymbolKind {
    type Target = models::parsed::SymbolKind;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

/// A newtype Lua binding for the [`onoma::resolver::SymbolKindFilter`] enum.
#[derive(Debug)]
pub struct SymbolKindFilter(onoma::resolver::SymbolKindFilter);

impl FromLua for SymbolKindFilter {
    fn from_lua(value: LuaValue, _lua: &Lua) -> LuaResult<Self> {
        match value {
            LuaValue::Table(value) => {
                let is_list = value
                    .pairs::<LuaValue, LuaValue>()
                    .any(|res| matches!(res, Ok((LuaValue::Integer(_), _))));

                let filter = if is_list || value.is_empty() {
                    // The filter is a numerically indexed list (or close to it). This means we can read
                    // it out as a global list of symbol kinds to filter on.
                    Self(onoma::resolver::SymbolKindFilter::Global(
                        value
                            .sequence_values::<SymbolKind>()
                            .fold(Vec::new(), |mut kinds, i| {
                                if let Ok(i) = i {
                                    kinds.push(i.0);
                                }

                                kinds
                            }),
                    ))
                } else {
                    // The filter is a map of non-numerical keys (i.e. probably languages). This
                    // means we should attempt to read it out as a per-language map of languages to
                    // symbol kinds.
                    let mut per_language = HashMap::new();

                    for pair in value.pairs::<LuaValue, LuaValue>() {
                        let (k, v) = pair?;

                        let Ok(key) = k.to_string() else {
                            continue;
                        };
                        let Ok(language) = onoma::models::parsed::Language::from_str(&key) else {
                            continue;
                        };

                        let LuaValue::Table(value) = v else {
                            continue;
                        };

                        per_language.insert(
                            language,
                            value.sequence_values::<SymbolKind>().fold(
                                Vec::new(),
                                |mut kinds, i| {
                                    if let Ok(i) = i {
                                        kinds.push(i.0);
                                    }

                                    kinds
                                },
                            ),
                        );
                    }

                    Self(onoma::resolver::SymbolKindFilter::PerLanguage(per_language))
                };

                Ok(filter)
            }
            other => Err(mlua::Error::FromLuaConversionError {
                from: other.type_name(),
                to: "SymbolKindFilter".to_string(),
                message: Some("expected table or nil".to_string()),
            }),
        }
    }
}

impl Deref for SymbolKindFilter {
    type Target = onoma::resolver::SymbolKindFilter;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl From<SymbolKindFilter> for onoma::resolver::SymbolKindFilter {
    fn from(val: SymbolKindFilter) -> Self {
        val.0
    }
}

/// A newtype Lua binding for the [`models::resolved::ResolvedSymbol`] enum.
pub struct ResolvedSymbol(models::resolved::ResolvedSymbol);
impl LuaUserData for ResolvedSymbol {
    fn add_fields<F: LuaUserDataFields<Self>>(fields: &mut F) {
        fields.add_field_method_get("id", |_, this| Ok(this.id));
        fields.add_field_method_get("kind", |_, this| Ok(SymbolKind(this.kind)));
        fields.add_field_method_get("name", |_, this| Ok(this.name.clone()));
        fields.add_field_method_get("path", |_, this| Ok(this.path.clone()));
        fields.add_field_method_get("score", |_, this| Ok(*this.score));
        fields.add_field_method_get("start_line", |_, this| Ok(this.start_line));
        fields.add_field_method_get("start_column", |_, this| Ok(this.start_column));
        fields.add_field_method_get("end_line", |_, this| Ok(this.end_line));
        fields.add_field_method_get("end_column", |_, this| Ok(this.end_column));
    }
}
impl DerefMut for ResolvedSymbol {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl Deref for ResolvedSymbol {
    type Target = models::resolved::ResolvedSymbol;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

/// A newtype Lua binding for the [`onoma::resolver::Resolver`] struct.
///
/// This struct can be safely returned from Rust to Lua,
/// and Rust methods on the struct can be called by Lua.
pub struct Resolver<R>(pub(super) R)
where
    R: onoma::resolver::Resolver;

impl<R> DerefMut for Resolver<R>
where
    R: onoma::resolver::Resolver,
{
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}
impl<R> Deref for Resolver<R>
where
    R: onoma::resolver::Resolver,
{
    type Target = R;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<R> LuaUserData for Resolver<R>
where
    R: onoma::resolver::Resolver<
            QueryContext = onoma::resolver::Context,
            QueryResult = tokio_stream::wrappers::ReceiverStream<models::resolved::ResolvedSymbol>,
        > + Send
        + 'static,
{
    fn add_methods<M: LuaUserDataMethods<Self>>(methods: &mut M) {
        methods.add_async_method(
            "query",
            async |_lua, this, (query, context): (String, Context)| {
                let _guard = RUNTIME.enter();

                let symbols = this.query(query, context.0);

                mlua::Result::Ok(ReceiverStream(symbols))
            },
        );
    }
}
