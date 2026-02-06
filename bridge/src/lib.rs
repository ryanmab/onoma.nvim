#![crate_name = "onoma_bridge"]
#![deny(missing_docs)]
#![deny(clippy::all)]
#![warn(clippy::pedantic)]
#![warn(clippy::nursery)]
#![warn(missing_debug_implementations, rust_2018_idioms, rustdoc::all)]
#![allow(rustdoc::private_doc_tests)]
#![forbid(unsafe_code)]

//! # Onoma Bridge

use std::path::PathBuf;

use mlua::prelude::*;

mod logger;
mod resolver;
mod watcher;

#[mlua::lua_module]
fn onoma_bridge(lua: &Lua) -> LuaResult<LuaTable> {
    logger::init();

    let exports = lua.create_table()?;

    exports.set("database_path", watcher::DATABASE_PATH.as_path())?;

    exports.set(
        "get_watcher",
        lua.create_async_function::<_, Vec<PathBuf>, _, _>(watcher::get_watcher)?,
    )?;
    exports.set("get_resolver", lua.create_function(resolver::get_resolver)?)?;
    exports.set(
        "create_context",
        lua.create_function(resolver::create_context)?,
    )?;

    // Logging function for Lua to use
    exports.set("log", lua.create_function(logger::log)?)?;

    // Since Lua is responsible for driving the futures to completion, this is a helpful
    // binding which Lua coroutines can use to check if a returned value is a polling result
    // that is not yet ready.
    exports.set(
        "pending",
        lua.create_async_function(|_, ()| async move {
            tokio::task::yield_now().await;
            Ok(())
        })?,
    )?;

    Ok(exports)
}
