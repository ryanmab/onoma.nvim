use std::{ops::Deref, str::FromStr};

pub struct Level(log::Level);

impl Deref for Level {
    type Target = log::Level;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl mlua::FromLua for Level {
    fn from_lua(value: mlua::Value, _lua: &mlua::Lua) -> mlua::Result<Self> {
        match value {
            mlua::Value::String(s) => Ok(log::Level::from_str(&s.to_str()?)
                .map_err(|e| mlua::Error::FromLuaConversionError {
                    from: "str",
                    to: "Level".to_string(),
                    message: Some(format!("Invalid log level: {e}")),
                })
                .map(Level)?),
            _ => Err(mlua::Error::FromLuaConversionError {
                from: value.type_name(),
                to: "Level".to_string(),
                message: Some("Expected a string".to_string()),
            }),
        }
    }
}
