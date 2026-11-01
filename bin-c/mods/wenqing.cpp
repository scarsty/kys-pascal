#include "definitions.h"

namespace mods
{
namespace
{
class WenqingMod final : public Definition
{
public:
    int version() const override { return 91; }
    const char* name() const override { return "问情"; }
    void applyPresentationDefaults() const override
    {
        TitleString = "All Heros in Kam Yung's Stories - What's Loving";
    }
    bool renameHomeScene() const override { return false; }
};
}    //namespace

const Definition& Wenqing()
{
    static WenqingMod mod;
    return mod;
}
}    //namespace mods
