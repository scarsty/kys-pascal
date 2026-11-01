#pragma once

#include "kys_rules.h"
#include <span>

namespace rules { class ProgressionRules; }

namespace mods
{
struct StartingStatsResult
{
    bool fixed = false;
};

// A resolved mod owns its rules, data compatibility and character setup.
// INI selectors are interpreted only by LoadDefinition.
class Definition
{
public:
    virtual ~Definition() = default;
    virtual int version() const = 0;
    virtual const char* name() const = 0;
    virtual const char* ruleProfile() const { return "remake"; }
    virtual const rules::ProgressionRules& progression() const;
    virtual const CombatRules& combat() const;
    virtual bool configurableGrowth() const { return false; }
    virtual void applyPresentationDefaults() const { }
    virtual const char* titleMenuImage() const { return nullptr; }
    virtual std::string defaultPlayerName(const std::string& dataName) const { return dataName; }
    virtual bool renameHomeScene() const { return true; }
    virtual bool clearPreviousEventTile(int targetScene, int currentScene) const { return true; }
    virtual StartingStatsResult createStartingStats(TRole&, const std::string&,
        const RulesRandom& random = RulesRandomDraw) const;
    // Apply visible hero-only presets before confirmation; defer other effects.
    virtual bool applySpecialStartingStats(TRole&, const std::string&) const { return false; }
    virtual void finishCharacterCreation(const std::string&) const { }
    virtual bool worldStepPassable(bool passable, int16_t& inShip) const { return passable; }
    virtual bool worldPathTilePassable(int terrain, bool inShip) const;
    virtual bool sceneTilePassable(int picture, bool passable) const { return passable; }
    virtual const char* partyMenuLabel() const { return "離隊"; }
    virtual const char* partySelectionPrompt() const { return "要求誰離隊？"; }
    virtual const char* confirmationPrompt() const { return "请選擇是或者否"; }
    virtual void customizeStatusLabels(std::span<std::string, 22>) const { }
    virtual int statusMenuEvent() const { return -1; }
    virtual int battleSpecialEvent() const { return -1; }
    virtual bool attackRequirementMet(int attack, int minimum, int maximum) const;
    virtual bool instruction50UsesItemCheck(int instruction) const { return instruction > 128; }
    virtual bool eventUsesWorldPictures(int location, int event) const { return location != 1; }
    virtual bool eventRequestsNumber(int event) const { return false; }
};

const Definition& Active();
const Definition& Find(int version);
void LoadDefinition(const std::string& iniPath);
}    //namespace mods
