--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--
local isOwner=false
function onInit()

	wildcard.getDatabaseNode().onUpdate = onWildcardChanged
	onWildcardChanged()
	type.getDatabaseNode().onUpdate = onTypeChanged
	onTypeChanged()

	updateDisplay()

	DB.createChild(getDatabaseNode(), "inc", "number").onUpdate = updateIncapacitated
	updateMenuOptions()

	updateBackground()

	tokenrefnode.getDatabaseNode().onUpdate = token.onTokenUpdate
	tokenrefid.getDatabaseNode().onUpdate = token.onTokenUpdate
	update()
	getDatabaseNode().onObserverUpdate = update
	link.getDatabaseNode().onUpdate = update
end

function updateOwnership()
	champion_type, champion_record = link.getValue()
	isOwner = DB.isOwner(champion_record)
end

function getActorShortcut()
	return CharacterManager.getActorShortcut("ct", getDatabaseNode())
end

function updateMenuOptions()
	resetMenuItems()
	if User.isHost() then
		registerMenuItem(Interface.getString("ct_menu_delete_combatants"), "delete", 6)
		registerMenuItem(Interface.getString("ct_menu_delete_combatants_confirm"), "delete", 6, 7)
	end
end
--
-- UPDATE AND EVENT HANDLERS
--

function onWildcardChanged()
	local bWildCard = wildcard.getValue() == 1
	wildcard_icon.setIcon(bWildCard and "wildcard" or "nowildcard")
	if bennies then
		bennies.setVisible(bWildCard)
	end
end

function onTypeChanged()
end

function onIDChanged()
	local sType = type.getValue()
	if StringManager.isNotBlank(sType) and sType ~= "pc" then
		local bID = LibraryData.getIDState(sType, getDatabaseNode(), true)
		name.setVisible(bID)
		nonid_name.setVisible(not bID)
		isidentified.setVisible(true)
	else
		name.setVisible(true)
		nonid_name.setVisible(false)
		isidentified.setVisible(false)
	end
end

function updateDisplay()
	if type.isNot("pc") then
		name.setFrame("textline",0,0,0,0)
	end
end

--
-- ACCESSOR METHODS
--

function updateBackground()
	updateBackgroundColor()
end

function updateTargetedBackground()
	setBackColor("33" .. CombatManager2.CT_ENTRY_COLORS.targeted)
end

function updateBackgroundColor()
	setBackColor(nil)
end

function updateIncapacitated()
	local nodeCT = getDatabaseNode()
	if ActionTrait.isAutoRollIncapacitation(nodeCT) then
		ActionTrait.rollIncapacitation(nodeCT)
	end
end

--
-- Helpers
--

function isIncapacitated()
	return CharacterManager.isIncapacitated(getDatabaseNode())
end

function update()
	updateOwnership()
	local participatedNode = getDatabaseNode().getChild("participated")
	local bAlreadyApplied = DB.getValue(getDatabaseNode(),"pendingResultsActivated",0)==1
	if bAlreadyApplied then
		participateButton.setEnabled(false)
		participateButton.setVisible(false)
	else
		participateButton.setEnabled(true)
		participateButton.setVisible(true)
	end
	
	champion_type, champion_record = link.getValue()
	isOwner = DB.isOwner(champion_record)

	if not isOwner then
		participateButton.setVisible(false)
		participation_skill.setComboBoxVisible(false)
		mb_participation_label.setVisible(false)
	else
		participateButton.setVisible(true)
		participation_skill.setComboBoxVisible(true)
		mb_participation_label.setVisible(true)
	end

	participation_skill.update()
end

function makeParticipationRoll(bReroll)
	MassBattles.deleteBEChildNodes(getDatabaseNode())
	local sActorType, sActorLink = link.getValue()
	local sSkill = participation_skill.getValue()
	local nodeActor = DB.findNode(sActorLink)
	ModifierManager.applyEffectModifierOnEntity(sActorType, nodeActor, "battleparticipation")
	local sDescPrefix = Interface.getString("mb_participation_roll_prefix")
	local nodeTrait = SkillManager.getSkillNode(nodeActor, sSkill, true)
	local CustomData = {mb_entry=getDatabaseNode().getPath()}
	if bReroll then
		CustomData.reroll=true
	end
	local rActor = CharacterManager.getActorShortcut(sActorType,nodeActor)
	if bReroll then
		ModifierManager.applyTraitModifiers(sActorType, nodeActor, "reroll")
	end
	TraitManager.rollTrait(rActor, nodeTrait, CustomData, sDescPrefix, "battleparticipation")
end
