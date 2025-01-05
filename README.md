
# nvirun

*nvirun* is the plugin manager for plugins written using the *nvi* Rust
framework. Managing addons with it is similar to using *lazy* for Lua plugins,
and *nvirun* itself is designed to be installed with a package manager.

```lua
require("lazy").setup({
    {
        dir = "cortesi/nvirun.nvim",
        config = function()
            require("nvirun").plugins(
                {
                    {
                        "cortesi/nvi-win",
                    },
                    {
                        "cortesi/nvi-stacks",
                        opts: {
                            bar = "top",
                        }
                    }
                }
            )
        end
    },
}
```


# Design

*nvirun* manages Rust plugins using Rust's own pakage manager, *cargo*. It
installs and updates plugins using *cargo install*, which means that plugins
are installed locally as executables. By convention, nvi plugins are named with
the prefix *nvi-*, which means that all nvi plugins should be easily
discoverable by listing the contents of the cargo bin directory (usually
*~/.cargo/bin*).


# Commands

    :NviRunUpdate

    :NviRunCheck

    :NviStatus

