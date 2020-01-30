SUBSYSTEM_DEF(materials)
	name = "Materials"
	init_order = SS_INIT_MATERIALS
	flags = SS_NO_FIRE

	var/list/materials
	var/list/materials_by_name
	var/list/alloy_components
	var/list/alloy_products
	var/list/processable_ores
	var/list/fusion_reactions

/datum/controller/subsystem/materials/Initialize()
	build_material_lists()
	build_fusion_reaction_list()
	. = ..()

/datum/controller/subsystem/materials/proc/build_material_lists()

	if(LAZYLEN(materials))
		return

	materials =         list()
	materials_by_name = list()
	alloy_components =  list()
	alloy_products =    list()
	processable_ores =  list()

	for(var/type in subtypesof(/material))
		var/material/new_mineral = new type
		if(new_mineral.name)
			materials += new_mineral
			materials_by_name[lowertext(new_mineral.name)] = new_mineral
			if(new_mineral.ore_smelts_to || new_mineral.ore_compresses_to)
				processable_ores[new_mineral.name] = TRUE
			if(new_mineral.alloy_product && LAZYLEN(new_mineral.alloy_materials))
				alloy_products[new_mineral] = TRUE
				for(var/component in new_mineral.alloy_materials)
					processable_ores[component] = TRUE
					alloy_components[component] = TRUE

	. = ..()

/datum/controller/subsystem/materials/proc/get_material_by_name(name)
	if(!materials_by_name)
		build_material_lists()
	. = materials_by_name[name]
	if(!.)
		log_error("Unable to acquire material by name '[name]'")

/proc/material_display_name(name)
	var/material/material = SSmaterials.get_material_by_name(name)
	if(material)
		return material.display_name
	return null

/datum/controller/subsystem/materials/proc/build_fusion_reaction_list()
	fusion_reactions = list()
	for(var/rtype in typesof(/decl/fusion_reaction) - /decl/fusion_reaction)
		var/decl/fusion_reaction/cur_reaction = new rtype()
		if(!fusion_reactions[cur_reaction.p_react])
			fusion_reactions[cur_reaction.p_react] = list()
			fusion_reactions[cur_reaction.p_react][cur_reaction.s_react] = cur_reaction
			if(!fusion_reactions[cur_reaction.s_react])
				fusion_reactions[cur_reaction.s_react] = list()
			fusion_reactions[cur_reaction.s_react][cur_reaction.p_react] = cur_reaction

/datum/controller/subsystem/materials/proc/get_fusion_reaction(var/p_react, var/s_react, var/m_energy)
	if(fusion_reactions.Find(p_react))
		var/list/secondary_reactions = fusion_reactions[p_react]
		if(secondary_reactions.Find(s_react))
			return fusion_reactions[p_react][s_react]
