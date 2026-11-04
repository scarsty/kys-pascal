#include "definitions.h"
#include <map>

namespace mods
{
namespace
{
class OtherMod final : public Definition
{
public:
    int version() const override { return 100; }
    const char* name() const override { return "其他"; }
    void applyPresentationDefaults() const override { TitlePosition.y = 270; }
    bool applySpecialStartingStats(TRole& role, const std::string& name) const override { return ApplyBaseStartingStats(role, name); }
    void finishCharacterCreation(const std::string& name) const override { ApplyBaseCharacterSetup(name); }
};

class UnspecifiedMod final : public Definition
{
    int id;
public:
    explicit UnspecifiedMod(int version) : id(version) { }
    int version() const override { return id; }
    const char* name() const override { return "未指定 MOD"; }
    void applyPresentationDefaults() const override { TitlePosition.y = 270; }
};
}    //namespace

const Definition& Other()
{
    static OtherMod mod;
    return mod;
}

const Definition& Unspecified(int version)
{
    static std::map<int, UnspecifiedMod> definitions;
    return definitions.try_emplace(version, version).first->second;
}
}    //namespace mods
