<h1 align="center">Wooshy: Window to the Foreground!</h1>

<p align="center">
    <a href="https://apps.apple.com/us/app/macos-big-sur/id1526878132?mt=12"><img src="https://img.shields.io/badge/macOS-11.5 Big%20Sur%2B-red"></a>
    <a href="https://github.com/godbout/WooshyWindowToTheForeground/actions"><img src="https://img.shields.io/github/workflow/status/godbout/WooshyWindowToTheForeground/tests" alt="Build Status"></a>
    <a href="https://github.com/godbout/WooshyWindowToTheForeground/releases"><img src="https://img.shields.io/github/release/godbout/WooshyWindowToTheForeground.svg" alt="GitHub Release"></a>
    <a href="https://github.com/godbout/WooshyWindowToTheForeground/releases"><img src="https://img.shields.io/github/downloads/godbout/WooshyWindowToTheForeground/total.svg" alt="GitHub Downloads"></a>
</p>

<p align="center">
    Switch apps with <a href="https://www.alfredapp.com">Alfred</a>. Switch app windows with <a href="https://github.com/godbout/WooshyWindowToTheForeground/releases/latest">Wooshy: Window to the Foreground!</a>
</p>

https://user-images.githubusercontent.com/121373/179673312-38913928-a51b-453e-aac8-ef41b21ab497.mp4

___

# Why

Aren't you annoyed when you have your fingers gently caressing your keyboard for hours but then you have one of those popups or windows that you can't reach?
Alfred can switch apps but not windows within apps, nor windows without apps. Well here you go.

# Features

* FAST
* brings visible windows to the foreground
* all visible windows are listed except the already currently focused one
* Alfred results order follows windows order: first result is frontmost window, last result is backmost window
* windows are matched by title, position and size so 99.9% accurate
* FAST

# Why is this an Alfred Workflow and not part of Wooshy?

The goal of [Wooshy](https://wooshy.app) is to take as little screen estate as possible. What you want to see from Wooshy is the list of UI elements it can help you reach, not a big Input with a list of results à la Alfred.
Having this in Wooshy would then require creating one more Input specifically made for this feature, which means one more keyboard shortcut to remember. That's bad UX.
If you use Wooshy, you probably also use Alfred. It's the perfect tool for this.

# Permissions

macOS requires `Screen Recording` permissions (yes. huh.) to [read windows names](https://github.com/godbout/WooshyWindowToTheForeground/blob/129f1cdf213988d194135e95a9cdb55621840183/WooshyWindowToTheForeground/Core/Menus/Entrance.swift#L60), and the `Accessibility` to manipulate windows.
You may give those permissions to Alfred itself, or to this Workflow. Up to what makes you more comfortable.

# Roadmap

[Here](https://github.com/godbout/WooshyWindowToTheForeground/issues?q=is%3Aissue+is%3Aopen+label%3Aroadmap).

# But I use Raycast!

Raycast comes with a window switching feature integrated (although it may not find all windows).

# Alternatives

* [Contexts](https://contexts.co) (paid app)
* [Swift Window Switcher](https://github.com/mandrigin/AlfredSwitchWindows) (free, open-source Alfred Workflow, windows and tabs)
* [Window Switcher](https://github.com/alfredapp/window-switcher-workflow/) (free, open-source Alfred Workflow, also hidden windows and maybe more)
