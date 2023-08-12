<h1 align="center">Wooshy: Window to the Foreground!</h1>

<p align="center">
    <a href="https://apps.apple.com/us/app/macos-big-sur/id1526878132?mt=12"><img src="https://img.shields.io/badge/macOS-11.5 Big%20Sur%2B-red"></a>
    <a href="https://github.com/godbout/WooshyWindowToTheForeground/actions"><img src="https://img.shields.io/github/actions/workflow/status/godbout/WooshyWindowToTheForeground/main.yml?branch=master" alt="Build Status"></a>
    <a href="https://github.com/godbout/WooshyWindowToTheForeground/releases"><img src="https://img.shields.io/github/release/godbout/WooshyWindowToTheForeground.svg" alt="GitHub Release"></a>
    <a href="https://github.com/godbout/WooshyWindowToTheForeground/releases"><img src="https://img.shields.io/github/downloads/godbout/WooshyWindowToTheForeground/total.svg" alt="GitHub Downloads"></a>
</p>

<p align="center">
    Switch apps with <a href="https://www.alfredapp.com">Alfred</a>. Switch app windows with <a href="https://github.com/godbout/WooshyWindowToTheForeground/releases/latest">Wooshy: Window to the Foreground!</a>
</p>

https://user-images.githubusercontent.com/121373/179673312-38913928-a51b-453e-aac8-ef41b21ab497.mp4

___

# Why

Aren't you annoyed when you have your fingers gently caressing your keyboard for hours but then you have one of those popups or windows that you can't reach and then you have to move your whole hand for like a whole second?

Alfred can switch apps but not windows within apps, nor windows without apps. So here you go.

# Features

* FAST
* brings visible windows to the foreground
* all visible windows are listed except the one you're already on because why would you want that (last part is actually changeable through the Workflow Configuration)
* Alfred results order follows windows order: first result is most frontmost, last result is most backmost (LOL)
* window match is 100% accurate
* DID I SAY FAST???

# Permissions

macOS requires `Screen Recording` permissions (yes. huh?) to [read windows names](https://github.com/godbout/WooshyWindowToTheForeground/blob/c906b1921ad4b419f8aa99a469a2a3f76b0952fb/WooshyWindowToTheForeground/Menus/Entrance.swift#L158), and the `Accessibility` permissions to manipulate windows.
You most probably have already given the `Accessibility` permissions to Alfred, which is enough.
For the `Screen Recording` permissions, the Workflow will detect if they're missing and you'll be able to prompt from an Alfred Result.

⚠️ Developers can only show the `Screen Recording` permissions dialog once. This is a "feature" from Apple.
If for whatever reason you've missed it or denied the permissions, you'll have to add Alfred or this Workflow manually in the macOS `Privacy & Security` Settings, or [reset the permissions dialog status manually](https://apple.stackexchange.com/questions/384230/how-do-i-reset-screen-recording-permission-on-macos-catalina).

# Updates

Starting with version 3.0.0 _Wooshy: Window to the Foreground!_ is built to be integrated with the new [Alfred Gallery](https://www.google.com/search?q=alfred+gallery). Now Alfred itself will take care of the Workflow's update!

# Why is this an Alfred Workflow and not part of Wooshy?

The goal of [Wooshy](https://wooshy.app) is to take as little screen estate as possible. What you want to see from Wooshy is the list of UI elements it can help you reach, not a big Input with a list of results à la Alfred.
Having this in Wooshy would then require creating one more Input specifically made for this feature, which means one more keyboard shortcut to remember. That's bad UX.
If you use Wooshy, you probably also use Alfred. Alfred is the perfect tool for this.

# Roadmap

[Here](https://github.com/godbout/WooshyWindowToTheForeground/issues?q=is%3Aissue+is%3Aopen+label%3Aroadmap).

# But I use Raycast!

Raycast comes with a window switching feature integrated (although it may not find all windows).

# Alternatives

* [Contexts](https://contexts.co) (paid app)
* [Swift Window Switcher](https://github.com/mandrigin/AlfredSwitchWindows) (free, open-source Alfred Workflow, windows and tabs)
* [Window Switcher](https://github.com/alfredapp/window-switcher-workflow/) (free, open-source Alfred Workflow, also hidden windows and maybe more)
