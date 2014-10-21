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

lang:Add("no_users", "No such player exists on the server.")
lang:Add("ambiguous_users", "Ambiguous results for search \"%s\". (Matched %s users).")
lang:Add("access_denied", "Access Denied!")
lang:Add("under_construction", "Under Construction!")


--[[

	//		Prints:Settings		\\

]]--


--[[

	//		Categories		\\

]]--

lang:Add("category:basic", "Basics")
lang:Add("category:server", "Server Settings")
lang:Add("category:ranks", "Ranks")
lang:Add("category:player", "Player Editors")
lang:Add("category:limits", "Limits")


--[[

	//		Toolgun Limiter

]]--

lang:Add("limit_toolgun:cannot_use", "You cannot use this toolgun mode!")


Vermilion:RegisterLanguage(lang)