#include <amxmodx>
#include <reapi>
#include <fakemeta>

new g_iHudObject;
new bool:g_bOnOffPre[MAX_PLAYERS + 1];

new g_szFogType[][] = {
	"[VB]",
	"[P]",
	"[G]",
	"[B]"
};

enum E_STATSINFO {
	m_iFog,
	m_iFogType,
	Float:m_flSpeed,
	Float:m_flPreSpeed,
	Float:m_flOldSpeed,
	Float:m_flMaxPreStrafe,
	Float:m_flFallTime,
	bool:m_bFirstFallGround,
	bool:m_bShowFirst,
	bool:m_bSgs,
	bool:m_bIsDuck,
	bool:m_bLadderProtect,
	bool:m_bSlideProtect
};

new g_sStatsInfo[MAX_PLAYERS + 1][E_STATSINFO];

enum E_PLAYERINFO {
	m_iFlags,
	m_iOldFlags,
	m_iMoveType,
	m_iButtons,
	m_iOldButtons
};

new g_sPlayerInfo[MAX_PLAYERS + 1][E_PLAYERINFO];

new bool:g_isSpec[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("PreFog", "2.0.4", "WessTorn"); // Спасибо: FAME, Destroman, Borjomi, Denzer, Albertio

	register_clcmd("say /showpre", "cmdShowPre")
	register_clcmd("say /pre", "cmdShowPre")

	RegisterHookChain(RG_CBasePlayer_PreThink, "rgPlayerPreThink");

	g_iHudObject = CreateHudSyncObj();
}

public client_connect(id) {
	g_bOnOffPre[id] = true;
}

public cmdShowPre(id) {
	g_bOnOffPre[id] = g_bOnOffPre[id] ? false : true;

	if (!g_bOnOffPre[id])
		client_print_color(id, print_team_blue, "[^3PreFog^1] Show Fog/Prestrafe: ^3OFF^1");
	else
		client_print_color(id, print_team_blue, "[^3PreFog^1] Show Fog/Prestrafe: ^3ON^1");
}

