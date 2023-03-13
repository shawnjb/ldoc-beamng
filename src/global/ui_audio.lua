--[[
{
  __extensionName__ = "ui_audio",
  __extensionPath__ = "ui/audio",
  __manuallyLoaded__ = true,
  onFirstUpdate = <function 1>,
  playEventSound = <function 2>,
  ui_sound_classes = {
    bng_back_generic = {
      click = {
        sfx = "event:>UI>Generic>Back"
      }
    },
    bng_back_hover_generic = {
      click = {
        sfx = "event:>UI>Generic>Back"
      },
      mouseenter = {
        sfx = "event:>UI>Generic>Hover"
      }
    },
    bng_cancel_generic = {
      click = {
        sfx = "event:>UI>Generic>Cancel"
      }
    },
    bng_cancel_hover_generic = {
      click = {
        sfx = "event:>UI>Generic>Cancel"
      },
      mouseenter = {
        sfx = "event:>UI>Generic>Hover"
      }
    },
    bng_checkbox_generic = {
      click = {
        sfx = "event:>UI>Generic>Checkbox"
      }
    },
    bng_click_generic = {
      click = {
        sfx = "event:>UI>Generic>Click_Tonal"
      }
    },
    bng_click_generic_small = {
      click = {
        sfx = "event:>UI>Generic>Click_Tonal_Small"
      }
    },
    bng_click_hover_bigmap = {
      click = {
        sfx = "event:>UI>Bigmap>Select_Entry"
      },
      mouseenter = {
        sfx = "event:>UI>Bigmap>Hover_Entry"
      }
    },
    bng_click_hover_generic = {
      click = {
        sfx = "event:>UI>Generic>Click_Tonal"
      },
      mouseenter = {
        sfx = "event:>UI>Generic>Hover"
      }
    },
    bng_click_set_route = {
      click = {
        sfx = "event:>UI>Bigmap>Route"
      }
    },
    bng_hover_generic = {
      mouseenter = {
        sfx = "event:>UI>Generic>Hover"
      }
    },
    bng_pause_generic = {
      click = {
        sfx = "event:>UI>Generic>Pause"
      }
    }
  }
}
]]


--- @meta
--- @module 'ui_audio'

--- @class ui_audio
--- @field __extensionName__ 'ui_audio'
--- @field __extensionPath__ 'ui/audio'
--- @field __manuallyLoaded__ boolean
--- @field ui_sound_classes table<string, table<string, table<string, string>>>
ui_audio = {}

--- Plays an event sound.
--- @vararg any
--- @return any
function ui_audio.playEventSound(...) end

--- Runs the first update.
--- @vararg any
--- @return any
function ui_audio.onFirstUpdate(...) end
