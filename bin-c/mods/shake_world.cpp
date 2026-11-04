#include "definitions.h"

namespace mods
{
namespace
{
class ShakeWorldMod final : public Definition
{
public:
    int version() const override { return 72; }
    const char* name() const override { return "Shake the World"; }
    void applyPresentationDefaults() const override
    {
        TitleString = "All Heros in Kam Yung's Stories - Shake the World";
        MAX_ITEM_AMOUNT = 400;
    }
};
}    //namespace

const Definition& ShakeWorld()
{
    static ShakeWorldMod mod;
    return mod;
}
}    //namespace mods
