/* 
*
* 	The Plugin is Made by N.O.V.A 
* 	
*	Contacts:-
*
* 		Fb:- facebook.com/nova.gaming.cs
* 		Insta :-  instagram.com/_n_o_v_a_g_a_m_i_n_g
* 		Discord :- N.O.V.A#1790
* 		Youtube :- NOVA GAMING
*
*
*/


/*----------------------------------*/
/*           INCLUDES               */
/*----------------------------------*/

#include <amxmodx>
//#include <amxmisc>
#include <engine>
#include <fun>
#include <cstrike>
//#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>


/*----------------------------------*/
/*           WEAPON-SUPPORTS        */
/*----------------------------------*/

// Uncomment the weapon you Wanna use and Comment the Others by "///"


//#define KNIFE_ITEM
#define HE_ITEM


/*----------------------------------*/
/*         ANTI-DECOMPILE           */
/*----------------------------------*/

#pragma compress 1
#pragma semicolon 1

/*----------------------------------*/
/*           MODE-SUPPORTS          */
/*----------------------------------*/

// Uncomment the Mod you are using and Comment the Others by "///"

#define NORMAL_MOD
//#define ZOMBIE_ESCAPE_MOD
//#define ZOMBIE_PLAUGE


#if defined ZOMBIE_ESCAPE_MOD

	new g_itemid;
	
	// Forwards 
	forward ze_select_item_pre(id, itemid);
	forward ze_select_item_post(id, itemid);
	forward ze_user_infected(id, itemid);
	
	// Natives
	native ze_register_item(const szItemName[], iCost, iLimit);
	native ze_is_user_zombie(id);
	
#endif

#if defined ZOMBIE_PLAUGE
	
	new g_itemid;
	#include <zombieplague>
	
#endif


/*----------------------------------*/
/*            DEFINES               */
/*----------------------------------*/

#define PLUGIN "[N:V] Bunker Buster LTD."
#define VERSION "16-12-2020"
#define AUTHOR "N.O.V.A"

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

// Task

#define TASK_FIRE 69821478

// Weapon Settings 

#define WEAPON_KEY	7812365

#if defined HE_ITEM

	#define CSW_BUNKER 	CSW_HEGRENADE
	#define weapon_bunker	"weapon_hegrenade"
	#define old_w_model "models/w_hegrenade.mdl"
	
#endif

#if defined KNIFE_ITEM

	#define CSW_BUNKER 	CSW_KNIFE
	#define weapon_bunker	"weapon_knife"
	
#endif

// Bunker Buster Two Modes.

#define MODE_ENDLESS	0
#define MODE_INPOINT	1

/*----------------------------------*/
/*            	NEWS                */
/*----------------------------------*/

new g_selected,g_has_Bunker,g_zoom,Float:pOrigin[3],m_iTrail,m_iSmoke,m_iExp,m_iFire,m_iBlackS,g_maxplayer,g_iPlayer_Mode[33],g_iCvar[10];

// Class Names
new const C_Plane[] = "nv_bunker_plane";
new const C_Missile[] = "nv_bunker_missile";
new const C_Target[] = "nv_bunker_target";
new const C_Bunker[] = "nv_bunker_dropped";

// Resources

new const MODELS[][] = 
{
	"models/bunkerbuster_missile.mdl",
	"models/b52-big.mdl",
	"models/bunkerbuster_target.mdl",
	"models/v_bunkerbuster.mdl",
	"models/bynova/v_bunker_sight_new.mdl",
	"models/p_bunkerbuster.mdl",
	"models/w_bunkerbuster.mdl"
	
};

new const SPRITES[][] =
{
	"sprites/bunkerbuster_explosion.spr",
	"sprites/bunkerbuster_fire.spr",
	"sprites/bunkerbuster_smoke.spr",
	"sprites/black_smoke3.spr"
	
};

new const GENERIC[][]=
{
	"sprites/bunker/640hud18.spr",
	"sprites/bunker/640hud166.spr",
	"sprites/weapon_bunker.txt"
	
};

new const SOUND[][] = 
{
	"weapons/bunkerbuster_draw.wav",
	"weapons/bunkerbuster_zoom_in.wav",
	"weapons/bunkerbuster_zoom_out.wav",
	"weapons/bunkerbuster_explosion_1st.wav",
	"weapons/bunkerbuster_explosion_after_1st.wav",
	"weapons/bunkerbuster_fire.wav",
	"weapons/bunkerbuster_fly.wav",
	"weapons/bunkerbuster_gauge.wav",
	"weapons/bunkerbuster_target_siren.wav",
	"weapons/bunkerbuster_whistling1.wav",
	"weapons/bunkerbuster_whistling2.wav",
	"weapons/bunkerbuster_whistling3.wav"
};

enum
{
	S_DRAW = 0,
	S_ZOOM_IN,
	S_ZOOM_OUT,
	S_EXP_1,
	S_EXP_AFTER,
	S_FIRE,
	S_FLY,
	S_GAUGE,
	S_TARGET,
	S_WIS_1,
	S_WIS_2,
	S_WIS_3
};

