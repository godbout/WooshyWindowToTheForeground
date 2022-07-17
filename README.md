<h1 align="center">Wooshy: Window to the Foreground!</h1>
<p align="center">
    <a href="https://www.alfredapp.com">Alfred</a> <a href="https://www.alfredapp.com/workflows/">Workflow</a> that brings your windows to the foreground when Alfred itself cannot. 
</p>

https://user-images.githubusercontent.com/121373/179395191-1b2b3e05-4ffc-4bac-8224-2ba1101c155b.mp4

___

# Why

Aren't you annoyed when you have your fingers gently caressing your keyboard for hours but then you have one of those popups or windows that you can't reach with any tool including Alfred.
Well here you go.

# Why is this an Alfred Workflow and not part of Wooshy?

The goal of [Wooshy](https://wooshy.app) is to take as little screen estate as possible. What you want to see from Wooshy is the list of UI elements it can help you reach, not a big Input with a list of results à la Alfred.
Having this in Wooshy would then require creating one more Input specifically made for this feature, which means one more keyboard shortcut to remember. That's bad UX.
If you use Wooshy, you probably also use Alfred. And it's the perfect tool for this.

# Permissions

macOS requires `Screen Recording` permissions (yes. huh.) to [read windows names](https://github.com/godbout/WooshyWindowToTheForeground/blob/129f1cdf213988d194135e95a9cdb55621840183/WooshyWindowToTheForeground/Core/Menus/Entrance.swift#L60), and the `Accessibility` to manipulate windows.
You may give those permissions to Alfred itself, or to this Workflow. Up to what makes you more comfortable.

# But I use Raycast!

Raycast comes with a window switching feature integrated (although it may not find all windows).
