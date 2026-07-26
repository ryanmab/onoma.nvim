use std::{ops::Deref, sync::Arc};

use mlua::prelude::*;
use tokio::sync::RwLock;

use crate::watcher::RUNTIME;

/// A newtype Lua binding for the [`onoma::watcher::Watcher`] struct.
///
/// This struct can be safely returned from Rust to Lua,
/// and Rust methods on the struct can be called by Lua.
pub struct Watcher<I>(pub(super) Arc<RwLock<onoma::watcher::Watcher<I>>>)
where
    I: onoma::indexer::Indexer + Send + 'static;

impl<I> Deref for Watcher<I>
where
    I: onoma::indexer::Indexer + Send + 'static,
{
    type Target = Arc<RwLock<onoma::watcher::Watcher<I>>>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<I> LuaUserData for Watcher<I>
where
    I: onoma::indexer::Indexer + Send + 'static,
{
    fn add_methods<M: LuaUserDataMethods<Self>>(methods: &mut M) {
        methods.add_async_method(
            "start",
            async |_lua, this: mlua::UserDataRef<Self>, (): ()| {
                let _guard = RUNTIME.enter();

                this.write()
                    .await
                    .start()
                    .map_err(|err| mlua::Error::RuntimeError(err.to_string()))?;

                mlua::Result::Ok(())
            },
        );

        methods.add_async_method(
            "run_full_index",
            async |_lua, this: mlua::UserDataRef<Self>, (): ()| {
                let _guard = RUNTIME.enter();

                let watcher = Arc::clone(&this.0);

                tokio::spawn(async move {
                    let _ = watcher.read().await.run_full_index().await.map_err(|err| {
                        mlua::Error::RuntimeError(format!("Initial indexing failed: {err:?}"))
                    });
                });

                mlua::Result::Ok(())
            },
        );
    }
}
