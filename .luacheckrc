std = "lua54"
unused_args = false
allow_defined_top = true
globals = {
  "vim",
}

exclude_files = {
  ".luarocks/**",
}
files["lua/**/*.lua"] = {
  ignore = {
    "631", -- line too long
  }
}
