use std::ops::{Deref, DerefMut};

use mlua::prelude::*;

use crate::watcher::RUNTIME;

/// A newtype Lua binding for the [`onoma::watcher::Watcher`] struct.
///
/// This struct can be safely returned from Rust to Lua,
/// and Rust methods on the struct can be called by Lua.
pub struct Watcher<I>(pub(super) onoma::watcher::Watcher<I>)
where
    I: onoma::indexer::Indexer + Send + 'static;

impl<I> DerefMut for Watcher<I>
where
    I: onoma::indexer::Indexer + Send + 'static,
{
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl<I> Deref for Watcher<I>
where
    I: onoma::indexer::Indexer + Send + 'static,
{
    type Target = onoma::watcher::Watcher<I>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<I> LuaUserData for Watcher<I>
where
    I: onoma::indexer::Indexer + Send + 'static,
{
    fn add_methods<M: LuaUserDataMethods<Self>>(methods: &mut M) {
        methods.add_async_method_mut(
            "start",
            async |_lua, mut this: mlua::UserDataRefMut<Self>, (): ()| {
                let _guard = RUNTIME.enter();

                this.start()
                    .map_err(|err| mlua::Error::RuntimeError(err.to_string()))?;

                this.run_full_index().await.map_err(|err| {
                    mlua::Error::RuntimeError(format!("Initial indexing failed: {err:?}"))
                })?;

                mlua::Result::Ok(())
            },
        );
    }
}
