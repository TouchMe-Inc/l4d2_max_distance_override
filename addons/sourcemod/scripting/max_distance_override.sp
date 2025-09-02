#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>
#include <left4dhooks>


public Plugin myinfo = {
    name        = "MaxDistanceOverride",
    author      = "TouchMe",
    description = "Dynamically overrides the Versus max completion score for specific maps",
    version     = "build0001",
    url         = "https://github.com/TouchMe-Inc/l4d2_max_distance_override"
}


#define CMD_SET                "max_distance_set"
#define CMD_CLEAR              "max_distance_clear"

#define MAXSIZE_MAP_NAME       32
#define MAXSIZE_MAX_DISTANCE   8


StringMap g_hWeaponSlots = null;

/**
 * Called when the plugin is loaded.
 * Ensures the engine is Left 4 Dead 2 before continuing.
 */
public APLRes AskPluginLoad2(Handle myself, bool bLate, char[] sErr, int iErrLen)
{
    if (GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(sErr, iErrLen, "Plugin only supports Left 4 Dead 2");
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
    g_hWeaponSlots = new StringMap();

    RegServerCmd(CMD_SET, Cmd_Set);
    RegServerCmd(CMD_CLEAR, Cmd_Clear);
}

/**
 * Applies stored max distance if available for this map.
 */
public void OnMapStart() {
    RequestFrame(OnMapStart_Post);
}

void OnMapStart_Post()
{
    char szCurrentMapName[MAXSIZE_MAP_NAME];
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

    char szMapName[MAXSIZE_MAP_NAME];
    GetCmdArg(1, szMapName, sizeof(szMapName));

    char szMaxDistance[MAXSIZE_MAX_DISTANCE];
    GetCmdArg(2, szMaxDistance, sizeof(szMaxDistance));

    int iMaxDistance = StringToInt(szMaxDistance);

    if (g_hWeaponSlots.SetValue(szMapName, iMaxDistance))
    {
        char szCurrentMapName[MAXSIZE_MAP_NAME];
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
