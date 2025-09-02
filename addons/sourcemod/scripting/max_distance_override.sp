#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>
#include <left4dhooks>
#include <colors>


public Plugin myinfo = {
    name        = "MaxDistanceOverride",
    author      = "TouchMe",
    description = "Dynamically overrides the Versus max completion score for specific maps",
    version     = "build0001",
    url         = "https://github.com/TouchMe-Inc/l4d2_max_distance_override"
}


#define TRANSLATIONS           "max_distance_override.phrases"

#define CMD_SET                "max_distance_set"
#define CMD_CLEAR              "max_distance_clear"

#define MAXLENGTH_MAP_NAME     32
#define MAXLENGTH_MAX_DISTANCE 8


StringMap g_hWeaponSlots = null;


/**
 * Called when the plugin is loaded.
 * Ensures the engine is Left 4 Dead 2 before continuing.
 */
public APLRes AskPluginLoad2(Handle myself, bool bLate, char[] szErr, int iErrLen)
{
    if (GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(szErr, iErrLen, "Plugin only supports Left 4 Dead 2");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/**
 * Called when the plugin starts.
 * Initializes storage and registers server commands.
 */
public void OnPluginStart()
{
    LoadTranslations(TRANSLATIONS);

    g_hWeaponSlots = new StringMap();

    RegServerCmd(CMD_SET, Cmd_Set);
    RegServerCmd(CMD_CLEAR, Cmd_Clear);
    RegConsoleCmd("sm_mapinfo", Cmd_MapInfo);
}

/**
 * Applies stored max distance if available for this map.
 */
public void OnMapStart() {
    RequestFrame(OnMapStart_Post);
}

void OnMapStart_Post()
{
    char szCurrentMapName[MAXLENGTH_MAP_NAME];
    GetCurrentMap(szCurrentMapName, sizeof(szCurrentMapName));

    int iValue = 0;
    if (g_hWeaponSlots.GetValue(szCurrentMapName, iValue)) {
        L4D_SetVersusMaxCompletionScore(iValue);
    }
}

/**
 * Stores a max distance for the given map and applies it if the map is active.
 */
Action Cmd_Set(int iArgs)
{
    if (iArgs != 2)
    {
        LogError("Invalid command \"" ... CMD_SET ... "\". Usage: \"" ... CMD_SET ... " <map> <value>\"");
        return Plugin_Handled;
    }

    char szMapName[MAXLENGTH_MAP_NAME];
    GetCmdArg(1, szMapName, sizeof(szMapName));

    char szMaxDistance[MAXLENGTH_MAX_DISTANCE];
    GetCmdArg(2, szMaxDistance, sizeof(szMaxDistance));

    int iMaxDistance = StringToInt(szMaxDistance);

    if (g_hWeaponSlots.SetValue(szMapName, iMaxDistance))
    {
        char szCurrentMapName[MAXLENGTH_MAP_NAME];
        GetCurrentMap(szCurrentMapName, sizeof(szCurrentMapName));

        if (StrEqual(szMapName, szCurrentMapName)) {
            L4D_SetVersusMaxCompletionScore(iMaxDistance);
        }
    }

    return Plugin_Handled;
}

/**
 * Clears all stored max distance values.
 */
Action Cmd_Clear(int iArgs)
{
    g_hWeaponSlots.Clear();

    return Plugin_Handled;
}

Action Cmd_MapInfo(int iClient, int iArgs)
{
    if (!iClient) {
        return Plugin_Continue;
    }

    CPrintToChat(iClient, "%T%T", "TAG", iClient, "MAP_DISTANCE", iClient, L4D_GetVersusMaxCompletionScore());

    return Plugin_Handled;
}