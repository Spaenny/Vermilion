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

local Skin = {}

if(CLIENT) then
	surface.CreateFont( 'VToolkitButton', {
		font		= 'Helvetica',
		size		= 14,
		weight		= 500,
		additive 	= false,
		antialias 	= true,
		bold		= true,
	} )
end

Skin.CheckboxCross = Material("icon16/cross.png")

Skin.Checkbox = {}
Skin.Checkbox.Config = function(checkbox)
	checkbox:SetTextColor( Color( 0, 0, 0, 255 ) )
end

Skin.Checkbox.Paint = function(self, w, h)
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.DrawRect( 0, 0, w, h )
	surface.SetDrawColor( 255, 0, 0, 255 )
	surface.DrawOutlinedRect( 0, 0, w, h )
	surface.SetMaterial( Skin.CheckboxCross )
	if self:GetChecked() then
		surface.DrawTexturedRect( 2, 2, w - 4, h - 4 )
	end
end


Skin.Button = {}
Skin.Button.Config = function(button)
	button:SetColor(Color(0, 0, 0, 255))
	button:SetFont("VermilionButton")
end

Skin.Button.Paint = function(self)
	local w, h = self:GetWide(), self:GetTall()
	-- body
	surface.SetDrawColor( 255, 240, 240, 255 )
	surface.DrawRect( 0, 0, w, h )
	-- frame
	surface.SetDrawColor( 255, 0, 0, 255 )
	surface.DrawOutlinedRect( 0, 0, w, h )
end


Skin.Textbox = {}
Skin.Textbox.Config = function(textbox)
	textbox.m_bBackground = false
	textbox.m_colText = Color( 0, 0, 0, 255 )
end

Skin.Textbox.Paint = function( self, w, h )
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.DrawRect( 0, 0, w, h )
	surface.SetDrawColor( 255, 0, 0, 255 )
	surface.DrawOutlinedRect( 0, 0, w, h )
	if(self.PlaceholderText != nil and (self:GetValue() == nil or self:GetValue() == "")) then
		surface.SetTextColor(0, 0, 0, 128)
		surface.SetFont(self.m_FontName)
		surface.SetTextPos(2, self:GetTall() / 2 - (select(2, surface.GetTextSize(self.PlaceholderText)) / 2))
		surface.DrawText(self.PlaceholderText)
	end
	self:DrawTextEntryText( self.m_colText, self.m_colHighlight, self.m_colCursor )
end


Skin.Frame = {}
Skin.Frame.Config = function(frame)
	frame.lblTitle:SetBright(true)
end

Skin.Frame.Paint = function( self, w, h ) 
	-- body
	surface.SetDrawColor( 100, 0, 0, 200 )
	surface.DrawRect( 0, 0, w, h )
	-- frame
	surface.SetDrawColor( 255, 0, 0, 200 )
	surface.DrawOutlinedRect( 0, 0, w, h )
end


Skin.WindowPanel = {}
Skin.WindowPanel.Paint = function(self, w, h)
	-- body
	surface.SetDrawColor( 100, 0, 0, 200 )
	surface.DrawRect( 0, 0, w, h )
	-- frame
	surface.SetDrawColor( 255, 0, 0, 200 )
	surface.DrawOutlinedRect( 0, 0, w, h )
end


Skin.PropertySheet = {}
Skin.PropertySheet.Paint = function(self, w, h)
	-- body
	surface.SetDrawColor( 100, 0, 0, 200 )
	surface.DrawRect( 0, 0, w, h )
	-- frame
	surface.SetDrawColor( 255, 0, 0, 200 )
	surface.DrawOutlinedRect( 0, 0, w, h )
end

Skin.CollapsibleCateogryHeader = {}
Skin.CollapsibleCateogryHeader.Paint = function(self, w, h)
	surface.SetDrawColor(Color(255, 0, 0))
	surface.DrawRect(0, 0, w, 20)
end

VToolkit:RegisterSkin("Basic", Skin)