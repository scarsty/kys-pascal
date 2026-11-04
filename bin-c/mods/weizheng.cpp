#include "definitions.h"

namespace mods
{
namespace
{
class WeizhengMod final : public Definition
{
public:
    int version() const override { return 51; }
    const char* name() const override { return "魏征"; }
    void applyPresentationDefaults() const override
    {
        TitleString = "All Heros in Kam Yung's Stories - An Prime Minister of Tang";
    }
    int statusMenuEvent() const override { return 1092; }
    int battleSpecialEvent() const override { return 1077; }
};
}    //namespace

const Definition& Weizheng()
{
    static WeizhengMod mod;
    return mod;
}
}    //namespace mods
