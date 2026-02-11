<h1>Auto Hide UI</h1>

<h3><font color="83d2ff">What this does:</font></h2>

Fades out UI Elements and brings them back when certain conditions (like mouseover or combat) are met.<br>
You choose what, how and when to fade!<br>
- Esc => "Options" => "Addons" => "Auto Hide UI"
- /autohide
- /autohideui
<h3><font color="83d2ff">Default behavior:</font></h2>

Frames will fade out or remain hidden until any of these conditions are true:
- you are <b>in combat</b>
- you have a <b>target</b>
- you are <b>in an instance</b>
- you <b>mouseover</b> a hidden frame
- you are <b>below 35% health</b>
- you are <b>in a vehicle</b>

<h3><font color="83d2ff">Customizability:</font></h2>

You decide which Frames are affected and under which conditions they should be visible/hidden.  
- Choose which Frames are affected.
- Customize fade conditions and behavior.
- Create Groups to assign different settings to different Frames.
- Add Custom Frames that aren't listed in the GUI.

You could have your UnitFrames and your CooldownManager fade in whenever you are in combat.<br>
And have that one ActionBar with toys and mounts only fade in when you mouse over it. 

<h3><font color="83d2ff">Supports other AddOns:</font></h2>

Supports <b>ElvUI</b>, <b>Unhalted Unit Frames</b>, <b>Details</b> and <b>Dominos</b>.<br>
Will automatically detect and use their Frames over the default Blizzard ones.<br>
I can't add support for Bartender, but it has its own fade system built in.<br>
<br>
There is a setting in the "Fade Settings" tab to override the Alpha of these AddOns. It's enabled by default.<br>
If you want these AddOns to remain in control of their Alpha (for range checks or their own fade system), either remove their Frames from <b>Auto Hide UI</b> or disable this setting.


<h3><font color="83d2ff">How to add Custom Frames:</font></h2>

If the provided Frame selection doesn't include the Frame you wish to hide, you must first find out that Frame's name:
- Type /fstack in your chat.
- Hover your mouse over the Frame you want to hide.
- The Tooltip is most likely highlighting some sub-element, like a button or a texture.  
Your goal is to find the root of that Frame.
- Press the left or right Alt key to cycle up and down the stack.  
Right Alt will probably take you there faster.
- Once your entire Frame (not just a part of it) is marked green, check the Tooltip for the entry marked with an arrow. This is probably the Frame you are looking for. 
- It may take a few guesses until you find the right Frame.
- Type /fstack again when you're done.  

Once you know the name, open the Options, scroll down in the "Frame Selection" tab and enter it in the text box for "Custom Frames".<br>
Separate multiple entries with a comma. The entries are case-sensitive!
