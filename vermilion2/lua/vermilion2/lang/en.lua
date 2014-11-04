--[[
 Copyright 2014 Ned Hyett

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 in compliance with the License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License
 is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 or implied. See the License for the specific language governing permissions and limitations under
 the License.
 
 The right to upload this project to the Steam Workshop (which is operated by Valve Corporation) 
 is reserved by the original copyright holder, regardless of any modifications made to the code,
 resources or related content. The original copyright holder is not affiliated with Valve Corporation
 in any way, nor claims to be so. 
]]

local lang = Vermilion:CreateLangBody("English")

lang:Add("yes", "Yes")
lang:Add("no", "No")
lang:Add("close", "Close")

lang:Add("dayslabel", "Days:")
lang:Add("hourslabel", "Hours:")
lang:Add("minuteslabel", "Minutes:")
lang:Add("secondslabel", "Seconds:")


lang:Add("no_users", "No such player exists on the server.")
lang:Add("ambiguous_users", "Ambiguous results for search \"%s\". (Matched %s users).")
lang:Add("access_denied", "Access Denied!")
lang:Add("under_construction", "Under Construction!")
lang:Add("bad_syntax", "Invalid Syntax!")
lang:Add("not_number", "That isn't a number!")
lang:Add("not_bool", "That isn't a boolean!")
lang:Add("player_immune", "%s is immune to you.")
lang:Add("ban_self", "You can't ban yourself!")
lang:Add("kick_self", "You can't kick yourself!")
lang:Add("no_rank", "No such rank!")


--[[

	//		Prints:Settings		\\

]]--


--[[

	//		Categories		\\

]]--

lang:Add("category:basic", "Basics")
lang:Add("category:server", "Server Settings")
lang:Add("category:ranks", "Ranks")
lang:Add("category:player", "Player Management")
lang:Add("category:limits", "Limits")



--[[

	//		Addon Validator		\\

]]--
lang:Add("addon_validator:title", "Vermilion Addon Alert")
lang:Add("addon_validator:windowtext", [[Vermilion has detected that you are missing some addons. 

Subscribing to these addons will significantly decrease the time taken to connect to this server as you will not have to download the addons each time you connect, and will also solve any missing textures that you are seeing as a result of missing these addons! 

Please consider fixing this by using the list below!]])
lang:Add("addon_validator:open_workshop_page", "Open Workshop Page")
lang:Add("addon_validator:open_workshop_page:g1", "Must select at least one addon to open the workshop page for!")
lang:Add("addon_validator:dna", "Close and do not ask again")
lang:Add("addon_validator:dna:confirm", "Are you sure?\nThis will take effect on every server you join.\nTo reset it, type \"vermilion_addonnag_do_not_ask 0\" into the console!")


--[[

	//		Automatic Broadcast		\\

]]--
lang:Add("menu:autobroadcast", "Auto-Broadcast")
lang:Add("autobroadcast:list:text", "Text")
lang:Add("autobroadcast:list:interval", "Interval")
lang:Add("autobroadcast:list:title", "Auto-Broadcast Listings")
lang:Add("autobroadcast:remove", "Remove Listing")
lang:Add("autobroadcast:remove:g1", "Must select at least one listing to remove.")
lang:Add("autobroadcast:new", "New Listing...")
lang:Add("autobroadcast:new:interval", "Broadcast every:")
lang:Add("autobroadcast:new:add", "Add Listing")
lang:Add("autobroadcast:new:gz", "Must have interval greater than zero!")


--[[

	//		Battery Meter		\\

]]--
lang:Add("battery_meter:unplugged", "Computer unplugged!")
lang:Add("battery_meter:pluggedin", "Computer plugged in!")
lang:Add("battery_meter:low", "Low battery: %s%!")
lang:Add("battery_meter:critical", "Critical battery: %s%!")
lang:Add("battery_meter:interface", "Battery Level: %s%")
lang:Add("battery_meter:cl_opt", "Enable Battery Meter")

--[[

	//		Toolgun Limiter		\\

]]--

lang:Add("limit_toolgun:cannot_use", "You cannot use this toolgun mode!")


Vermilion:RegisterLanguage(lang)