public rgPlayerPreThink(id) {
	if (!g_bOnOffPre[id])
		return HC_CONTINUE;

	if (!is_user_alive(id)) {
		if(get_member(id, m_iObserverLastMode) == OBS_ROAMING)
			return HC_CONTINUE;

		g_isSpec[id] = true;
		return HC_CONTINUE;
	} else {
		g_isSpec[id] = false;
	}
	
	g_sPlayerInfo[id][m_iButtons] = get_entvar(id, var_button);
	g_sPlayerInfo[id][m_iOldButtons] = get_entvar(id, var_oldbuttons);
	g_sPlayerInfo[id][m_iFlags] = get_entvar(id, var_flags);
	g_sPlayerInfo[id][m_iMoveType] = get_entvar(id, var_movetype);
	g_sStatsInfo[id][m_flMaxPreStrafe] = get_maxspeed(id);
	g_sStatsInfo[id][m_flSpeed] = get_speed(id);

	if (g_sPlayerInfo[id][m_iFlags] & FL_ONGROUND) {
		if (!(g_sPlayerInfo[id][m_iOldFlags] & FL_ONGROUND)) {
			g_sStatsInfo[id][m_flPreSpeed] = g_sStatsInfo[id][m_flSpeed];
		}


		if (g_sStatsInfo[id][m_bFirstFallGround] == true && get_gametime() - g_sStatsInfo[id][m_flFallTime] > 0.5) {
			g_sStatsInfo[id][m_bFirstFallGround] = false;
			g_sStatsInfo[id][m_bShowFirst] = true;
		}

		if (g_sStatsInfo[id][m_bFirstFallGround] == false) {
			g_sStatsInfo[id][m_flFallTime] = get_gametime();
			g_sStatsInfo[id][m_bFirstFallGround] = true;
		}

		if (g_sPlayerInfo[id][m_iButtons] & IN_JUMP && !(g_sPlayerInfo[id][m_iOldButtons] & IN_JUMP) && g_sStatsInfo[id][m_bShowFirst]) {
			for (new i = 1; i <= MaxClients; i++) {
				if (i == id || g_isSpec[i]) {
					set_hudmessage(250, 250, 250, -1.0, 0.64, 0, 0.0, 1.0, 0.1, 0.0, 2);
					ShowSyncHudMsg(i, g_iHudObject, "[Jump]^n%.2f", g_sStatsInfo[id][m_flSpeed]);
				}
			}
			g_sStatsInfo[id][m_bShowFirst] = false;
		} else if (g_sPlayerInfo[id][m_iButtons] & IN_DUCK && !(g_sPlayerInfo[id][m_iOldButtons] & IN_DUCK) && g_sStatsInfo[id][m_bShowFirst]) {
			for (new i = 1; i <= MaxClients; i++) {
				if (i == id || g_isSpec[i]) {
					set_hudmessage(250, 250, 250, -1.0, 0.64, 0, 0.0, 1.0, 0.1, 0.0, 2);
					ShowSyncHudMsg(i, g_iHudObject, "[Duck]^n%.2f", g_sStatsInfo[id][m_flSpeed]);
				}
			}
			g_sStatsInfo[id][m_bShowFirst] = false;
		}

		if (g_sStatsInfo[id][m_iFog] <= 10) {
			g_sStatsInfo[id][m_iFog]++;

			if (g_sPlayerInfo[id][m_iButtons] & IN_DUCK && !(g_sPlayerInfo[id][m_iOldButtons] & IN_DUCK)) {
				g_sStatsInfo[id][m_bIsDuck] = true;
			}

			if (g_sStatsInfo[id][m_iFog] == 1) {
				g_sStatsInfo[id][m_bSgs] = (g_sPlayerInfo[id][m_iFlags] & FL_DUCKING) ? true : false;
			}
		}
	} else {
		if (g_sStatsInfo[id][m_bFirstFallGround] == true)
			g_sStatsInfo[id][m_bFirstFallGround] = false;

		if (isUserSurfing(id)) {
			g_sStatsInfo[id][m_iFog] = 0;
			g_sStatsInfo[id][m_bSlideProtect] = true;
		} else {
			if (g_sStatsInfo[id][m_bSlideProtect]) {
				for (new i = 1; i <= MaxClients; i++) {
					if (i == id || g_isSpec[i]) {
						set_hudmessage(250, 250, 250, -1.0, 0.64, 0, 0.0, 1.0, 0.01, 0.0);
						ShowSyncHudMsg(i, g_iHudObject, "[Slide]^n%.2f", g_sStatsInfo[id][m_flSpeed]);
					}
				}
			}
			g_sStatsInfo[id][m_bSlideProtect] = false;
		}

		if (g_sPlayerInfo[id][m_iMoveType] == MOVETYPE_FLY) {
			g_sStatsInfo[id][m_bLadderProtect] = true;
		} else {
			if (g_sStatsInfo[id][m_bLadderProtect]) {
				for (new i = 1; i <= MaxClients; i++) {
					if (i == id || g_isSpec[i]) {
						set_hudmessage(250, 250, 250, -1.0, 0.64, 0, 0.0, 1.0, 0.01, 0.0);
						ShowSyncHudMsg(i, g_iHudObject, "[Ladder]^n%.2f", g_sStatsInfo[id][m_flSpeed]);
					}
				}
			}
			g_sStatsInfo[id][m_bLadderProtect] = false;
		}

		if (g_sStatsInfo[id][m_iFog] > 0 && g_sStatsInfo[id][m_iFog] < 10) {
			g_sStatsInfo[id][m_iFogType] = 0;
			
			if (g_sPlayerInfo[id][m_iOldButtons] & IN_JUMP) {
				if (g_sStatsInfo[id][m_flSpeed] < g_sStatsInfo[id][m_flMaxPreStrafe] && (g_sStatsInfo[id][m_iFog] == 1 || g_sStatsInfo[id][m_iFog] >= 2 && g_sStatsInfo[id][m_flOldSpeed] > g_sStatsInfo[id][m_flMaxPreStrafe]))
					g_sStatsInfo[id][m_iFogType] = 1;

				if (!g_sStatsInfo[id][m_iFogType]) {
					switch(g_sStatsInfo[id][m_iFog]) {
						case 1..2: g_sStatsInfo[id][m_iFogType] = 2;
						case 3: g_sStatsInfo[id][m_iFogType] = 3;
						default: g_sStatsInfo[id][m_iFogType] = 0;
					}
				}
			} else if (g_sStatsInfo[id][m_bIsDuck]) {
				if (g_sStatsInfo[id][m_bSgs]) {
					switch(g_sStatsInfo[id][m_iFog]) {
						case 3: g_sStatsInfo[id][m_iFogType] = 1;
						case 4: g_sStatsInfo[id][m_iFogType] = 2;
						case 5: g_sStatsInfo[id][m_iFogType] = 3;
						default: g_sStatsInfo[id][m_iFogType] = 0;
					}
				} else {
					switch(g_sStatsInfo[id][m_iFog]) {
						case 2: g_sStatsInfo[id][m_iFogType] = 1;
						case 3: g_sStatsInfo[id][m_iFogType] = 2;
						case 4: g_sStatsInfo[id][m_iFogType] = 3;
						default: g_sStatsInfo[id][m_iFogType] = 0;
					}
				}
				g_sStatsInfo[id][m_bIsDuck] = false;
			}
			
			for (new i = 1; i <= MaxClients; i++) {
				if (i == id || g_isSpec[i]) {
					if (g_sStatsInfo[id][m_iFogType] == 1) {
						set_hudmessage(0, 250, 60, -1.0, 0.64, 0, 0.0, 1.0, 0.1, 0.0, 2);
						ShowSyncHudMsg(i, g_iHudObject, "%d %s^n%.2f^n%.2f", g_sStatsInfo[id][m_iFog], g_szFogType[g_sStatsInfo[id][m_iFogType]], g_sStatsInfo[id][m_flPreSpeed], g_sStatsInfo[id][m_flOldSpeed]);
					} else {
						set_hudmessage(250, 250, 250, -1.0, 0.64, 0, 0.0, 1.0, 0.1, 0.0, 2);
						ShowSyncHudMsg(i, g_iHudObject, "%d %s^n%.2f^n%.2f", g_sStatsInfo[id][m_iFog], g_szFogType[g_sStatsInfo[id][m_iFogType]],g_sStatsInfo[id][m_flPreSpeed], g_sStatsInfo[id][m_flOldSpeed]);
					}
				}
			}
			g_sStatsInfo[id][m_bIsDuck] = false;
		}
		g_sStatsInfo[id][m_bSgs] = false
		g_sStatsInfo[id][m_iFog] = 0;
	}

	g_sPlayerInfo[id][m_iOldFlags] = g_sPlayerInfo[id][m_iFlags]
	g_sStatsInfo[id][m_flOldSpeed] = g_sStatsInfo[id][m_flSpeed];

	return HC_CONTINUE;
}

stock Float:get_speed(id) {
	static Float:flVelocity[3];
	get_entvar(id, var_velocity, flVelocity);

	new Float:flNorma = floatpower(flVelocity[0], 2.0) + floatpower(flVelocity[1], 2.0)

	if (flNorma > 0.0)
		return floatsqroot(flNorma);

	return 0.0
}

stock Float:get_maxspeed(id) {
	new Float:flMaxSpeed;
	flMaxSpeed = get_entvar(id, var_maxspeed);
	
	return flMaxSpeed * 1.2;
}

stock bool:isUserSurfing(id) {
	static Float:origin[3], Float:dest[3];
	get_entvar(id, var_origin, origin);
	
	dest[0] = origin[0];
	dest[1] = origin[1];
	dest[2] = origin[2] - 1.0;

	static Float:flFraction;

	engfunc(EngFunc_TraceHull, origin, dest, 0, 
		g_sPlayerInfo[id][m_iFlags] & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, id, 0);

	get_tr2(0, TR_flFraction, flFraction);

	if (flFraction >= 1.0) return false;
	
	get_tr2(0, TR_vecPlaneNormal, dest);

	return dest[2] <= 0.7;
} 