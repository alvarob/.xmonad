import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run
import XMonad.Util.EZConfig
import XMonad.Layout.Spacing
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.FadeWindows
import XMonad.Util.Replace
import XMonad.Util.Run

import System.IO
import System.Exit

import Data.Monoid

import Graphics.X11.ExtraTypes.XF86

import qualified XMonad.StackSet as W
import qualified Data.Map        as M

------------------------------------------------------------------------

myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $

    -- launch a terminal
    [ ((mod1Mask .|. controlMask, xK_t), spawn $ XMonad.terminal conf)

    -- launch dmenu
    , ((modm,               xK_r     ), spawn "dmenu_run")
    , ((modm,               xK_t     ), spawn "dmenu-terminal.sh")
      
    -- lock screen
    , ((mod1Mask .|. controlMask, xK_l), spawn "dm-tool lock")

    -- control displays
    , ((mod1Mask .|. controlMask, xK_d), spawn "/home/alvr/scripts/switch_displays.sh")
    , ((mod1Mask .|. controlMask, xK_Left), spawn "/home/alvr/scripts/switch_displays.sh left")
    , ((mod1Mask .|. controlMask, xK_Right), spawn "/home/alvr/scripts/switch_displays.sh right")

    -- close focused window
    , ((mod1Mask,           xK_F4),     kill)

     -- Rotate through the available layout algorithms
    , ((modm,               xK_space ), sendMessage NextLayout)

    --  Reset the layouts on the current workspace to defaulj
    , ((modm .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)

    -- Resize viewed windows to the correct size
    , ((modm,               xK_n     ), refresh)

    -- Move focus to the next window
    , ((modm,               xK_Tab   ), windows W.focusDown)

    -- Move focus to the next window
    , ((modm,               xK_j     ), windows W.focusDown)

    -- Move focus to the previous window
    , ((modm,               xK_k     ), windows W.focusUp  )

    -- Move focus to the master window
    , ((modm,               xK_m     ), windows W.focusMaster  )

    -- Swap the focused window and the master window
    , ((modm,               xK_Return), windows W.swapMaster)

    -- Swap the focused window with the next window
    , ((modm .|. shiftMask, xK_j     ), windows W.swapDown  )

    -- Swap the focused window with the previous window
    , ((modm .|. shiftMask, xK_k     ), windows W.swapUp    )

    -- Shrink the master area
    , ((modm,               xK_h     ), sendMessage Shrink)

    -- Expand the master area
    , ((modm,               xK_l     ), sendMessage Expand)

    -- Push window back into tiling
    , ((modm,               xK_z     ), withFocused $ windows . W.sink)

    -- Increment the number of windows in the master area
    , ((modm              , xK_comma ), sendMessage (IncMasterN 1))

    -- Deincrement the number of windows in the master area
    , ((modm              , xK_period), sendMessage (IncMasterN (-1)))

    -- Print screen
    , ((0, xK_Print), spawn "scrot ~/screenshots/%Y-%m-%d-%T-screenshot.png")
      
    -- Toggle the status bar gap
    -- Use this binding with avoidStruts from Hooks.ManageDocks.
    -- See also the statusBar function from Hooks.DynamicLog.
    , ((modm              , xK_b     ), sendMessage ToggleStruts)

    -- Quit xmonad
    , ((modm .|. shiftMask, xK_q     ), io (exitWith ExitSuccess))

    -- Restart xmonad
    , ((modm              , xK_q     ), spawn "xmonad --recompile; xmonad --restart")

    -- Replace with openbox

    , ((mod1Mask .|. controlMask, xK_o), restart "/home/alvr/.xmonad/xopenbox.sh" True)


    -- Volume keys
    , ((0, xF86XK_AudioLowerVolume   ), spawn "pactl set-sink-volume 0 -- -5%")
    , ((0, xF86XK_AudioRaiseVolume   ), spawn "pactl set-sink-volume 0 +5%")
    , ((0, xF86XK_AudioMute          ), spawn "amixer set Master toggle")


    -- Media keys for MPD:
    , ((0, xF86XK_AudioPlay          ), spawn "/home/alvr/scripts/mpdplay.sh")
    , ((0, xF86XK_AudioPrev          ), spawn "( sleep 0.1; echo 'previous'; ) | telnet localhost 6600")
    , ((0, xF86XK_AudioNext          ), spawn "( sleep 0.1; echo 'next'; ) | telnet localhost 6600")
    , ((0, xF86XK_AudioStop          ), spawn "( sleep 0.1; echo 'stop'; ) | telnet localhost 6600")
    ]
    ++

    --
    -- mod-[1..9], Switch to workspace N
    -- mod-shift-[1..9], Move client to workspace N
    --
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++

    --
    -- mod-{i,o,p}, Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{i,o,p}, Move client to screen 1, 2, or 3
    --
    [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_i, xK_o, xK_p] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]


------------------------------------------------------------------------

myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $

    -- mod-button1, Set the window to floating mode and move by dragging
    [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w
                                       >> windows W.shiftMaster))

    -- mod-button2, Raise the window to the top of the stack
    , ((modm, button2), (\w -> focus w >> windows W.shiftMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modm, button3), (\w -> focus w >> mouseResizeWindow w
                                       >> windows W.shiftMaster))

    -- you may also bind events to the mouse scroll wheel (button4 and button5)
    ]

------------------------------------------------------------------------

myLayout = avoidStruts( Mirror tiled ||| tiled ||| Full )
  where
     -- default tiling algorithm partitions the screen into two panes
     tiled   = spacing 3 $ Tall nmaster delta ratio

     -- The default number of windows in the master pane
     nmaster = 1

     -- Default proportion of screen occupied by master pane
     ratio   = 2/3

     -- Percent of screen to increment by when resizing panes
     delta   = 3/100

------------------------------------------------------------------------

myManageHook = composeAll
               [ className =? "Gimp"      --> doFloat
               , className =? "Vncviewer" --> doFloat
               ]

------------------------------------------------------------------------

alwaysOpaque = [ "Firefox", "Evince", "feh", "Plugin-container",
                 "VirtualBox", "luakit", "Vlc", "libreoffice-writer",
                 "Krita", "Chromium", "libprs500"]

myFadeHook = composeAll(
             [ opacity 0.85
             , isUnfocused --> opacity 0.7
             ]
             ++
             [ className =? name --> opaque | name <- alwaysOpaque ]
             )

------------------------------------------------------------------------

main = do
    replace
    xmproc <- spawnPipe "/usr/bin/xmobar /home/alvr/.xmonad/.xmobarrc"
    xmonad $ defaultConfig
        { manageHook = manageDocks
                       <+>
                       (isDialog --> doF W.shiftMaster) <+> doF W.swapDown
                       <+>
                       myManageHook
                       <+>
                       manageHook defaultConfig
        , layoutHook = myLayout
        , logHook = dynamicLogWithPP xmobarPP
                        { ppOutput = hPutStrLn xmproc
                        , ppTitle = xmobarColor "#97B4C2" "" . shorten 50
                        , ppLayout = const ""
                        }
                        <+>
                        fadeWindowsLogHook myFadeHook
        , handleEventHook = fadeWindowsEventHook
        , modMask = mod4Mask
        , terminal = "urxvt"
        , focusFollowsMouse = False
        , keys = myKeys
        , mouseBindings = myMouseBindings
        , focusedBorderColor = "#97B4C2"
        , borderWidth = 1
        }
