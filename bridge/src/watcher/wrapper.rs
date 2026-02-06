use std::ops::{Deref, DerefMut};

use mlua::prelude::*;

use crate::{logger, watcher::RUNTIME};

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
        methods.add_async_method(
            "start",
            async |_lua, this: mlua::UserDataRef<Self>, (): ()| {
                let _guard = RUNTIME.enter();

                let (watcher_start, initial_index_run) =
                    tokio::join!(this.start(), this.run_full_index());

                watcher_start.map_err(|err| mlua::Error::RuntimeError(err.to_string()))?;
                initial_index_run.map_err(|err| {
                    mlua::Error::RuntimeError(format!("Initial indexing failed: {err:?}"))
                })?;

                mlua::Result::Ok(())
            },
        );

        methods.add_method("stop_blocking", |_lua, this: &Self, (): ()| {
            futures::executor::block_on(this.0.stop());

            // This is usually called right before Vim is exited, and as such we should
            // flush the logs onto disk eagerly
            logger::flush();

            mlua::Result::Ok(())
        });
    }
}
