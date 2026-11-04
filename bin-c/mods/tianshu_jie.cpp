#include "definitions.h"

namespace mods
{
namespace
{
class TianshuJieMod final : public Definition
{
public:
    int version() const override { return 71; }
    const char* name() const override { return "天书劫"; }
    void applyPresentationDefaults() const override
    {
        TitleString = "All Heros in Kam Yung's Stories - Books from Heaven";
        TitlePosition.x = 60;
        TitlePosition.y = 270;
        MAX_ITEM_AMOUNT = 400;
    }
};
}    //namespace

const Definition& TianshuJie()
{
    static TianshuJieMod mod;
    return mod;
}
}    //namespace mods