enum
{
	M_MISSILE = 0,
	M_PLANE,
	M_TARGET,
	M_V_MODEL,
	M_V_MODEL_SIGHT,
	M_P_MODEL,
	M_W_MODEL
	
};

enum
{
	C_DMG_FIRE = 0,
	C_FIRE_TIME,
	C_DMG_F_RAD,
	C_SHAKE_RADIUS,
	C_PRICE
};

/*----------------------------------*/
/*            	START               */
/*----------------------------------*/

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	Register_Cvars();
	
	// Events
	register_event("ResetHUD", "newRound", "b"); 
	register_logevent("logevent_round_end", 2, "1=Round_End"); 
	
	// Forwards
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_SetModel, "fw_SetModel");
	
	
	// Touch
	register_touch(C_Missile, "*", "Fw_Touch");
	register_touch(C_Bunker, "player", "Fw_Touch_Bunker");
	
	// Hams
	RegisterHam(Ham_Item_AddToPlayer, weapon_bunker , "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Item_Deploy,weapon_bunker , "fw_Item_Deploy", 1);
	
	
	#if defined HE_ITEM
		RegisterHam(Ham_Weapon_PrimaryAttack,weapon_bunker,"fw_Primary_Attack");
	#endif
	
	RegisterHam(Ham_Spawn,"player","fw_Ham_Spawn");
	
	// Thinks
	register_think(C_Plane,"Think_Plane");
	register_think(C_Missile,"Think_Missile");
	
	// CMDS
	
	//register_clcmd("say /getbunker","Give_Bunker");
	
	register_clcmd("weapon_bunker","Hook_Cmd");
	register_clcmd("drop","Drop_Bunker");
	
	// Others
	g_maxplayer = get_maxplayers();
	
	#if defined NORMAL_MOD
		register_clcmd("say /bunker","Buy_Bunker");
	#endif
	
	#if defined ZOMBIE_ESCAPE_MOD
		g_itemid = ze_register_item("[CSO] Bunker Buster LTD", 10, 0);
	#endif

	#if defined ZOMBIE_PLAUGE
		g_itemid = zp_register_extra_item("[CSO] Bunker Buster LTD", 10 ,ZP_TEAM_HUMAN);
	#endif
	
	
}

public Register_Cvars()
{
	register_cvar("nv_bunker_buster", VERSION, FCVAR_SERVER | FCVAR_SPONLY);
	
	g_iCvar[C_DMG_FIRE] = register_cvar("nv_bb_dmg_fire","20.0");
	g_iCvar[C_FIRE_TIME] = register_cvar("nv_bb_fire_time","20");
	g_iCvar[C_DMG_F_RAD] = register_cvar("nv_bb_fire_radius_dmg","200.0");
	g_iCvar[C_SHAKE_RADIUS] = register_cvar("nv_bb_explosion_rad","200.0");
	
	#if defined NORMAL_MOD
		g_iCvar[C_PRICE] = register_cvar("nv_bb_cost","500");
	#endif
	
}

public plugin_precache()
{
	
	for(new i = 0; i <sizeof(MODELS);i++)
	{
		precache_model(MODELS[i]);
	}
	
	for(new i = 0; i <sizeof(GENERIC);i++)
	{
		precache_generic(GENERIC[i]);
	}
	for(new i = 0; i <sizeof(SOUND);i++)
	{
		precache_sound(SOUND[i]);
	}
	
	m_iTrail = precache_model("sprites/smoke.spr");
	m_iExp = precache_model(SPRITES[0]);
	m_iFire = precache_model(SPRITES[1]);
	m_iSmoke = precache_model("sprites/smokepuff.spr");
	m_iBlackS = precache_model(SPRITES[3]);
}
public plugin_natives()
{
	register_native("nv_give_user_bunker","Give_Bunker");
	register_native("nv_remove_user_bunker","Remove_Bunker");
	register_native("nv_Get_user_bunker","Native_Get_Bunker");
	register_native("is_bunkerbuster","Native_Is_Bunker");
	
}

public Native_Get_Bunker(id)
{
	return Get_BitVar(g_has_Bunker,id);
}

public Native_Is_Bunker(Ent)
{
	if(pev_valid(Ent))
	{
		if(pev(Ent,pev_impulse) == WEAPON_KEY)
			return true;
	}
	return false;
}

public client_connect(id) Remove_Bunker(id);

#if AMXX_VERSION_NUM >= 183

public client_disconnected(id) Remove_Bunker(id);

#else

public client_disconnect(id) Remove_Bunker(id);

#endif

#if defined ZOMBIE_PLAUGE

public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_itemid)
	{
		Give_Bunker(id);
	}
}

public zp_user_infected_pre(id)
{
	Remove_Bunker(id);

}
public zp_user_humanized_pre(id)
{
	Remove_Bunker(id);
}

#endif

#if defined ZOMBIE_ESCAPE_MOD

public ze_select_item_pre(id, itemid)
{
	if (itemid != g_itemid)
		return 0;
	
	if (ze_is_user_zombie(id))
		return 2;
   
	return 0;
}


