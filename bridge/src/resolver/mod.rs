use std::{path::PathBuf, sync::LazyLock};

use mlua::prelude::*;
use onoma::resolver::DatabaseBackedResolver;

use crate::{resolver::wrapper::SymbolKind, watcher};

use tokio::runtime;

mod wrapper;

/// An async runtime instance (provided by Tokio) for the resolver to use when
/// Lua calls async functions.
///
/// Note that the runtime must be entered inside of the outermost async call, and
/// all guards must be dropped in reference order.
///
/// Also note that because Lua is the calling mechanism, the normal Tokio constructs
/// cannot be used to drive the futures. It is the responsibility of Lua to drive the async
/// calls to completion using coroutines.
///
/// ```rust
/// let _guard = RUNTIME.enter();
/// ````
static RUNTIME: LazyLock<runtime::Runtime> = LazyLock::new(|| {
    runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("Initializing Tokio runtime should not fail")
});

#[allow(clippy::unnecessary_wraps, clippy::needless_pass_by_value)]
pub fn get_resolver(
    _lua: &Lua,
    directories: Vec<PathBuf>,
) -> mlua::Result<wrapper::Resolver<DatabaseBackedResolver>> {
    let _guard = RUNTIME.enter();

    let resolver = onoma::resolver::DatabaseBackedResolver::new(
        &watcher::DATABASE_PATH,
        directories.iter().map(PathBuf::as_path),
    );

    log::info!("Created resolver for indexed directories");

    Ok(wrapper::Resolver(resolver))
}

#[allow(clippy::unnecessary_wraps)]
pub fn create_context(
    _lua: &Lua,
    (current_file, symbol_kinds): (Option<PathBuf>, Option<Vec<SymbolKind>>),
) -> mlua::Result<wrapper::Context> {
    let mut context = onoma::resolver::Context::default();

    if let Some(current_file) = current_file {
        context = context.with_current_file(current_file);
    }

    if let Some(symbol_kinds) = symbol_kinds {
        context = context.with_symbol_kinds(
            symbol_kinds
                .into_iter()
                .map(|kind| *kind)
                .collect::<Vec<onoma::models::parsed::SymbolKind>>()
                .as_slice(),
        );
    }

    Ok(wrapper::Context(context))
}
