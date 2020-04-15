/*
 * ============================================================================
 *
 *  GameUI Fix - Prevent game_ui from disabling movement prediction.
 *  Copyright (C) 2020 - Bruno "quasemago" Ronning <brunoronningfn@gmail.com>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, per version 3 of the License, or
 *  any later version.	
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
*/
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

Address g_pPatchAddress = Address_Null;
int g_patchRestore[100];
int g_patchBytes;

public Plugin myinfo =
{
	name        = "GameUI Fix",
	author      = "quasemago",
	description = "Prevent game_ui from disabling movement prediction so it doesn't lag.",
	version     = "1.0.0",
	url         = "#"
};

public void OnPluginStart()
{
	Handle gameConf = LoadGameConfigFile("gameui_fix.games");
	if (gameConf == null)
	{
		SetFailState("Could not load gamedata file.");
		return;
	}

	// Get Offsets.
	int patchOffset = GameConfGetOffset(gameConf, "PatchOffset");
	if (patchOffset == -1)
	{
		SetFailState("Could not get 'PatchOffset' offset!");
		return;
	}

	g_patchBytes = GameConfGetOffset(gameConf, "PatchBytes");
	if (g_patchBytes == -1)
	{
		SetFailState("Could not get 'PatchBytes' offset!");
		return;
	}

	// Get function address.
	Address pAddy = GameConfGetAddress(gameConf, "GameUI_Think");
	if (pAddy == Address_Null)
	{
		SetFailState("Could not get 'CGameUI::Think' address!");
		return;
	}

	// Patch function.
	Address pPatch = pAddy + view_as<Address>(patchOffset);
	g_pPatchAddress = pPatch;

	for (int i = 0; i < g_patchBytes; i++)
	{
		g_patchRestore[i] = LoadFromAddress(pPatch + view_as<Address>(i), NumberType_Int8);
		StoreToAddress(pPatch + view_as<Address>(i), 0x90, NumberType_Int8);
	}

	delete gameConf;
}

public void OnPluginEnd()
{
	// Restore original function.
	if (g_pPatchAddress != Address_Null)
	{
		for (int i = 0; i < g_patchBytes; i++)
		{
			StoreToAddress(g_pPatchAddress + view_as<Address>(i), g_patchRestore[i], NumberType_Int8);
		}
	}
}