public ze_select_item_post(id, itemid)
{
	if (itemid == g_itemid)
	{
		Give_Bunker(id);
	}

}

public ze_user_infected(id, infector)
{
	if(Get_BitVar(g_has_Bunker,id)) Remove_Bunker(id);
}

#endif

#if defined NORMAL_MOD

public Buy_Bunker(id)
{
	if(is_user_alive(id))
	{
		if(cs_get_user_money(id) >= get_pcvar_num(g_iCvar[C_PRICE]))
		{
			Give_Bunker(id);
			cs_set_user_money(id,cs_get_user_money(id)-get_pcvar_num(g_iCvar[C_PRICE]));
			ChatColor(id,"^3[^4B:B^3] You Have Buyed ^3 Bunker Buster LTD ^4...");
		}
		else
			ChatColor(id,"^3[^4B:B^3] You Are Poor xD...");
	}
}

#endif

public Hook_Cmd(id)
{
	engclient_cmd(id,weapon_bunker);
	return PLUGIN_HANDLED;
}

// Create Fake Bunker Drop..

public Drop_Bunker(id)
{
	if(is_user_alive(id))
	{
		if(get_user_weapon(id) == CSW_BUNKER && Get_BitVar(g_has_Bunker, id))
		{
			Create_Fake_World(id);
			Remove_Bunker(id);
			ham_strip_weapon(id,weapon_bunker);
			
			#if defined KNIFE_ITEM
				give_item(id,weapon_bunker);	
			#endif
			
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

// Just Some Safety

public newRound()
{
	for(new i=1;i<= g_maxplayer;i++)
	{
		Remove_Bunker(i);
	}
	
	fm_remove_entity_name(C_Plane);
	fm_remove_entity_name(C_Target);
	fm_remove_entity_name(C_Missile);
	fm_remove_entity_name(C_Bunker);
}

public logevent_round_end()
{
	for(new i=1;i<= g_maxplayer;i++)
	{
		Remove_Bunker(i);
	}
	
	fm_remove_entity_name(C_Plane);
	fm_remove_entity_name(C_Target);
	fm_remove_entity_name(C_Missile);
	fm_remove_entity_name(C_Bunker);
	
}


public Give_Bunker(id)
{
	if(is_user_alive(id))
	{
		if(!Get_BitVar(g_has_Bunker,id))
		{
			#if defined HE_ITEM
			
				Set_BitVar(g_has_Bunker,id);
				UnSet_BitVar(g_selected,id);
				UnSet_BitVar(g_zoom,id);
				give_item(id,weapon_bunker);
				engclient_cmd(id,weapon_bunker);
				Wpnlist(id,1);
				
			#endif
			#if defined KNIFE_ITEM
			
				Set_BitVar(g_has_Bunker,id);
				UnSet_BitVar(g_selected,id);
				UnSet_BitVar(g_zoom,id);
				Wpnlist(id,1);
				engclient_cmd(id,weapon_bunker);
			#endif
			
			client_print(id,print_center,"Press E For Changing Mode");
			
			// Why Again, if it is Added on Deploy ? Hm if user Don't Have HE The Engine Switch it HE when giving and Model Not Changed..
			
			set_pev(id,pev_viewmodel2,MODELS[M_V_MODEL]);
			set_pev(id,pev_weaponmodel2,MODELS[M_P_MODEL]);
			
		}
		#if defined HE_ITEM
		else
		{
			// User Have Bunker Buseter , So lets Give Him AMMO.
			
			static Ent; Ent = fm_get_user_weapon_entity(id, CSW_BUNKER);
			if(pev_valid(Ent))
			{
				cs_set_user_bpammo(id, CSW_BUNKER, cs_get_user_bpammo(id,CSW_BUNKER)+1);
			}
		}
		#endif
	}
	
}
public Remove_Bunker(id)
{
	UnSet_BitVar(g_has_Bunker,id);
	UnSet_BitVar(g_selected,id);
	UnSet_BitVar(g_zoom,id);
	
	Wpnlist(id,0);
	Remove_Entities_By_Id(id);
	
}

public Remove_Entities_By_Id(id)
{
	new ent;
	while((ent = find_ent_by_class(ent,C_Plane))!= 0)
	{
		if(pev_valid(ent))
		{
			if(pev(ent,pev_iuser1) == id)
			{
				fm_remove_entity(ent);
				remove_task(ent);
			}
		}
	}
	while((ent = find_ent_by_class(ent,C_Missile))!= 0)
	{
		if(pev_valid(ent))
		{
			if(pev(ent,pev_iuser1) == id)
			{
				fm_remove_entity(ent);
				remove_task(ent);
				remove_task(ent+TASK_FIRE);
			}
		}
	}
	while((ent = find_ent_by_class(ent,C_Target))!= 0)
	{
		if(pev_valid(ent))
		{
			if(pev(ent,pev_iuser1) == id)
			{
				fm_remove_entity(ent);
				remove_task(ent);
			}
		}
	}
}



/*----------------------------------*/
/*           	FORWARDS            */
/*----------------------------------*/

public fw_Ham_Spawn(id)
{
	if(is_user_alive(id))
	{
		Remove_Bunker(id);
	}
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(is_user_alive(id))
	{
		if(Get_BitVar(g_has_Bunker,id) && cs_get_user_weapon(id) == CSW_BUNKER)
		{
			new Float:eOrigin[3],Float:hOrigin[3];
		
			static iButton; iButton = get_uc(uc_handle, UC_Buttons);
			static OldButton; OldButton = pev(id, pev_oldbuttons);
		
			if(iButton & IN_ATTACK)
			{
				if(Get_BitVar(g_zoom,id))
				{
					if(!Get_BitVar(g_selected,id))
					{
						get_user_hitpoint(id,hOrigin);
				
						pOrigin[0] = hOrigin[0];
						pOrigin[1] = hOrigin[1];
						pOrigin[2] = hOrigin[2];
				
						Set_BitVar(g_selected,id);
						
						#if defined HE_ITEM
							emit_sound(id, CHAN_WEAPON, SOUND[S_GAUGE],  VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
						#endif
					}
					
					set_weapon_anim(id,0,1);
				}
				
			}
			if(OldButton & IN_ATTACK && !(iButton & IN_ATTACK))
			{
				
				if(Get_BitVar(g_selected,id) && Get_BitVar(g_zoom,id))
				{
					get_user_hitpoint(id,eOrigin);
					
					// If The Starting and Ending Point are Same or Maybe Too Near 
					// Than Throw Only One BOMB... at Aim Position....
				
					if(get_distance_f(pOrigin,eOrigin) < 100.0)
					{
						Create_Missile(id,pOrigin);
						Create_Target(id,eOrigin);
					}
					else
					{
						Create_Target(id,pOrigin);
						Create_Target(id,eOrigin);
						Create_Plane(id,pOrigin,eOrigin);
						
					}
					
					set_weapon_anim(id,0,0);
					UnSet_BitVar(g_zoom,id);
					UnSet_BitVar(g_selected,id);
					set_pev(id,pev_viewmodel2,MODELS[M_V_MODEL]);
					
					#if defined KNIFE_ITEM
						UnSet_BitVar(g_has_Bunker,id);
						ham_strip_weapon(id,weapon_bunker);
						give_item(id,weapon_bunker);
						Wpnlist(id,0);
					#endif
					
					set_task(0.5,"Task_Siren",id,_,_,"a",10);
				}
				
			}
			if(OldButton & IN_ATTACK2 && !(iButton & IN_ATTACK2))
			{
				
				if(!Get_BitVar(g_zoom,id))
				{
					emit_sound(id, CHAN_WEAPON, SOUND[S_ZOOM_IN],  VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					Set_BitVar(g_zoom,id);
					set_pev(id,pev_viewmodel2,MODELS[M_V_MODEL_SIGHT]);
				}
				else
				{	
					UnSet_BitVar(g_zoom,id);
					emit_sound(id, CHAN_WEAPON, SOUND[S_ZOOM_OUT],  VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					set_pev(id,pev_viewmodel2,MODELS[M_V_MODEL]);
					set_weapon_anim(id,2,0);
				}
			}
			if(OldButton & IN_USE && !(iButton & IN_USE))
			{
				
				switch(g_iPlayer_Mode[id])
				{
					case MODE_ENDLESS:
					{
						g_iPlayer_Mode[id] = MODE_INPOINT;
						client_print(id,print_center,"Bunker Mode:- Between Targets");
					}
				
					case MODE_INPOINT:
					{
						g_iPlayer_Mode[id] = MODE_ENDLESS;
						client_print(id,print_center,"Bunker Mode:- EndLess");
					}
				}
			}
		}
	}
}

#if defined HE_ITEM

public fw_Primary_Attack(ent)
{
	if(pev_valid(ent))
	{
		new id = pev(ent,pev_owner);
		
		if(is_user_alive(id))
		{
			if(Get_BitVar(g_has_Bunker,id))
			{
				// The Player Has Not Opened Zoom , So Lets Block Him xD
				if(!Get_BitVar(g_zoom,id))
					return HAM_SUPERCEDE;
			}
		}
	}
	return HAM_IGNORED;	
}

// Yeah Boi , This Was My iDeA...

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED;
	
	static id;
	id = pev(entity, pev_owner);
	
	if(!is_user_alive(id))
		return FMRES_IGNORED;
		
	if(equal(model, old_w_model))
	{
		if(Get_BitVar(g_has_Bunker, id))
		{
			if(cs_get_user_bpammo(id,CSW_BUNKER) < 2)
			{
				UnSet_BitVar(g_has_Bunker, id);
				Wpnlist(id,0);
			}
			remove_entity(entity);
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

#endif

// I Have No Idea About This xD.

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
		
	if(get_user_weapon(id) == CSW_BUNKER && Get_BitVar(g_has_Bunker, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001);
	
	return FMRES_HANDLED;
}

// Opps We Hit SomeThing...

public Fw_Touch(iEnt, iTouch)
{
	if(is_valid_ent(iEnt))
	{
		
		new Float:Origin[3];
		pev(iEnt,pev_origin,Origin);
		
		if((engfunc(EngFunc_PointContents , Origin) != CONTENTS_WATER))
		{	
		
			CreateExplosion(iEnt,Origin);
			
			set_task(0.1,"Create_Fire",iEnt + TASK_FIRE,_,_,"a",get_pcvar_num(g_iCvar[C_FIRE_TIME])*10);
			emit_sound(iEnt, CHAN_ITEM, SOUND[5],  0.5, ATTN_NORM, 0, PITCH_NORM);
			

			set_task(get_pcvar_float(g_iCvar[C_FIRE_TIME]) + 1.0,"Kill_Remove",iEnt);
			
			// We Don't Remove The Ent , Just make it Invisible
			
			set_pev(iEnt, pev_movetype, MOVETYPE_NONE);
			set_pev(iEnt, pev_solid, SOLID_NOT);
			engfunc(EngFunc_SetModel, iEnt, "");
		}
		else
		{
			// Damn Bomb Hits The Water , Lets Make Smoke fissssss....
			
			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0);
			write_byte(TE_SMOKE); // TE id
			engfunc(EngFunc_WriteCoord, Origin[0]); // x
			engfunc(EngFunc_WriteCoord, Origin[1]); // y
			engfunc(EngFunc_WriteCoord, Origin[2]-50.0); // z
			write_short(m_iBlackS); // sprite
			write_byte(random_num(40,60)); // scale
			write_byte(random_num(10, 20)); // framerate
			message_end();
			
			Kill_Remove(iEnt);
		}
		
	}
}

public Fw_Touch_Bunker(ent,id)
{
	if(is_valid_ent(ent))
	{
		if(is_user_alive(id))
		{
			if(!Get_BitVar(g_has_Bunker,id))
			{
				Give_Bunker(id);
				remove_entity(ent);
			}
		}
	}
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED;
		
	if(Get_BitVar(g_has_Bunker, id))
	{
		set_pev(Ent,pev_impulse,WEAPON_KEY);
		Wpnlist(id,1);
	}
	else
	{
		// Just For Safety
		set_pev(Ent,pev_impulse,0);
		Wpnlist(id,0);
	}
	return HAM_HANDLED;
}

public fw_Item_Deploy(entity)
{
	if(!pev_valid(entity))
		return HAM_IGNORED;
	
	new id = pev(entity,pev_owner);
	if(Get_BitVar(g_has_Bunker, id))
	{
		UnSet_BitVar(g_zoom,id);
		set_pev(id,pev_viewmodel2,MODELS[M_V_MODEL]);
		set_pev(id,pev_weaponmodel2,MODELS[M_P_MODEL]);
	}
	
	return HAM_HANDLED;
}

/*----------------------------------*/
/*            	ENTITY              */
/*----------------------------------*/
	
public Create_Plane(id,Float:sOrigin[3],Float:eOrigin[3])
{
	new i_Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_breakable"));
	entity_set_model(i_Ent,MODELS[M_PLANE]);
	
	set_pev(i_Ent, pev_classname, C_Plane);
	set_pev(i_Ent, pev_solid, SOLID_NOT);
	set_pev(i_Ent, pev_movetype, MOVETYPE_NOCLIP);
	
	sOrigin[2] = GetMaxHeight(i_Ent,sOrigin);
	
	set_pev(i_Ent, pev_origin,sOrigin);
	set_pev(i_Ent, pev_iuser1,id);
	
	set_pev(i_Ent, pev_vuser1,sOrigin);
	set_pev(i_Ent, pev_vuser2,eOrigin);
	
	Aim_To_Target(i_Ent,eOrigin);
	
	fm_set_rendering(i_Ent,kRenderFxNone,0,0,0,kRenderTransAlpha,0); 
	
	// This is Random Value , I Am Not Sure When To Remove , Bcz This Depends On Map Size :-D
	
	set_task(20.0,"Kill_Remove",i_Ent);
	set_task(4.0,"Task_Fly",i_Ent);
	
	set_pev(i_Ent, pev_nextthink,get_gametime() + 4.0);
	
}

public Create_Fake_World(id) 
{
	new Float:Aim[3],Float:origin[3];
	VelocityByAim(id, 80, Aim);
	entity_get_vector(id,EV_VEC_origin,origin);
	
	origin[0] += Aim[0];
	origin[1] += Aim[1];
	
	new i_Ent = create_entity("info_target");
	entity_set_string(i_Ent,EV_SZ_classname,C_Bunker);
	entity_set_model(i_Ent,MODELS[M_W_MODEL]);
	entity_set_size(i_Ent,Float:{-2.0,-2.0,-2.0},Float:{5.0,5.0,5.0});
	entity_set_int(i_Ent,EV_INT_solid,1);
	entity_set_int(i_Ent,EV_INT_movetype,6);
	entity_set_vector(i_Ent,EV_VEC_origin,origin);
	
}

public Create_Target(id,Float:sOrigin[3])
{
	new i_Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	entity_set_model(i_Ent,MODELS[M_TARGET]);
	
	set_pev(i_Ent, pev_classname, C_Target);
	set_pev(i_Ent, pev_solid, SOLID_NOT);
	set_pev(i_Ent, pev_movetype, MOVETYPE_TOSS);
	set_pev(i_Ent, pev_origin,sOrigin);
	set_pev(i_Ent, pev_iuser1,id);
	set_pev(i_Ent, pev_light_level, 180);
	set_pev(i_Ent, pev_rendermode, kRenderTransAdd);
	set_pev(i_Ent, pev_renderamt, 255.0);
	
	set_anim(i_Ent,0);
	
	set_task(10.0,"Direct_Remove",i_Ent);
}

public Create_Missile(id,Float:sOrigin[3])
{
	new Float:vAngle[3];
	new i_Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_breakable"));
	entity_set_model(i_Ent,MODELS[M_MISSILE]);
	
	set_pev(i_Ent, pev_classname, C_Missile);
	set_pev(i_Ent, pev_solid, SOLID_BBOX);
	set_pev(i_Ent, pev_movetype, MOVETYPE_TOSS);
	set_pev(i_Ent, pev_size, Float:{-34.0, -34.0, -94.0}, Float:{34.0, 34.0, 95.0});
	set_pev(i_Ent, pev_iuser1,id);
	
	sOrigin[2] = GetMaxHeight(i_Ent,sOrigin);
	
	set_pev(i_Ent, pev_origin,sOrigin);
	
	vAngle[0] -= 90.0;
	set_pev(i_Ent, pev_angles, vAngle);
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte(TE_BEAMFOLLOW);
	write_short(i_Ent);		//entity
	write_short(m_iTrail);		//model
	write_byte(7);			//life
	write_byte(5);			//width
	write_byte(224);		//r
	write_byte(224);		//g
	write_byte(255);		//b
	write_byte(190);		//brightness
	message_end();	
	
	emit_sound(i_Ent, CHAN_STATIC, SOUND[random_num(9,11)],  VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	set_pev(i_Ent, pev_nextthink,get_gametime() + 0.1);
	
}

public Create_Fire(taskid)
{
	new ent = taskid-TASK_FIRE;
	
	if(pev_valid(ent))
	{
		new iOwner = pev(ent,pev_iuser1);
		new Float:Origin[3];
		
		new iVictim;
		iVictim = FM_NULLENT;
		
		pev(ent,pev_origin,Origin);
		
		while((iVictim = find_ent_in_sphere(iVictim, Origin, get_pcvar_float(g_iCvar[C_DMG_F_RAD]))) > 0)
		{
			if(is_user_alive(iVictim))
			{	
				if(is_target_capable(iOwner,iVictim))
				{
					if(!(get_user_flags(iVictim) & FL_INWATER))
					{
						ExecuteHamB(Ham_TakeDamage, iVictim, ent, iOwner,get_pcvar_float(g_iCvar[C_DMG_FIRE])/10.0, DMG_BURN);
					}
				}
			}
		}
		
		random_fire(ent);
		
	}
}

public Task_Siren(id)
{
	if(is_user_alive(id))
	{
		emit_sound(id, CHAN_WEAPON, SOUND[S_TARGET],  VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

public Task_Fly(ent)
{
	if(pev_valid(ent))
	{
		emit_sound(0, CHAN_WEAPON, SOUND[S_FLY],  VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

public Think_Missile(ent)
{
	if(is_valid_ent(ent)) 
	{
		static Float:Origin[3];
		pev(ent, pev_origin, Origin);
		
		if(!(entity_get_int(ent,EV_INT_flags) & FL_ONGROUND))
		{
			Make_FireSmoke(ent);
		}
		
		set_pev(ent, pev_nextthink,get_gametime() + 0.1);
	}
}

public Think_Plane(ent)
{
	if(is_valid_ent(ent))
	{
		fm_set_rendering(ent);
		
		new Float:sOrigin[3],Float:Velocity[3],Float:eOrigin[3],Float:Origin[3], Float:vRefDistance, Float:vCurrentDistance ,iDiffDistance;
		new id = pev(ent,pev_iuser1);
		
		if(is_user_alive(id))
		{
			pev(ent,pev_origin,Origin);
			pev(ent,pev_vuser1,sOrigin);
			pev(ent,pev_vuser2,eOrigin);
		
			velocity_by_aim(ent, 350, Velocity);
			set_pev(ent, pev_velocity, Velocity);
		
			if(g_iPlayer_Mode[id] == MODE_INPOINT)
			{
				sOrigin[2] = Origin[2];
				eOrigin[2] = Origin[2];
			
				// Thanks RAHEEM for This Calculation , You know from where i took it xD
			
				// Refference distance = distance between first point and second point defined by player
				// Current distance = distance between first point defined by player and current origin of the plane
			
				vRefDistance = get_distance_f(sOrigin, eOrigin);
				vCurrentDistance = get_distance_f(sOrigin, Origin);
				
				// Get difference as integer, ensure that it always +ve using abs (Maybe not neccesary)
				iDiffDistance = abs(floatround(vRefDistance)) - abs(floatround(vCurrentDistance));
			
				if(iDiffDistance >= - 50.0)
				{
					Create_Missile(id,Origin);
				}
			}
			else if(g_iPlayer_Mode[id] == MODE_ENDLESS)
			{
				Create_Missile(id,Origin);
			}
		}
		set_pev(ent, pev_nextthink,get_gametime() + 1.0);
	}
}

public Direct_Remove(ent)
{
	if(pev_valid(ent))  fm_remove_entity(ent);
}

public Kill_Remove(ent)
{
	if(pev_valid(ent)) set_pev(ent, pev_flags, FL_KILLME);
}

public Aim_To_Target(iEnt, Float:vTargetOrigin[3])
{
	if(!pev_valid(iEnt))	
		return;
		
	static Float:Vec[3], Float:Angles[3];
	pev(iEnt, pev_origin, Vec);
	
	Vec[0] = vTargetOrigin[0] - Vec[0];
	Vec[1] = vTargetOrigin[1] - Vec[1];
	Vec[2] = vTargetOrigin[2] - Vec[2];
	engfunc(EngFunc_VecToAngles, Vec, Angles);
	Angles[0] = Angles[2] = 0.0 ;
	
	set_pev(iEnt, pev_v_angle, Angles);
	set_pev(iEnt, pev_angles, Angles);
}
 

public Make_FireSmoke(Ent)
{
	if(pev_valid(Ent))
	{
		static Float:Origin[3];
		pev(Ent, pev_origin, Origin);
	
		Origin[2] -= 10.0;
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) ;
		write_byte(TE_EXPLOSION) ;
		engfunc(EngFunc_WriteCoord, Origin[0]);
		engfunc(EngFunc_WriteCoord, Origin[1]);
		engfunc(EngFunc_WriteCoord, Origin[2]);
		write_short(m_iSmoke) ;
		write_byte(10);
		write_byte(10);
		write_byte(14);
		message_end();
	}	
}

public CreateExplosion(ent,Float:fOrigin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2] + 300);
	write_short(m_iExp);
	write_byte(60);
	write_byte(200);
	message_end();
	
	// Put decal on "world" (a wall)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_WORLDDECAL);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_byte(random_num(46, 48));
	message_end();	
	
	emit_sound(ent, CHAN_WEAPON, SOUND[random_num(3,4)],  1.0, ATTN_NORM, 0, PITCH_NORM);

	for(new i = 0; i <= g_maxplayer ;i++)
	{
		if(is_user_alive(i))
		{
			if(is_user_in_sphere(ent,i,get_pcvar_float(g_iCvar[C_SHAKE_RADIUS])))
			{
				Util_ScreenShake(i);
			}
		}
	}
}

public is_target_capable(owner,target)
{
	if(is_user_alive(owner) && is_user_alive(target))
	{
		#if defined NORMAL_MOD
		
		if(cs_get_user_team(owner) != cs_get_user_team(target) && owner != target)
			return true;
		
		#endif
		
		#if defined ZOMBIE_ESCAPE_MOD
		if(ze_is_user_zombie(target) && owner != target)
			return true;
		
		#endif
		
		#if defined ZOMBIE_PLAUGE
		
		if(zp_get_user_zombie(target) && owner != target)
			return true;
			
		#endif
		
	}
	return false;
}
 
public Float:GetMaxHeight( iEnt, Float:fOrigin[ 3 ] ) 
{ 
    new pcCurrent;
    
    while( engfunc( EngFunc_PointContents , fOrigin ) == CONTENTS_EMPTY )
    {
        fOrigin[ 2 ] += 5.0; 
    }
    
    pcCurrent = engfunc( EngFunc_PointContents , fOrigin ); 

    return ( ( pcCurrent == CONTENTS_SKY )) ? fOrigin[ 2 ] - 150.0 : fOrigin[ 2 ];
}

public is_user_in_sphere(id,enemy,Float:radius)
{
	new Float:Distance;
	Distance = entity_range(id, enemy);
	
	if(Distance <= radius)
		return true;
	
	return false;
	
}

public Wpnlist(id,type)
{
	if(is_user_alive(id))
	{
		message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
		write_string(type?"weapon_bunker":weapon_bunker);
		
		#if defined HE_ITEM
		write_byte(12);
		write_byte(1);
		write_byte(-1);
		write_byte(-1);
		write_byte(3);
		write_byte(1);
		write_byte(CSW_BUNKER);
		write_byte(24);
		#endif
		
		#if defined KNIFE_ITEM
		
		write_byte(-1);
		write_byte(-1);
		write_byte(-1);
		write_byte(-1);
		write_byte(2);
		write_byte(1);
		write_byte(CSW_BUNKER);
		write_byte(24);
		
		#endif
		
		message_end();
	}
}

/*----------------------------------*/
/*            	STOCKS              */
/*----------------------------------*/

stock ham_strip_weapon(id,weapon[])
{
    if(!equal(weapon,"weapon_",7)) return 0;

    new wId = get_weaponid(weapon);
    if(!wId) return 0;

    new wEnt;
    while((wEnt = engfunc(EngFunc_FindEntityByString,wEnt,"classname",weapon)) && pev(wEnt,pev_owner) != id) {}
    if(!wEnt) return 0;

    if(get_user_weapon(id) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon,wEnt);

    if(!ExecuteHamB(Ham_RemovePlayerItem,id,wEnt)) return 0;
    ExecuteHamB(Ham_Item_Kill,wEnt);

    set_pev(id,pev_weapons,pev(id,pev_weapons) & ~(1<<wId));
    return 1;
}

stock random_fire(ent) 
{
	if(pev_valid(ent))
	{
	
		new Float:range = 200.0;
	
		new Float:iOrigin[3], Float:Origin[3];
		pev(ent,pev_origin,Origin);
	
		for ( new i = 1 ; i <= 3 ; i++ ) 
		{
			iOrigin[0] = Origin[0] + random_float(-range, range);
			iOrigin[1] = Origin[1] + random_float(-range, range);
			iOrigin[2] = Origin[2];
		
		
			while ( get_distance_f(iOrigin, Origin) > range ) 
			{
			
				iOrigin[0] = Origin[0] + random_float(-range, range);
				iOrigin[1] = Origin[1] + random_float(-range, range);
				iOrigin[2] = Origin[2];
			}
		
			Flame(iOrigin);	
		}
	}
}

stock Flame(Float:iOrigin[3]) 
{
	
	new rand = random_num(3, 9);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, iOrigin[0]); // x
	engfunc(EngFunc_WriteCoord, iOrigin[1]); // y
	engfunc(EngFunc_WriteCoord, iOrigin[2] + 100.0); // z
	write_short(m_iFire);
	write_byte(rand);
	write_byte(100);
	message_end();
	
}

stock set_weapon_anim(id, anim,body)
{
	if(!is_user_alive(id))
		return;
	
	set_pev(id, pev_weaponanim, anim);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id);
	write_byte(anim);
	write_byte(body);
	message_end();
}

stock ground_z(iOrigin[3], ent, skip = 0) {
	
	iOrigin[2] += random_num(5, 80);
	
	new Float:fOrigin[3];
	
	IVecFVec(iOrigin, fOrigin);
	
	set_pev(ent, pev_origin, fOrigin);
	
	engfunc(EngFunc_DropToFloor, ent);
	
	if ( ! skip && ! engfunc(EngFunc_EntIsOnFloor, ent) )
		return ground_z(iOrigin, ent);
	
	pev(ent, pev_origin, fOrigin);
	
	return floatround(fOrigin[2]);
}

stock Util_ScreenShake(id)
{
	static ScreenShake = 0;
	if( !ScreenShake )
	{
		ScreenShake = get_user_msgid("ScreenShake");
	}
	if(is_user_connected(id))
	{
		message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, ScreenShake, _, id);
		write_short(255<<14); //ammount 
		write_short(10 << 14); //lasts this long 
		write_short(255<< 14); //frequency 
		message_end();
	}
}

stock get_user_hitpoint(id, Float:hOrigin[3])  
{ 
	if (!is_user_alive( id )) 
	return 0; 
	
	new Float:fOrigin[3], Float:fvAngle[3], Float:fvOffset[3], Float:fvOrigin[3], Float:feOrigin[3]; 
	new Float:fTemp[3]; 
	
	pev(id, pev_origin, fOrigin); 
	pev(id, pev_v_angle, fvAngle); 
	pev(id, pev_view_ofs, fvOffset); 
	
	xs_vec_add(fOrigin, fvOffset, fvOrigin); 
	
	engfunc(EngFunc_AngleVectors, fvAngle, feOrigin, fTemp, fTemp); 
	
	xs_vec_mul_scalar(feOrigin, 9999.0, feOrigin); 
	xs_vec_add(fvOrigin, feOrigin, feOrigin); 
	
	engfunc(EngFunc_TraceLine, fvOrigin, feOrigin, 0, id); 
	global_get(glb_trace_endpos, hOrigin); 
	
	return 1; 
}

stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
       
	replace_all(msg, 190, "!g", "^4"); // Green Color
	replace_all(msg, 190, "!y", "^1"); // Default Color
	replace_all(msg, 190, "!team", "^3"); // Team Color
	replace_all(msg, 190, "!team2", "^0"); // Team2 Color
       
        if (id) players[0] = id; else get_players(players, count, "ch");
        {
                for (new i = 0; i < count; i++)
                {
                        if (is_user_connected(players[i]))
                        {
                                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
                                write_byte(players[i]);
                                write_string(msg);
                                message_end();
                        }
                }
        }
}


stock set_anim(ent, sequence) 
{
	if(is_valid_ent(ent))
	{
		set_pev(ent, pev_sequence, sequence);
		set_pev(ent, pev_animtime, halflife_time());
		set_pev(ent, pev_framerate, 1.0);
	}
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2057\\ f0\\ fs16 \n\\ par }
*/
