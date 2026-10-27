#!/usr/bin/env python
import os
import sys

env = SConscript("godot-cpp/SConstruct")

env.Append(CPPPATH=["src/"])
sources = Glob("src/*.cpp")

if env["platform"] == "macos":
    library = env.SharedLibrary(
        "bin/librobloxclone{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )
elif env["platform"] == "ios":
    library = env.StaticLibrary(
        "bin/librobloxclone{}{}".format(env["suffix"], env["LIBSUFFIX"]),
        source=sources,
    )
else:
    library = env.SharedLibrary(
        "bin/librobloxclone{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )

Default(library)
