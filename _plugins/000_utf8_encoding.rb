# Build environments without a UTF-8 locale (Cloudflare Pages: "cannot change locale (en_US.UTF-8)") make Ruby read
# files as US-ASCII. `encoding:` in _config.yml covers pages only; _data YAML is read with Ruby's default, and
# kramdown then fails on accented pt-BR text. Plugins load before the site is read, so this fixes it for every file.
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
